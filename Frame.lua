local _, AddOn = ...
local L = AddOn.L

local icon = LibStub("LibDBIcon-1.0")
local CreateFrame, unpack, GetItemInfo, select, GetItemQualityColor = CreateFrame, unpack, C_Item.GetItemInfo, select,
    C_Item.GetItemQualityColor
local GetItemInfoInstant = C_Item.GetItemInfoInstant
local CreateFont, UIParent = CreateFont, UIParent
local tsort, tonumber, xpcall, geterrorhandler = table.sort, tonumber, xpcall, geterrorhandler
local IsModifiedClick, ChatEdit_InsertLink, DressUpItemLink = IsModifiedClick, ChatEdit_InsertLink, DressUpItemLink
local ShowUIPanel, GameTooltip = ShowUIPanel, GameTooltip
local IsAzeriteEmpoweredItemByID = C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItemByID
local OpenAzeriteEmpoweredItemUIFromLink = OpenAzeriteEmpoweredItemUIFromLink
local BackdropTemplateMixin = BackdropTemplateMixin
local CanIMogIt = _G['CanIMogIt'] or false

local function showItemTooltip(itemLink)
    ShowUIPanel(GameTooltip)
    GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
    GameTooltip:SetHyperlink(itemLink)
    --GameTooltip_ShowCompareItem()
    GameTooltip:Show()
end

local function hideItemTooltip() GameTooltip:Hide() end

local function skinBackdrop(frame, ...)
    if (frame.background) then return false end

    local border = { 0, 0, 0, 1 }
    local color = { ... }
    if (not ...) then
        color = { .11, .15, .18, 1 }
        border = { .06, .08, .09, 1 }
    end

    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    frame:SetBackdropColor(unpack(color))
    frame:SetBackdropBorderColor(unpack(border))

    return true
end

local function skinButton(frame, small, color)
    local colors = { .1, .1, .1, 1 }
    local hovercolors = { 0, 0.55, .85, 1 }
    if (color == "red") then
        colors = { .6, .1, .1, 0.6 }
        hovercolors = { .6, .1, .1, 1 }
    elseif (color == "blue") then
        colors = { 0, 0.55, .85, 0.6 }
        hovercolors = { 0, 0.55, .85, 1 }
    elseif (color == "dark") then
        colors = { .1, .1, .1, 1 }
        hovercolors = { .1, .1, .1, 1 }
    elseif (color == "lightgrey") then
        colors = { .219, .219, .219, 1 }
        hovercolors = { .270, .270, .270, 1 }
    end

    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, top = 1, right = 1, bottom = 1 }
    })

    frame:SetBackdropColor(unpack(colors))
    frame:SetBackdropBorderColor(0, 0, 0, 1)
    frame:SetNormalFontObject("dynt_button")
    frame:SetHighlightFontObject("dynt_button")
    frame:SetPushedTextOffset(0, -1)

    frame:SetSize(frame:GetTextWidth() + 16, 24)

    if (small and frame:GetWidth() <= 24) then
        frame:SetWidth(20)
    end

    if (small) then
        frame:SetHeight(18)
    end

    frame:HookScript("OnEnter", function(f)
        f:SetBackdropColor(unpack(hovercolors))
    end)
    frame:HookScript("OnLeave", function(f)
        f:SetBackdropColor(unpack(colors))
    end)

    return true
end

local function setItemBorderColor(frame, item)
    local quality = select(3, GetItemInfo(item))

    if not quality then
        return false
    end

    local r, g, b = GetItemQualityColor(select(3, GetItemInfo(item)))
    frame:SetBackdropBorderColor(r, g, b, 1)
    return true
end

function AddOn:repositionFrames()
    local lastentry = nil
    local sortByIlvl = {}
    local ilvls = {}

    tsort(AddOn.Entries, function(a, b)
        -- sort by ilvl
        local ailvl, bilvl = tonumber(a.ilvl:GetText()), tonumber(b.ilvl:GetText())
        return ailvl > bilvl
    end)
    
    for i = 1, #AddOn.Entries do
        local ilvl = tonumber(AddOn.Entries[i].ilvl:GetText())

        if ilvl ~= nil and ilvl > 0 then
            if sortByIlvl[ilvl] == nil then
                sortByIlvl[ilvl] = {}
                table.insert(ilvls, ilvl)
            end

            table.insert(sortByIlvl[ilvl], AddOn.Entries[i])
        end
    end

    tsort(ilvls, function(a, b)
        return a > b
    end)

    for _, ilvl in pairs(ilvls) do
        local entries = sortByIlvl[ilvl]

        tsort(entries, function(a, b)
            local aitemID, bitemID = tonumber(a.itemID), tonumber(b.itemID)
            return aitemID > bitemID
        end)
        
        for i = 1, #entries do
            local currententry = entries[i]

            if currententry.itemLink then
                if lastentry then
                    currententry:SetPoint("TOPLEFT", lastentry, "BOTTOMLEFT", 0, 1)
                else
                    currententry:SetPoint("TOPLEFT", AddOn.lootFrame.table.content, "TOPLEFT", 0, 1)
                end
                lastentry = currententry
            end
        end
    end
end

