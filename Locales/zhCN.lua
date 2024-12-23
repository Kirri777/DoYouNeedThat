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
L["SETTINGS_MENU_CUSTOM_MESSAGES"] = "Custom messages"
L["MINIMAP_ICON_TOOLTIP1"] = "Click to toggle Window"
L["MINIMAP_ICON_TOOLTIP2"] = "Right-click to open DoYouNeedThat options panel"
L["OPTIONS_DONT_CHECK_ISITEMUPGRADE"] =
"Show all items for you (if checked then you can see items below your item Level)"
L["OPTIONS_SHOW_EVERYWHERE"] = "Show everywhere (not only in instances)"
L["OPTIONS_CHECK_TRANSMOG"] = "Check if the item is transmoggable (\124cFF8080FFRequires the CanIMogIt addon\124r)"
L["OPTIONS_CHECK_TRANSMOG_OTHER_SOURCES"] = "Also show items that are learned from other sources (\124cFF8080FFRequires the CanIMogIt addon\124r)"
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

L["OPTIONS_CHECK_DEBUG"] = "Enable Debug Mode"
L["OPTIONS_CHECK_DEBUG_TOOLTIP"] = "Enables debug messages for troubleshooting or development. Use only if experiencing issues or when advised."

L["OPTIONS_CHECK_OPEN_AFTER_ENCOUNTER"] = "Open loot window post-encounter"
L["OPTIONS_CHECK_OPEN_AFTER_ENCOUNTER_TOOLTIP"] = "The loot window will appear automatically after a boss or mob kill, if its drop aligns with your set preferences."

L["OPTIONS_CHECK_TRANSMOGABLE"] = "Check missing transmogs (\124cFF8080FFCanIMogIt\124r)"
L["OPTIONS_CHECK_TRANSMOGABLE_TOOLTIP"] = "Displays items that are not yet in your transmog collection. Useful for spotting missing appearances. (\124cFF8080FFRequires CanIMogIt\124r)."

L["OPTIONS_CHECK_TRANSMOGABLE_OTHER_SOURCE"] = "Show from other sources (\124cFF8080FFCanIMogIt\124r)"
L["OPTIONS_CHECK_TRANSMOGABLE_OTHER_SOURCE_TOOLTIP"] = "Shows items that are already in your collection from another source, but not from this specific item drop. (\124cFF8080FFRequires CanIMogIt\124r)."

L["OPTIONS_CHECK_HIDE_WARBOUND_ITEMS"] = "Hide warbound items (\124cFF8080FFCanIMogIt\124r)"
L["OPTIONS_CHECK_HIDE_WARBOUND_ITEMS_TOOLTIP"] = "Hides warbound items from the loot list. (\124cFF8080FFRequires CanIMogIt\124r)."

L["OPTIONS_CHECK_SHOW_ILVL_DIFFRENT"] = "Show item level difference"
L["OPTIONS_CHECK_SHOW_ILVL_DIFFRENT_TOOLTIP"] = "Displays the difference in item levels between currently equipped and looted items. Ideal for quick comparison."

L["OPTIONS_CHECK_CHECK_MOUNTS"] = "Check mounts"
L["OPTIONS_CHECK_CHECK_MOUNTS_TOOLTIP"] = "Verifies if a looted item is a mount you don't yet own. Helps expand your mount collection."

L["OPTIONS_CHECK_CHECK_TOYS"] = "Check toys"
L["OPTIONS_CHECK_CHECK_TOYS_TOOLTIP"] = "Detects if a looted item is a toy you haven't collected, making it easier to collect new toys."

L["OPTIONS_CHECK_CHECK_PETS"] = "Check pets"
L["OPTIONS_CHECK_CHECK_PETS_TOOLTIP"] = "Identifies if a looted item is a pet missing from your collection. Great for pet collectors."

L["OPTIONS_CHECK_HIDE_MINIMAP"] = "Hide minimap button"
L["OPTIONS_CHECK_HIDE_MINIMAP_TOOLTIP"] = "Removes the minimap button from view, helping to reduce clutter on your minimap."

L["OPTIONS_CHECK_CHAT_SHOW_LOOT_FRAME"] = "Show loot frame on item drop"
L["OPTIONS_CHECK_CHAT_SHOW_LOOT_FRAME_TOOLTIP"] = "Displays the loot frame when a classifiable item drops from any mob / boss. Helps with quicker item assessments."

L["OPTIONS_SLIDER_DELTA"] = "Minimum Item Level Offset"
L["OPTIONS_SLIDER_DELTA_TOOLTIP"] = "Sets an item level threshold by adjusting the offset from equipped items. Useful for filtering out minor upgrades."
