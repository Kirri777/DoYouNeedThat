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
AddOn.instanceType = 'none'
AddOn.eventsLoaded = false

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

function AddOn:getItemID(itemLink)
    return tonumber(itemLink:match("item:(%d+)"))
end

function AddOn:getPetID(itemLink)
    return tonumber(itemLink:match("battlepet:(%d+)"))
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

    -- Check to see if it's a pet cage
    if string.find(messageItemLink, "battlepet:") then
        return AddOn:checkOther(messageItemLink, looter)
    end

    local item = Item:CreateFromItemLink(messageItemLink)
    item:ContinueOnItemLoad(function()
        local itemLink = item:GetItemLink()
        local itemLevel = item:GetCurrentItemLevel()
        local _, _, rarity, _, _, type, _, _, equipLoc, _, _, itemClass, itemSubClass = GetItemInfo(itemLink)

        -- If not Armor/Weapon
        if (type ~= ARMOR and type ~= AUCTION_CATEGORY_ARMOR and type ~= WEAPON) then
            self.Debug("Armor/Weapon: false")
            return AddOn:checkOther(itemLink, looter)
        end

        local check, mog = self:checkAddItem(itemLink, rarity, equipLoc, itemClass, itemSubClass, itemLevel)

        if not check then
            self.Debug("checkAddItem: false")
            return
        end

        AddOn:addItem(itemLink, looter, itemLevel, mog)
    end)
end

--[[
    Checks if the item is a mount, toy, or pet, and adds it to the loot table if the player knows it.

    @param itemLink string: The item link to check.
    @param looter string: The name of the looter.

    @return void
]]
function AddOn:checkOther(itemLink, looter)
    self.Debug("checkOther")

    -- Check if the item is a mount and if the player knows it
    if self.db.config.checkMounts and AddOn:isItemMount(itemLink) then
        self.Debug("isItemMount: true")

        if not AddOn:playerKnowsMount(itemLink) then
            self.Debug("playerKnowsMount: false")
            -- Add the item to the loot table with a specific level for mounts
            return AddOn:addItem(itemLink, looter, 9999, '')
        end

        self.Debug("playerKnowsMount: true")
        return
    end

    -- Check if the item is a toy and if the player knows it
    if self.db.config.checkToys and AddOn:isItemToy(itemLink) then
        self.Debug("isItemToy: true")

        if not AddOn:playerKnowsToy(itemLink) then
            self.Debug("playerKnowsToy: false")
            -- Add the item to the loot table with a specific level for toys
            return AddOn:addItem(itemLink, looter, 8888, '')
        end

        self.Debug("playerKnowsToy: true")
        return
    end

    -- Check if the item is a pet and if the player knows it
    if self.db.config.checkPets and AddOn:isItemPet(itemLink) then
        self.Debug("isItemPet: true")

        if not AddOn:playerKnowsPet(itemLink) then
            self.Debug("playerKnowsPet: false")
            -- Add the item to the loot table with a specific level for pets
            return AddOn:addItem(itemLink, looter, 7777, '')
        end

        self.Debug("playerKnowsPet: true")
        return
    end
end

--[[
    Adds an item to the loot table

    @param itemLink string: The item link to add
    @param looter string: The name of the looter
    @param itemLevel number: The level of the item
    @param mog string: The mog icon

    @return void
--]]
function AddOn:addItem(itemLink, looter, itemLevel, mog)
    self.Debug("addItem")

    -- If the looter is a player and not a player-server pair, add the server
    if not sfind(looter, '-') then
        looter = self.Utils.GetUnitNameWithRealm(looter)
    end

    -- Create a table with the item data
    local t = { itemLink, looter, itemLevel, mog }

    -- Add the item to the loot table
    self:AddItemToLootTable(t)
end

--[[
    Checks if an item is a mount or not
    
    @param itemLink string: The item link to check

    @return boolean: True if the item is a mount, false otherwise
--]]
function AddOn:isItemMount(itemLink)
    -- Retrieve the item ID from the item link
    local itemID = AddOn:getItemID(itemLink)

    -- Return false if the item ID could not be determined
    if itemID == nil then
        return false
    end

    -- Use the Mount Journal API to check if the item is a mount
    if C_MountJournal.GetMountFromItem(itemID) then
        return true
    end

    -- Return false if the item is not a mount
    return false
end

