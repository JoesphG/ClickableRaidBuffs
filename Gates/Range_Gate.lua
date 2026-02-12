-- ====================================
-- \Gates\Range_Gate.lua
-- ====================================

local addonName, ns = ...
ns = ns or {}

local function DB()
  return (ns.GetDB and ns.GetDB()) or ClickableRaidBuffsDB or {}
end

local function GetSpellRange(spellID)
  local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
  if info and info.maxRange and info.maxRange > 0 then
    return info.maxRange, info.name
  end
  return 0, info and info.name or nil
end

local function IsUnitInSpellRange(spellID, unit)
  if C_Spell and C_Spell.IsSpellInRange then
    local ret = C_Spell.IsSpellInRange(spellID, unit)
    if ret == true then
      return true
    end
    if ret == false then
      return false
    end
  end

  if UnitInRange then
    local ur = UnitInRange(unit)
    if ur == true then
      return true
    end
  end

  -- Fail open on unknown range to avoid suppressing valid rebuff prompts.
  return true
end

local function UnitHasAnyBuffFromIDs(unit, ids)
  if ns.UnitHasAnyBuffByIDs then
    return ns.UnitHasAnyBuffByIDs(unit, ids)
  end
  return false
end

local function ResolveBuffIDsForData(data)
  if not data then
    return {}
  end
  local list = data.buffID or data.buffIDs
  if not list then
    if data.spellID then
      local s = {}
      s[data.spellID] = true
      return s
    end
    return {}
  end
  local ids = {}
  if type(list) == "table" then
    if ns.BuildSpellIDSet then
      ids = ns.BuildSpellIDSet(list)
    else
      for i = 1, #list do
        local v = list[i]
        if v then
          ids[v] = true
        end
      end
    end
  elseif type(list) == "number" then
    ids[list] = true
  end
  return ids
end

local RangeState = {
  ticker = nil,
  lastSummary = nil,
  inactivityTicks = 0,
}

function ns.IsRangeTickerRunning()
  return RangeState.ticker ~= nil
end

local function IsTickerEligible()
  if type(ns.locked) == "function" and ns.locked() then
    return false
  end
  if ns._inCombat or (InCombatLockdown and InCombatLockdown()) then
    return false
  end
  if ns._isDead or (UnitIsDeadOrGhost and UnitIsDeadOrGhost("player")) then
    return false
  end
  if not (IsInGroup() or IsInRaid()) then
    return false
  end
  return true
end

local function StopTicker()
  if RangeState.ticker then
    RangeState.ticker:Cancel()
    RangeState.ticker = nil
  end
end

