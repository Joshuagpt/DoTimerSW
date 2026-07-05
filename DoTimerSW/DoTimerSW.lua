DoTimerSWDB = DoTimerSWDB or {}

local SW = {}
DoTimerSW = SW

SW.OnDataUpdate = nil

local COLOR_NORMAL   = { 1.0, 0.86, 0.22 }
local COLOR_LOW      = { 1.0, 0.25, 0.18 }
local COLOR_TARGET   = { 0.75, 0.9, 1.0 }
local COLOR_FRIENDLY = { 0.25, 1.0, 0.25 }
local COLOR_HOSTILE  = { 1.0, 0.25, 0.2 }

local DEFAULT_ICON  = "Interface\\Icons\\INV_Misc_QuestionMark"
local ICON_SIZE     = 36
local TARGET_WIDTH  = 125
local TARGET_HEIGHT = 336

SW.patterns = {}

local function Chat(msg)
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage("|cff7fd5ffDoTimerSW:|r " .. tostring(msg))
	end
end

local function Now() return GetTime() end

local function Clamp(v, minv, maxv)
	if v < minv then return minv end
	if v > maxv then return maxv end
	return v
end

local function CopyDefaults(dst, src)
	for k, v in pairs(src) do
		if dst[k] == nil then dst[k] = v end
	end
end

local function UnitGUID(unit)
	if not unit then return nil end
	local exists, guid = UnitExists(unit)
	if exists then return guid end
	return nil
end

local function ResolveName(unitOrGUID)
	if not unitOrGUID then return "Unknown" end
	local name
	if UnitExists(unitOrGUID) then
		name = UnitName(unitOrGUID)
	end
	return name or SW.guidNames[unitOrGUID] or "Unknown"
end

local function TruncateUTF8(str, maxVisualWidth)
	if not str then return "Unknown" end
	maxVisualWidth = maxVisualWidth or 12
	local len = string.len(str)
	local visualWidth = 0
	local pos = 1

	while pos <= len do
		local c = string.byte(str, pos)
		if not c then break end

		local charWidth = 1
		local nextPos = pos + 1

		if c >= 128 then
			charWidth = 2
			if c < 224 then
				nextPos = pos + 2
			elseif c < 240 then
				nextPos = pos + 3
			else
				nextPos = pos + 4
			end
		end

		if visualWidth + charWidth > maxVisualWidth then
			return string.sub(str, 1, pos - 1) .. "."
		end

		visualWidth = visualWidth + charWidth
		pos = nextPos
	end

	return str
end

local function ResolveLevel(unitOrGUID)
	if not unitOrGUID then return "??" end
	local lvl
	if UnitExists(unitOrGUID) then
		lvl = UnitLevel(unitOrGUID)
	end
	lvl = lvl or SW.guidLevels[unitOrGUID]
	if not lvl or lvl <= 0 then
		return "??"
	end
	return tostring(lvl)
end

local function IsFriendly(unitOrGUID)
	if not unitOrGUID then return nil end
	if UnitExists(unitOrGUID) and UnitIsFriend("player", unitOrGUID) then return 1 end
	if SW.guidRelation and SW.guidRelation[unitOrGUID] == "friendly" then return 1 end
	return nil
end

local function IsHostile(unitOrGUID)
	if not unitOrGUID then return nil end
	if UnitExists(unitOrGUID) and UnitCanAttack("player", unitOrGUID) then return 1 end
	if SW.guidRelation and SW.guidRelation[unitOrGUID] == "hostile" then return 1 end
	return nil
end

local CONFLAGRATE_INFO = {
	[17962] = { consumeSpellId = 348, durationReduction = 3 },
	[18930] = { consumeSpellId = 348, durationReduction = 3 },
	[18931] = { consumeSpellId = 348, durationReduction = 3 },
	[18932] = { consumeSpellId = 348, durationReduction = 3 },
	[18933] = { consumeSpellId = 348, durationReduction = 3 },
}

local SHIELD_SIDE_EFFECTS = {
	[17]    = 6788,
	[592]   = 6788,
	[600]   = 6788,
	[3747]  = 6788,
	[6065]  = 6788,
	[6066]  = 6788,
	[10898] = 6788,
	[10899] = 6788,
	[10900] = 6788,
	[10901] = 6788,
}

local _shieldFamilyName = nil
local function GetShieldFamilyName()
	if _shieldFamilyName == nil then
		local n = SpellInfo(17)
		_shieldFamilyName = n and string.lower(n) or false
	end
	return _shieldFamilyName or nil
end

local SPELL_OVERRIDE = {
	[6788] = { duration = 15 }
}

local function SpellDetails(spellId)
	local override = SPELL_OVERRIDE[spellId]
	local name, rank, texture = nil, "", DEFAULT_ICON
	if spellId and SpellInfo then
		name, rank, texture = SpellInfo(spellId)
	end
	if override then
		name = override.name or name
		rank = override.rank or rank or ""
		if not texture then texture = DEFAULT_ICON end
	else
		if not texture then texture = DEFAULT_ICON end
		if not name then name = "Spell " .. tostring(spellId or "?") end
	end
	return name, rank or "", texture
end

local function BuildPattern(gstring)
	if not gstring then return nil end
	local p = string.gsub(gstring, "([%.%+%-%*%?%^%$%(%)%[%]])", "%%%1")
	p = string.gsub(p, "%%[1-9]%$s", "(.-)")
	p = string.gsub(p, "%%[1-9]%$d", "(%%d+)")
	p = string.gsub(p, "%%s", "(.-)")
	p = string.gsub(p, "%%d", "(%%d+)")
	return p
end

local function MatchesAnyPattern(text, patternList)
	if not text or not patternList then return false end
	for _, pattern in ipairs(patternList) do
		if pattern and string.find(text, pattern) then
			return true
		end
	end
	return false
end

function SW:InitGlobalStringPatterns()
	self.patterns.resist = {
		BuildPattern(SPELLRESISTSELFOTHER),
		BuildPattern(SPELLRESISTOTHERSELF),
		BuildPattern(SPELLRESISTOTHEROTHER)
	}
	self.patterns.immune = {
		BuildPattern(SPELLIMMUNESELFOTHER),
		BuildPattern(SPELLIMMUNEOTHERSELF),
		BuildPattern(SPELLIMMUNEOTHEROTHER)
	}
	self.patterns.evade = {
		BuildPattern(COMBATLOG_EVADE_OTHER),
		BuildPattern(SPELLEVADEDOTHEROTHER)
	}
	self.patterns.reflect = {
		BuildPattern(SPELLREFLECTSELFOTHER),
		BuildPattern(SPELLREFLECTOTHERSELF),
		BuildPattern(SPELLREFLECTOTHEROTHER)
	}
	self.patterns.fade = {
		BuildPattern(AURAREMOVEDOTHER)
	}
	self.patterns.death = {
		BuildPattern(UNITDIESOTHER),
		BuildPattern(ERR_COMBAT_PLAYER_SLAIN)
	}
end

local scanTip = CreateFrame("GameTooltip", "DoTimerSWScanTip", UIParent, "GameTooltipTemplate")
scanTip:SetOwner(UIParent, "ANCHOR_NONE")
scanTip:Hide()

local linesCache = {}
for i = 1, 15 do
	linesCache[i] = getglobal("DoTimerSWScanTipTextLeft" .. i)
end

local function ScanLine(i)
	local fs = linesCache[i]
	return (fs and fs:IsShown() and fs:GetText()) or ""
end

local function ExtractNumbers(text)
	if not text or text == "" then return {} end
	local nums = {}
	local pos = 1
	while pos <= string.len(text) do
		local s, e, num = string.find(text, "(%d+%.?%d*)", pos)
		if not s then break end
		local val = tonumber(num)
		if val then table.insert(nums, val) end
		pos = e + 1
	end
	return nums
end

local function ClosestTo(nums, base)
	if not nums or table.getn(nums) == 0 then return nil end
	local best, bestDelta
	for _, v in ipairs(nums) do
		local delta = math.abs(v - base)
		if not bestDelta or delta < bestDelta then
			best, bestDelta = v, delta
		end
	end
	return best
end

local _durationCache       = {}
local dynamicDurationCache = {}

SW.nameConfigCache = {}
SW.idConfigCache   = {}

