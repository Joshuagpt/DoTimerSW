if not SUPERWOW_VERSION then return end
if not DoTimerSW then return end

local SW = DoTimerSW

-- ============================================================
-- 工具函数
-- ============================================================
local function GetUnitGUID(unit)
    local exists, guid = UnitExists(unit)
    return exists and guid or nil
end

local function FormatTime(seconds)
    if seconds < 0 then seconds = 0 end
    local color
    if seconds < 5 then
        color = "|cffff5555"
    elseif seconds < 10 then
        color = "|cffffff55"
    else
        color = "|cffffffff"
    end
    if seconds < 60 then
        return color .. math.ceil(seconds) .. "|r"
    elseif seconds < 3600 then
        return color .. math.ceil(seconds / 60) .. "m|r"
    elseif seconds < 86400 then
        return color .. math.ceil(seconds / 3600) .. "h|r"
    else
        return color .. math.ceil(seconds / 86400) .. "d|r"
    end
end

-- ============================================================
-- 数据查询层
-- ============================================================
local function GetPreciseAuraTime(unitTarget, buffnum, isDebuff)
    local guid = GetUnitGUID(unitTarget)
    if not guid then return nil, nil end

    local func = isDebuff and UnitDebuff or UnitBuff
    local texture, _, _, auraSpellId = func(unitTarget, buffnum)
    if not texture then return nil, nil end

    local target = SW.targets and SW.targets[guid]
    if not target or not target.timers then return nil, nil end

    local now = GetTime()
    local timer

    if auraSpellId and auraSpellId > 0 then
        timer = target.timers[auraSpellId]
    end

    if not timer then
        local lowerTex = string.lower(texture)
        for spellId, t in pairs(target.timers) do
            local _, _, spellTexture = SpellInfo(spellId)
            if spellTexture and string.lower(spellTexture) == lowerTex then
                timer = t
                break
            end
        end
    end

    if timer then
        local timeleft = timer.expires - now
        if timeleft > 0 then
            return timer.duration, timeleft
        end
    end
    return nil, nil
end

function GetPreciseBuffTime(unitTarget, buffnum)
    return GetPreciseAuraTime(unitTarget, buffnum, false)
end

function GetPreciseDebuffTime(unitTarget, buffnum)
    return GetPreciseAuraTime(unitTarget, buffnum, true)
end

-- ============================================================
-- 渲染层
-- ============================================================

local function ApplyTimerToButton(button, duration, timeleft)
    if not button then return end

    if not duration or not timeleft or timeleft <= 0 then
        if button.timerFrame then
            button.timerFrame.start    = nil
            button.timerFrame.duration = nil
            button.timerFrame:Hide()
        end
        return
    end

    local start = GetTime() + timeleft - duration

    if not button.timerFrame then
        local timer = CreateFrame("Frame", nil, button)
        timer:SetAllPoints(button)
        timer:SetFrameLevel(button:GetFrameLevel() + 1)
        timer:EnableMouse(false)

        local text = timer:CreateFontString(nil, "OVERLAY")
        text:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
        text:SetPoint("CENTER", timer, "CENTER", 0, 0)
        timer.text = text

        timer:SetScript("OnUpdate", function()
            if not timer.duration or not timer.start then
                timer:Hide()
                return
            end
            local remaining = timer.duration - (GetTime() - timer.start)
            if remaining > 0 then
                timer.text:SetText(FormatTime(remaining))
                timer:Show()
            else
                timer.start    = nil
                timer.duration = nil
                timer:Hide()
            end
        end)

        button.timerFrame = timer
    end

    button.timerFrame.start    = start
    button.timerFrame.duration = duration
    button.timerFrame:Show()
end

-- 原生目标框架刷新
local function UpdateTargetAuras()
    local unit = "target"
    if not UnitExists(unit) then return end
    for i = 1, 20 do
        local btn = _G["TargetFrameBuff" .. i]
        if btn then
            local duration, timeleft = GetPreciseBuffTime(unit, i)
            ApplyTimerToButton(btn, duration, timeleft)
        end
    end
    for i = 1, 16 do
        local btn = _G["TargetFrameDebuff" .. i]
        if btn then
            local duration, timeleft = GetPreciseDebuffTime(unit, i)
            ApplyTimerToButton(btn, duration, timeleft)
        end
    end
end

-- 原生队伍框架刷新（只处理 buff）
local function UpdateNativePartyAuras(unit, index)
    if not UnitExists(unit) then return end
    for i = 1, 16 do
        local btn = _G["PartyMemberFrame" .. index .. "Buff" .. i]
        if btn then
            local duration, timeleft = GetPreciseBuffTime(unit, i)
            ApplyTimerToButton(btn, duration, timeleft)
        end
    end
end