--[[
    Determines if the player knows the mount associated with the given item ID.

    @param itemLink string: The item link to check

    @return boolean: True if the player knows the mount, false otherwise.
]]
function AddOn:playerKnowsMount(itemLink)
    -- Retrieve the item ID from the item link
    local itemID = AddOn:getItemID(itemLink)

    -- Return false if the item ID could not be determined
    if itemID == nil then
        return false
    end

    -- Get the mount ID from the item ID using the Mount Journal API
    local mountID = C_MountJournal.GetMountFromItem(itemID)

    -- If no mount ID is found, the player does not know the mount
    if mountID == nil then
        return false
    end

    -- Retrieve mount information using the mount ID and check if it's known by the player
    return select(11, C_MountJournal.GetMountInfoByID(mountID))
end

--[[
    Checks if an item is a toy or not

    @param itemLink string: The item link to check

    @return boolean: True if the item is a toy, false otherwise
--]]
function AddOn:isItemToy(itemLink)
    -- Retrieve the item ID from the item link
    local itemID = AddOn:getItemID(itemLink)

    -- Return false if the item ID could not be determined
    if itemID == nil then
        return false
    end

    -- Check if the item is a toy using the Toy Box API
    if C_ToyBox.GetToyInfo(itemID) then
        return true
    end

    -- If no toy info is found, the item is not a toy
    return false
end

--[[
    Determines if the player knows the toy associated with the given item ID.

    @param itemLink string: The item link to check.

    @return boolean: True if the player knows the toy, false otherwise.
--]]
function AddOn:playerKnowsToy(itemLink)
    -- Retrieve the item ID from the item link
    local itemID = AddOn:getItemID(itemLink)

    -- Return false if the item ID could not be determined
    if itemID == nil then
        return false
    end

    -- Use the PlayerHasToy API to check if the player knows the toy
    return PlayerHasToy(itemID)
end

--[[
    Checks if an item is a pet or not

    @param itemLink string: The item link to check.

    @return boolean: True if the item is a pet, false otherwise
--]]
function AddOn:isItemPet(itemLink)
    -- Retrieve the item ID from the item link
    local itemID = AddOn:getItemID(itemLink)

    -- If itemID is not provided, check if the itemLink is a pet cage
    if itemID == nil then
        -- Check to see if it's a pet cage
        if string.find(itemLink, "battlepet:") then
            return true
        end

        -- If it's not a pet cage, it's not a pet
        return false
    end

    -- If itemID is provided, check if the item is a pet using the Pet Journal API
    if C_PetJournal.GetPetInfoByItemID(itemID) then
        return true
    end

    -- If we reach this point, the item is not a pet
    return false
end

--[[
    Determines if the player knows the pet associated with the given item ID or item link.

    @param itemLink string: The item link to check.

    @return boolean: True if the player knows the pet, false otherwise.
]]
function AddOn:playerKnowsPet(itemLink)
    local speciesID = nil

    -- Retrieve the item ID from the item link
    local itemID = AddOn:getItemID(itemLink)

    if itemID ~= nil then
        -- Get species ID from the item ID using the Pet Journal API
        speciesID = select(13, C_PetJournal.GetPetInfoByItemID(itemID))
    else
        -- Extract species ID from the item link if item ID is not provided
        _, _, speciesID = string.find(itemLink, "battlepet:(%d+)")

        if speciesID ~= nil then
            speciesID = tonumber(speciesID)
        end
    end

    -- Return false if speciesID could not be determined
    if speciesID == nil then
        return false
    end

    -- Check if the pet is collected by the player
    return C_PetJournal.GetNumCollectedInfo(speciesID) > 0
end

--[[
    Checks if an item is transmogable or upgrade currently equipped.

    @param itemLink string: The item link to check.
    @param rarity number: The rarity of the item.
    @param equipLoc string: The equip location of the item.
    @param itemClass number: The class of the item.
    @param itemSubClass number: The subclass of the item.
    @param iLvl number: The item level of the item.

    @return boolean: True if the item is transmogable and the player does not know the transmog, but another character knows it.
    @return string: The icon to use for the item.
--]]
function AddOn:checkAddItem(itemLink, rarity, equipLoc, itemClass, itemSubClass, iLvl)
    -- Check if the item is transmogable
    local checkmog, mog = self:checkAddItemTransmog(itemLink)

    if checkmog then
        self.Debug("checkAddItemTransmog: true")
        return true, mog
    end

    -- Check if the item is equippable
    if not IsEquippableItem(itemLink) then
        self.Debug("IsEquippableItem: false")
        return false, mog
    end

    -- If its a Legendary or under rare quality, do not add it
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

    -- Check if the item is an upgrade
    if not self:IsItemUpgrade(iLvl, equipLoc) then
        self.Debug("IsItemUpgrade: false")
        return false, mog
    end

    self.Debug("IsItemUpgrade: true")
    return true, mog