function AddOn.setItemTooltip(frame, item)
    local tex = select(5, GetItemInfoInstant(item))
    frame.tex:SetTexture(tex)
    frame:SetScript("OnEnter", function() showItemTooltip(item) end)
    frame:SetScript("OnLeave", function() hideItemTooltip() end)
    frame:SetScript("OnClick", function(_, button)
        if IsModifiedClick("CHATLINK") then
            if ChatEdit_InsertLink(item) then return true end
        end
        if IsModifiedClick("DRESSUP") then return DressUpItemLink(item) end
        if button == "RightButton" and IsModifiedClick("EXPANDITEM") then
            if IsAzeriteEmpoweredItemByID(item) then
                OpenAzeriteEmpoweredItemUIFromLink(item);
                return true;
            end
        end
    end)
    setItemBorderColor(frame, item)
    frame:Show()
end

local normal_button_text = CreateFont("dynt_button")
normal_button_text:SetFont("Interface\\AddOns\\DoYouNeedThat\\Media\\Roboto-Medium.ttf", 12, "")
normal_button_text:SetTextColor(1, 1, 1, 1)
normal_button_text:SetShadowColor(0, 0, 0)
normal_button_text:SetShadowOffset(1, -1)
normal_button_text:SetJustifyH("CENTER")

local large_font = CreateFont("dynt_large_text")
large_font:SetFont("Interface\\AddOns\\DoYouNeedThat\\Media\\Roboto-Medium.ttf", 14, "")
large_font:SetShadowColor(0, 0, 0)
large_font:SetShadowOffset(1, -1)

local normal_font = CreateFont("dynt_normal_text")
normal_font:SetFont("Interface\\AddOns\\DoYouNeedThat\\Media\\Roboto-Medium.ttf", 11, "")
normal_font:SetTextColor(1, 1, 1, 1)
normal_font:SetShadowColor(0, 0, 0)
normal_font:SetShadowOffset(1, -1)
normal_font:SetJustifyH("CENTER")

