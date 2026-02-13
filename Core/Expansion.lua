-- ====================================
-- \Core\Expansion.lua
-- ====================================

local addonName, ns = ...
ns = ns or {}

ns.EXPANSION_TWW = 10
ns.EXPANSION_MIDNIGHT = 11

local TARGET_CATEGORIES = {
  FOOD = ns.EXPANSION_MIDNIGHT,
  FLASK = ns.EXPANSION_MIDNIGHT,
  MAIN_HAND = ns.EXPANSION_MIDNIGHT,
  OFF_HAND = ns.EXPANSION_MIDNIGHT,
  AUGMENT_RUNE = ns.EXPANSION_MIDNIGHT,
}

local function DB()
  return (ns.GetDB and ns.GetDB()) or _G.ClickableRaidBuffsDB or {}
end

local function trim(s)
  return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

function ns.IsExpansionEnabled(expansionId)
  if type(expansionId) ~= "number" then
    return true
  end
  local d = DB()
  local map = d and d.expansions
  if type(map) ~= "table" then
    return true
  end
  local value = map[expansionId]
  if value == nil then
    return true
  end
  return value ~= false
end

function ns.SetExpansionEnabled(expansionId, enabled)
  if type(expansionId) ~= "number" then
    return
  end
  local d = DB()
  d.expansions = d.expansions or {}
  d.expansions[expansionId] = enabled and true or false
end

local function inferExpansionId(name, fallback)
  if type(name) ~= "string" then
    return fallback
  end
  if name:find("^%[TWW%]") then
    return ns.EXPANSION_TWW
  end
  if name:find("^%[MIDNIGHT%]") then
    return ns.EXPANSION_MIDNIGHT
  end
  return fallback
end

function ns.NormalizeExpansionName(name)
  if type(name) ~= "string" then
    return name
  end
  local clean = name
  clean = clean:gsub("^%[TWW%]%s*", "")
  clean = clean:gsub("^%[MIDNIGHT%]%s*", "")
  return trim(clean)
end

function ns.ApplyExpansionMetadata()
  local data = _G.ClickableRaidData
  if type(data) ~= "table" then
    return
  end

  for category, fallbackExpansion in pairs(TARGET_CATEGORIES) do
    local tbl = data[category]
    if type(tbl) == "table" then
      for id, row in pairs(tbl) do
        if type(id) == "number" and type(row) == "table" then
          row.expansionId = tonumber(row.expansionId) or inferExpansionId(row.name, fallbackExpansion)
          row.name = ns.NormalizeExpansionName(row.name)
        end
      end
    end
  end
end
