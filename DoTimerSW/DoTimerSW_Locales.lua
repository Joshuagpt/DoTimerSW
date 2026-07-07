-- DoTimerSW_Locales.lua

local CLIENT_LOCALE = (GetLocale and GetLocale()) or "enUS"

local LOCALES = {}

LOCALES["zhCN"] = {
	ANCHOR_TOOLTIP_TITLE  = "DoTimerSW 布局锚点",
	ANCHOR_TOOLTIP_DRAG   = "左键按住：拖动位置",
	ANCHOR_TOOLTIP_MENU   = "右键点击：弹出菜单",
	ANCHOR_TOOLTIP_UNLOCK = "隐藏后输入 /dot 可重新解锁显示",

	BTN_LOCK_HIDE         = "锁定并隐藏",
	MSG_LOCKED            = "已锁定。输入 /dot unlock 重新显示锚点。",
	MSG_LOCKED_HIDDEN     = "布局已锁定，锚点已隐藏。",
	MSG_UNLOCKED          = "布局锚点已显示。",

	BTN_SCALE             = "  界面缩放 ▶",
	MSG_SCALE_SET         = "缩放比例设置为 ",
	
	BTN_LAYOUT            = "  界面布局 ▶",
	LAYOUT_HORIZ          = "横向排布",
	LAYOUT_VERT           = "垂直排布",

	BTN_HIDE_TIMER        = "    |cffff8040隐藏计时器|r",
	BTN_SHOW_TIMER        = "    |cff40ff40显示计时器|r",
	BTN_HIDE_TIMER_CHECKED = "  |cffffd700\226\156\147|r |cffff8040隐藏计时器|r",
	BTN_SHOW_TIMER_CHECKED = "  |cffffd700\226\156\147|r |cff40ff40显示计时器|r",

	TARGET_TOOLTIP_SELECT = "左键点击名字选定目标",
	TARGET_TOOLTIP_CAST   = "左键点击图标反向施法",
}

LOCALES["enUS"] = {
	ANCHOR_TOOLTIP_TITLE  = "DoTimerSW Layout Anchor",
	ANCHOR_TOOLTIP_DRAG   = "Left-click and hold: move position",
	ANCHOR_TOOLTIP_MENU   = "Right-click: open menu",
	ANCHOR_TOOLTIP_UNLOCK = "After hiding, type /dot to unlock it again",

	BTN_LOCK_HIDE         = "Lock & Hide",
	MSG_LOCKED            = "Locked. Type /dot unlock to show the anchor again.",
	MSG_LOCKED_HIDDEN     = "Layout locked, anchor hidden.",
	MSG_UNLOCKED          = "Anchor shown.",

	BTN_SCALE             = "  UI Scale▶",
	MSG_SCALE_SET         = "Scale set to ",
	
	BTN_LAYOUT            = "  UI Layout▶",
	LAYOUT_HORIZ          = "Horizontal",
	LAYOUT_VERT           = "Vertical",

	BTN_HIDE_TIMER        = "    |cffff8040Hide Timer|r",
	BTN_SHOW_TIMER        = "    |cff40ff40Show Timer|r",
	BTN_HIDE_TIMER_CHECKED = "  |cffffd700\226\156\147|r |cffff8040Hide Timer|r",
	BTN_SHOW_TIMER_CHECKED = "  |cffffd700\226\156\147|r |cff40ff40Show Timer|r",

	TARGET_TOOLTIP_SELECT = "Left-click name to select target",
	TARGET_TOOLTIP_CAST   = "Left-click icon to cast on target",
}

-- 默认英文：私服环境下，如果客户端语言不是已知值（比如 enGB、deDE 等没有单独提供翻译的语言)

local defaultLocale = LOCALES["enUS"]
local activeLocale = LOCALES[CLIENT_LOCALE] or defaultLocale

-- 如果当前语言不是英文，设置元表：当找不到某个翻译时，自动去英文库里找
if activeLocale ~= defaultLocale then
	setmetatable(activeLocale, { __index = defaultLocale })
end

DoTimerSW_L = activeLocale