local AddonName, AddOn = ...
local KIRRI_DEBUG = false

-- Localize
local print, gsub, sfind = print, string.gsub, string.find
local GetItemInfo, IsEquippableItem = GetItemInfo, IsEquippableItem
local GetInventoryItemLink, UnitClass = GetInventoryItemLink, UnitClass
local SendChatMessage, UIParent = SendChatMessage, UIParent
local select, IsInGroup, GetItemInfoInstant = select, IsInGroup, GetItemInfoInstant
local UnitGUID, IsInRaid, GetNumGroupMembers, GetInstanceInfo = UnitGUID, IsInRaid, GetNumGroupMembers, GetInstanceInfo
local C_Timer, InCombatLockdown, time = C_Timer, InCombatLockdown, time
local UnitIsConnected, CanInspect, UnitName = UnitIsConnected, CanInspect, UnitName
local WEAPON, ARMOR, RAID_CLASS_COLORS = _G.WEAPON, _G.ARMOR, RAID_CLASS_COLORS
local CreateFrame, GetDetailedItemLevelInfo = CreateFrame, GetDetailedItemLevelInfo
-- Fix for clients with other languages
local AUCTION_CATEGORY_ARMOR = _G.AUCTION_CATEGORY_ARMOR

local L = AddOn.L
-- local LibItemLevel = LibStub("LibItemLevel")
local LibInspect = LibStub("LibInspect")
local _, playerClass, playerClassId = UnitClass("player")
local icon = LibStub("LibDBIcon-1.0")
local LDB = LibStub("LibDataBroker-1.1"):NewDataObject("DoYouNeedThat", {
    type = "data source",
    text = "DoYouNeedThat",
    icon = "Interface\\Icons\\inv_misc_bag_17",
    OnClick = function(_,buttonPressed)
        if buttonPressed == "RightButton" then
			InterfaceOptionsFrame_OpenToCategory("DoYouNeedThat")
        else
            AddOn:ToggleWindow()
        end
    end,
    OnTooltipShow = function(tooltip)
        if not tooltip or not tooltip.AddLine then return end
        tooltip:AddLine("DoYouNeedThat")
        tooltip:AddLine(L["MINIMAP_ICON_TOOLTIP1"])
        tooltip:AddLine(L["MINIMAP_ICON_TOOLTIP2"])
    end,
})

AddOn.EventFrame = CreateFrame("Frame", nil, UIParent)
AddOn.db = {}
AddOn.Entries = {}
AddOn.RaidMembers = {}
AddOn.Config = {}
AddOn.inspectCount = 1

function AddOn.Print(msg)
	print("[|cff3399FFDYNT|r] " .. msg)
end

function AddOn.Debug(msg)
	if AddOn.Config.debug then AddOn.Print(msg) end
end

function AddOn:kirriCheckInGroup()
	return (IsInGroup() or IsInGroup()) and true or false
end

function AddOn:kirriGetLinkDebug(message)
	local LOOT_ITEM_PATTERN = _G.LOOT_ITEM_SELF:gsub("%%s", "(.+)")
	local link = message:match(LOOT_ITEM_PATTERN)

	if not link then
		return
	end

	return link
end

function AddOn:kirriGetLink(message)
	if KIRRI_DEBUG == true then
		return self:kirriGetLinkDebug(message)
	end

	local LOOT_ITEM_PATTERN = _G.LOOT_ITEM:gsub("%%s", "(.+)")
	local LOOT_ITEM_PUSHED_PATTERN = _G.LOOT_ITEM_PUSHED:gsub("%%s", "(.+)")
	local LOOT_ITEM_MULTIPLE_PATTERN = _G.LOOT_ITEM_MULTIPLE:gsub("%%s", "(.+)")
	local LOOT_ITEM_PUSHED_MULTIPLE_PATTERN = _G.LOOT_ITEM_PUSHED_MULTIPLE:gsub("%%s", "(.+)")
	
    local _, link = message:match(LOOT_ITEM_MULTIPLE_PATTERN)

    if not link then
        _, link = message:match(LOOT_ITEM_PUSHED_MULTIPLE_PATTERN)

        if not link then
            _, link = message:match(LOOT_ITEM_PATTERN)

            if not link then
                _, link = message:match(LOOT_ITEM_PUSHED_PATTERN)

                if not link then
                    return
                end
            end
        end
    end
	
	return link
end

function AddOn:kirriGetItemID(itemLink)
    return tonumber(itemLink:match("item:(%d+)"))
end