function SW:InitializeConfigCache()
	if not DoTimerSW_BaseDurations then return end
	self.idConfigCache = {}

	for spellId, config in pairs(DoTimerSW_BaseDurations) do
		local normalized
		if type(config) == "table" then
			normalized = {
				duration   = config.duration or 0,
				hideMain   = config.hideMain,
				multiplier = config.multiplier or 1,
				isAoE      = config.isAoE
			}
		else
			normalized = {
				duration   = config,
				hideMain   = nil,
				multiplier = 1,
				isAoE      = nil
			}
		end

		self.idConfigCache[spellId] = normalized

		local name, rank = SpellInfo(spellId)
		if name then
			local lowerName = string.lower(name)
			DoTimerSWDB.spellNameMap[lowerName] = spellId

			if rank and rank ~= "" then
				if SW.nameConfigCache[lowerName] and SW.nameConfigCache[lowerName]._spellId ~= spellId then
					Chat("WARNING: nameConfigCache collision on '" .. lowerName ..
						"' existing spellId=" .. tostring(SW.nameConfigCache[lowerName]._spellId) ..
						" new spellId=" .. spellId .. " (idConfigCache 不受影响，仍按各自 spellId 独立生效)")
				end

				normalized._spellId = spellId
				SW.nameConfigCache[lowerName] = normalized
			end
		end
	end
end

local function SW_CreateSafePattern(globalStr)
	if not globalStr then return "^$" end
	local placeholder = "___TOKEN___"
	local cleaned = string.gsub(globalStr, "%%[ds]", placeholder)
	cleaned = string.gsub(cleaned, "([%(%)%.%%%+%-%%*%?%[%^%$])", "%%%1")
	return "^" .. string.gsub(cleaned, placeholder, "%%d+")
end

local patternRage   = SW_CreateSafePattern(RAGE_COST)
local patternMana   = SW_CreateSafePattern(MANA_COST)
local patternEnergy = SW_CreateSafePattern(ENERGY_COST)

function SW:ReturnDuration(spellname, rank, playerClass, baseNumber, multiplier)
	if not spellname then return nil end

	local lowerName = string.lower(spellname)
	local cacheKey = spellname .. (rank or "")

	if _durationCache[cacheKey] ~= nil then
		return _durationCache[cacheKey] ~= false and _durationCache[cacheKey] or nil
	end

	if not baseNumber then
		local config = self.nameConfigCache and self.nameConfigCache[lowerName]
		if not config then return nil end
		baseNumber = config.duration
		multiplier = config.multiplier or 1
	end
	multiplier = multiplier or 1

	local books = { BOOKTYPE_SPELL, BOOKTYPE_PET }
	for _, booktype in ipairs(books) do
		local i = 1
		while true do
			local sName, sRank = GetSpellName(i, booktype)
			if not sName then break end 

			local rankMatch = false
			if (booktype == BOOKTYPE_PET) or (rank == nil) or (rank == "") or (sRank == rank) then
				rankMatch = true
			else
				local _, _, sRankNum = string.find(sRank or "", "(%d+)")
				local _, _, rankNum = string.find(rank or "", "(%d+)")
				if sRankNum and rankNum and sRankNum == rankNum then
					rankMatch = true
				end
			end

			if string.lower(sName) == lowerName and rankMatch then
				scanTip:SetOwner(UIParent, "ANCHOR_NONE")
				scanTip:ClearLines()
				scanTip:SetSpell(i, booktype)

				local nums = {}
				
				for lineIdx = 3, 15 do 
					local lineText = ScanLine(lineIdx)
					if lineText and lineText ~= "" then
												
						if string.find(lineText, patternRage) or 
						   string.find(lineText, patternMana) or 
						   string.find(lineText, patternEnergy) then
						else
							local lineNums = ExtractNumbers(lineText)
							for _, n in ipairs(lineNums) do							
								if n >= (baseNumber - 0.1) then 
									table.insert(nums, n)
								end
							end
						end						
					end
				end

				local chosen   = ClosestTo(nums, baseNumber)
				local duration = chosen and (chosen * multiplier) or (baseNumber * multiplier)
				
				_durationCache[cacheKey] = duration
				return duration
			end
			i = i + 1
		end
	end

	local fallback = baseNumber * multiplier
	_durationCache[cacheKey] = fallback
	return fallback
end

function SW:ClearDurationCache()
	_durationCache       = {}
	dynamicDurationCache = {}
end

function SW:InitDB()
	DoTimerSWDB.settings     = DoTimerSWDB.settings     or {}
	DoTimerSWDB.spellNameMap  = DoTimerSWDB.spellNameMap  or {}
	DoTimerSWDB.anchor        = DoTimerSWDB.anchor        or {}
	CopyDefaults(DoTimerSWDB.settings, {
		maxTargets           = 8,
		maxTimersPerTarget   = 8,
		scale                = 1,
		locked               = false,
		visible              = true,
		debug                = false,
		auraConfirmGrace     = 1.2,
	})
	DoTimerSWDB.settings.maxTargets = Clamp(tonumber(DoTimerSWDB.settings.maxTargets) or 8, 1, 8)
	DoTimerSWDB.settings.maxTimersPerTarget = Clamp(tonumber(DoTimerSWDB.settings.maxTimersPerTarget) or 8, 1, 20)
end

