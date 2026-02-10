-- ====================================
-- \Core\MidnightBootstrap.lua
-- ====================================

local addonName, ns = ...
ns = ns or {}

ns.MIDNIGHT_LIMP_MODE = true
ns.MIDNIGHT_ERROR_REPORTING = false

ns._midnightEvents = ns._midnightEvents or {}
ns._midnightNotified = false
ns._midnightDeferredOpen = false

local realCombatClear
local _timerWrapped = false
local _wasLocked = false

function ns.ExecutionLocked()
  if C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive and C_ChallengeMode.IsChallengeModeActive() then
    return true
  end
  if InCombatLockdown and InCombatLockdown() then return true end
  if ns._inCombat then return true end
  if ns._inEncounter then return true end
  if ns._isDead then return true end
  return false
end

local function recordViolation(name)
  local e = ns._midnightEvents[name]
  if not e then
    e = {
      name = name,
      firstSeen = date("%Y-%m-%d %H:%M:%S"),
      count = 0,
      stack = debugstack(3, 25, 25),
    }
    ns._midnightEvents[name] = e
  end
  e.count = e.count + 1

  if ns.MIDNIGHT_ERROR_REPORTING and not ns._midnightNotified then
    ns._midnightNotified = true
    print("|cffff3333CRB error report generated. Use /crb error|r")
    if realCombatClear then
      realCombatClear()
    end
  end
end

local function wrapFunction(fn, name)
  return function(...)
    if ns.MIDNIGHT_LIMP_MODE and ns.ExecutionLocked() then
      recordViolation(name)
      return nil
    end
    return fn(...)
  end
end

local function WrapCTimer()
  if _timerWrapped or not C_Timer then return end

  if C_Timer.After then
    local realAfter = C_Timer.After
    C_Timer.After = function(delay, callback)
      if type(callback) ~= "function" then
        return realAfter(delay, callback)
      end
      return realAfter(delay, function(...)
        if ns.ExecutionLocked() then return end
        callback(...)
      end)
    end
  end

  if C_Timer.NewTicker then
    local realNewTicker = C_Timer.NewTicker
    C_Timer.NewTicker = function(interval, callback, iterations)
      if type(callback) ~= "function" then
        return realNewTicker(interval, callback, iterations)
      end
      return realNewTicker(interval, function(...)
        if ns.ExecutionLocked() then return end
        callback(...)
      end, iterations)
    end
  end

  _timerWrapped = true
end

local DO_NOT_WRAP = {
  MidnightBootstrap    = true,
  ExecutionLocked      = true,
  MidnightShowError    = true,
  CombatClearIcons     = true,
  HideAllRenderedIcons = true,
}

function ns.MidnightBootstrap()
  realCombatClear = ns.CombatClearIcons
  WrapCTimer()

  for k, v in pairs(ns) do
    if type(v) == "function" and not DO_NOT_WRAP[k] then
      ns[k] = wrapFunction(v, k)
    end
  end
end

local function ForceReassessIfUnlocked()
  local locked = ns.ExecutionLocked()
  if _wasLocked and not locked then
    if ns.RequestRebuild then ns.RequestRebuild() end
    if ns.RenderAll then ns.RenderAll() end
  end
  _wasLocked = locked
end

local combatFrame = CreateFrame("Frame")
combatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
combatFrame:RegisterEvent("CHALLENGE_MODE_START")
combatFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
combatFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
combatFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

combatFrame:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_REGEN_DISABLED" or event == "CHALLENGE_MODE_START" then
    if realCombatClear then realCombatClear() end
    _wasLocked = true
    return
  end

  ForceReassessIfUnlocked()
end)

local reportFrame

local function ForceShowErrorUI()
  if InCombatLockdown and InCombatLockdown() then return end
  if not next(ns._midnightEvents) then
    print("|cFF00ccffCRB:|r No Midnight errors recorded.")
    return
  end
  if reportFrame then
    reportFrame:Show()
    return
  end

  reportFrame = CreateFrame("Frame", "CRB_MidnightErrorReport", UIParent, "BackdropTemplate")
  reportFrame:SetSize(760, 560)
  reportFrame:SetPoint("CENTER")
  reportFrame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  reportFrame:SetBackdropColor(0, 0, 0, 0.95)

  local scroll = CreateFrame("ScrollFrame", nil, reportFrame, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 12, -12)
  scroll:SetPoint("BOTTOMRIGHT", -30, 12)

  local editBox = CreateFrame("EditBox", nil, scroll)
  editBox:SetMultiLine(true)
  editBox:SetFontObject(ChatFontNormal)
  editBox:SetWidth(700)
  editBox:SetAutoFocus(false)
  scroll:SetScrollChild(editBox)

  local lines = { "Addon: ClickableRaidBuffs", "" }
  for _, e in pairs(ns._midnightEvents) do
    lines[#lines+1] = ("%s (%d×)"):format(e.name, e.count)
    lines[#lines+1] = "First seen: " .. e.firstSeen
    lines[#lines+1] = e.stack
    lines[#lines+1] = string.rep("-", 50)
  end

  editBox:SetText(table.concat(lines, "\n"))
end

function ns.MidnightShowError()
  if InCombatLockdown and InCombatLockdown() then
    ns._midnightDeferredOpen = true
    return
  end
  ForceShowErrorUI()
end

C_Timer.After(0, function()
  if ns.MIDNIGHT_LIMP_MODE then
    ns.MidnightBootstrap()
  end
end)