end

--[[
    Checks if an item is transmogable and returns its status.

    If the CanIMogIt library is outdated, it will return false and a not transmogable icon.
    If the item is not transmogable, it will return false and a not transmogable icon.
    If the player knows the transmog, it will return false and a known icon.
    If the player does not know the transmog, but another character knows it, it will return true and a known circle icon
    if the user has enabled the option to check the source of the transmog.
    If the player does not know the transmog and no other character knows it, it will return true and an unknown icon.

    @param itemLink string: The link to the item to be checked.

    @return boolean: Whether the item is transmogable.
    @return string: The icon to be used to represent the state of the item.
--]]
function AddOn:checkAddItemTransmog(itemLink)
    local mog = '|TInterface\\AddOns\\CanIMogIt\\Icons\\not_transmogable:0|t'

    -- Check if the user has enabled the option to check if the item is transmogable
    if not self.db.config.checkTransmogable then
        self.Debug("checkTransmogable: false")
        return false, mog
    end

    -- Check if the CanIMogIt library is outdated
    local isTransmogable, isKnown, isOtherKnown, isOutdated = self:CanIMogItCheckItem(itemLink)

    if isOutdated then
        self.Debug("CanIMogIt - isOutdated: true")
        return false, mog
    end

    -- Check if the item is transmogable
    if not isTransmogable then
        self.Debug("CanIMogIt - isTransmogable: false")
        return false, mog
    end

    -- Check if the player knows the transmog
    if isKnown then
        mog = '|TInterface\\AddOns\\CanIMogIt\\Icons\\known:0|t'
        self.Debug("CanIMogIt - isKnown: true")
        return false, mog
    end

    -- Check if another character knows the transmog
    if isOtherKnown then
        mog = '|TInterface\\AddOns\\CanIMogIt\\Icons\\known_circle:0|t'
        -- Check if the user has enabled the option to check the source of the transmog
        if self.db.config.checkTransmogableSource then
            self.Debug("CanIMogIt - isOtherKnown and checkTransmogableSource: true")
            return true, mog
        end

        self.Debug("CanIMogIt - isOtherKnown: true")
        return false, mog
    end

    -- If the player does not know the transmog and no other character knows it
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

    @param encounterID number: The encounter ID of the boss that was killed.
    @param encounterName string: The name of the boss that was killed.

    @return void
--]]
function AddOn:BOSS_KILL(encounterID, encounterName)
    self.Debug("BOSS_KILL")
    self.Debug("encounterID:" .. encounterID)
    self.Debug("encounterName:" .. encounterName)
    
    -- Dont open frame when you dont in group
    if not self:checkInGroupOrRaid() then
        self.Debug("checkInGroupOrRaid: false")
        return
    end

    local _, _, difficulty = GetInstanceInfo()
    -- Clear all entries in the loot table
    self:ClearEntries()

    -- Don't open if its disabled or its not the right difficultyID
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

    @return void
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

    @param encounterId number: The encounter ID to check.

    @return boolean: True if the encounter ID is a last boss in a Mythic+ dungeon, false otherwise.
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

--[[
    Handles the PLAYER_ENTERING_WORLD event. This function is triggered when the player enters the world,
    either by logging in, reloading the UI, or changing zones.
    It determines the type of instance the player is in and decides whether to register or unregister events 
    based on the configuration settings and instance type.

    @return void
--]]
function AddOn:PLAYER_ENTERING_WORLD()
    -- Retrieve the current instance type
    local _, instanceType = GetInstanceInfo()
    -- Store the instance type in the AddOn object
    AddOn.instanceType = instanceType

    -- Log the instance type for debugging purposes
    self.Debug("PLAYER_ENTERING_WORLD - instanceType: " .. AddOn.instanceType)

    -- Register events if the loot frame should be shown everywhere or if the player is in an instance
    if self.db.config.chatShowLootFrame == "everywhere" or AddOn.instanceType ~= "none" then
        AddOn:registerEvents()
        return
    end

    -- Unregister events if the conditions above are not met
    AddOn:unregisterEvents()