local function TickRangeGate()
  if not IsTickerEligible() then
    StopTicker()
    return
  end

  local spells = {}
  local anyMissing = false
  local anyGlowChanged = false
  local anySuppressionChanged = false

  if ns._rangeTracked and next(ns._rangeTracked) then
    local units = (ns.GetGroupUnits and ns.GetGroupUnits({ includePlayer = true, onlyExisting = true })) or {}
    for spellID, entry in pairs(ns._rangeTracked) do
      local maxRange, spellName = GetSpellRange(spellID)
      local ids = entry.ids or {}
      local miss = {}
      local anyMissingOutOfRange = false
      local foundInRange = false
      local playerHas = UnitHasAnyBuffFromIDs("player", ids)

      if not playerHas then
        if entry.lastSuppressed ~= false then
          entry.lastSuppressed = false
          anySuppressionChanged = true
        end
        spells[#spells + 1] = { spellID = spellID, name = spellName, maxRange = maxRange, missing = miss }
      else
        for i = 1, #units do
          local u = units[i]
          if u ~= "player" and not UnitHasAnyBuffFromIDs(u, ids) then
            local inRange = IsUnitInSpellRange(spellID, u)
            miss[#miss + 1] = { unit = u, name = UnitName(u), inRange = inRange }
            if inRange then
              foundInRange = true
              break
            else
              anyMissingOutOfRange = true
            end
          end
        end

        if #miss > 0 then
          anyMissing = true
        end

        local nowSuppressed = (#miss > 0) and not foundInRange
        if entry.lastSuppressed ~= nowSuppressed then
          entry.lastSuppressed = nowSuppressed
          anySuppressionChanged = true
        end

        local nowAllIn = (#miss > 0) and (foundInRange and not anyMissingOutOfRange) or false
        local desiredGlow = nowAllIn and "special" or nil

        if entry.desiredGlow ~= desiredGlow then
          entry.desiredGlow = desiredGlow
          anyGlowChanged = true
        end

        spells[#spells + 1] = { spellID = spellID, name = spellName, maxRange = maxRange, missing = miss }
      end
    end
  end

  RangeState.lastSummary = { spells = spells, anyMissing = anyMissing }

  if anyMissing then
    RangeState.inactivityTicks = 0
  else
    RangeState.inactivityTicks = RangeState.inactivityTicks + 1
    if RangeState.inactivityTicks >= 2 then
      StopTicker()
    end
  end

  if anyGlowChanged and type(ns.RequestRebuild) == "function" then
    ns.RequestRebuild()
  end

  if anySuppressionChanged then
    if type(ns.MarkGatesDirty) == "function" then
      ns.MarkGatesDirty()
    end
    if type(ns.PokeUpdateBus) == "function" then
      ns.PokeUpdateBus()
    end
  end
end

local function StartTicker()
  if RangeState.ticker or not IsTickerEligible() then
    return
  end
  RangeState.inactivityTicks = 0
  RangeState.ticker = C_Timer.NewTicker(2.0, TickRangeGate)
end

function ns.InitRangeGate()
  ns._rangeTracked = ns._rangeTracked or {}
  RangeState.lastSummary = nil
end

function ns.RangeGate_OnRosterOrSpellsChanged()
  if not ns._rangeTracked then
    return
  end

  local shouldRun = false
  if next(ns._rangeTracked) then
    local units = (ns.GetGroupUnits and ns.GetGroupUnits({ includePlayer = true, onlyExisting = true })) or {}
    for spellID, entry in pairs(ns._rangeTracked) do
      local ids = entry.ids or {}
      if UnitHasAnyBuffFromIDs("player", ids) then
        for i = 1, #units do
          local u = units[i]
          if u ~= "player" and not UnitHasAnyBuffFromIDs(u, ids) then
            shouldRun = true
            break
          end
        end
      end
      if shouldRun then
        break
      end
    end
  end

  if shouldRun then
    StartTicker()
  else
    StopTicker()
  end
end

local function EnsureTracked(spellID, ids)
  if not ns._rangeTracked then
    ns._rangeTracked = {}
  end
  local t = ns._rangeTracked[spellID]
  if not t then
    ns._rangeTracked[spellID] = { ids = ids }
  else
    t.ids = ids
  end
end

function ns.Gate_Range(ctx, data)
  if not data or not data.spellID then
    return true
  end

  local ids = ResolveBuffIDsForData(data)
  local spellID = data.spellID
  EnsureTracked(spellID, ids)

  local playerHas = UnitHasAnyBuffFromIDs("player", ids)
  if not playerHas then
    StopTicker()
    return true
  end

  local units = (ns.GetGroupUnits and ns.GetGroupUnits({ includePlayer = true, onlyExisting = true })) or {}
  local anyMissing = false
  local anyMissingInRange = false

  for i = 1, #units do
    local u = units[i]
    if u ~= "player" and not UnitHasAnyBuffFromIDs(u, ids) then
      anyMissing = true
      local inRange = IsUnitInSpellRange(spellID, u)
      if inRange then
        anyMissingInRange = true
        break
      end
    end
  end

  if anyMissing then
    StartTicker()
  else
    StopTicker()
  end

  if not anyMissing then
    return true
  end

  if not anyMissingInRange then
    ctx.suppress = true
    return false
  end

  return true
end

ns.RegisterGate("range", function(ctx, data)
  return ns.Gate_Range(ctx, data)
end)