-- Events: CHAT_MSG_LOOT, BOSS_KILL
function AddOn:CHAT_MSG_LOOT(...)
	local message, _, _, _, looter = ...
	local item = self:kirriGetLink(message)

	if not item then return end

	local itemName, itemLink, rarity, _, _, type, _, _, equipLoc, _, _, itemClass, itemSubClass = GetItemInfo(item)

	if not IsEquippableItem(itemLink) then
		if KIRRI_DEBUG == true then
			print('IsEquippableItem: false')
			print(itemName)
		end

		return
	end

	-- If not Armor/Weapon
	if (type ~= ARMOR and type ~= AUCTION_CATEGORY_ARMOR and type ~= WEAPON) then
		if KIRRI_DEBUG == true then
			print('IsArmorWeapon: false')
			print(itemName)
		end

		return
	end

	-- If its a Legendary or under rare quality
	if KIRRI_DEBUG == true then
		if rarity == 5 or rarity < 2 then
			print('Rarity: false')
			print(rarity)
			print(itemName)
	
			return
		end
	else
		if rarity == 5 or rarity < 3 then
			if KIRRI_DEBUG == true then
				print('Rarity: false')
				print(rarity)
				print(itemName)
			end
	
			return
		end
	end

	-- If not equippable by your class return
	if not self:IsEquippableForClass(itemClass, itemSubClass, equipLoc) then
		if KIRRI_DEBUG == true then
			print('IsEquippableForClass: false')
			print(itemName)
		end

		return
	end

	-- Should get rid of class specific pieces that you cannnot equip.
	if not DoesItemContainSpec(itemLink, playerClassId) then
		if KIRRI_DEBUG == true then
			print('DoesItemContainSpec: false')
			print(itemName)
		end

		return
	end

	--local _, iLvl = LibItemLevel:GetItemInfo(item)
	local iLvl = GetDetailedItemLevelInfo(itemLink)

	self.Debug(itemLink .. " " .. iLvl)
	if KIRRI_DEBUG == true then
		print('itemLink')
		print(iLvl)
		print('equipLoc')
		print(equipLoc)
	end

	if AddOn.Config.check_isitemupgrade then
		if not self:IsItemUpgrade(iLvl, equipLoc) then
			if KIRRI_DEBUG == true then
				print('IsItemUpgrade: false')
				print(iLvl)
				print(itemName)
			end
	
			return
		end
	end

	if not sfind(looter, '-') then
		looter = self.Utils.GetUnitNameWithRealm(looter)
	end
	
	local t = {itemLink, looter, iLvl}
	self:AddItemToLootTable(t)
end

function AddOn:BOSS_KILL()
	-- dont open frame when you dont in group
	if self:kirriCheckInGroup() == false then
		return
	end

    local _, _, difficulty = GetInstanceInfo()
	self:ClearEntries()
    -- Don't open if its M+
	if self.Config.openAfterEncounter and difficulty ~= 8 then self.lootFrame:Show() end
end

function AddOn:PLAYER_ENTERING_WORLD()
	local _, instanceType = GetInstanceInfo()
	if instanceType == "none" then
		-- self.Debug("Not in instance, unregistering events")
		self.EventFrame:UnregisterEvent("CHAT_MSG_LOOT")
		self.EventFrame:UnregisterEvent("BOSS_KILL")
		if self.InspectTimer then
			self.InspectTimer:Cancel()
			self.InspectTimer = nil
		end
		return
	end
	self.Debug("In instance, registering events")
	self.EventFrame:RegisterEvent("CHAT_MSG_LOOT")
    self.EventFrame:RegisterEvent("BOSS_KILL")
	-- Set repeated timer to check for raidmembers inventory
	self.InspectTimer = C_Timer.NewTicker(7, function() self.InspectGroup() end)
end

function AddOn:ADDON_LOADED(addon)
	if not addon == AddonName then return end
	self.EventFrame:UnregisterEvent("ADDON_LOADED")

	-- Set SavedVariables defaults
	if DyntDB == nil then
		DyntDB = {
			lootWindow = {"CENTER", 0, 0},
			lootWindowOpen = false,
			config = {
				whisperMessage = L["Default Whisper Message"],
				openAfterEncounter = true,
				check_isitemupgrade = false,
				debug = false,
				minDelta = 0,
				whisperMessages = {
					WHISPER_MESSAGE_1 = L["WHISPER_MESSAGE_1"],
					WHISPER_MESSAGE_2 = L["WHISPER_MESSAGE_2"],
					WHISPER_MESSAGE_3 = L["WHISPER_MESSAGE_3"],
					WHISPER_MESSAGE_4 = L["WHISPER_MESSAGE_4"],
					WHISPER_MESSAGE_5 = L["WHISPER_MESSAGE_5"],
				}
			},
            minimap = {
                hide = false
            }
		}
	end

	self.db = DyntDB

	-- Set minDelta default if its not a fresh install
	if not self.db.config.minDelta then
		self.db.config.minDelta = 0
	end

	-- Set window position
	self.lootFrame:SetPoint(self.db.lootWindow[1], self.db.lootWindow[2], self.db.lootWindow[3])
	-- Reopen window if left opened on uireload/exit
	if self.db.lootWindowOpen then self.lootFrame:Show() end

	-- Replace config with saved one
	self.Config = self.db.config

	-- if addon is updated without clean SavedVariables
	if not self.Config.whisperMessages then
		self.Config.whisperMessages = {
			WHISPER_MESSAGE_1 = L["WHISPER_MESSAGE_1"],
			WHISPER_MESSAGE_2 = L["WHISPER_MESSAGE_2"],
			WHISPER_MESSAGE_3 = L["WHISPER_MESSAGE_3"],
			WHISPER_MESSAGE_4 = L["WHISPER_MESSAGE_4"],
			WHISPER_MESSAGE_5 = L["WHISPER_MESSAGE_5"],
		}
	end

    icon:Register("DoYouNeedThat", LDB, self.db.minimap)
    if not self.db.minimap.hide then
        icon:Show("DoYouNeedThat")
    end

    self.createOptionsFrame()