end

--[[
    Registers the necessary events for the AddOn and sets up a repeated timer to inspect group members.
    This function ensures that events are only registered once and starts a timer for periodic inspection.
    
    @return void
--]]
function AddOn:registerEvents()
    self.Debug("registerEvents")

    -- Check if events are already loaded to avoid duplicate registration
    if AddOn.eventsLoaded then
        return
    end

    -- Register events for loot messages, boss kills, and challenge mode completion
    self.EventFrame:RegisterEvent("CHAT_MSG_LOOT")
    self.EventFrame:RegisterEvent("BOSS_KILL")
    self.EventFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")

    -- Set a repeated timer every 7 seconds to check the inventory of raid members
    self.InspectTimer = C_Timer.NewTicker(7, function() self.InspectGroup() end)

    -- Mark events as loaded to prevent re-registration
    AddOn.eventsLoaded = true
end

--[[
    Unregisters the events for the AddOn and cancels the repeated timer for inspection.

    This function is the counterpart to registerEvents() and is called when the player is no longer
    in a group or raid. It ensures that events are not registered multiple times and stops the timer
    for periodic inspection to prevent excessive CPU usage.

    @return void
--]]
function AddOn:unregisterEvents()
    self.Debug("unregisterEvents")

    -- Check if events are already unloaded to avoid duplicate unregistration
    if not AddOn.eventsLoaded then
        return
    end

    -- Unregister events for loot messages, boss kills, and challenge mode completion
    self.EventFrame:UnregisterEvent("CHAT_MSG_LOOT")
    self.EventFrame:UnregisterEvent("BOSS_KILL")
    self.EventFrame:UnregisterEvent("CHALLENGE_MODE_COMPLETED")

    -- Cancel the repeated timer for inspection
    if self.InspectTimer then
        self.InspectTimer:Cancel()
        self.InspectTimer = nil
    end

    -- Mark events as unloaded to prevent re-registration
    AddOn.eventsLoaded = false
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
                checkMounts = true,
                checkToys = true,
                checkPets = true,
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

    -- Set chatShowLootFrameEverywhere default if its not a fresh install
    if not self.db.config.chatShowLootFrame then
        self.db.config.chatShowLootFrame = 'disabled'
    end

    -- Set checkMounts default if its not a fresh install
    if not self.db.config.checkMounts then
        self.db.config.checkMounts = false
    end

    -- Set checkToys default if its not a fresh install
    if not self.db.config.checkToys then
        self.db.config.checkToys = false
    end

    -- Set checkPets default if its not a fresh install
    if not self.db.config.checkPets then
        self.db.config.checkPets = false
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
    entry.itemID = self:getItemID(t[1])

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
    if self.db.lootWindowOpen or self.db.config.chatShowLootFrame == "disabled" then
        return
    end

    if not self:checkInGroupOrRaid() then
        self.Debug("checkInGroupOrRaid: false")
        return
    end

    if self.db.config.chatShowLootFrame == "everywhere" then
        self.lootFrame:Show()
        self.db.lootWindowOpen = true
        return
    end

    -- local _, instanceType = GetInstanceInfo()
    self.Debug("ShowLootFrameFromChat - instanceType: " .. AddOn.instanceType)

    if AddOn.instanceType ~= "none" then
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
        local player = UnitName("player")
        LibInspect:RequestData("items", "player", false)

        if itemID then
            item = Item:CreateFromItemID(itemID)
        else
            -- Check to see if it's a pet cage
            if string.find(args, "battlepet:") then
                return AddOn:checkOther(args, player)
            end

            item = Item:CreateFromItemLink(args)
        end

        item:ContinueOnItemLoad(function()
            local itemLink = item:GetItemLink()
            local itemLevel = item:GetCurrentItemLevel()
            local _, _, rarity, _, _, _, _, _, equipLoc, _, _, itemClass, itemSubClass = GetItemInfo(itemLink)
            
            -- If not Armor/Weapon
            if (type ~= ARMOR and type ~= AUCTION_CATEGORY_ARMOR and type ~= WEAPON) then
                AddOn.Debug("Armor/Weapon: false")
                return AddOn:checkOther(itemLink, player)
            end

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
