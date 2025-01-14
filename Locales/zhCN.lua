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
L["SETTINGS_MENU_CUSTOM_MESSAGES"] = "自定义消息"
L["MINIMAP_ICON_TOOLTIP1"] = "点击以切换窗口"
L["MINIMAP_ICON_TOOLTIP2"] = "右键打开插件设置选项"
L["OPTIONS_DONT_CHECK_ISITEMUPGRADE"] = "显示所有适合你的装备（如果勾选，可以看到低于你当前装等的装备）"
L["OPTIONS_SHOW_EVERYWHERE"] = "在所有地方显示（不仅限于副本）"
L["OPTIONS_CHECK_TRANSMOG"] = "检查装备是否可以幻化（\124cFF8080FF需要CanIMogIt插件\124r）"
L["OPTIONS_CHECK_TRANSMOG_OTHER_SOURCES"] = "显示其他来源的已学外观（\124cFF8080FF需要CanIMogIt插件\124r）"
L["CanIMogIt"] = "幻化插件"
L["SELECT_OPTION_DISABLED"] = "禁用"
L["SELECT_OPTION_ONLY_DUNGEON_RAID"] = "仅限地下城或团队副本"
L["SELECT_OPTION_EVERYWHERE"] = "所有地方"
L["OPTIONS_CHECK_MOUNTS"] = "检查坐骑"
L["OPTIONS_CHECK_TOYS"] = "检查玩具"
L["OPTIONS_CHECK_PETS"] = "检查宠物"
L["CUSTOM_TEXT"] = "你好，你需要[item]吗？我想要它用来幻化。"
L["OPTIONS_CHECK_CUSTOM_TEXTS"] = "\
显示选择额外自定义消息的按钮。\
在下方定义消息（包含[item]快捷方式以链接装备）。\
"

L["OPTIONS_CHECK_DEBUG"] = "启用调试模式"
L["OPTIONS_CHECK_DEBUG_TOOLTIP"] = "启用调试消息，用于排查问题或开发调试。仅在出现问题或被建议时使用。"

L["OPTIONS_CHECK_OPEN_AFTER_ENCOUNTER"] = "战斗后自动打开拾取窗口"
L["OPTIONS_CHECK_OPEN_AFTER_ENCOUNTER_TOOLTIP"] = "战斗结束后，若掉落的装备符合设置偏好，则自动显示拾取窗口。"

L["OPTIONS_CHECK_TRANSMOGABLE"] = "检查缺失的幻化外观（\124cFF8080FF需要CanIMogIt插件\124r）"
L["OPTIONS_CHECK_TRANSMOGABLE_TOOLTIP"] = "显示尚未收集的幻化外观。对追求幻化的玩家非常有用。（\124cFF8080FF需要CanIMogIt插件\124r）"

L["OPTIONS_CHECK_TRANSMOGABLE_OTHER_SOURCE"] = "显示其他来源的外观（\124cFF8080FF需要CanIMogIt插件\124r）"
L["OPTIONS_CHECK_TRANSMOGABLE_OTHER_SOURCE_TOOLTIP"] = "显示你的收藏中已学但来自其他来源的外观，而非当前掉落装备的外观。（\124cFF8080FF需要CanIMogIt插件\124r）"

L["OPTIONS_CHECK_HIDE_WARBOUND_ITEMS"] = "隐藏战斗绑定物品（\124cFF8080FF需要CanIMogIt插件\124r）"
L["OPTIONS_CHECK_HIDE_WARBOUND_ITEMS_TOOLTIP"] = "从拾取列表中隐藏战斗绑定物品。（\124cFF8080FF需要CanIMogIt插件\124r）"

L["OPTIONS_CHECK_SHOW_ILVL_DIFFRENT"] = "显示装等差异"
L["OPTIONS_CHECK_SHOW_ILVL_DIFFRENT_TOOLTIP"] = "显示当前装备和拾取装备之间的装等差异，便于快速比较。"

L["OPTIONS_CHECK_CHECK_MOUNTS"] = "检查坐骑"
L["OPTIONS_CHECK_CHECK_MOUNTS_TOOLTIP"] = "检测拾取的物品是否是你尚未拥有的坐骑，方便扩展你的坐骑收藏。"

L["OPTIONS_CHECK_CHECK_TOYS"] = "检查玩具"
L["OPTIONS_CHECK_CHECK_TOYS_TOOLTIP"] = "检查拾取的物品是否是尚未收集的玩具，方便收集新玩具。"

L["OPTIONS_CHECK_CHECK_PETS"] = "检查宠物"
L["OPTIONS_CHECK_CHECK_PETS_TOOLTIP"] = "检查拾取的物品是否是你未收集的宠物，非常适合宠物收藏者。"

L["OPTIONS_CHECK_HIDE_MINIMAP"] = "隐藏小地图按钮"
L["OPTIONS_CHECK_HIDE_MINIMAP_TOOLTIP"] = "移除小地图按钮，减少小地图上的混乱。"

L["OPTIONS_CHECK_CHAT_SHOW_LOOT_FRAME"] = "物品掉落时显示拾取框"
L["OPTIONS_CHECK_CHAT_SHOW_LOOT_FRAME_TOOLTIP"] = "当任何怪物/首领掉落分类装备时，显示拾取框。便于更快的装备评估。"

L["OPTIONS_SLIDER_DELTA"] = "最低装等差距"
L["OPTIONS_SLIDER_DELTA_TOOLTIP"] = "设置装等偏差，过滤掉较小的升级项。"