function SW:CreateUI()
	local anchor = CreateFrame("Button", "DoTimerSWAnchor", UIParent)
	anchor:SetWidth(18)
	anchor:SetHeight(18)
	anchor:SetMovable(true)
	anchor:EnableMouse(true)
	anchor:RegisterForDrag("LeftButton")
	anchor:SetScript("OnDragStart", function()
		if not DoTimerSWDB.settings.locked then this:StartMoving() end
	end)
	anchor:SetScript("OnDragStop", function()
		this:StopMovingOrSizing()
		local point, _, relpoint, x, y = this:GetPoint()
		DoTimerSWDB.anchor.point    = point
		DoTimerSWDB.anchor.relpoint = relpoint
		DoTimerSWDB.anchor.x        = x
		DoTimerSWDB.anchor.y        = y
	end)
	anchor:SetScript("OnEnter", function()
		GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
		local L = DoTimerSW_L or {}
		GameTooltip:SetText(L.ANCHOR_TOOLTIP_TITLE or "DoTimerSW")
		GameTooltip:AddLine(L.ANCHOR_TOOLTIP_DRAG or "", 1, 1, 1)
		GameTooltip:AddLine(L.ANCHOR_TOOLTIP_MENU or "", 1, 0.8, 0)
		GameTooltip:AddLine(L.ANCHOR_TOOLTIP_UNLOCK or "", 0.5, 1, 0.5)
		GameTooltip:Show()
	end)
	anchor:SetScript("OnLeave", function() GameTooltip:Hide() end)

	local tex = anchor:CreateTexture(nil, "BACKGROUND")
	tex:SetAllPoints(anchor)
	tex:SetTexture(0.1, 0.45, 0.75, 0.9)
	anchor.texture = tex

	local popup = CreateFrame("Frame", "DoTimerSWPopup", UIParent)
	popup:SetWidth(140)
	popup:SetHeight(72)
	popup:SetFrameStrata("TOOLTIP")
	popup:SetBackdrop({
		bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = { left=4, right=4, top=4, bottom=4 }
	})
	popup:Hide()
	popup:EnableMouse(true)

	local scalePanel = CreateFrame("Frame", "DoTimerSWScalePanel", UIParent)
	scalePanel:SetWidth(110)
	scalePanel:SetFrameStrata("TOOLTIP")
	scalePanel:SetBackdrop({
		bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = { left=4, right=4, top=4, bottom=4 }
	})
	scalePanel:Hide()
	scalePanel:EnableMouse(true)
	popup.scalePanel = scalePanel

	local function ClosePopup()
		popup:Hide()
		scalePanel:Hide()
	end

	local closeOverlay = CreateFrame("Button", nil, UIParent)
	closeOverlay:SetAllPoints(UIParent)
	closeOverlay:SetFrameStrata("DIALOG")
	closeOverlay:Hide()
	closeOverlay:SetScript("OnClick", function()
		ClosePopup()
	end)

	local function OpenPopup()
		local scale = UIParent:GetEffectiveScale()
		local mx, my = GetCursorPosition()
		mx = mx / scale
		my = my / scale
		popup:ClearAllPoints()
		popup:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", mx, my)
		popup:Show()
		closeOverlay:Show()
	end

	local function MakeBtn(parent, yOffset, label, onClick)
		local btn = CreateFrame("Button", nil, parent)
		btn:SetWidth(120)
		btn:SetHeight(22)
		btn:SetPoint("TOP", parent, "TOP", 0, yOffset)
		btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
		local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		fs:SetAllPoints(btn)
		fs:SetJustifyH("LEFT")
		fs:SetText("  " .. label)
		btn.fs = fs
		btn:SetScript("OnClick", function()
			ClosePopup()
			onClick()
		end)
		return btn
	end

	MakeBtn(popup, -10, (DoTimerSW_L and DoTimerSW_L.BTN_LOCK_HIDE) or "Lock & Hide", function()
		DoTimerSWDB.settings.locked = true
		if SW.anchor then SW.anchor:Hide() end
		Chat((DoTimerSW_L and DoTimerSW_L.MSG_LOCKED) or "Locked.")
	end)

	local scaleBtn = CreateFrame("Button", nil, popup)
	scaleBtn:SetWidth(120)
	scaleBtn:SetHeight(22)
	scaleBtn:SetPoint("TOP", popup, "TOP", 0, -34)
	scaleBtn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
	local scaleBtnFs = scaleBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	scaleBtnFs:SetAllPoints(scaleBtn)
	scaleBtnFs:SetJustifyH("LEFT")
	scaleBtnFs:SetText((DoTimerSW_L and DoTimerSW_L.BTN_SCALE) or "  UI Scale")
	scaleBtn:SetScript("OnClick", function()
		if scalePanel:IsShown() then
			scalePanel:Hide()
		else
			scalePanel:ClearAllPoints()
			scalePanel:SetPoint("TOPLEFT", popup, "TOPRIGHT", -4, 0)
			scalePanel:Show()
		end
	end)

	local scaleValues = { 0.5, 0.8, 1.0, 1.2, 1.5 }
	local scaleRows = {}
	for i, v in ipairs(scaleValues) do
		local val  = v
		local yOff = -8 - (i - 1) * 22
		local row  = CreateFrame("Button", nil, scalePanel)
		row:SetWidth(94)
		row:SetHeight(20)
		row:SetPoint("TOP", scalePanel, "TOP", 0, yOff)
		row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
		local fs = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		fs:SetAllPoints(row)
		fs:SetJustifyH("LEFT")
		row.fs  = fs
		row.val = val
		row:SetScript("OnClick", function()
			DoTimerSWDB.settings.scale = val
			if SW.ui then SW.ui:SetScale(val) end
			ClosePopup()
		end)
		scaleRows[i] = row
	end

	local hideRow = CreateFrame("Button", nil, scalePanel)
	hideRow:SetWidth(94)
	hideRow:SetHeight(20)
	hideRow:SetPoint("TOP", scalePanel, "TOP", 0, -8 - table.getn(scaleValues) * 22)
	hideRow:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
	local hideFs = hideRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	hideFs:SetAllPoints(hideRow)
	hideFs:SetJustifyH("LEFT")
	hideFs:SetText((DoTimerSW_L and DoTimerSW_L.BTN_HIDE_TIMER) or "    Hide Timer")
	hideRow:SetScript("OnClick", function()
		DoTimerSWDB.settings.visible = false
		if SW.ui then SW.ui:Hide() end
		ClosePopup()
	end)

	local showRow = CreateFrame("Button", nil, scalePanel)
	showRow:SetWidth(94)
	showRow:SetHeight(20)
	showRow:SetPoint("TOP", scalePanel, "TOP", 0, -8 - (table.getn(scaleValues) + 1) * 22)
	showRow:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
	local showFs = showRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	showFs:SetAllPoints(showRow)
	showFs:SetJustifyH("LEFT")
	showFs:SetText((DoTimerSW_L and DoTimerSW_L.BTN_SHOW_TIMER) or "    Show Timer")
	showRow:SetScript("OnClick", function()
		DoTimerSWDB.settings.visible = true
		if SW.ui then
			SW.ui:SetScale(DoTimerSWDB.settings.scale or 1)
			SW.ui:Show()
		end
		ClosePopup()
	end)

	scalePanel:SetHeight((table.getn(scaleValues) + 2) * 22 + 16)

	scalePanel:SetScript("OnShow", function()
		local cur = DoTimerSWDB.settings and DoTimerSWDB.settings.scale or 1
		for _, row in ipairs(scaleRows) do
			if math.abs(row.val - cur) < 0.01 then
				row.fs:SetText("  |cffffd700\226\156\147|r " .. row.val)
			else
				row.fs:SetText("    " .. row.val)
			end
		end
		local vis = DoTimerSWDB.settings and DoTimerSWDB.settings.visible
		local L = DoTimerSW_L or {}
		if vis then
			hideFs:SetText(L.BTN_HIDE_TIMER or "    Hide Timer")
			showFs:SetText(L.BTN_SHOW_TIMER_CHECKED or "  \226\156\147 Show Timer")
		else
			hideFs:SetText(L.BTN_HIDE_TIMER_CHECKED or "  \226\156\147 Hide Timer")
			showFs:SetText(L.BTN_SHOW_TIMER or "    Show Timer")
		end
	end)

	popup:SetScript("OnHide", function()
		scalePanel:Hide()
		closeOverlay:Hide()
	end)
	table.insert(UISpecialFrames, "DoTimerSWPopup")

	anchor:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	anchor:SetScript("OnClick", function()
		if arg1 == "RightButton" then
			if popup:IsShown() then
				ClosePopup()
			else
				OpenPopup()
			end
		end
	end)

	local p  = DoTimerSWDB.anchor.point    or "CENTER"
	local rp = DoTimerSWDB.anchor.relpoint or "CENTER"
	local x  = DoTimerSWDB.anchor.x        or 0
	local y  = DoTimerSWDB.anchor.y        or 0
	anchor:SetPoint(p, UIParent, rp, x, y)
	if DoTimerSWDB.settings.locked then anchor:Hide() else anchor:Show() end
	self.anchor = anchor

	local frame = CreateFrame("Frame", "DoTimerSWMainFrame", UIParent)
	frame:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -4)
	frame:SetScale(DoTimerSWDB.settings.scale)
	frame:SetWidth(TARGET_WIDTH * 8)
	frame:SetHeight(TARGET_HEIGHT)
	self.ui   = frame
	self.rows = {}
	for i = 1, 8 do
		self.rows[i] = self:CreateTargetRow(frame, i)
	end
	if DoTimerSWDB.settings.visible then frame:Show() else frame:Hide() end
end

function SW:CreateTargetRow(parent, index)
	local row = CreateFrame("Frame", nil, parent)
	row:SetWidth(TARGET_WIDTH)
	row:SetHeight(TARGET_HEIGHT)
	if index == 1 then
		row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
	else
		row:SetPoint("TOPRIGHT", self.rows[index - 1].frame, "TOPLEFT", -6, 0)
	end

	local nameBtn = CreateFrame("Button", nil, row)
	nameBtn:SetWidth(TARGET_WIDTH)
	nameBtn:SetHeight(16)
	nameBtn:SetPoint("TOP", row, "TOP", 0, -3)
	nameBtn:RegisterForClicks("LeftButtonUp")
	nameBtn:SetScript("OnClick", function()
		if this.guid then
			TargetUnit(this.guid)
		end
	end)
	row.nameBtn = nameBtn

	local name = nameBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	name:SetJustifyH("CENTER")
	row.name = name

	local raidIcon = nameBtn:CreateTexture(nil, "ARTWORK")
	raidIcon:SetWidth(14)
	raidIcon:SetHeight(14)
	raidIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
	raidIcon:SetPoint("BOTTOMLEFT", name, "TOPLEFT", 1, 1)
	raidIcon:Hide()
	row.raidIcon = raidIcon

	local timers = {}
	for i = 1, 8 do
		local b = CreateFrame("Button", nil, row)
		b:SetWidth(ICON_SIZE)
		b:SetHeight(ICON_SIZE)
		if i == 1 then
			b:SetPoint("TOP", row, "TOP", 0, -22)
		else
			b:SetPoint("TOP", timers[i - 1], "BOTTOM", 0, -5)
		end
		local icon = b:CreateTexture(nil, "BACKGROUND")
		icon:SetAllPoints(b)
		icon:SetTexture(DEFAULT_ICON)
		b.icon = icon
		local text = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		text:SetPoint("CENTER", b, "CENTER", 0, 0)
		text:SetTextColor(1, 1, 1)
		b.text = text

		b:SetScript("OnEnter", function()
			local timer = this.timer
			if timer then
				GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
				GameTooltip:SetText(timer.name or "Unknown")
				local L = DoTimerSW_L or {}
				GameTooltip:AddLine(L.TARGET_TOOLTIP_SELECT or "", 0.4, 0.8, 1.0)
				GameTooltip:AddLine(L.TARGET_TOOLTIP_CAST or "", 0.4, 1.0, 0.4)
				GameTooltip:Show()
			end
		end)
		b:SetScript("OnLeave", function() GameTooltip:Hide() end)
		b:SetScript("OnClick", function()
			local timer = this.timer
			if timer then SW:CastTimer(timer) end
		end)
		b:Hide()
		timers[i] = b
	end

	row:Hide()
	return { frame = row, nameBtn = nameBtn, name = name, raidIcon = raidIcon, timers = timers }
