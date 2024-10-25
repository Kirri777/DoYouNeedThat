local AddonName, AddOn = ...

-- Localize
local print, gsub, sfind = print, string.gsub, string.find
local GetItemInfo, IsEquippableItem = C_Item.GetItemInfo, C_Item.IsEquippableItem
local GetInventoryItemLink, UnitClass = GetInventoryItemLink, UnitClass
local SendChatMessage, UIParent = SendChatMessage, UIParent
local select, IsInGroup, GetItemInfoInstant = select, IsInGroup, C_Item.GetItemInfoInstant
local UnitGUID, IsInRaid, GetNumGroupMembers, GetInstanceInfo = UnitGUID, IsInRaid, GetNumGroupMembers, GetInstanceInfo
local C_Timer, InCombatLockdown, time = C_Timer, InCombatLockdown, time
local UnitIsConnected, CanInspect, UnitName = UnitIsConnected, CanInspect, UnitName
local WEAPON, ARMOR, RAID_CLASS_COLORS = _G['WEAPON'], _G['ARMOR'], RAID_CLASS_COLORS
local CreateFrame, GetDetailedItemLevelInfo = CreateFrame, C_Item.GetDetailedItemLevelInfo
-- Fix for clients with other languages
local AUCTION_CATEGORY_ARMOR = _G['AUCTION_CATEGORY_ARMOR']
local CanIMogIt = _G['CanIMogIt'] or false