function AddOn.createLootFrame()
    -- Window
    ---@type table|BackdropTemplate|Frame
    AddOn.lootFrame = CreateFrame('frame', 'DYNT', UIParent, "BackdropTemplate")
    skinBackdrop(AddOn.lootFrame, .1, .1, .1, .8)
    AddOn.lootFrame:EnableMouse(true)
    AddOn.lootFrame:SetMovable(true)
    AddOn.lootFrame:SetUserPlaced(true)
    AddOn.lootFrame:SetFrameStrata("DIALOG")
    AddOn.lootFrame:SetFrameLevel(1)
    AddOn.lootFrame:SetClampedToScreen(true)
    AddOn.lootFrame:SetSize(380, 200)
    AddOn.lootFrame:SetPoint("CENTER")
    AddOn.lootFrame:Hide()

    -- Header
    ---@type table|BackdropTemplate|Frame
    AddOn.lootFrame.header = CreateFrame('frame', nil, AddOn.lootFrame, "BackdropTemplate")
    AddOn.lootFrame.header:EnableMouse(true)
    AddOn.lootFrame.header:RegisterForDrag('LeftButton', 'RightButton')
    AddOn.lootFrame.header:SetScript("OnDragStart", function() AddOn.lootFrame:StartMoving() end)
    AddOn.lootFrame.header:SetScript("OnDragStop", function()
        AddOn.lootFrame:StopMovingOrSizing()
        local point, _, _, x, y = AddOn.lootFrame:GetPoint()
        AddOn.db.lootWindow = { point, x, y }
    end)
    AddOn.lootFrame.header:SetPoint("TOPLEFT", AddOn.lootFrame, "TOPLEFT")
    AddOn.lootFrame.header:SetPoint("BOTTOMRIGHT", AddOn.lootFrame, "TOPRIGHT", 0, -24)
    skinBackdrop(AddOn.lootFrame.header, .1, .1, .1, 1)

    local minimized = false
    ---@type table|BackdropTemplate|Button
    AddOn.lootFrame.header.minimize = CreateFrame("Button", nil, AddOn.lootFrame.header, "BackdropTemplate")
    AddOn.lootFrame.header.minimize:SetPoint("RIGHT", AddOn.lootFrame.header, "RIGHT", -30, 0)
    AddOn.lootFrame.header.minimize:SetText("-")
    skinButton(AddOn.lootFrame.header.minimize, true, "lightgrey")

    ---@type table|BackdropTemplate|Button
    AddOn.lootFrame.header.close = CreateFrame("Button", nil, AddOn.lootFrame.header, "BackdropTemplate")
    AddOn.lootFrame.header.close:SetPoint("RIGHT", AddOn.lootFrame.header, "RIGHT", -4, 0)
    AddOn.lootFrame.header.close:SetText("x")
    skinButton(AddOn.lootFrame.header.close, true, "red")
    AddOn.lootFrame.header.close:SetScript("OnClick", function()
        AddOn.lootFrame:Hide()
        AddOn.db.lootWindowOpen = false
    end)

    AddOn.lootFrame.header.text = AddOn.lootFrame.header:CreateFontString(nil, "OVERLAY", "dynt_large_text")
    AddOn.lootFrame.header.text:SetText("|cFFFF6B6BDoYouNeedThat")
    AddOn.lootFrame.header.text:SetPoint("CENTER", AddOn.lootFrame.header, "CENTER")

    -- Vote table
    ---@type table|BackdropTemplate|Frame
    local loot_table = CreateFrame("Frame", nil, AddOn.lootFrame, "BackdropTemplate")
    loot_table:SetPoint("TOPLEFT", AddOn.lootFrame, "TOPLEFT", 10, -50)
    loot_table:SetPoint("BOTTOMRIGHT", AddOn.lootFrame, "BOTTOMRIGHT", -30, 10)
    skinBackdrop(loot_table, .1, .1, .1, .8)
    AddOn.lootFrame.table = loot_table

    ---@type table|BackdropTemplate|ScrollFrame
    local scrollframe = CreateFrame("ScrollFrame", nil, loot_table)
    scrollframe:SetPoint("TOPLEFT", loot_table, "TOPLEFT", 0, -2)
    scrollframe:SetPoint("BOTTOMRIGHT", loot_table, "BOTTOMRIGHT", 0, 2)
    loot_table.scrollframe = scrollframe

    ---@type table|BackdropTemplate|Slider
    local scrollbar = CreateFrame("Slider", nil, scrollframe, "UIPanelScrollBarTemplate")
    Mixin(scrollbar, BackdropTemplateMixin)
    scrollbar:SetPoint("TOPLEFT", loot_table, "TOPRIGHT", 6, -16)
    scrollbar:SetPoint("BOTTOMLEFT", loot_table, "BOTTOMRIGHT", 0, 16)
    scrollbar:SetMinMaxValues(1, 60)
    scrollbar:SetValueStep(1)
    scrollbar.scrollStep = 1
    scrollbar:SetValue(0)
    scrollbar:SetWidth(16)
    scrollbar:SetScript("OnValueChanged", function(self, value) self:GetParent():SetVerticalScroll(value) end)
    skinBackdrop(scrollbar, .1, .1, .1, .8)
    loot_table.scrollbar = scrollbar

    ---@type Frame
    loot_table.content = CreateFrame("Frame", nil, scrollframe)
    -- loot_table.content:SetSize(340, 140)
    scrollframe:SetScrollChild(loot_table.content)


    loot_table.item_text = loot_table:CreateFontString(nil, "OVERLAY", "dynt_button")
    loot_table.item_text:SetText(L["Item"])
    loot_table.item_text:SetTextColor(1, 1, 1)
    loot_table.item_text:SetPoint("TOPLEFT", loot_table, "TOPLEFT", 10, 16)

    loot_table.ilvl_text = loot_table:CreateFontString(nil, "OVERLAY", "dynt_button")
    loot_table.ilvl_text:SetText(L["ILvl"])
    loot_table.ilvl_text:SetTextColor(1, 1, 1)
    loot_table.ilvl_text:SetPoint("TOPLEFT", loot_table, "TOPLEFT", 50, 16)

    loot_table.name_text = loot_table:CreateFontString(nil, "OVERLAY", "dynt_button")
    loot_table.name_text:SetText(L["Looter"])
    loot_table.name_text:SetTextColor(1, 1, 1)
    loot_table.name_text:SetPoint("TOPLEFT", loot_table, "TOPLEFT", 90, 16)

    loot_table.equipped_text = loot_table:CreateFontString(nil, "OVERLAY", "dynt_button")
    loot_table.equipped_text:SetText(L["Looter Eq"])
    loot_table.equipped_text:SetTextColor(1, 1, 1)
    loot_table.equipped_text:SetPoint("TOPLEFT", loot_table, "TOPLEFT", 175, 16)

    -- print(AddOn.db.config.checkTransmogable)
    -- print(AddOn.Config)
    -- print(CanIMogIt)

    local content_size = 340
    local lootFrame_size = 380

    if AddOn.db.config.checkTransmogable and CanIMogIt then
        loot_table.canimogit_text = loot_table:CreateFontString(nil, "OVERLAY", "dynt_button")
        loot_table.canimogit_text:SetText(L["CanIMogIt"])
        loot_table.canimogit_text:SetTextColor(1, 1, 1)
        loot_table.canimogit_text:SetPoint("TOPLEFT", loot_table, "TOPLEFT", 90, 16)

        -- loot_table.content:SetSize(380, 140)
        loot_table.name_text:SetPoint("TOPLEFT", loot_table, "TOPLEFT", 130, 16)
        loot_table.equipped_text:SetPoint("TOPLEFT", loot_table, "TOPLEFT", 215, 16)

        content_size = content_size + 40
        lootFrame_size = lootFrame_size + 40
    end

    if AddOn.db.config.checkCustomTexts and next(AddOn.db.config.customTexts) then
        content_size = content_size + 40
        lootFrame_size = lootFrame_size + 40
    end
    
    AddOn.lootFrame:SetSize(lootFrame_size, 200)
    loot_table.content:SetSize(content_size, 140)

    AddOn.lootFrame.header.minimize:SetScript("OnClick", function(self)
        if minimized then
            AddOn.lootFrame:SetSize(lootFrame_size, 200)
            AddOn.lootFrame.table:Show()
            self:SetText("-")
            minimized = false
        else
            AddOn.lootFrame:SetSize(lootFrame_size, 24)
            AddOn.lootFrame.table:Hide()
            self:SetText("+")
            minimized = true
        end
    end)

    local lastframe = nil
    for i = 1, 20 do
        ---@type table|BackdropTemplate|Button
        local entry = CreateFrame("Button", nil, loot_table.content, "BackdropTemplate")
        entry:SetSize(loot_table.content:GetWidth(), 24)
        if (lastframe) then
            entry:SetPoint("TOPLEFT", lastframe, "BOTTOMLEFT", 0, 2)
        else
            entry:SetPoint("TOPLEFT", loot_table.content, "TOPLEFT", 0, -3)
        end
        skinBackdrop(entry, 1, 1, 1, .1)
        entry:Hide()

        entry.itemLink = nil
        entry.itemID = nil
        entry.looter = nil

        ---@type table|BackdropTemplate|Frame
        entry.item = CreateFrame("Button", nil, entry, "BackdropTemplate")
        entry.item:SetSize(20, 20)
        --entry.item:Hide()
        entry.item:SetPoint("LEFT", entry, "LEFT", 12, 0)
        entry.item:RegisterForClicks("LeftButtonDown", "RightButtonUp")
        skinBackdrop(entry.item, 0, 0, 0, 1)

        entry.item.tex = entry.item:CreateTexture(nil, "OVERLAY")
        entry.item.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        entry.item.tex:SetDrawLayer("ARTWORK")
        -- entry.item.tex:SetTexture(nil)
        entry.item.tex:SetTexture('')
        entry.item.tex:SetPoint("TOPLEFT", entry.item, "TOPLEFT", 2, -2)
        entry.item.tex:SetPoint("BOTTOMRIGHT", entry.item, "BOTTOMRIGHT", -2, 2)

        entry.ilvl = entry:CreateFontString(nil, "OVERLAY", "dynt_normal_text")
        entry.ilvl:SetText("0")
        entry.ilvl:SetTextColor(1, 1, 1)
        entry.ilvl:SetPoint("LEFT", entry, "LEFT", 50, 0)

        entry.name = entry:CreateFontString(nil, "OVERLAY", "dynt_normal_text")
        entry.name:SetText("test")
        entry.name:SetTextColor(1, 1, 1)
        entry.name:SetPoint("LEFT", entry, "LEFT", 90, 0)

        ---@type table|BackdropTemplate|Frame
        entry.looterEq1 = CreateFrame("Button", nil, entry, "BackdropTemplate")
        entry.looterEq1:SetSize(20, 20)
        --entry.looterEq1:Hide()
        entry.looterEq1:SetPoint("LEFT", entry, "LEFT", 181, 0)
        entry.looterEq1:RegisterForClicks("LeftButtonDown", "RightButtonUp")
        skinBackdrop(entry.looterEq1, 0, 0, 0, 1)

        entry.looterEq1.tex = entry.looterEq1:CreateTexture(nil, "OVERLAY")
        entry.looterEq1.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        entry.looterEq1.tex:SetDrawLayer("ARTWORK")
        entry.looterEq1.tex:SetTexture(134400)
        entry.looterEq1.tex:SetPoint("TOPLEFT", entry.looterEq1, "TOPLEFT", 2, -2)
        entry.looterEq1.tex:SetPoint("BOTTOMRIGHT", entry.looterEq1, "BOTTOMRIGHT", -2, 2)

        ---@type table|BackdropTemplate|Frame
        entry.looterEq2 = CreateFrame("Button", nil, entry, "BackdropTemplate")
        entry.looterEq2:SetSize(20, 20)
        entry.looterEq2:Hide()
        entry.looterEq2:SetPoint("LEFT", entry, "LEFT", 203, 0)
        entry.looterEq2:RegisterForClicks("LeftButtonDown", "RightButtonUp")
        skinBackdrop(entry.looterEq2, 0, 0, 0, 1)

        entry.looterEq2.tex = entry.looterEq2:CreateTexture(nil, "OVERLAY")
        entry.looterEq2.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        entry.looterEq2.tex:SetDrawLayer("ARTWORK")
        -- entry.looterEq2.tex:SetTexture(nil)
        entry.looterEq2.tex:SetTexture('')
        entry.looterEq2.tex:SetPoint("TOPLEFT", entry.looterEq2, "TOPLEFT", 2, -2)
        entry.looterEq2.tex:SetPoint("BOTTOMRIGHT", entry.looterEq2, "BOTTOMRIGHT", -2, 2)

        ---@type table|BackdropTemplate|Button
        entry.whisper = CreateFrame("Button", nil, entry, "BackdropTemplate")
        entry.whisper:SetSize(45, 20)
        entry.whisper:SetPoint("RIGHT", entry, "RIGHT", -30, 0)
        entry.whisper:SetText(L["Whisper"])
        skinButton(entry.whisper, true, "blue")
        entry.whisper:SetScript("OnClick", function()
            AddOn:sendWhisperToLooter(entry.itemLink, entry.looter)
            entry.whisper:Hide()
        end)
        entry.whisper:Hide()

        ---@type table|BackdropTemplate|Button
        entry.delete = CreateFrame("Button", nil, entry, "BackdropTemplate")
        entry.delete:SetSize(25, 20)
        entry.delete:SetPoint("RIGHT", entry, "RIGHT", -7, 0)
        entry.delete:SetText("x")
        skinButton(entry.delete, true, "red")
        entry.delete:SetScript("OnClick", function()
            entry:Hide()
            entry.itemLink = nil
            entry.looter = nil
            entry.guid = nil
            entry.ilvl:SetText("0")
            entry.itemID = nil
            entry.looter = nil
            
            -- Re order
            AddOn:repositionFrames()
        end)

        if AddOn.db.config.checkTransmogable and CanIMogIt then
            entry.mog = entry:CreateFontString(nil, "OVERLAY", "dynt_normal_text")
            entry.mog:SetText("0")
            entry.mog:SetTextColor(1, 1, 1)
            entry.mog:SetPoint("LEFT", entry, "LEFT", 90, 0)

            entry.name:SetPoint("LEFT", entry, "LEFT", 130, 0)
            entry.looterEq1:SetPoint("LEFT", entry, "LEFT", 221, 0)
            entry.looterEq2:SetPoint("LEFT", entry, "LEFT", 243, 0)
        end

        if AddOn.db.config.checkCustomTexts and next(AddOn.db.config.customTexts) then
            entry.whisper:SetPoint("RIGHT", entry, "RIGHT", -60, 0)
            
            ---@type table|BackdropTemplate|Button
            entry.customTextButton = CreateFrame("Button", "DYNT_Entry_CustomTextButton" .. i, entry, "BackdropTemplate")
            entry.customTextButton:SetPoint("RIGHT", entry, "RIGHT", -30, 0)
            entry.customTextButton:SetText("|TInterface\\Buttons\\Arrow-Down-Down:10:10:0:-3|t")
            entry.customTextButton:SetSize(20, 20)
            skinButton(entry.customTextButton, true, "black")

            entry.customTextMenu = CreateFrame("Frame", "DYNT_Entry_CustomTextMenu" .. i, entry, "UIDropDownMenuTemplate")
            UIDropDownMenu_SetWidth(entry.customTextMenu, 100)
            UIDropDownMenu_Initialize(entry.customTextMenu, (function()
                local info = {}

                for key, value in pairs(AddOn.db.config.customTexts) do
                    info.text = value
                    info.value = key
                    info.func = function(self)
                        AddOn:sendCustomWhisperToLooter(self.value, entry.itemLink, entry.looter)
                        -- print(self.value .. " " .. entry.itemLink .. " " .. entry.looter)
                        entry.whisper:Hide()
                        entry.customTextButton:Hide()
                    end
                    UIDropDownMenu_AddButton(info)
                end
            end), "MENU")

            entry.customTextButton:SetScript("OnClick", function(self)
                ToggleDropDownMenu(1, nil, entry.customTextMenu, self, 0, 0)
            end)
            entry.customTextButton:Hide()
        end

        lastframe = entry
        AddOn.Entries[i] = entry
    end