end

function SW:UpdateOwnerGUIDs()
	self.ownerGUIDs = self.ownerGUIDs or {}
	for k in pairs(self.ownerGUIDs) do self.ownerGUIDs[k] = nil end

	local playerGUID = UnitGUID("player")
	if playerGUID then
		self.playerGUID = playerGUID
		self.ownerGUIDs[playerGUID] = "player"
	end

	local petGUID = UnitGUID("pet")
	if petGUID then
		self.petGUID = petGUID
		self.ownerGUIDs[petGUID] = "pet"
	end
end

function SW:IsOwnerGUID(guid)
    if not guid then return nil end
    if not self.ownerGUIDs then return nil end  
    return self.ownerGUIDs[guid]
end

function SW:BuildAoESpellList()
	self.aoeSpellList = {}
	if not self.idConfigCache then return end
	for spellId, cfg in pairs(self.idConfigCache) do
		if cfg.isAoE then
			local name = SpellInfo(spellId)
			table.insert(self.aoeSpellList, { name = name, spellId = spellId })
		end
	end
end

function SW:Startup()
	self:InitDB()
	self:InitGlobalStringPatterns()
	self:InitializeConfigCache()
	self:BuildAoESpellList()

	if not self.initialized then
		self.targets        = {}
		self.targetOrder    = {}
		self.guidNames      = {}
		self.guidLevels     = {}
		self.guidRelation   = {}
		self.pendingScans   = {}
		self.initialized    = true
	else		
		local preserve = {}
		local playerGUID = UnitGUID("player") or self.playerGUID
		local petGUID = UnitGUID("pet") or self.petGUID
		
		if playerGUID then preserve[playerGUID] = true end
		if petGUID then preserve[petGUID] = true end
				
		for i = 1, GetNumPartyMembers() do
			local guid = UnitGUID("party" .. i)
			if guid then preserve[guid] = true end
		end
		for i = 1, GetNumRaidMembers() do
			local guid = UnitGUID("raid" .. i)
			if guid then preserve[guid] = true end
		end
				
		local toRemove = {}
		for guid in pairs(self.targets) do
			if not preserve[guid] then
				table.insert(toRemove, guid)
			end
		end
		
		for _, guid in ipairs(toRemove) do
			self:PurgeTarget(guid)
		end
	end

	self.ownerGUIDs = {}
	self:UpdateOwnerGUIDs()

	local _, class = UnitClass("player")
	self.playerClass = class

	if not self.ui then self:CreateUI() end
	self:RefreshKnownNames()
	
	for guid, target in pairs(self.targets) do
		if target.timers then
			for spellId, timer in pairs(target.timers) do
				self:ValidateTimer(timer)
			end
		end
	end

	self.frame:SetScript("OnUpdate", function() SW:OnUpdate() end)
end

function SW:RefreshKnownNames()
	local units = { "player", "pet", "target", "mouseover", "pettarget" }
	for i = 1, GetNumPartyMembers() do table.insert(units, "party" .. i) end
	for i = 1, GetNumRaidMembers()  do table.insert(units, "raid"  .. i) end
	for i = 1, 8 do table.insert(units, "mark" .. i) end
	for _, unit in ipairs(units) do
		local guid = UnitGUID(unit)
		if guid then
			self.guidNames[guid] = UnitName(unit) or self.guidNames[guid]
			local lvl = UnitLevel(unit)
			if lvl and lvl ~= 0 then self.guidLevels[guid] = lvl end

			if IsFriendly(unit)    then self.guidRelation[guid] = "friendly"
			elseif IsHostile(unit) then self.guidRelation[guid] = "hostile" end
		end
	end
end

function SW:GetTarget(guid, name)
	if not guid then return nil end
	local t = self.targets[guid]
	if not t then
		t = {
			guid     = guid,
			name     = name or ResolveName(guid),
			timers   = {},
			lastSeen = Now(),
			relation = self.guidRelation[guid],
		}
		self.targets[guid] = t
		table.insert(self.targetOrder, guid)
	else
		t.name     = name or t.name or ResolveName(guid)
		t.lastSeen = Now()
		t.relation = self.guidRelation[guid] or t.relation
	end
	self:TouchTarget(guid)
	return t
end

function SW:TouchTarget(guid)
    for i = table.getn(self.targetOrder), 1, -1 do
        if self.targetOrder[i] == guid then
            table.remove(self.targetOrder, i)
            break
        end
    end
    table.insert(self.targetOrder, 1, guid)
end

function SW:GetDuration(spellName, spellRank, baseNumber, multiplier)
	return self:ReturnDuration(spellName, spellRank or "", self.playerClass, baseNumber, multiplier)
end

function SW:AddOrRefreshTimer(casterGUID, targetGUID, spellId, castDuration)
	if not self:IsOwnerGUID(casterGUID) then return end
	if not targetGUID or not spellId then return end

	local duration, hideMain, isAoE
	local fastCache = dynamicDurationCache[spellId]
	if fastCache then
		duration = fastCache.duration
		hideMain = fastCache.hideMain
		isAoE    = fastCache.isAoE
	end

	local name, rank, texture
	if not duration then
		name, rank, texture = SpellDetails(spellId)
		local lowerName = string.lower(name)

		local cfg = self.idConfigCache and self.idConfigCache[spellId]

		if not cfg then
			cfg = self.nameConfigCache and self.nameConfigCache[lowerName]
		end

		if cfg then
			hideMain = cfg.hideMain
			isAoE    = cfg.isAoE
			duration = self:GetDuration(name, rank, cfg.duration, cfg.multiplier)
		else
			duration = self:GetDuration(name, rank)
		end

		local override = SPELL_OVERRIDE[spellId]
		if override and override.duration then
			duration = override.duration
		end

		if not duration then return end
		dynamicDurationCache[spellId] = { duration = duration, hideMain = hideMain, isAoE = isAoE }
	else
		name, rank, texture = SpellDetails(spellId)
	end

	local target   = self:GetTarget(targetGUID, ResolveName(targetGUID))
	local friendly = IsFriendly(targetGUID)
	local now      = Now()
	local timer    = target.timers[spellId]

	if timer then
		if timer.seenAura then
			timer._backup = {
				start    = timer.start,
				duration = timer.duration,
				expires  = timer.expires,
				seenAura = timer.seenAura,
				pending  = timer.pending,
			}
		end
	end

	if not timer then
		timer = {}
		target.timers[spellId] = timer
	end

	timer.spellId     = spellId
	timer.name        = name
	timer.rank        = rank
	timer.texture     = texture
	timer.casterGUID  = casterGUID
	timer.targetGUID  = targetGUID
	timer.targetName  = target.name
	timer.start       = now
	timer.lastRefresh = now
	timer.duration    = duration
	timer.expires     = now + duration
	timer.unknown     = nil
	timer.pending     = 1
	timer.hidden      = nil
	timer.friendly    = friendly
	timer.hideUntil   = nil
	timer.dead        = nil
	timer.failed      = nil
	timer.seenAura    = nil
	timer.hideMain    = hideMain

	if spellId == 2649 or spellId == 26090 or spellId == 6358 or spellId == 19244 or spellId == 19647 then
		timer.seenAura = 1
		timer.pending  = nil
	end

	if isAoE then
		timer.seenAura = 1
		timer.pending  = nil
	end

	local lowerName = string.lower(name)
	DoTimerSWDB.spellNameMap[lowerName] = spellId
	self:TouchTarget(targetGUID)
	self:ValidateTimer(timer, 1)

	if self.OnDataUpdate then
		self:OnDataUpdate(targetGUID)
	end
