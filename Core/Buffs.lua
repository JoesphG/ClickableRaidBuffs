-- ====================================
-- \Core\Buffs.lua
-- ====================================

local addonName, ns = ...
local IsSecret = ns.Compat and ns.Compat.IsSecret

local function IsNonSecretNumber(v)
  return type(v) == "number" and not (IsSecret and IsSecret(v))
end

local function IsNonSecretString(v)
  return type(v) == "string" and not (IsSecret and IsSecret(v))
end

function ns.GetLocalizedBuffName(spellID)
  local info = C_Spell.GetSpellInfo(spellID)
  return info and info.name or nil
end

local NAME_MODE_EXCLUDE = { [442522] = true }

local function BuildNameLookup(spellIDs)
  local t = {}
  for _, id in ipairs(spellIDs or {}) do
    local name = ns.GetLocalizedBuffName(id)
    if name and type(name) == "string" then
      t[name] = true
    end
  end
  return next(t) and t or nil
end

function ns.BuildSpellIDSet(spellIDs)
  local t = {}
  if type(spellIDs) ~= "table" then
    return t
  end
  for _, id in ipairs(spellIDs) do
    if id then
      t[id] = true
    end
  end
  return t
end

function ns.BuildBuffNameSet(spellIDs)
  local t = {}
  if type(spellIDs) ~= "table" then
    return t
  end
  for _, id in ipairs(spellIDs) do
    local name = ns.GetLocalizedBuffName(id)
    if name and type(name) == "string" then
      t[name] = true
    end
  end
  return t
end

function ns.GetGroupUnits(opts)
  opts = opts or {}
  local includePlayer = (opts.includePlayer ~= false)
  local onlyExisting = (opts.onlyExisting == true)
  local units = {}

  if IsInRaid() then
    for i = 1, GetNumGroupMembers() do
      local u = "raid" .. i
      if (not onlyExisting) or UnitExists(u) then
        units[#units + 1] = u
      end
    end
  elseif IsInGroup() then
    for i = 1, GetNumSubgroupMembers() do
      local u = "party" .. i
      if (not onlyExisting) or UnitExists(u) then
        units[#units + 1] = u
      end
    end
  end

  if includePlayer then
    units[#units + 1] = "player"
  end
  return units
end

function ns.UnitHasAnyBuffByIDs(unit, ids)
  if not unit or type(ids) ~= "table" then
    return false
  end
  local idx = 1
  while true do
    local aura = C_UnitAuras.GetAuraDataByIndex(unit, idx, "HELPFUL")
    if not aura then
      break
    end
    local sid = aura.spellId
    if IsNonSecretNumber(sid) and ids[sid] then
      return true
    end
    idx = idx + 1
  end
  return false
end

function ns.UnitHasAnyBuffByNames(unit, names)
  if not unit or type(names) ~= "table" then
    return false
  end
  local idx = 1
  while true do
    local aura = C_UnitAuras.GetAuraDataByIndex(unit, idx, "HELPFUL")
    if not aura then
      break
    end
    local name = aura.name
    if IsNonSecretString(name) and names[name] then
      local sid = aura.spellId
      if not (IsNonSecretNumber(sid) and NAME_MODE_EXCLUDE[sid]) then
        return true
      end
    end
    idx = idx + 1
  end
  return false
end

function ns.GetPlayerBuffExpire(spellIDs, nameMode, infinite)
  local function safeExpiration(aura)
    if not aura then
      return nil
    end
    local exp = aura.expirationTime
    if IsSecret and IsSecret(exp) then
      return nil
    end
    if infinite or exp == 0 then
      return math.huge
    end
    return exp
  end

  if nameMode then
    local nameLookup = BuildNameLookup(spellIDs)
    if not nameLookup then
      return nil
    end
    local index = 1
    while true do
      local aura = C_UnitAuras.GetAuraDataByIndex("player", index, "HELPFUL")
      if not aura then
        break
      end

      local auraName = aura.name
      local auraSpellID = aura.spellId
      if
        IsNonSecretString(auraName)
        and nameLookup[auraName]
        and IsNonSecretNumber(auraSpellID)
        and not NAME_MODE_EXCLUDE[auraSpellID]
      then
        return safeExpiration(aura)
      end

      index = index + 1
    end
  else
    local spellLookup = {}
    for _, id in ipairs(spellIDs or {}) do
      spellLookup[id] = true
    end

    local index = 1
    while true do
      local aura = C_UnitAuras.GetAuraDataByIndex("player", index, "HELPFUL")
      if not aura then
        break
      end

      local sid = aura.spellId
      if IsNonSecretNumber(sid) and spellLookup[sid] then
        return safeExpiration(aura)
      end

      index = index + 1
    end
  end

  return nil
end

function ns.GetRaidBuffExpire(spellIDs, nameMode, infinite)
  local spellLookup, nameLookup
  if nameMode then
    nameLookup = BuildNameLookup(spellIDs)
    if not nameLookup then
      return nil
    end
  else
    spellLookup = ns.BuildSpellIDSet(spellIDs or {})
  end

  local earliest = nil
  for _, unit in ipairs(ns.GetGroupUnits({ includePlayer = true })) do
    local found = false
    local idx = 1
    while true do
      local aura = C_UnitAuras.GetAuraDataByIndex(unit, idx, "HELPFUL")
      if not aura then
        break
      end

      local sid = aura.spellId
      if IsNonSecretNumber(sid) then
        if nameMode then
          local auraName = aura.name
          if IsNonSecretString(auraName) and nameLookup[auraName] and not NAME_MODE_EXCLUDE[sid] then
            found = true
            local exp = aura.expirationTime
            if IsSecret and IsSecret(exp) then
              return nil
            end
            exp = (infinite or exp == 0) and math.huge or exp
            if not earliest or exp < earliest then
              earliest = exp
            end
            break
          end
        else
          if spellLookup[sid] then
            found = true
            local exp = aura.expirationTime
            if IsSecret and IsSecret(exp) then
              return nil
            end
            exp = (infinite or exp == 0) and math.huge or exp
            if not earliest or exp < earliest then
              earliest = exp
            end
            break
          end
        end
      end

      idx = idx + 1
    end

    if not found then
      return nil
    end
  end

  return earliest
end

function ns.GetRaidBuffExpireMine(spellIDs, nameMode, infinite)
  local playerGUID = UnitGUID("player")
  local units = ns.GetGroupUnits({ includePlayer = true })

  local spellLookup, nameLookup
  if nameMode then
    nameLookup = BuildNameLookup(spellIDs)
    if not nameLookup then
      return nil
    end
  else
    spellLookup = ns.BuildSpellIDSet(spellIDs or {})
  end

  for _, unit in ipairs(units) do
    local idx = 1
    while true do
      local aura = C_UnitAuras.GetAuraDataByIndex(unit, idx, "HELPFUL")
      if not aura then
        break
      end

      local auraSpellID = aura.spellId
      if IsNonSecretNumber(auraSpellID) and UnitGUID(aura.sourceUnit) == playerGUID then
        if nameMode then
          local auraName = aura.name
          if IsNonSecretString(auraName) and nameLookup[auraName] and not NAME_MODE_EXCLUDE[auraSpellID] then
            local exp = aura.expirationTime
            if IsSecret and IsSecret(exp) then
              return nil
            end
            return (infinite or exp == 0) and math.huge or exp
          end
        else
          if spellLookup[auraSpellID] then
            local exp = aura.expirationTime
            if IsSecret and IsSecret(exp) then
              return nil
            end
            return (infinite or exp == 0) and math.huge or exp
          end
        end
      end

      idx = idx + 1
    end
  end

  return nil
end