end

--- Options GUI
function AddOn.createOptionsFrame()
    local options = CreateFrame("Frame", "DYNT_Options")
    options.name = "DoYouNeedThat"

    -- Debug toggle
    ---@type table|BackdropTemplate|CheckButton
    options.debug = CreateFrame("CheckButton", "DYNT_Options_Debug", options, "ChatConfigCheckButtonTemplate")
    options.debug:SetPoint("TOPLEFT", options, "TOPLEFT", 20, -20)
    -- DYNT_Options_DebugText:SetText(L["Debug"])
    getglobal(options.debug:GetName() .. 'Text'):SetText(L["Debug"]);
    if AddOn.Config.debug then options.debug:SetChecked(true) end
    options.debug:SetScript("OnClick", function(self)
        AddOn.db.config.debug = self:GetChecked()
    end)

    -- Open after boss kill toggle
    ---@type table|BackdropTemplate|CheckButton
    options.openAfterEncounter = CreateFrame("CheckButton", "DYNT_Options_OpenAfterEncounter", options,
        "ChatConfigCheckButtonTemplate")
    options.openAfterEncounter:SetPoint("TOPLEFT", options, "TOPLEFT", 20, -50)
    -- DYNT_Options_OpenAfterEncounterText:SetText(L["Open loot window after encounter"])
    getglobal(options.openAfterEncounter:GetName() .. 'Text'):SetText(L["Open loot window after encounter"]);
    if AddOn.Config.openAfterEncounter then options.openAfterEncounter:SetChecked(true) end
    options.openAfterEncounter:SetScript("OnClick", function(self)
        AddOn.db.config.openAfterEncounter = self:GetChecked()
    end)

    -- Check item is Transmogable
    ---@type table|BackdropTemplate|CheckButton
    options.checkTransmogable = CreateFrame("CheckButton", "DYNT_Options_CheckTransmogable", options,
        "ChatConfigCheckButtonTemplate")
    options.checkTransmogable:SetPoint("TOPLEFT", options, "TOPLEFT", 20, -80)
    -- DYNT_Options_CheckTransmogableText:SetText(L["OPTIONS_CHECK_TRANSMOG"])
    getglobal(options.checkTransmogable:GetName() .. 'Text'):SetText(L["OPTIONS_CHECK_TRANSMOG"]);
    if AddOn.Config.checkTransmogable then options.checkTransmogable:SetChecked(true) end
    options.checkTransmogable:SetScript("OnClick", function(self)
        AddOn.db.config.checkTransmogable = self:GetChecked()
        AddOn:recreateLootFrame()
    end)

    -- Show optional source too
    ---@type table|BackdropTemplate|CheckButton
    options.checkTransmogableSource = CreateFrame("CheckButton", "DYNT_Options_CheckTransmogableSource", options,
        "ChatConfigCheckButtonTemplate")
    options.checkTransmogableSource:SetPoint("TOPLEFT", options, "TOPLEFT", 20, -110)
    -- DYNT_Options_CheckTransmogableSourceText:SetText(L["OPTIONS_CHECK_TRANSMOG_OTHER_SOURCES"])
    getglobal(options.checkTransmogableSource:GetName() .. 'Text'):SetText(L["OPTIONS_CHECK_TRANSMOG_OTHER_SOURCES"]);
    if AddOn.Config.checkTransmogableSource then options.checkTransmogableSource:SetChecked(true) end
    options.checkTransmogableSource:SetScript("OnClick", function(self)
        AddOn.db.config.checkTransmogableSource = self:GetChecked()
    end)

    -- Check mounts
    ---@type table|BackdropTemplate|CheckButton
    options.checkMounts = CreateFrame("CheckButton", "DYNT_Options_CheckMounts", options,
        "ChatConfigCheckButtonTemplate")
    options.checkMounts:SetPoint("TOPLEFT", options, "TOPLEFT", 20, -140)
    getglobal(options.checkMounts:GetName() .. 'Text'):SetText(L["OPTIONS_CHECK_MOUNTS"]);
    if AddOn.Config.checkMounts then options.checkMounts:SetChecked(true) end
    options.checkMounts:SetScript("OnClick", function(self)
        AddOn.db.config.checkMounts = self:GetChecked()
    end)

    -- Check toys
    ---@type table|BackdropTemplate|CheckButton
    options.checkToys = CreateFrame("CheckButton", "DYNT_Options_CheckToys", options,
        "ChatConfigCheckButtonTemplate")
    options.checkToys:SetPoint("TOPLEFT", options, "TOPLEFT", 20, -170)
    getglobal(options.checkToys:GetName() .. 'Text'):SetText(L["OPTIONS_CHECK_TOYS"]);
    if AddOn.Config.checkToys then options.checkToys:SetChecked(true) end
    options.checkToys:SetScript("OnClick", function(self)
        AddOn.db.config.checkToys = self:GetChecked()
    end)

    -- Check pets
    ---@type table|BackdropTemplate|CheckButton
    options.checkPets = CreateFrame("CheckButton", "DYNT_Options_CheckPets", options,
        "ChatConfigCheckButtonTemplate")
    options.checkPets:SetPoint("TOPLEFT", options, "TOPLEFT", 20, -200)
    getglobal(options.checkPets:GetName() .. 'Text'):SetText(L["OPTIONS_CHECK_PETS"]);
    if AddOn.Config.checkPets then options.checkPets:SetChecked(true) end
    options.checkPets:SetScript("OnClick", function(self)
        AddOn.db.config.checkPets = self:GetChecked()
    end)

    -- Hide minimap button
    ---@type table|BackdropTemplate|CheckButton
    options.hideMinimap = CreateFrame("CheckButton", "DYNT_Options_HideMinimap", options, "ChatConfigCheckButtonTemplate")
    options.hideMinimap:SetPoint("TOPLEFT", options, "TOPLEFT", 20, -230)
    -- DYNT_Options_HideMinimapText:SetText(L["Hide minimap button"])
    getglobal(options.hideMinimap:GetName() .. 'Text'):SetText(L["Hide minimap button"]);
    if AddOn.db.minimap.hide then options.hideMinimap:SetChecked(true) end
    options.hideMinimap:SetScript("OnClick", function(self)
        AddOn.db.minimap.hide = self:GetChecked()

        if not self:GetChecked() then
            icon:Show("DoYouNeedThat")
        else
            icon:Hide("DoYouNeedThat")
        end
    end)

	local chatshowlootframe_options = {
        ['disabled'] = L["SELECT_OPTION_DISABLED"],
        ['only_dungeon_raid'] = L["SELECT_OPTION_ONLY_DUNGEON_RAID"],
        ['everywhere'] = L["SELECT_OPTION_EVERYWHERE"],
    }

	options.chatShowLootFrame = CreateFrame("Frame", "DYNT_Options_ChatShowLootFrame", options, "UIDropDownMenuTemplate")
	options.chatShowLootFrame:SetPoint("TOPLEFT", options, "TOPLEFT", 3, -270)
	-- options.chatShowLootFrame:SetWidth(150)
    UIDropDownMenu_SetWidth(options.chatShowLootFrame, 150)
    getglobal(options.chatShowLootFrame:GetName() .. 'Text'):SetText(chatshowlootframe_options[AddOn.db.config.chatShowLootFrame]);
	options.chatShowLootFrame.initialize = function()
        local info = {}
        for key, value in pairs(chatshowlootframe_options) do
			info.text = value
			info.value = key
			info.checked = key == AddOn.db.config.chatShowLootFrame
			info.func = function(self)
				AddOn.db.config.chatShowLootFrame = self.value
                getglobal(options.chatShowLootFrame:GetName() .. 'Text'):SetText(self:GetText());
                AddOn:PLAYER_ENTERING_WORLD()
			end
			UIDropDownMenu_AddButton(info)
        end
	end

    options.chatShowLootFrame.labelText = options.chatShowLootFrame:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
    options.chatShowLootFrame.labelText:SetPoint("TOPLEFT", options.chatShowLootFrame, "TOPLEFT", 20, 15)
    options.chatShowLootFrame.labelText:SetJustifyH("LEFT")
    options.chatShowLootFrame.labelText:SetTextColor(1, 1, 1)
    options.chatShowLootFrame.labelText:SetShadowColor(0, 0, 0)
    options.chatShowLootFrame.labelText:SetShadowOffset(1, -1)
    options.chatShowLootFrame.labelText:SetText(L["OPTIONS_CHECK_CHAT_SHOW_LOOT_FRAME"])

    -- Whisper message
    ---@type table|BackdropTemplate|EditBox
    options.whisperMessage = CreateFrame("EditBox", "DYNT_Options_WhisperMessage", options, "InputBoxTemplate")
    options.whisperMessage:SetSize(200, 32)
    options.whisperMessage:SetPoint("TOPLEFT", options, "TOPLEFT", 28, -320)
    options.whisperMessage:SetAutoFocus(false)
    options.whisperMessage:SetMaxLetters(128)
    AddOn.Debug(AddOn.Config.whisperMessage)
    if AddOn.Config.whisperMessage then options.whisperMessage:SetText(AddOn.Config.whisperMessage) end
    options.whisperMessage:SetCursorPosition(0)
    options.whisperMessage:SetScript("OnEditFocusGained", function() --[[ Override to not highlight the text ]] end)
    options.whisperMessage:SetScript("OnEnterPressed", function(self)
        AddOn.db.config.whisperMessage = self:GetText()
        self:ClearFocus()
    end)

    local whisperLabel = options.whisperMessage:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
    whisperLabel:SetPoint("TOPLEFT", options.whisperMessage, "TOPLEFT", -3, 15)
    --whisperLabel:SetPoint("BOTTOMRIGHT", options.whisperMessage, "TOPRIGHT", -6, 0)
    whisperLabel:SetJustifyH("LEFT")
    options.whisperMessage.labelText = whisperLabel
    options.whisperMessage.labelText:SetTextColor(1, 1, 1)
    options.whisperMessage.labelText:SetShadowColor(0, 0, 0)
    options.whisperMessage.labelText:SetShadowOffset(1, -1)
    options.whisperMessage.labelText:SetText(L["Whisper Message"])

    options.minDelta = CreateFrame("Slider", "DYNT_Options_MinDelta", options, "OptionsSliderTemplate")
    options.minDelta:SetWidth(300)
    options.minDelta:SetHeight(20)
    options.minDelta:SetPoint("TOPLEFT", 28, -390)
    options.minDelta:SetOrientation("HORIZONTAL")
    options.minDelta:SetMinMaxValues(0, 100)
    options.minDelta:SetValue(AddOn.Config.minDelta)
    options.minDelta:SetValueStep(1)
    options.minDelta:SetObeyStepOnDrag(true)
    options.minDelta:SetScript("OnValueChanged", function(_, val)
        getglobal(options.minDelta:GetName() .. 'Text'):SetText(val); --Sets the "title" text (top-centre of slider).
        AddOn.db.config.minDelta = val
    end)
    options.minDelta.tooltipText = L["Minimum itemlevel allowed"]                      --Creates a tooltip on mouseover.
    getglobal(options.minDelta:GetName() .. 'Low'):SetText('1');                       --Sets the left-side slider text (default is "Low").
    getglobal(options.minDelta:GetName() .. 'High'):SetText('100');                    --Sets the right-side slider text (default is "High").
    getglobal(options.minDelta:GetName() .. 'Text'):SetText(AddOn.db.config.minDelta); --Sets the "title" text (top-centre of slider).
    options.minDelta:Show()


    local minDeltaLabel = options.minDelta:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
    minDeltaLabel:SetPoint("TOPLEFT", options.minDelta, "TOPLEFT", -3, 30)
    minDeltaLabel:SetJustifyH("LEFT")
    options.minDelta.labelText = minDeltaLabel
    options.minDelta.labelText:SetTextColor(1, 1, 1)
    options.minDelta.labelText:SetShadowColor(0, 0, 0)
    options.minDelta.labelText:SetShadowOffset(1, -1)
    options.minDelta.labelText:SetText(L["Minimum itemlevels lower"])

    -- Check custom texts
    ---@type table|BackdropTemplate|CheckButton
    options.checkCustomTexts = CreateFrame("CheckButton", "DYNT_Options_CheckCustomTexts", options,
        "ChatConfigCheckButtonTemplate")
    options.checkCustomTexts:SetPoint("TOPLEFT", options, "TOPLEFT", 20, -430)
    getglobal(options.checkCustomTexts:GetName() .. 'Text'):SetText(L["OPTIONS_CHECK_CUSTOM_TEXTS"]);
    if AddOn.Config.checkCustomTexts then options.checkCustomTexts:SetChecked(true) end
    options.checkCustomTexts:SetScript("OnClick", function(self)
        AddOn.db.config.checkCustomTexts = self:GetChecked()
        AddOn:recreateLootFrame()
    end)

    AddOn.createCustomTextInputs(options)

    -- Set the field values to their value in SavedVariables.
    function options.refreshFields()
        options.debug:SetChecked(AddOn.Config.debug)
        options.openAfterEncounter:SetChecked(AddOn.Config.openAfterEncounter)
        options.checkTransmogable:SetChecked(AddOn.Config.checkTransmogable)
        options.checkTransmogableSource:SetChecked(AddOn.Config.checkTransmogableSource)
        options.whisperMessage:SetText(AddOn.Config.whisperMessage)
        options.whisperMessage:SetCursorPosition(0)
        options.hideMinimap:SetChecked(AddOn.db.minimap.hide)
        options.minDelta:SetValue(AddOn.Config.minDelta)
    end

    function options.okay()
        -- print(options.checkTransmogable:GetChecked())
        xpcall(function()
            AddOn.db.config.debug = options.debug:GetChecked()
            AddOn.db.config.openAfterEncounter = options.openAfterEncounter:GetChecked()
            AddOn.db.config.checkTransmogable = options.checkTransmogable:GetChecked()
            AddOn.db.config.checkTransmogableSource = options.checkTransmogableSource:GetChecked()
            AddOn.db.config.whisperMessage = options.whisperMessage:GetText()
            if options.hideMinimap:GetChecked() then
                icon:Hide("DoYouNeedThat")
                AddOn.db.minimap.hide = true;
            else
                icon:Show("DoYouNeedThat")
                AddOn.db.minimap.hide = false;
            end
            AddOn.db.config.minDelta = options.minDelta:GetValue()
        end, geterrorhandler())
    end

    function options.cancel()
        -- Return the fields to a clean slate
        options.refreshFields()
    end

    if (Settings ~= nil) then
        -- wow10
        local category = Settings.RegisterCanvasLayoutCategory(options, 'DoYouNeedThat')
        Settings.RegisterAddOnCategory(category)
        options.categoryID = category:GetID() -- for OpenToCategory use
    else
        InterfaceOptions_AddCategory(options)
    end