end

function SW:RemoveTimer(targetGUID, spellId, reason)
	local target = self.targets[targetGUID]
	if not target then return end
	local timer = target.timers[spellId]
	if not timer then return end

	timer._backup = nil
	target.timers[spellId] = nil

	if not next(target.timers) then
		self.targets[targetGUID] = nil
		for i = table.getn(self.targetOrder), 1, -1 do
			if self.targetOrder[i] == targetGUID then
				table.remove(self.targetOrder, i)
			end
		end
	end

	if self.OnDataUpdate then
		self:OnDataUpdate(targetGUID)
	end
end

function SW:FindAura(unitOrGUID, spellId, spellTexture)
    if not unitOrGUID then return nil end
    for list = 1, 2 do
        local func     = list == 1 and UnitDebuff or UnitBuff
        local auraKind = list == 1 and "debuff"   or "buff"
        if func then
            for i = 1, 32 do
                local texture, _, _, auraSpellId = func(unitOrGUID, i)
                if not texture then break end
                if auraSpellId and auraSpellId > 0 then
                    if auraSpellId == spellId then return 1, spellId, texture, auraKind end
                elseif spellTexture and texture == spellTexture then
                    return 1, spellId, texture, auraKind
                end
            end
        end
    end
    return nil
end

function SW:ValidateTimer(timer, fresh)
    if not timer or not timer.targetGUID then return end

    if timer.casterGUID and not self:IsOwnerGUID(timer.casterGUID) then
        self:RemoveTimer(timer.targetGUID, timer.spellId, "foreign-caster")
        return
    end

    if timer.seenAura then return end

    local found, _, _, auraKind = self:FindAura(timer.targetGUID, timer.spellId, timer.texture)
    if found then
        timer.seenAura = 1
        timer.pending  = nil
        timer.auraKind = auraKind
        timer._backup = nil
        return
    end

    if fresh then return end
    if Now() - timer.start > DoTimerSWDB.settings.auraConfirmGrace then
        self:RemoveTimer(timer.targetGUID, timer.spellId, "no-aura")
        return
    end
end

function SW:OnCastEvent(casterGUID, targetGUID, eventType, spellId, castDuration)
	if casterGUID == UnitGUID("player") or casterGUID == self.playerGUID then
		if eventType == "START" then
			local name = SpellInfo(spellId)
			if name then 
				self.playerCurrentCast = string.lower(name) 
			end
		elseif eventType == "CAST" or eventType == "FAIL" then
			self.playerCurrentCast = nil
		end
	end

	if eventType ~= "CAST" and eventType ~= "CHANNEL" then return end
	if not self:IsOwnerGUID(casterGUID) then return end

	spellId = tonumber(spellId)
	if not spellId then return end
	castDuration = tonumber(castDuration) or 0

	local spellName = SpellInfo(spellId)
	local lowerName = spellName and string.lower(spellName) or ""
	local cfg = self.idConfigCache and self.idConfigCache[spellId]
	if not cfg then
		cfg = self.nameConfigCache and self.nameConfigCache[lowerName]
	end

	if targetGUID and targetGUID ~= "" and targetGUID ~= "0x0000000000000000" then
		if not (cfg and cfg.isAoE) then
			self:AddOrRefreshTimer(casterGUID, targetGUID, spellId, castDuration)
			self:QueueAuraScan(casterGUID, spellId, castDuration, targetGUID)
		end
	elseif cfg and cfg.isAoE then
		self.lastAoECasts = self.lastAoECasts or {}
		self.lastAoECasts[lowerName] = Now()

		local refreshCount = 0
		for tGUID, targetData in pairs(self.targets) do
			if targetData.timers and targetData.timers[spellId] then
				self:AddOrRefreshTimer(casterGUID, tGUID, spellId, castDuration)
				refreshCount = refreshCount + 1
			end
		end
	end

	if eventType == "CAST"
	and self:IsOwnerGUID(casterGUID)
	and targetGUID and targetGUID ~= "" and targetGUID ~= "0x0000000000000000" then
		local sideEffectId = SHIELD_SIDE_EFFECTS[spellId]

		local shieldName = GetShieldFamilyName()
		if not sideEffectId and shieldName and lowerName == shieldName then
			Chat("WARNING: '" .. spellName .. "' (spellId=" .. spellId ..
				") 未在 SHIELD_SIDE_EFFECTS 中注册，虚弱灵魂副作用不会触发，请补录 [" .. spellId .. "] = 6788")
		end

		if sideEffectId then
			local target = self:GetTarget(targetGUID, ResolveName(targetGUID))
			local now    = Now()
			local timer  = target.timers[sideEffectId] or {}
			local sName, sRank, sTexture = SpellDetails(sideEffectId)
			timer.spellId     = sideEffectId
			timer.name        = sName
			timer.rank        = sRank
			timer.texture     = sTexture
			timer.casterGUID  = casterGUID
			timer.targetGUID  = targetGUID
			timer.targetName  = target.name
			timer.start       = now
			timer.lastRefresh = now
			timer.duration    = 15
			timer.expires     = now + 15
			timer.pending     = nil
			timer.seenAura    = 1
			timer.hideMain    = nil
			timer.dead        = nil
			timer.failed      = nil
			target.timers[sideEffectId] = timer
			self:TouchTarget(targetGUID)
			if self.OnDataUpdate then
				self:OnDataUpdate(targetGUID)
			end
		end
	end

	if eventType == "CAST"
	and self.playerClass == "WARLOCK"
	and self:IsOwnerGUID(casterGUID)
	and targetGUID and targetGUID ~= "" and targetGUID ~= "0x0000000000000000" then
		local conflagInfo = CONFLAGRATE_INFO[spellId]
		if conflagInfo then
			self:ApplyConflagHit(targetGUID, conflagInfo.consumeSpellId, conflagInfo.durationReduction)
		end
	end
end

function SW:OnSpellSystemSuccess(spellName, rank, targetUnitOrName)
	local targetGUID = nil
	if targetUnitOrName and UnitExists(targetUnitOrName) then
		targetGUID = UnitGUID(targetUnitOrName)
	elseif targetUnitOrName == "target" or targetUnitOrName == "mouseover" then
		targetGUID = UnitGUID(targetUnitOrName)
	else
		if UnitExists("target") and UnitName("target") == targetUnitOrName then
			targetGUID = UnitGUID("target")
		elseif UnitExists("mouseover") and UnitName("mouseover") == targetUnitOrName then
			targetGUID = UnitGUID("mouseover")
		end
	end

	if not targetGUID then return end
	local lowerName = string.lower(spellName)
	local spellId   = DoTimerSWDB.spellNameMap[lowerName] or self:SpellNameToId(spellName)
	if spellId then
		local cfg = self.idConfigCache and self.idConfigCache[spellId]
		if not cfg then
			cfg = self.nameConfigCache and self.nameConfigCache[lowerName]
		end
		if not (cfg and cfg.isAoE) then
			local existingTarget = self.targets[targetGUID]
			local existingTimer  = existingTarget and existingTarget.timers[spellId]
			if existingTimer and existingTimer.seenAura then
				return
			end
			self:AddOrRefreshTimer(self.playerGUID or UnitGUID("player"), targetGUID, spellId, 0)
		end
	end
end

function SW:OnSpellSystemFailAfter(spellName, rank, targetUnitOrName)
	local lowerName = string.lower(spellName)
	local spellId   = DoTimerSWDB.spellNameMap[lowerName] or self:SpellNameToId(spellName)
	if not spellId then return end

	local cfg = self.idConfigCache and self.idConfigCache[spellId]
	if not cfg then
		cfg = self.nameConfigCache and self.nameConfigCache[lowerName]
	end
	if cfg and cfg.isAoE then return end

	local targetGUID = nil
	if targetUnitOrName and UnitExists(targetUnitOrName) then
		targetGUID = UnitGUID(targetUnitOrName)
	end
	if not targetGUID then
		for guid, target in pairs(self.targets) do
			local t = target.timers[spellId]
			if t and t._backup then
				targetGUID = guid
				break
			end
		end
	end

	if not targetGUID or not self.targets[targetGUID] then return end

	local timer = self.targets[targetGUID].timers[spellId]
	if timer and timer._backup then
		local backup = timer._backup
		if backup.expires > GetTime() then
			timer.start    = backup.start
			timer.duration = backup.duration
			timer.expires  = backup.expires
			timer.seenAura = backup.seenAura
			timer.pending  = backup.pending
			timer._backup  = nil
			self:TouchTarget(targetGUID)
			if self.OnDataUpdate then
				self:OnDataUpdate(targetGUID)
			end
		else
			self:RemoveTimer(targetGUID, spellId, "SPELLSYSTEM_FAIL_BACKUP_EXPIRED")
		end
	else
		self:RemoveTimer(targetGUID, spellId, "SPELLSYSTEM_FAIL")
	end