local L = AddOn.L
-- local LibItemLevel = LibStub("LibItemLevel")
local LibInspect = LibStub("LibInspect")
local _, playerClass, playerClassId = UnitClass("player")
local icon = LibStub("LibDBIcon-1.0")
local LDB = LibStub("LibDataBroker-1.1"):NewDataObject("DoYouNeedThat", {
    type = "data source",
    text = "DoYouNeedThat",
    icon = "Interface\\Icons\\inv_misc_bag_17",
    OnClick = function(_, buttonPressed)
        if buttonPressed == "RightButton" then
            if (Settings ~= nil) then
                -- wow10
                local settingsCategoryID = _G['DYNT_Options'].categoryID
                Settings.OpenToCategory(settingsCategoryID)
            else
                InterfaceOptionsFrame_OpenToCategory("DoYouNeedThat")
            end
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

function AddOn:checkInGroupOrRaid()
    return (IsInGroup() or IsInRaid()) and true or false
end

function AddOn:kirriGetLinkDebug(message)
    local LOOT_ITEM_PATTERN = _G['LOOT_ITEM_SELF']:gsub("%%s", "(.+)")
    local link = message:match(LOOT_ITEM_PATTERN)

    if not link then
        return
    end

    return link
end

function AddOn:getItemLinkFromChat(message)
    self.Debug("getItemLinkFromChat")
    local LOOT_ITEM_PATTERN = _G['LOOT_ITEM']:gsub("%%s", "(.+)")
    local LOOT_ITEM_PUSHED_PATTERN = _G['LOOT_ITEM_PUSHED']:gsub("%%s", "(.+)")
    local LOOT_ITEM_MULTIPLE_PATTERN = _G['LOOT_ITEM_MULTIPLE']:gsub("%%s", "(.+)")
    local LOOT_ITEM_PUSHED_MULTIPLE_PATTERN = _G['LOOT_ITEM_PUSHED_MULTIPLE']:gsub("%%s", "(.+)")

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
    self.Debug("CHAT_MSG_LOOT")
    local message, _, _, _, looter = ...
    local messageItemLink = self:getItemLinkFromChat(message)

    if not messageItemLink then
        self.Debug("getItemLinkFromChat: false")
        return
    end

    local item = Item:CreateFromItemLink(messageItemLink)
    item:ContinueOnItemLoad(function()
        local itemLink = item:GetItemLink()
        local itemLevel = item:GetCurrentItemLevel()
        local _, _, rarity, _, _, type, _, _, equipLoc, _, _, itemClass, itemSubClass = GetItemInfo(itemLink)

        -- If not Armor/Weapon
        if (type ~= ARMOR and type ~= AUCTION_CATEGORY_ARMOR and type ~= WEAPON) then
            self.Debug("Armor/Weapon: false")
            return
        end

        local check, mog = self:checkAddItem(itemLink, rarity, equipLoc, itemClass, itemSubClass, itemLevel)

        if not check then
            self.Debug("checkAddItem: false")
            return
        end

        -- self.Debug(itemLink .. " " .. itemLevel)

        if not sfind(looter, '-') then
            looter = self.Utils.GetUnitNameWithRealm(looter)
        end

        local t = { itemLink, looter, itemLevel, mog }
        self:AddItemToLootTable(t)
    end)
end

function AddOn:checkAddItem(itemLink, rarity, equipLoc, itemClass, itemSubClass, iLvl)
    local checkmog, mog = self:checkAddItemTransmog(itemLink)

    if checkmog then
        self.Debug("checkAddItemTransmog: true")
        return true, mog
    end

    if not IsEquippableItem(itemLink) then
        self.Debug("IsEquippableItem: false")
        return false, mog
    end

    -- If its a Legendary or under rare quality
    if rarity == 5 or rarity < 3 then
        self.Debug("rarity == 5 or rarity < 3: false")
        return false, mog
    end

    -- If not equippable by your class return
    if not self:IsEquippableForClass(itemClass, itemSubClass, equipLoc) then
        self.Debug("IsEquippableForClass: false")
        return false, mog
    end

    -- Should get rid of class specific pieces that you cannnot equip.
    if not C_Item.DoesItemContainSpec(itemLink, playerClassId) then
        self.Debug("DoesItemContainSpec: false")
        return false, mog
    end

    if not self:IsItemUpgrade(iLvl, equipLoc) then
        self.Debug("IsItemUpgrade: false")
        return false, mog
    end

    self.Debug("IsItemUpgrade: true")
    return true, mog
end

function AddOn:checkAddItemTransmog(itemLink)
    local mog = '|TInterface\\AddOns\\CanIMogIt\\Icons\\not_transmogable:0|t'

    if not self.db.config.checkTransmogable then
        self.Debug("checkTransmogable: false")
        return false, mog
    end

    local isTransmogable, isKnown, isOtherKnown, isOutdated = self:CanIMogItCheckItem(itemLink)

    if isOutdated then
        self.Debug("CanIMogIt - isOutdated: true")
        return false, mog
    end

    if not isTransmogable then
        self.Debug("CanIMogIt - isTransmogable: false")
        return false, mog
    end

    if isKnown then
        mog = '|TInterface\\AddOns\\CanIMogIt\\Icons\\known:0|t'
        self.Debug("CanIMogIt - isKnown: true")
        return false, mog
    end

    if isOtherKnown then
        mog = '|TInterface\\AddOns\\CanIMogIt\\Icons\\known_circle:0|t'

        if self.db.config.checkTransmogableSource then
            self.Debug("CanIMogIt - isOtherKnown and checkTransmogableSource: true")
            return true, mog
        end

        self.Debug("CanIMogIt - isOtherKnown: true")
        return false, mog
    end

    mog = '|TInterface\\AddOns\\CanIMogIt\\Icons\\unknown:0|t'
    return true, mog
end

--[[
    BOSS_KILL event handler. This function is called when a boss is killed and the event is fired.
    It checks if the player is in a group and if the encounter was not a Mythic Keystone (M+)
    If the conditions are met, it clears the entries and shows the loot frame, if the user has enabled
    the option to open the frame after an encounter.

    @see https://wowpedia.fandom.com/wiki/DifficultyID
    @see https://wowpedia.fandom.com/wiki/BOSS_KILL
--]]
function AddOn:BOSS_KILL(encounterID, encounterName)
    self.Debug("BOSS_KILL")
    self.Debug("encounterID:" .. encounterID)
    self.Debug("encounterName:" .. encounterName)
-- function AddOn:BOSS_KILL(encounterID)
    -- Dont open frame when you dont in group
    if not self:checkInGroupOrRaid() then
        self.Debug("checkInGroupOrRaid: false")
        return
    end

    local _, _, difficulty = GetInstanceInfo()
    -- Clear all entries in the loot table
    self:ClearEntries()

    -- Don't open if its M+ (8 is Mythic Keystone)
    -- if self.Config.openAfterEncounter and difficulty ~= 8 then
    --     self.lootFrame:Show()
    -- end
    if self.Config.openAfterEncounter and (difficulty ~= 8 or self:isLastBossMythicPlus(encounterID)) then
        self.lootFrame:Show()
        self.db.lootWindowOpen = true
    end
end

--[[
    CHALLENGE_MODE_COMPLETED event handler. This function is called when the player completes a Mythic+ dungeon.
    It checks if the player is in a group and if the encounter was not a Mythic Keystone (M+)
    If the conditions are met, it clears the entries and shows the loot frame, if the user has enabled
    the option to open the frame after an encounter.

    @see https://wowpedia.fandom.com/wiki/CHALLENGE_MODE_COMPLETED
--]]
function AddOn:CHALLENGE_MODE_COMPLETED()
    self.Debug("CHALLENGE_MODE_COMPLETED")

    -- Dont open frame when you dont in group
    if not self:checkInGroupOrRaid() then
        self.Debug("checkInGroupOrRaid: false")
        return
    end

    -- Clear all entries in the loot table
    self:ClearEntries()

    -- Don't open if its disabled
    if self.Config.openAfterEncounter then
        self.lootFrame:Show()
        self.db.lootWindowOpen = true
    end
end
--[[
    Checks if the given encounter ID corresponds to a last boss in a Mythic+ dungeon.

    @param encounterId The encounter ID to check.
    @return True if the encounter ID is a last boss in a Mythic+ dungeon, false otherwise.
--]]
function AddOn:isLastBossMythicPlus(encounterId)
    -- Convert the encounter ID to a number
    encounterId = AddOn:getNumberOrZero(encounterId)

    -- Iterate through the list of Mythic+ last boss IDs
    for _, id in ipairs(self.Utils.MythicPlusLastBosses) do
        -- Check if the current ID matches the provided encounter ID
        if AddOn:getNumberOrZero(id) == encounterId then
            return true -- Return true if a match is found
        end
    end
    return false -- Return false if no match is found
end

function AddOn:PLAYER_ENTERING_WORLD()
    local _, instanceType = GetInstanceInfo()
    self.Debug("PLAYER_ENTERING_WORLD - instanceType: " .. instanceType)
    if instanceType == "none" then
        -- self.Debug("Not in instance, unregistering events")
        self.EventFrame:UnregisterEvent("CHAT_MSG_LOOT")
        self.EventFrame:UnregisterEvent("BOSS_KILL")
        self.EventFrame:UnregisterEvent("CHALLENGE_MODE_COMPLETED")
        if self.InspectTimer then
            self.InspectTimer:Cancel()
            self.InspectTimer = nil
        end
        return
    end
    self.Debug("In instance, registering events")
    self.EventFrame:RegisterEvent("CHAT_MSG_LOOT")
    self.EventFrame:RegisterEvent("BOSS_KILL")
    self.EventFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    -- Set repeated timer to check for raidmembers inventory
    self.InspectTimer = C_Timer.NewTicker(7, function() self.InspectGroup() end)
end

function AddOn:ADDON_LOADED(addon)
    if not addon == AddonName then return end
    self.EventFrame:UnregisterEvent("ADDON_LOADED")

    -- Set SavedVariables defaults
    if DyntDB == nil then
        DyntDB = {
            lootWindow = { "CENTER", 0, 0 },
            lootWindowOpen = false,
            config = {
                whisperMessage = L["Default Whisper Message"],
                openAfterEncounter = true,
                debug = false,
                checkTransmogable = true,
                checkTransmogableSource = true,
                chatShowOnlyInDungeonOrRaid = true,
                chatShowLootFrameEverywhere = true,
                chatShowLootFrame = 'disabled',
                minDelta = 0,
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

    -- Set chatShowOnlyInDungeonOrRaid default if its not a fresh install
    if not self.db.config.chatShowOnlyInDungeonOrRaid then
        self.db.config.chatShowOnlyInDungeonOrRaid = false
    end

    -- Set chatShowLootFrameEverywhere default if its not a fresh install
    if not self.db.config.chatShowLootFrameEverywhere then
        self.db.config.chatShowLootFrameEverywhere = false
    end
    -- Set chatShowLootFrameEverywhere default if its not a fresh install
    if not self.db.config.chatShowLootFrame then
        self.db.config.chatShowLootFrame = 'disabled'
    end

    self.createLootFrame()

    -- Set window position
    self.lootFrame:SetPoint(self.db.lootWindow[1], self.db.lootWindow[2], self.db.lootWindow[3])
    -- Reopen window if left opened on uireload/exit
    if self.db.lootWindowOpen then self.lootFrame:Show() end

    -- Replace config with saved one
    self.Config = self.db.config

    icon:Register("DoYouNeedThat", LDB, self.db.minimap)
    if not self.db.minimap.hide then
        icon:Show("DoYouNeedThat")
    end

    self.createOptionsFrame()
end

function AddOn:recreateLootFrame()
    self.lootFrame:Hide()
    AddOn:ClearEntries()
    self.lootFrame:SetParent(nil)
    self.lootFrame:ClearAllPoints()
    self.lootFrame:UnregisterAllEvents()
    self.lootFrame:SetID(0)

    self.createLootFrame()

    -- Set window position
    self.lootFrame:SetPoint(self.db.lootWindow[1], self.db.lootWindow[2], self.db.lootWindow[3])
    -- Reopen window if left opened on uireload/exit
    if self.db.lootWindowOpen then self.lootFrame:Show() end
end

local function GetEquippedIlvlBySlotID(slotID)
    local item = GetInventoryItemLink('player', slotID)
    return item and GetDetailedItemLevelInfo(item) or 0
end

function AddOn:IsItemUpgrade(ilvl, equipLoc)
    local function overOrWithinMin(eqilvl, eq, delta)
        return eq <= eqilvl or eqilvl >= eq - delta
    end

    -- print('ilvl', ilvl, 'equipLoc', equipLoc)

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
        elseif equipLoc == 'INVTYPE_WEAPON' or equipLoc == 'INVTYPE_HOLDABLE' or equipLoc == 'INVTYPE_WEAPONOFFHAND' or equipLoc == 'INVTYPE_SHIELD' then
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
    if equipLoc == 'INVTYPE_CLOAK' or equipLoc == 'INVTYPE_FINGER' or equipLoc == 'INVTYPE_TRINKET' or equipLoc == 'INVTYPE_NECK' or equipLoc == 'INVTYPE_WEAPON' or itemSubClass == 0 then return true end
    local classGear = self.Utils.ValidGear[playerClass]
    -- Loop through equippable item classes, if a match is found return true
    for i = 1, #classGear[itemClass] do
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
            self.Entries[i].itemID = nil
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

    AddOn:ShowLootFrameFromChat()

    local entry = self:GetEntry(t[1], t[2])
    local _, _, _, equipLoc, _, _, itemSubClass = GetItemInfoInstant(t[1])
    local character = t[2]:match("(.*)%-") or t[2]
    local classColor = RAID_CLASS_COLORS[select(2, UnitClass(character))]
    entry.itemLink = t[1]
    entry.looter = t[2]
    entry.guid = UnitGUID(character)

    
    -- print('ilvl', ilvl, 'equipLoc', equipLoc)
    self.Debug("equipLoc: " .. equipLoc)

    -- If looter has been inspected, show their equipped items in those slots
    if self.RaidMembers[entry.guid] then
        local raidMember = self.RaidMembers[entry.guid]
        local item, item2 = nil, nil
        if equipLoc == "INVTYPE_FINGER" then
            item, item2 = raidMember.items[11] or nil, raidMember.items[12] or nil
        elseif equipLoc == "INVTYPE_TRINKET" then
            item, item2 = raidMember.items[13] or nil, raidMember.items[14] or nil
        elseif equipLoc == 'INVTYPE_WEAPON' or equipLoc == 'INVTYPE_HOLDABLE' or equipLoc == 'INVTYPE_WEAPONOFFHAND' or equipLoc == 'INVTYPE_SHIELD' then
            item, item2 = raidMember.items[16] or nil, raidMember.items[17] or nil
        else
            entry.looterEq2:Hide()
            local slotId = self.Utils.GetSlotID(equipLoc)
            item = raidMember.items[slotId] or nil
        end
        if item ~= nil then self.setItemTooltip(entry.looterEq1, item) end
        if item2 ~= nil then self.setItemTooltip(entry.looterEq2, item2) end
    end

    entry.name:SetText(character)
    entry.name:SetTextColor(classColor.r, classColor.g, classColor.b)
    self.setItemTooltip(entry.item, t[1])
    entry.ilvl:SetText(t[3])
    entry.itemID = self:kirriGetItemID(t[1])

    if self.db.config.checkTransmogable and CanIMogIt then
        entry.mog:SetText(t[4])
    end

    self:repositionFrames()

    entry.whisper:Show()
    entry:Show()
end

function AddOn:ShowLootFrameFromChat()
    self.Debug("ShowLootFrame")

    -- check is opened
    if self.db.lootWindowOpen or (not self.Config.chatShowLootFrameEverywhere and not self.Config.chatShowOnlyInDungeonOrRaid) then
        return
    end

    if not self:checkInGroupOrRaid() then
        self.Debug("checkInGroupOrRaid: false")
        return
    end

    if self.Config.chatShowLootFrameEverywhere then
        self.lootFrame:Show()
        self.db.lootWindowOpen = true
        return
    end

    local _, instanceType = GetInstanceInfo()
    self.Debug("PLAYER_ENTERING_WORLD - instanceType: " .. instanceType)

    if instanceType ~= "none" and self.Config.chatShowOnlyInDungeonOrRaid then
        self.lootFrame:Show()
        self.db.lootWindowOpen = true
    end
end

--[[
    Sends a whisper message to a player with the provided item link.

    @param itemLink The item link to include in the whisper message.
    @param looterName The name of the player to send the whisper to.
]]
function AddOn:sendWhisperToLooter(itemLink, looterName)
    -- Generate the whisper message by replacing [item] placeholder with the actual item link
    local message = self.Config.whisperMessage:gsub("%[item%]", itemLink)

    -- Send the whisper message to the specified player
    SendChatMessage(message, "WHISPER", nil, looterName)
end

--[[
    This function inspects a player's items and returns true if the inspection is successful. If the player is not online, not inspectable, or if the player is in combat, the function returns false.

    @param unitName The name of the player to inspect.

    @return boolean True if the inspection was successful, false otherwise.
]]
function AddOn.InspectPlayer(unitName)
    if not (UnitIsConnected(unitName) and CanInspect(unitName) and not InCombatLockdown()) then
        return false
    end

    -- Request the player's items
    local canInspect, unitFound = LibInspect:RequestData("items", unitName, false)
    if not canInspect or not unitFound then
        return false
    end

    return true
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
        local guid = UnitGUID(unit .. i)
        if (AddOn.RaidMembers[guid] == nil or AddOn.RaidMembers[guid].maxAge <= curTime) and AddOn.InspectPlayer(unit .. i) then
            break
        end
        i = i + 1
    end

    i = i + 1
    if i > max then
        i = 1
    end
    AddOn.inspectCount = i
end

--[[
    ToggleWindow
    Toggles the visibility of the loot frame.

    If the frame is not visible, it will be shown and the db variable will be set to true.
    If the frame is visible, it will be hidden and the db variable will be set to false.
--]]
function AddOn:ToggleWindow()
    -- If the window is not open, show it and set the db variable
    if not self.db.lootWindowOpen then
        self.lootFrame:Show()
        self.db.lootWindowOpen = true
        -- If the window is open, hide it and set the db variable
    else
        self.lootFrame:Hide()
        self.db.lootWindowOpen = false
    end
end

--[[
    Checks if an item is transmogable and returns its status.

    @param itemLink The link to the item to be checked.

    @return isTransmogable (bool) Whether the item is transmogable.
    @return isKnownByPlayer (bool) Whether the player knows the transmog.
    @return isOtherKnown (bool) Whether the transmog is known by other characters.
    @return isOutdated (bool) Whether the CanIMogIt library is outdated.
--]]
function AddOn:CanIMogItCheckItem(itemLink)
    -- Initialize variables to track various transmog states
    local isTransmogable, isKnownByPlayer, isOtherKnown, isOutdated = false, false, false, false

    -- Check if the CanIMogIt library is loaded
    if not CanIMogIt then
        self.Debug("CanIMogIt: false")
        return isTransmogable, isKnownByPlayer, isOtherKnown, isOutdated
    end

    -- Determine if the CanIMogIt library functions are outdated
    isOutdated = not CanIMogIt.IsTransmogable or
        not CanIMogIt.PlayerKnowsTransmogFromItem or
        not CanIMogIt.PlayerKnowsTransmog or
        not CanIMogIt.CharacterCanLearnTransmog

    if isOutdated then
        self.Debug("CanIMogIt (isOutdated): true")
        return isTransmogable, isKnownByPlayer, isOtherKnown, isOutdated
    end

    -- Verify if the item is equippable
    if not CanIMogIt:IsEquippable(itemLink) then
        self.Debug("CanIMogIt (IsEquippable): false")
        return isTransmogable, isKnownByPlayer, isOtherKnown, isOutdated
    end

    -- Check if the item is transmogable and update the state variables accordingly
    if CanIMogIt:IsTransmogable(itemLink) then
        self.Debug("CanIMogIt (IsTransmogable): true")
        isTransmogable = true
        if CanIMogIt:PlayerKnowsTransmogFromItem(itemLink) then
            self.Debug("CanIMogIt (PlayerKnowsTransmogFromItem): true")
            isKnownByPlayer = true
        elseif CanIMogIt:PlayerKnowsTransmog(itemLink) then
            self.Debug("CanIMogIt (PlayerKnowsTransmog): true")
            isOtherKnown = true
        end
    end

    return isTransmogable, isKnownByPlayer, isOtherKnown, isOutdated
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

--[[
    Returns the number if the value is a number, or false if not.

    @param x The value to check
    @return The number if the value is a number, or false if not.
--]]
function AddOn:getNumber(x)
    local number = tonumber(x)
    return number and number or false
end

--[[
    Converts the input value to a number if possible, otherwise returns zero.

    @param x The value to convert to a number.
    @return The number if conversion is successful, or zero if not.
--]]
function AddOn:getNumberOrZero(x)
    local number = tonumber(x)
    return number and number or 0
end

local function SlashCommandHandler(msg)
    local _, _, cmd, args = sfind(msg, "%s?(%w+)%s?(.*)")
    if cmd == "clear" then
        AddOn:ClearEntries()
    elseif cmd == "test" and args ~= "" then
        local itemID = AddOn:getNumber(args)
        local item

        if itemID then
            item = Item:CreateFromItemID(itemID)
        else
            item = Item:CreateFromItemLink(args)
        end

        item:ContinueOnItemLoad(function()
            local player = UnitName("player")
            LibInspect:RequestData("items", "player", false)

            -- local itemID = item:GetItemID()
            local itemLink = item:GetItemLink()
            -- local itemQuality = item:GetItemQuality()
            local itemLevel = item:GetCurrentItemLevel()
            -- local inventoryTypeName = item:GetInventoryTypeName()

            -- print("itemID", itemID)
            -- print("itemLink", itemLink)
            -- print("itemQuality", itemQuality)
            -- print("itemLevel", itemLevel)
            -- print("inventoryTypeName", inventoryTypeName)

            local _, mog = AddOn:checkAddItemTransmog(itemLink)
            local t = { itemLink, player, itemLevel, mog }
            AddOn:AddItemToLootTable(t)
        end)

        -- item:ContinueWithCancelOnItemLoad (function()
        -- 	print('error')
        -- end)
    elseif cmd == "debug" then
        AddOn.Config.debug = not AddOn.Config.debug
        AddOn.Print("Debug mode " .. (AddOn.Config.debug and "enabled" or "disabled"))
    elseif cmd == "check" and args ~= "" then
        local itemID = AddOn:getNumber(args)
        local item

        if itemID then
            item = Item:CreateFromItemID(itemID)
        else
            item = Item:CreateFromItemLink(args)
        end

        item:ContinueOnItemLoad(function()
            local player = UnitName("player")
            LibInspect:RequestData("items", "player", false)

            local itemLink = item:GetItemLink()
            local itemLevel = item:GetCurrentItemLevel()
            local _, _, rarity, _, _, _, _, _, equipLoc, _, _, itemClass, itemSubClass = GetItemInfo(itemLink)
            local _, mog = AddOn:checkAddItem(itemLink, rarity, equipLoc, itemClass, itemSubClass, itemLevel)
            local t = { itemLink, player, itemLevel, mog }
            AddOn:AddItemToLootTable(t)
        end)
    else
        AddOn:ToggleWindow()
    end
end

SlashCmdList['DYNT'] = SlashCommandHandler
SLASH_DYNT1 = '/dynt'

-- Bindings
BINDING_HEADER_DOYOUNEEDTHAT = "DoYouNeedThat"
BINDING_NAME_DYNT_TOGGLE = L["Toggle Window"]