end

--[[
    Adds a new custom text input field to the specified frame at the specified index and saves the existing custom text inputs to the db.

    @param index The index of the new custom text input field
    @param frame The frame on which the custom text inputs are located
--]]
function AddOn.addCustomTextInput(index, frame)
    if not frame.customTextInput then
        frame.customTextInput = {}
    end

    local inputFrame = frame.customTextInput[index]
    local position = -(index * 30 + 430)

    ---@type table|BackdropTemplate|EditBox
    frame.customTextInput[index] = CreateFrame("EditBox", "DYNT_Options_CustomTextInput_" .. index, frame, "InputBoxTemplate")
    frame.customTextInput[index]:SetSize(400, 32)
    frame.customTextInput[index]:SetPoint("TOPLEFT", frame, "TOPLEFT", 50, position)
    frame.customTextInput[index]:SetAutoFocus(false)
    frame.customTextInput[index]:SetMaxLetters(128)

    if AddOn.db.config.customTexts[index] then
        frame.customTextInput[index]:SetText(AddOn.db.config.customTexts[index])
    end

    frame.customTextInput[index]:SetCursorPosition(0)
    frame.customTextInput[index]:SetScript("OnEditFocusGained", function() --[[ Override to not highlight the text ]] end)
    frame.customTextInput[index]:SetScript("OnEditFocusLost", function(self)
        AddOn.db.config.customTexts[index] = self:GetText()
        AddOn.saveCustomTextInputs(frame)
    end)
    frame.customTextInput[index]:SetScript("OnEnterPressed", function(self)
        AddOn.db.config.customTexts[index] = self:GetText()
        AddOn.saveCustomTextInputs(frame)
    end)
    
    local whisperLabel = frame.customTextInput[index]:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
    whisperLabel:SetPoint("TOPLEFT", frame.customTextInput[index], "TOPLEFT", -25, -10)
    whisperLabel:SetJustifyH("LEFT")
    frame.customTextInput[index].labelText = whisperLabel
    frame.customTextInput[index].labelText:SetTextColor(1, 1, 1)
    frame.customTextInput[index].labelText:SetShadowColor(0, 0, 0)
    frame.customTextInput[index].labelText:SetShadowOffset(1, -1)
    frame.customTextInput[index].labelText:SetText(index .. '.')