end

function SW:QueueAuraScan(casterGUID, spellId, castDuration, targetGUID)
    if not self:IsOwnerGUID(casterGUID) or not spellId then return end
    if not targetGUID or targetGUID == "0x0000000000000000" then return end

    local target = self.targets[targetGUID]
    if target and target.timers[spellId] and target.timers[spellId].seenAura then return end

    if self.pendingScans[targetGUID] then
        self.pendingScans[targetGUID].stopAt = Now() + 1.5
    else
        self.pendingScans[targetGUID] = {
            casterGUID = casterGUID,
            spells     = {},
            stopAt     = Now() + 1.5,
        }
    end
    self.pendingScans[targetGUID].spells[spellId] = castDuration or 0
end

function SW:ProcessPendingScans()
    local now = Now()
    for guid, scanData in pairs(self.pendingScans) do
        if now > scanData.stopAt then
            local target = self.targets[guid]
            if target then
                for spellId, _ in pairs(scanData.spells) do
                    local timer = target.timers[spellId]
                    if timer and not timer.seenAura then
                        self:RemoveTimer(guid, spellId, "scan-timeout")
                    end
                end
            end
            self.pendingScans[guid] = nil
        else
            local confirmed = {}
            for spellId, castDuration in pairs(scanData.spells) do
                if self:FindAura(guid, spellId) then
                    confirmed[spellId] = castDuration
                end
            end
            for spellId, castDuration in pairs(confirmed) do
                local existingTarget = self.targets[guid]
                local existingTimer  = existingTarget and existingTarget.timers[spellId]

                if existingTimer then
                    existingTimer.seenAura = 1
                    existingTimer.pending  = nil
                    existingTimer._backup  = nil
                    self:TouchTarget(guid)
                    if self.OnDataUpdate then
                        self:OnDataUpdate(guid)
                    end
                else
                    self:AddOrRefreshTimer(scanData.casterGUID, guid, spellId, castDuration)
                end
                scanData.spells[spellId] = nil
            end
            if not next(scanData.spells) then
                self.pendingScans[guid] = nil
            end
        end
    end
end

function SW:ApplyConflagHit(targetGUID, consumeSpellId, reduction)
    local target = self.targets[targetGUID]
    if not target or not target.timers then return end

    local timer = target.timers[consumeSpellId]

    if not timer then
        local immolateName = SpellInfo(consumeSpellId)
        local lowerImmolateName = immolateName and string.lower(immolateName) or nil
        if lowerImmolateName then
            for _, t in pairs(target.timers) do
                if t.name and string.lower(t.name) == lowerImmolateName and t.casterGUID == self.playerGUID then
                    timer = t
                    break
                end
            end
        end
    end

    if not timer then return end

    local remain = timer.expires - GetTime()
    if remain <= reduction then
        self:RemoveTimer(targetGUID, timer.spellId, "CONFLAGRATE_CONSUME")
    else
        timer.expires = timer.expires - reduction
        if self.OnDataUpdate then
            self:OnDataUpdate(targetGUID)
        end
    end
end

function SW:ExtractGUIDs(text)
	local out = {}
	local pos = 1
	while true do
		local s, e, guid = string.find(text, "(0[xX]%x+)", pos)
		if not guid then break end
		table.insert(out, guid)
		pos = e + 1
	end
	return out
end

function SW:PurgeTarget(guid)
	if not guid or not self.targets[guid] then return end
	self.targets[guid] = nil
	for i = table.getn(self.targetOrder), 1, -1 do
		if self.targetOrder[i] == guid then table.remove(self.targetOrder, i) end
	end
	if self.OnDataUpdate then self.OnDataUpdate(guid) end
end

function SW:ProcessLogGUIDs(text, guids)
	for _, guid in ipairs(guids) do self.guidNames[guid] = self.guidNames[guid] or ResolveName(guid) end
end

local DEATH_EVENTS = {
	["CHAT_MSG_COMBAT_HOSTILE_DEATH"]  = true,
	["CHAT_MSG_COMBAT_FRIENDLY_DEATH"] = true,
}

local AURA_GONE_EVENTS = {
	["CHAT_MSG_SPELL_AURA_GONE_OTHER"] = true,
	["CHAT_MSG_SPELL_AURA_GONE_SELF"]  = true,
	["CHAT_MSG_SPELL_AURA_GONE_PARTY"] = true,
	["CHAT_MSG_SPELL_AURA_GONE_PET"]   = true,
}

local AURA_APPLIED_EVENTS = {
	["CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF"] = true,
	["CHAT_MSG_SPELL_SELF_BUFF"] = true,
	["CHAT_MSG_SPELL_PARTY_BUFF"] = true,
	["CHAT_MSG_SPELL_PET_BUFF"] = true,
	["CHAT_MSG_SPELL_CREATURE_BUFF"] = true,
	["CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS"] = true,
	["CHAT_MSG_SPELL_PERIODIC_PARTY_BUFFS"] = true,
	["CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS"] = true,
	["CHAT_MSG_SPELL_PERIODIC_PET_BUFFS"] = true,
	["CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS"] = true,
	["CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE"] = true,
	["CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE"] = true,
	["CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE"] = true,
	["CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE"] = true,
	["CHAT_MSG_SPELL_PERIODIC_PET_DAMAGE"] = true,
	["CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE"] = true,
	["CHAT_MSG_SPELL_CREATURE_DAMAGE"] = true,
	["CHAT_MSG_SPELL_SELF_DAMAGE"] = true,
	["CHAT_MSG_SPELL_PARTY_DAMAGE"] = true,
	["CHAT_MSG_SPELL_PET_DAMAGE"] = true,
	["CHAT_MSG_SPELL_AURA_APPLIED_SELF"] = true,
	["CHAT_MSG_SPELL_AURA_APPLIED_OTHER"] = true,
	["CHAT_MSG_SPELL_AURA_APPLIED_PARTY"] = true,
	["CHAT_MSG_SPELL_AURA_APPLIED_PET"] = true,
}

local MISS_EVENTS = {
	["CHAT_MSG_SPELL_SELF_DAMAGE"]                 = true,
	["CHAT_MSG_SPELL_PET_DAMAGE"]                  = true,
	["CHAT_MSG_COMBAT_SELF_MISSES"]                = true,
	["CHAT_MSG_COMBAT_PET_MISSES"]                 = true,
}

