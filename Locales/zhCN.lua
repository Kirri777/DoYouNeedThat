if not (GetLocale() == "zhCN") then
    return
end

local _, AddOn = ...
local L = AddOn.L
L = L or {}

L["Click to toggle window"] = "点击打开窗口"
L["Debug"] = "排错"
L["Default Whisper Message"] = "你需要[item]吗？"
L["Hide minimap button"] = "隐藏小地图图标"
L["ILvl"] = "装等"
L["Item"] = "装备"
L["Looter"] = "拾取者"
L["Looter Eq"] = "拾取者的装备"
L["Minimum itemlevel allowed"] = "最低允许的装等"
L["Minimum itemlevels lower"] = "显示低于你装等多少的装备"
L["Toggle Window"] = "打开窗口"
L["Whisper"] = "私聊"
L["Whisper Message"] = "私聊发送的信息（用[item]来表示你需要的装备）"
L["MINIMAP_ICON_TOOLTIP1"] = "Click to toggle Window"
L["MINIMAP_ICON_TOOLTIP2"] = "Right-click to open DoYouNeedThat options panel"
L["OPTIONS_DONT_CHECK_ISITEMUPGRADE"] =
"Show all items for you (if checked then you can see items below your item Level)"
L["OPTIONS_SHOW_EVERYWHERE"] = "Show everywhere (not only in instances)"
L["OPTIONS_CHECK_TRANSMOG"] = "Check if the item is transmoggable (\124cFF8080FFrequires the CanIMogIt addon\124r)"
L["OPTIONS_CHECK_TRANSMOG_OTHER_SOURCES"] = "Also show items that are learned from other sources (\124cFF8080FFRequires the CanIMogIt addon\124r)"
L["OPTIONS_CHECK_CHAT_SHOW_LOOT_FRAME"] = "Show the loot frame when a classifiable item drops from any mob (not only bosses)"
L["CanIMogIt"] = "Mog"
L["SELECT_OPTION_DISABLED"] = "Disabled"
L["SELECT_OPTION_ONLY_DUNGEON_RAID"] = "Only in dungeon or raid"
L["SELECT_OPTION_EVERYWHERE"] = "Everywhere"
L["OPTIONS_CHECK_MOUNTS"] = "Check mounts"
L["OPTIONS_CHECK_TOYS"] = "Check toys"
L["OPTIONS_CHECK_PETS"] = "Check pets"
L["CUSTOM_TEXT"] = "Hi, do you need [item]? I need it for transmog."
L["OPTIONS_CHECK_CUSTOM_TEXTS"] = "\
Show a button for selecting additional custom messages.\
Define messages below (include the [item] shortcut to link an item).\
"