end

--[[
    Initializes and creates custom text input fields on the specified frame based on the saved configuration.

    This function resets the current custom text inputs and iterates over the saved custom texts in the database,
    creating an input field for each one. It also adds an additional input field for new entries.

    @param frame The frame on which to create the custom text inputs
--]]
local count_custom_text = 0

function AddOn.createCustomTextInputs(frame)
    -- Initialize the customTextInput table for the frame
    frame.customTextInput = {}
    -- Reset the count of custom text inputs
    count_custom_text = 0

    -- Iterate over the existing custom texts and create input fields
    for i, _ in pairs(AddOn.db.config.customTexts) do
        AddOn.addCustomTextInput(i, frame)
        count_custom_text = count_custom_text + 1
    end

    -- Add an additional input field for new custom text
    count_custom_text = count_custom_text + 1
    AddOn.addCustomTextInput(count_custom_text, frame)
end

--[[
    Saves the custom text inputs to the db and recreates them if the "Recreate loot frame on custom text change" option is enabled.

    @param frame The frame on which the custom text inputs are located
--]]
function AddOn.saveCustomTextInputs(frame)
    local index = 1
    local old_custom_texts = AddOn.db.config.customTexts
    AddOn.db.config.customTexts = {}

    -- Loop through all custom text inputs and save their text to the db
    -- if they are not empty
    for _,text in pairs(old_custom_texts) do
        if text and text ~= "" then
            AddOn.db.config.customTexts[index] = text
            index = index + 1
        end
    end

    -- If the "Recreate loot frame on custom text change" option is enabled, recreate the loot frame
    if AddOn.db.config.checkCustomTexts then
        AddOn:recreateLootFrame()
    end

    -- Remove all custom text inputs from the frame and recreate them
    AddOn.removeCustomTextInputs(frame)
    AddOn.createCustomTextInputs(frame)
end

--[[
    Removes all custom text input fields from the frame

    This function is called when the user changes the number of custom text inputs
    in the options menu. It removes all the current custom text inputs from the
    frame and then recreates them according to the new number of custom text
    inputs set in the options menu.

    @param frame The frame on which the custom text inputs are located
--]]
function AddOn.removeCustomTextInputs(frame)
    for i = 1, count_custom_text do
        if frame.customTextInput[i] then
            -- Hide the input field
            frame.customTextInput[i]:Hide()
            -- Clear the input field text
            frame.customTextInput[i]:SetText("")
            -- Remove the input field from the frame
            frame.customTextInput[i]:SetParent(nil)
            -- Remove all anchors from the input field
            frame.customTextInput[i]:ClearAllPoints()
            -- Remove all event handlers from the input field
            frame.customTextInput[i]:UnregisterAllEvents()
            -- Reset the input field ID
            frame.customTextInput[i]:SetID(0)
            -- Reset the input field object
            frame.customTextInput[i] = nil
        end
    end
end