-- XPerl 目标框架 hook 后补充倒计时
local function ApplyXPerlTargetTimers(unitTarget, argFramePrefix, ttFrame)
    if not UnitExists(unitTarget) then return end
    for buffnum = 1, 20 do
        local btn = getglobal(argFramePrefix .. "BuffFrame_Buff" .. buffnum)
        if btn and btn:IsShown() then
            local duration, timeleft = GetPreciseBuffTime(unitTarget, buffnum)
            ApplyTimerToButton(btn, duration, timeleft)
        elseif btn and btn.timerFrame then
            btn.timerFrame.start    = nil
            btn.timerFrame.duration = nil
            btn.timerFrame:Hide()
        end
    end
    for buffnum = 1, 16 do
        local btn = getglobal(argFramePrefix .. "BuffFrame_DeBuff" .. buffnum)
        if btn and btn:IsShown() then
            local duration, timeleft = GetPreciseDebuffTime(unitTarget, buffnum)
            ApplyTimerToButton(btn, duration, timeleft)
        elseif btn and btn.timerFrame then
            btn.timerFrame.start    = nil
            btn.timerFrame.duration = nil
            btn.timerFrame:Hide()
        end
    end
end

-- XPerl 队伍框架补充倒计时（只处理 buff）
local function UpdateXPerlPartyAuras(unit, index)
    if not UnitExists(unit) then return end
    local xpFrame = getglobal("XPerl_party" .. index)
    if not xpFrame then return end
    local thisid = xpFrame:GetName()
    for buffnum = 1, 16 do
        local btn = getglobal(thisid .. "_BuffFrame_Buff" .. buffnum)
        if btn and btn:IsShown() then
            local duration, timeleft = GetPreciseBuffTime(unit, buffnum)
            ApplyTimerToButton(btn, duration, timeleft)
        elseif btn and btn.timerFrame then
            btn.timerFrame.start    = nil
            btn.timerFrame.duration = nil
            btn.timerFrame:Hide()
        end
    end
end

-- ============================================================
-- XPerl hook
-- ============================================================
local xperlHooked = false
local function HookXPerl()
    if xperlHooked then return end
    if not XPerl_Targets_BuffUpdate then return end

    -- hook 目标框架
    local origTargets = XPerl_Targets_BuffUpdate
    XPerl_Targets_BuffUpdate = function(unitTarget, argFramePrefix, ttFrame)
        origTargets(unitTarget, argFramePrefix, ttFrame)
        ApplyXPerlTargetTimers(unitTarget, argFramePrefix, ttFrame)
    end

    -- hook 队伍框架
    if XPerl_Party_Buff_UpdateAll then
        local origParty = XPerl_Party_Buff_UpdateAll
        XPerl_Party_Buff_UpdateAll = function(thisFrame)
            origParty(thisFrame)
            local partyid = thisFrame.partyid
            if not partyid or not UnitExists(partyid) then return end
            for i = 1, 4 do
                if partyid == "party" .. i then
                    UpdateXPerlPartyAuras(partyid, i)
                    break
                end
            end
        end
    end

    xperlHooked = true
end

-- ============================================================
-- 事件与回调层
-- ============================================================
local oldOnDataUpdate = SW.OnDataUpdate
SW.OnDataUpdate = function(self, targetGUID)
    if oldOnDataUpdate then
        oldOnDataUpdate(self, targetGUID)
    end

    -- 目标框架
    if targetGUID == GetUnitGUID("target") then
        if xperlHooked and XPerl_Target then
            local savedThis = this
            this = XPerl_Target
            this.Fading = nil
            pcall(XPerl_Targets_BuffUpdate, "target", "XPerl_Target_", XPerl_Target)
            this = savedThis
        else
            UpdateTargetAuras()
        end
    end

    -- 目标的目标框架
    if targetGUID == GetUnitGUID("targettarget") then
        if xperlHooked and XPerl_TargetTarget then
            local savedThis = this
            this = XPerl_TargetTarget
            this.Fading = nil
            pcall(XPerl_Targets_BuffUpdate, "targettarget", "XPerl_TargetTarget_", XPerl_TargetTarget)
            this = savedThis
        else
            UpdateTargetAuras()
        end
    end

    -- 队伍框架（只处理 buff）
    for i = 1, 4 do
        local unit = "party" .. i
        if targetGUID == GetUnitGUID(unit) then
            local xpFrame = getglobal("XPerl_party" .. i)
            if xpFrame then
                UpdateXPerlPartyAuras(unit, i)
            else
                UpdateNativePartyAuras(unit, i)
            end
        end
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_TARGET_CHANGED")
f:SetScript("OnEvent", function()
    if xperlHooked and XPerl_Target then
        local savedThis = this
        this = XPerl_Target
        this.Fading = nil
        pcall(XPerl_Targets_BuffUpdate, "target", "XPerl_Target_", XPerl_Target)
        this = savedThis
    else
        UpdateTargetAuras()
    end
end)

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function()
    local delay = CreateFrame("Frame")
    delay:SetScript("OnUpdate", function()
        HookXPerl()
        if xperlHooked and XPerl_Target then
            local savedThis = this
            this = XPerl_Target
            this.Fading = nil
            pcall(XPerl_Targets_BuffUpdate, "target", "XPerl_Target_", XPerl_Target)
            this = savedThis
        else
            UpdateTargetAuras()
        end
        delay:SetScript("OnUpdate", nil)
    end)
    initFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
end)