end

local function GetEquippedIlvlBySlotID(slotID)
	local item = GetInventoryItemLink('player', slotID)
	--local _, iLvl = LibItemLevel:GetItemInfo(item)
	local iLvl = GetDetailedItemLevelInfo(item)
	return iLvl
end

function AddOn:IsItemUpgrade(ilvl, equipLoc)
	local function overOrWithinMin(ilvl, eq, delta)
		return eq <= ilvl or ilvl >= eq - delta
	end

	if ilvl ~= nil and equipLoc ~= nil and equipLoc ~= '' then
		local delta = self.Config.minDelta
		-- Evaluate item. If ilvl > your current ilvl
		if equipLoc == 'INVTYPE_FINGER' then
			local eqIlvl1 = GetEquippedIlvlBySlotID(11)
			local eqIlvl2 = GetEquippedIlvlBySlotID(12)
			return overOrWithinMin(ilvl, eqIlvl1, delta) or overOrWithinMin(ilvl, eqIlvl2, delta)
		elseif equipLoc == 'INVTYPE_TRINKET' then
			local eqIlvl1 = GetEquippedIlvlBySlotID(13)
			local eqIlvl2 = GetEquippedIlvlBySlotID(14)
			return overOrWithinMin(ilvl, eqIlvl1, delta) or overOrWithinMin(ilvl, eqIlvl2, delta)
		elseif equipLoc == 'INVTYPE_WEAPON' then
			local eqIlvl1 = GetEquippedIlvlBySlotID(16)
			local eqIlvl2 = GetEquippedIlvlBySlotID(17)
			return overOrWithinMin(ilvl, eqIlvl1, delta) or overOrWithinMin(ilvl, eqIlvl2, delta)
		else
			local slotID = AddOn.Utils.GetSlotID(equipLoc)
			local eqIlvl = GetEquippedIlvlBySlotID(slotID)
			return overOrWithinMin(ilvl, eqIlvl, delta)
		end
	end
	return false
end

function AddOn:IsEquippableForClass(itemClass, itemSubClass, equipLoc)
	-- Can be equipped by all, return true without checking
	if equipLoc == 'INVTYPE_CLOAK' or equipLoc == 'INVTYPE_FINGER' or equipLoc == 'INVTYPE_TRINKET' then return true end
	local classGear = self.Utils.ValidGear[playerClass]
	-- Loop through equippable item classes, if a match is found return true
	for i=1, #classGear[itemClass] do
		if itemSubClass == classGear[itemClass][i] then return true end
	end

	return false
end

function AddOn:ClearEntries()
	for i = 1, #self.Entries do
		if self.Entries[i].itemLink then
			self.Entries[i]:Hide()
			self.Entries[i].itemLink = nil
			self.Entries[i].looter = nil
			self.Entries[i].guid = nil
		end
	end
end

function AddOn:GetEntry(itemLink, looter)
	for i = 1, #self.Entries do
		-- If it already exists
		if self.Entries[i].itemLink == itemLink and self.Entries[i].looter == looter then
			return self.Entries[i]
		end

		-- Otherwise return a new one
		if not self.Entries[i].itemLink then
			return self.Entries[i]
		end
	end
end

