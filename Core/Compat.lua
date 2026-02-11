-- ====================================
-- \Core\Compat.lua
-- ====================================

local addonName, ns = ...
ns = ns or {}

ns.Compat = ns.Compat or {}

function ns.Compat.Now()
  if GetTimePreciseSec then
    return GetTimePreciseSec()
  end
  if GetTime then
    return GetTime()
  end
  return time()
end

function ns.Compat.After(delay, fn)
  if C_Timer and C_Timer.After then
    return C_Timer.After(delay, fn)
  end
  if type(fn) == "function" then
    fn()
  end
end

function ns.Compat.IsSecret(value)
  if issecretvalue then
    return issecretvalue(value)
  end
  return false
end

function ns.Compat.HasAnySecret(...)
  if hasanysecretvalues then
    return hasanysecretvalues(...)
  end
  local n = select("#", ...)
  for i = 1, n do
    if ns.Compat.IsSecret(select(i, ...)) then
      return true
    end
  end
  return false
end

function ns.Compat.SecretToNumber(value, fallback)
  if value == nil then
    return fallback
  end
  if ns.Compat.IsSecret(value) then
    return fallback
  end
  return value
end
