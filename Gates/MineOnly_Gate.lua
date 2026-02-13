-- ====================================
-- \Gates\MineOnly_Gate.lua
-- ====================================

local addonName, ns = ...
ns = ns or {}
local IsSecret = ns.Compat and ns.Compat.IsSecret

local function IsNonSecretNumber(v)
  return type(v) == "number" and not (IsSecret and IsSecret(v))
end

local function IsNonSecretString(v)
  return type(v) == "string" and not (IsSecret and IsSecret(v))
end

function ns.MineOnly_IsActive(data)
  if not data then
    return false
  end
  if type(data.gates) == "table" then
    for i = 1, #data.gates do
      if data.gates[i] == "mineOnly" then
        return true
      end
    end
  end
  return data.mineOnly == true
end

local function _auraMatchesMineOnly(a, idSet, nameSet, nameMode)
  if not a then
    return false
  end
  local byPlayer = a.sourceUnit and UnitIsUnit(a.sourceUnit, "player")
  if not byPlayer then
    return false
  end
  local sid = a.spellId
  if idSet and IsNonSecretNumber(sid) and idSet[sid] then
    return true
  end
  local auraName = a.name
  if nameMode and nameSet and IsNonSecretString(auraName) and nameSet[auraName] then
    return true
  end
  return false
end

function ns.MineOnly_UnitHasBuff(unit, idSet, nameSet, nameMode)
  if not unit then
    return false, nil
  end
  local found, expire = false, nil
  if AuraUtil and AuraUtil.ForEachAura then
    AuraUtil.ForEachAura(unit, "HELPFUL", nil, function(a)
      if _auraMatchesMineOnly(a, idSet, nameSet, nameMode) then
        found = true
        local exp = a.expirationTime
        if exp and (not IsSecret or not IsSecret(exp)) and exp > 0 then
          expire = exp
        end
        return true
      end
    end, true)
  else
    local i = 1
    while true do
      local name, _, _, _, _, expTime, _, source, _, _, spellId = UnitAura(unit, i, "HELPFUL")
      if not name then
        break
      end
      local a = { name = name, spellId = spellId, expirationTime = expTime, sourceUnit = source }
      if _auraMatchesMineOnly(a, idSet, nameSet, nameMode) then
        found = true
        if expTime and (not IsSecret or not IsSecret(expTime)) and expTime > 0 then
          expire = expTime
        end
        break
      end
      i = i + 1
    end
  end
  return found, expire
end

ns.RegisterGate("mineOnly", function(ctx, data)
  return true
end)
