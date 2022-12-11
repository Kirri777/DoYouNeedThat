if not(GetLocale() == "zhCN") then return end
local addonName, AddOn = ...
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
L["Open loot window after encounter"] = "在战斗结束后打开窗口"
L["Right-click to lock Minimap Button"] = "右击锁定小地图图标"
L["Toggle Window"] = "打开窗口"
L["Whisper"] = "私聊"
L["Whisper Message"] = "私聊发送的信息（用[item]来表示你需要的装备）"

L["MINIMAP_ICON_TOOLTIP1"] = "Click to toggle Window"
L["MINIMAP_ICON_TOOLTIP2"] = "Right-click to open DoYouNeedThat options panel"
L["OPTIONS_dont_check_isitemupgrade"] = "Show all items for you (if checked then you can see items below your item Level)"
L["WHISPER_MESSAGE_1"] = "Do you need that [item]?"
L["WHISPER_MESSAGE_2"] = "May I have [item], if you don't need it?"
L["WHISPER_MESSAGE_3"] = "I could use [item] if you don't want it."
L["WHISPER_MESSAGE_4"] = "I would take [item] if you want to get rid of it."
L["WHISPER_MESSAGE_5"] = "Do you need [item], or may I have it?"
L["WHISPER_MESSAGE_LABEL"] = "Whisper messages - they will be sended random (Use [item] shortcut if you want to link the item.)"