function SW:OnRawCombatLog(originalEvent, text)
    if not text then return end

    if AURA_APPLIED_EVENTS[originalEvent] then
        local guids = self:ExtractGUIDs(text)
        local guidCount = table.getn(guids)

        local casterGUID, targetGUID

        if guidCount >= 2 then
            for _, guid in ipairs(guids) do
                if self:IsOwnerGUID(guid) then
                    casterGUID = guid
                else
                    targetGUID = guid
                end
            end
            if not casterGUID then
                targetGUID = guids[1]
                casterGUID = guids[guidCount]
            end
        elseif guidCount == 1 then
            targetGUID = guids[1]
            casterGUID = self.playerGUID or self.petGUID or UnitGUID("player")
        else
            return
        end

        if not casterGUID or not targetGUID then
            return
        end

        if guidCount >= 2 and not self:IsOwnerGUID(casterGUID) then
            return
        end

        local lowerText = string.lower(text)
        for _, aoeInfo in ipairs(self.aoeSpellList) do
            if string.find(lowerText, string.lower(aoeInfo.name), 1, true) then
                
                if guidCount == 1 then
                    local skillName = string.lower(aoeInfo.name)
                    local lastCastTime = self.lastAoECasts and self.lastAoECasts[skillName] or 0
                    local timeSinceCast = Now() - lastCastTime
                    
                    local isGuiding = (self.playerCurrentCast == skillName)
                    local maxAllowedDelay = isGuiding and 6.0 or 1.2
                    
                    if timeSinceCast > maxAllowedDelay then
                        break
                    end
                end

                self:AddOrRefreshTimer(casterGUID, targetGUID, aoeInfo.spellId, 0)
                local target = self.targets[targetGUID]
                local timer = target and target.timers[aoeInfo.spellId]
                if timer then
                    timer.seenAura = 1
                    timer.pending = nil
                    timer._backup = nil
                end
                break
            end
        end
        return
    end

    if DEATH_EVENTS[originalEvent] then
        local victimGUID = nil
        if self.patterns.death then
            for _, pattern in ipairs(self.patterns.death) do
                local _, _, captured = string.find(text, pattern)
                if captured then
                    local extracted = self:ExtractGUIDs(captured)
                    if extracted and extracted[1] then
                        victimGUID = extracted[1]
                        break
                    end
                end
            end
        end

        if not victimGUID then
            local guids = self:ExtractGUIDs(text)
            if guids and table.getn(guids) > 0 then
                victimGUID = guids[table.getn(guids)]
            end
        end

        if victimGUID and victimGUID ~= "0x0000000000000000" then
            if victimGUID ~= self.playerGUID and victimGUID ~= self.petGUID then
                self:PurgeTarget(victimGUID)
            end
        end
        return
    end

    if AURA_GONE_EVENTS[originalEvent] then
        if MatchesAnyPattern(text, self.patterns.fade) then
            local guids = self:ExtractGUIDs(text)
            self:ProcessLogGUIDs(text, guids)
            local targetGUID = nil
            for _, guid in ipairs(guids) do
                if not self:IsOwnerGUID(guid) then
                    targetGUID = guid
                    break
                end
            end
            if not targetGUID and table.getn(guids) > 0 then
                targetGUID = guids[1]
            end
            if targetGUID and self.targets[targetGUID] then
                local toRemove = {}
                for spellId, timer in pairs(self.targets[targetGUID].timers) do
                    if timer.name and string.find(text, timer.name, 1, true) then
                        local stillOnTarget = self:FindAura(targetGUID, spellId, timer.texture)
                        if not stillOnTarget then
                            table.insert(toRemove, spellId)
                        end
                    end
                end
                for _, spellId in ipairs(toRemove) do
                    self:RemoveTimer(targetGUID, spellId, "AURA_FADE")
                end
            end
        end
        return
    end

    if MISS_EVENTS[originalEvent] then
        local isOwnerSpell = (originalEvent == "CHAT_MSG_SPELL_SELF_DAMAGE" 
                           or originalEvent == "CHAT_MSG_COMBAT_SELF_MISSES"
                           or originalEvent == "CHAT_MSG_SPELL_PET_DAMAGE"
                           or originalEvent == "CHAT_MSG_COMBAT_PET_MISSES")
        if not isOwnerSpell then return end

        local isMissEvent = MatchesAnyPattern(text, self.patterns.resist)
            or MatchesAnyPattern(text, self.patterns.immune)
            or MatchesAnyPattern(text, self.patterns.evade)
            or MatchesAnyPattern(text, self.patterns.reflect)

        if not isMissEvent then return end

        local guids = self:ExtractGUIDs(text)
        self:ProcessLogGUIDs(text, guids)

        local targetGUID = nil
        for _, guid in ipairs(guids) do
            if IsHostile(guid) then
                targetGUID = guid
                break
            end
        end

        if not targetGUID and guids and table.getn(guids) > 0 then
            targetGUID = guids[table.getn(guids)]
        end

        if targetGUID and self.targets[targetGUID] then
            local toRemove = {}
            for spellId, timer in pairs(self.targets[targetGUID].timers) do
                if timer.name and string.find(text, timer.name, 1, true) then
                    if timer._backup then
                        local backup = timer._backup
                        if backup.expires > GetTime() then
                            timer.start    = backup.start
                            timer.duration = backup.duration
                            timer.expires  = backup.expires
                            timer.seenAura = backup.seenAura
                            timer.pending  = backup.pending
                            timer._backup  = nil
                            self:TouchTarget(targetGUID)
                            if self.OnDataUpdate then
                                self:OnDataUpdate(targetGUID)
                            end
                        else
                            self:RemoveTimer(targetGUID, spellId, "MISS_RESIST_BACKUP_EXPIRED")
                        end
                    elseif not timer.seenAura then
                        table.insert(toRemove, spellId)
                    end
                end
            end
            for _, spellId in ipairs(toRemove) do
                self:RemoveTimer(targetGUID, spellId, "MISS_RESIST_CLEAN")
            end
        end
        return
    end
end

function SW:Remaining(timer)
	if not timer or not timer.expires then return 0 end
	local r = timer.expires - GetTime()
	return r > 0 and r or 0
end

function SW:GetSortedTargets()
	local out = {}
	for _, guid in ipairs(self.targetOrder) do
		local t = self.targets[guid]
		if t and t.timers then
			local hasVisibleTimer = false
			for _, timer in pairs(t.timers) do
				if self:ShouldDisplayTimer(timer) then hasVisibleTimer = true break end
			end
			if hasVisibleTimer then table.insert(out, t) end
		end
	end
	return out
end

function SW:FormatTime(seconds)
	if not seconds or seconds <= 0 then return "0" end
	local displaySeconds = math.ceil(seconds)	
	if displaySeconds >= 60 then
		local m = math.floor(displaySeconds / 60)
		local s = displaySeconds - m * 60
		return string.format("%d:%02d", m, s)
	end
	return tostring(displaySeconds)
end

function SW:ShouldDisplayTimer(timer)
	if not timer or timer.hidden then return nil end
	if not timer.seenAura        then return nil end
	if timer.hideMain            then return nil end
	return 1
end

function SW:GetSortedTimers(target)
	local out = {}
	for _, timer in pairs(target.timers) do
		if self:ShouldDisplayTimer(timer) then table.insert(out, timer) end
	end
	table.sort(out, function(a, b)
		local ar = self:Remaining(a) or 999999
		local br = self:Remaining(b) or 999999
		return ar < br
	end)
	return out
end

function SW:Render()
	if not self.rows then return end
	local maxTargets = DoTimerSWDB.settings.maxTargets
	local maxTimers  = DoTimerSWDB.settings.maxTimersPerTarget
	local targets    = self:GetSortedTargets()
	for i = 1, 8 do
		local row    = self.rows[i]
		local target = targets[i]
		if target and i <= maxTargets then
			row.frame:Show()
			row.nameBtn.guid = target.guid

			local lvlStr    = ResolveLevel(target.guid)
			local rawName   = target.name or "Unknown"
			local cleanName = TruncateUTF8(rawName, 12)
			row.name:SetText("[" .. lvlStr .. "] " .. cleanName)

			if target.relation == "friendly" or IsFriendly(target.guid) then
				row.name:SetTextColor(COLOR_FRIENDLY[1], COLOR_FRIENDLY[2], COLOR_FRIENDLY[3])
			elseif target.relation == "hostile" or IsHostile(target.guid) then
				row.name:SetTextColor(COLOR_HOSTILE[1], COLOR_HOSTILE[2], COLOR_HOSTILE[3])
			else
				row.name:SetTextColor(COLOR_TARGET[1], COLOR_TARGET[2], COLOR_TARGET[3])
			end

			local symbol = GetRaidTargetIndex(target.guid) or 0
			if symbol > 0 then
				local index = symbol - 1
				local left  = math.mod(index, 4) * 0.25
				local top   = math.floor(index / 4) * 0.25
				row.raidIcon:SetTexCoord(left, left + 0.25, top, top + 0.25)
				row.raidIcon:Show()
			else
				row.raidIcon:Hide()
			end

			row.name:ClearAllPoints()
			row.name:SetPoint("CENTER", row.nameBtn, "CENTER", 0, 0)

			local timers = self:GetSortedTimers(target)
			for j = 1, 8 do
				local button = row.timers[j]
				local timer  = timers[j]
				if timer and j <= maxTimers then
					button.timer = timer
					button.icon:SetTexture(timer.texture or DEFAULT_ICON)
					local remain = self:Remaining(timer)
					button.text:SetText(self:FormatTime(remain))
					if remain and remain <= 5 then
						button.text:SetTextColor(COLOR_LOW[1],    COLOR_LOW[2],    COLOR_LOW[3])
					else
						button.text:SetTextColor(COLOR_NORMAL[1], COLOR_NORMAL[2], COLOR_NORMAL[3])
					end
					button:Show()
				else
					button.timer = nil
					button:Hide()
				end
			end
		else
			row.frame:Hide()
		end
	end
