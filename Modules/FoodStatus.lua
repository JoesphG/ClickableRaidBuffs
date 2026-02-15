-- ====================================
-- \Modules\FoodStatus.lua
-- ====================================

local addonName, ns = ...
local IsSecret = ns.Compat and ns.Compat.IsSecret

local EATING_ICON = 132805
local AuraByIndex = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
local AuraByInstance = C_UnitAuras and C_UnitAuras.GetAuraDataByAuraInstanceID
local GetTime = GetTimePreciseSec

local eatingActive = false
local lastInstanceID = nil
local _suppressActive = false

local EATING_NAMES = {}
local WELLFED_NAMES = {}

local function IsNonSecretString(v)
  return type(v) == "string" and not (IsSecret and IsSecret(v))
end

local function IsNonSecretNumber(v)
  return type(v) == "number" and not (IsSecret and IsSecret(v))
end

local function HasName(tbl, name)
  if type(tbl) ~= "table" then
    return false
  end
  if not IsNonSecretString(name) then
    return false
  end
  return tbl[name] == true
end

local function DB()
  return (ns.GetDB and ns.GetDB()) or ClickableRaidBuffsDB or {}
end

local function itemThresholdSeconds()
  local baseMin = (DB().itemThreshold or 5)
  if ns.MPlus_GetEffectiveThresholdSecs then
    return ns.MPlus_GetEffectiveThresholdSecs("item", baseMin)
  end
  return baseMin * 60
end

function BuildNameSets()
  wipe(EATING_NAMES)
  wipe(WELLFED_NAMES)

  local srcE = ClickableRaidData and ClickableRaidData["EATING"]
  if type(srcE) == "table" then
    for _, id in pairs(srcE) do
      local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(id)
      local name = info and info.name
      if IsNonSecretString(name) then
        EATING_NAMES[name] = true
      end
    end
  end

  local srcW = ClickableRaidData and ClickableRaidData["WELLFED"]
  if type(srcW) == "table" then
    for _, id in pairs(srcW) do
      local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(id)
      local name = info and info.name
      if IsNonSecretString(name) then
        WELLFED_NAMES[name] = true
      end
    end
  end
end

BuildNameSets()

local function EnsureEatingEntry()
  clickableRaidBuffCache = clickableRaidBuffCache or {}
  clickableRaidBuffCache.displayable = clickableRaidBuffCache.displayable or {}
  local cat = clickableRaidBuffCache.displayable["EATING"]
  if not cat then
    cat = {}
    clickableRaidBuffCache.displayable["EATING"] = cat
  end
  local entry = cat["EATING"]
  if not entry then
    entry = {
      category = "EATING",
      icon = EATING_ICON,
      itemID = nil,
      centerText = "",
      cooldownStart = nil,
      cooldownDuration = nil,
    }
    cat["EATING"] = entry
  end
  return entry
end

local function ClearEatingEntry()
  if not clickableRaidBuffCache or not clickableRaidBuffCache.displayable then
    return
  end
  local cat = clickableRaidBuffCache.displayable["EATING"]
  if cat then
    cat["EATING"] = nil
  end
end

local function ScanPlayerEatingAura()
  local now = GetTime()
  for i = 1, 40 do
    local aura = AuraByIndex and AuraByIndex("player", i, "HELPFUL")
    if not aura then
      break
    end
    if HasName(EATING_NAMES, aura and aura.name) then
      local exp = IsNonSecretNumber(aura.expirationTime) and aura.expirationTime or 0
      local dur = IsNonSecretNumber(aura.duration) and aura.duration or 0
      if (not dur or dur <= 0) and exp and exp > 0 then
        dur = math.max(0, exp - now)
      end
      local start = (exp and dur and exp > 0 and dur > 0) and (exp - dur) or now
      local inst = IsNonSecretNumber(aura.auraInstanceID) and aura.auraInstanceID or nil
      return true, aura, exp or 0, dur or 0, start, inst
    end
  end
  return false
end

local function HasWellFedOverThreshold(thresh)
  local now = GetTime()
  for i = 1, 40 do
    local aura = AuraByIndex and AuraByIndex("player", i, "HELPFUL")
    if not aura then
      break
    end
    if HasName(WELLFED_NAMES, aura and aura.name) then
      local exp = IsNonSecretNumber(aura.expirationTime) and aura.expirationTime or nil
      if exp and exp > now and (exp - now) > thresh then
        return true
      end
    end
  end
  return false
end

function ns.RecomputeEatingState()
  if ns._inCombat then
    return
  end
  local found, aura, exp, dur, start, instID = ScanPlayerEatingAura()
  local suppress = false
  if found then
    suppress = HasWellFedOverThreshold(itemThresholdSeconds())
  end
  _suppressActive = suppress

  if found and not suppress then
    eatingActive = true
    lastInstanceID = instID
    local e = EnsureEatingEntry()
    e.cooldownStart = start
    e.cooldownDuration = dur
    e.centerText = ""
    if ns.PushRender then
      ns.PushRender()
    else
      if ns.RenderAll then
        ns.RenderAll()
      end
    end
    if ns.Timer_RecomputeSchedule then
      ns.Timer_RecomputeSchedule()
    end
  else
    if eatingActive then
      eatingActive = false
      lastInstanceID = nil
      ClearEatingEntry()
      if ns.PushRender then
        ns.PushRender()
      else
        if ns.RenderAll then
          ns.RenderAll()
        end
      end
      if ns.Timer_RecomputeSchedule then
        ns.Timer_RecomputeSchedule()
      end
    end
  end
end

local function OnUnitAura(unit, updateInfo)
  if unit ~= "player" then
    return
  end

  if not updateInfo or updateInfo.isFullUpdate then
    ns.RecomputeEatingState()
    return
  end

  local changed = false

  if updateInfo.addedAuras then
    for i = 1, #updateInfo.addedAuras do
      local a = updateInfo.addedAuras[i]
      local n = a and a.name
      if HasName(EATING_NAMES, n) or HasName(WELLFED_NAMES, n) then
        changed = true
        break
      end
    end
  end

  if not changed and updateInfo.updatedAuraInstanceIDs and AuraByInstance then
    for i = 1, #updateInfo.updatedAuraInstanceIDs do
      local id = updateInfo.updatedAuraInstanceIDs[i]
      if IsNonSecretNumber(id) then
        local a = AuraByInstance("player", id)
        local n = a and a.name
        if id == lastInstanceID or HasName(EATING_NAMES, n) or HasName(WELLFED_NAMES, n) then
          changed = true
          break
        end
      end
    end
  end

  if not changed and updateInfo.removedAuraInstanceIDs then
    for i = 1, #updateInfo.removedAuraInstanceIDs do
      local id = updateInfo.removedAuraInstanceIDs[i]
      if (IsNonSecretNumber(id) and id == lastInstanceID) or _suppressActive then
        changed = true
        break
      end
    end
  end

  if changed then
    ns.RecomputeEatingState()
  end
end

function ns.FoodStatus_OnUnitAura(unit, updateInfo)
  OnUnitAura(unit, updateInfo)
  if ns.Timer_RecomputeSchedule then
    ns.Timer_RecomputeSchedule()
  end
end