function AddOn:AddItemToLootTable(t)
	-- Itemlink, Looter, Ilvl
	self.Debug("Adding item to entries")
	local entry = self:GetEntry(t[1], t[2])
	local _, _, _, equipLoc, _, _, itemSubClass = GetItemInfoInstant(t[1])
	local character = t[2]:match("(.*)%-") or t[2]
	local classColor = RAID_CLASS_COLORS[select(2, UnitClass(character))]
	entry.itemLink = t[1]
	entry.looter = t[2]
	entry.guid = UnitGUID(character)

	-- If looter has been inspected, show their equipped items in those slots
	if self.RaidMembers[entry.guid] then
		local raidMember = self.RaidMembers[entry.guid]
		local item, item2 = nil, nil
		if equipLoc == "INVTYPE_FINGER" then
			item, item2 = raidMember.items[11], raidMember.items[12]
		elseif equipLoc == "INVTYPE_TRINKET" then
			item, item2 = raidMember.items[13], raidMember.items[14]
		else
			entry.looterEq2:Hide()
			local slotId = self.Utils.GetSlotID(equipLoc)
			item = raidMember.items[slotId]
		end
		if item ~= nil then self.setItemTooltip(entry.looterEq1, item) end
		if item2 ~= nil then self.setItemTooltip(entry.looterEq2, item2) end
	end

	entry.name:SetText(character)
	entry.name:SetTextColor(classColor.r, classColor.g, classColor.b)
	self.setItemTooltip(entry.item, t[1])
	entry.ilvl:SetText(t[3])

	self:repositionFrames()

	entry.whisper:Show()
	entry:Show()
end

function AddOn:SendWhisper(itemLink, looter)
	-- Replace [item] with itemLink if supplied
	local message = self:kirriRandMessage():gsub("%[item%]", itemLink)
	SendChatMessage(message, "WHISPER", nil, looter)
end

function AddOn:kirriRandMessage()
	local messages = {}

	for key, message in next, self.Config.whisperMessages do
		-- print(message)
		if message ~= nil and message ~= '' then
			table.insert(messages, message)
		end
	end

	return tostring(messages[ math.random( #messages ) ])
end

function AddOn.InspectPlayer(unit)
	if not (UnitIsConnected(unit) and CanInspect(unit) and not InCombatLockdown()) then
		return false
	end

	local canInspect, unitFound = LibInspect:RequestData("items", unit, false)
	if not canInspect or not unitFound then
		return false
	end
	return true
end

function AddOn.CleanUpGroup()

end

function AddOn.InspectGroup()
	local isInRaid = IsInRaid()
	if not isInRaid and not IsInGroup() or InCombatLockdown() then return end
	--local max = isInRaid and 40 or 5
	local max = GetNumGroupMembers()
	local unit = isInRaid and "raid" or "party"
	local i = AddOn.inspectCount
	local curTime = time()

	while i <= max do
		local guid = UnitGUID(unit..i)
		if (AddOn.RaidMembers[guid] == nil or AddOn.RaidMembers[guid].maxAge <= curTime) and AddOn.InspectPlayer(unit..i) then
			--AddOn.Debug("New character to inspect " .. 	i)
			break
		end
		i = i + 1
	end
	--  GetNumGroupMembers() "group"..i

	i = i + 1
	if i > max then
		i = 1
	end
	AddOn.inspectCount = i
end

function AddOn:ToggleWindow()
    if not self.db.lootWindowOpen then
        self.lootFrame:Show()
        self.db.lootWindowOpen = true
    else
        self.lootFrame:Hide()
        self.db.lootWindowOpen = false
    end
end

LibInspect:SetMaxAge(599)
LibInspect:AddHook(AddonName, "items", function(guid, data)
	if data then
		AddOn.RaidMembers[guid] = {
			items = data.items,
			maxAge = time() + 600
		}
	end
end)

-- Event handler
AddOn.EventFrame:SetScript("OnEvent", function(self, event, ...)
	if AddOn[event] then AddOn[event](AddOn, ...) end
end)

AddOn.EventFrame:RegisterEvent("ADDON_LOADED")
AddOn.EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

local function SlashCommandHandler(msg)
	local _, _, cmd, args = sfind(msg, "%s?(%w+)%s?(.*)")
	if cmd == "clear" then
		AddOn:ClearEntries()
	elseif cmd == "test" and args ~= "" then
		local player = UnitName("player")
		local item = {args, player}
		-- local _, iLvl = LibItemLevel:GetItemInfo(args)
		local iLvl = GetDetailedItemLevelInfo(args)
		item[3] = iLvl
		LibInspect:RequestData("items", "player", false)
		AddOn:AddItemToLootTable(item)
	elseif cmd == "debug" then
		AddOn.Config.debug = not AddOn.Config.debug
		AddOn.Print("Debug mode " .. (AddOn.Config.debug and "enabled" or "disabled"))
	else
        AddOn:ToggleWindow()
	end
end

SLASH_DYNT1 = "/dynt"
SLASH_DYNT2 = "/doyouneedthat"
SlashCmdList["DYNT"] = SlashCommandHandler

-- Bindings
BINDING_HEADER_DOYOUNEEDTHAT = "DoYouNeedThat"
BINDING_NAME_DYNT_TOGGLE = L["Toggle Window"]