end

function SW:OnUpdate()
    if self.checkGhostNextUpdate then
        self.checkGhostNextUpdate = nil
        if UnitIsGhost("player") then self:PurgeTarget(self.playerGUID) end
    end
    local now = Now()
    if self.nextScan and now < self.nextScan then return end
    self.nextScan = now + 0.2
    self:ProcessPendingScans()
    for targetGUID, target in pairs(self.targets) do
        for spellId, timer in pairs(target.timers) do
            if timer.expires and now >= timer.expires then
                if timer._backup and timer._backup.expires > now then
                    local backup = timer._backup
                    timer.start    = backup.start
                    timer.duration = backup.duration
                    timer.expires  = backup.expires
                    timer.seenAura = backup.seenAura
                    timer.pending  = backup.pending
                    timer._backup  = nil
                    if self.OnDataUpdate then
                        self:OnDataUpdate(targetGUID)
                    end
                else
                    self:RemoveTimer(targetGUID, spellId, "expired")
                end
            else
                self:ValidateTimer(timer)
            end
        end
    end

    self:Render()
end

function SW:CastTimer(timer)
	if not timer then return end
	if timer.name and timer.targetGUID then CastSpellByName(timer.name, timer.targetGUID) end
end

function SW:SpellNameToId(spellname)
	if not spellname then return nil end
	if type(spellname) == "number" then return spellname end
	local id = tonumber(spellname)
	if id then return id end
	return DoTimerSWDB.spellNameMap[string.lower(spellname)]
end

function SW:FindTimer(spellname, unit)
	local guid = UnitGUID(unit or "target")
	if not guid then return nil end
	local target = self.targets[guid]
	if not target then return nil end
	local id = self:SpellNameToId(spellname)
	if id and target.timers[id] then return target.timers[id] end
	local key = type(spellname) == "string" and string.lower(spellname) or nil
	if key then
		for _, timer in pairs(target.timers) do
			if timer.name and string.lower(timer.name) == key then return timer end
		end
	end
	return nil
end

function SW:SpellOnUnit(spellname, unit)
    local timer = SW:FindTimer(spellname, unit or "target")
    if timer then return 1, timer end
    local guid = UnitGUID(unit or "target")
    if not guid then return nil end
    local id = SW:SpellNameToId(spellname)
    if id then
        local _, _, tex = SpellInfo(id)
        if SW:FindAura(guid, id, tex) then return 1 end
    end
    return nil
end

function SW:CastSpellOnUnit(spellname, unit)
	unit = unit or "target"
	local guid = UnitGUID(unit)
	if guid then CastSpellByName(spellname, guid) else CastSpellByName(spellname, unit) end
end

function SW:Command(msg)
	msg = string.lower(msg or "")
	if msg == "" then msg = "unlock" end
	local L = DoTimerSW_L or {}
	if msg == "lock" then
		DoTimerSWDB.settings.locked = true
		if self.anchor then self.anchor:Hide() end
		Chat(L.MSG_LOCKED_HIDDEN or L.MSG_LOCKED or "Locked, anchor hidden.")
	elseif msg == "unlock" then
		DoTimerSWDB.settings.locked = false
		if self.anchor then self.anchor:Show() end
		Chat(L.MSG_UNLOCKED or "Anchor shown.")
	elseif string.sub(msg, 1, 5) == "scale" then
		local v = tonumber(string.sub(msg, 7))
		if v and v > 0 then
			DoTimerSWDB.settings.scale = v
			if self.ui then self.ui:SetScale(v) end
			Chat((L.MSG_SCALE_SET or "Scale set to ") .. v)
		end
	elseif string.sub(msg, 1, 3) == "max" then
		local v = tonumber(string.sub(msg, 5))
		if v then
			DoTimerSWDB.settings.maxTargets = Clamp(v, 1, 8)
			self:Render()
		end
	elseif msg == "clear" then
		self.targets     = {}
		self.targetOrder = {}
		self:Render()
	elseif msg == "resetcache" then
		self:ClearDurationCache()
	elseif msg == "show" then
		DoTimerSWDB.settings.visible = true
		if self.ui then self.ui:Show() end
	elseif msg == "hide" then
		DoTimerSWDB.settings.visible = false
		if self.ui then self.ui:Hide() end
	end
end

function DSW_spell(spellname, unit)
	if SW.playerCurrentCast == string.lower(spellname) then return true end

	if SW:SpellOnUnit(spellname, unit or "target") then return true end
	SW:CastSpellOnUnit(spellname, unit or "target")
	return false
end

function DSW_elapsed(spellname, unit)
	local timer = SW:FindTimer(spellname, unit or "target")
	return timer and (Now() - timer.start) or 0
end
function DSW_remain(spellname, unit)
	local timer = SW:FindTimer(spellname, unit or "target")
	return timer and (SW:Remaining(timer) or 999) or 0
end
function DSW_cast(spellname, unit) SW:CastSpellOnUnit(spellname, unit or "target") end
function DoT_IsSpell(spellname, unit) return DSW_spell(spellname, unit) end

local frame = CreateFrame("Frame", "DoTimerSWEventFrame")
SW.frame = frame
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("UNIT_PET")
frame:RegisterEvent("PLAYER_ALIVE")
frame:RegisterEvent("UNIT_CASTEVENT")
frame:RegisterEvent("RAW_COMBATLOG")
frame:RegisterEvent("LEARNED_SPELL_IN_TAB")
frame:RegisterEvent("CHARACTER_POINTS_CHANGED")
frame:RegisterEvent("PLAYER_DEAD")
frame:RegisterEvent("CHAT_MSG_SPELL_PET_DAMAGE")
frame:RegisterEvent("PET_BAR_UPDATE_COOLDOWN")
frame:RegisterEvent("RAID_ROSTER_UPDATE")
frame:RegisterEvent("PARTY_MEMBERS_CHANGED")

if SpellSystem_RegisterEvent then
	SpellSystem_RegisterEvent(frame, "SPELLSYSTEM_SUCCESS")
	SpellSystem_RegisterEvent(frame, "SPELLSYSTEM_STOP")
	SpellSystem_RegisterEvent(frame, "SPELLSYSTEM_FAILAFTER")
end

frame:SetScript("OnEvent", function()
	if event == "PLAYER_ENTERING_WORLD" then
		SW:Startup()
	elseif event == "PLAYER_TARGET_CHANGED" then
		SW:RefreshKnownNames()
	elseif event == "RAID_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED" then
		SW:RefreshKnownNames()
	elseif event == "UNIT_PET" and arg1 == "player" then
		SW:UpdateOwnerGUIDs()
		SW:RefreshKnownNames()
	elseif event == "PLAYER_ALIVE" then
		SW.checkGhostNextUpdate = true
	elseif event == "PLAYER_DEAD" then
		if SW.playerGUID then 
			SW:PurgeTarget(SW.playerGUID) 
		end
		if SW.petGUID then 
			SW:PurgeTarget(SW.petGUID) 
		end
	elseif event == "CHAT_MSG_SPELL_PET_DAMAGE" or event == "PET_BAR_UPDATE_COOLDOWN" then
		SW:RefreshKnownNames()
	elseif event == "SPELLSYSTEM_SUCCESS" or event == "SPELLSYSTEM_STOP" then
		SW:OnSpellSystemSuccess(arg1, arg2, arg5)
	elseif event == "SPELLSYSTEM_FAILAFTER" then
		SW:OnSpellSystemFailAfter(arg1, arg2, arg5)
	elseif event == "UNIT_CASTEVENT" then
		SW:OnCastEvent(arg1, arg2, arg3, arg4, arg5)
	elseif event == "RAW_COMBATLOG" then
		SW:OnRawCombatLog(arg1, arg2)
	elseif event == "SPELLS_CHANGED" or event == "CHARACTER_POINTS_CHANGED" then
		SW:ClearDurationCache()
	end
end)

SLASH_DOTIMERSW1 = "/dsw"
SLASH_DOTIMERSW2 = "/dotimer"
SLASH_DOTIMERSW3 = "/dot"
SlashCmdList["DOTIMERSW"] = function(msg) SW:Command(msg) end
