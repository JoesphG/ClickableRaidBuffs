-- ====================================
-- \Modules\RaidBuffTargeting.lua
-- ====================================

local addonName, ns = ...

local NAME_TRUNCATE = 6

local function DB()
  return (ns.GetDB and ns.GetDB()) or ClickableRaidBuffsDB or {}
end

clickableRaidBuffCache = clickableRaidBuffCache or {}
clickableRaidBuffCache.targetedRaid = clickableRaidBuffCache.targetedRaid or {}

local function ShortNameNoRealm(name)
  if not name then
    return ""
  end
  local base = name:gsub("%-.+$", "")
  if #base <= NAME_TRUNCATE then
    return base
  end
  return base:sub(1, NAME_TRUNCATE)
end

local function InMyGroup(unitOrName)
  if not unitOrName then
    return false
  end
  if UnitExists(unitOrName) then
    return UnitInParty(unitOrName) or UnitInRaid(unitOrName) or UnitIsUnit(unitOrName, "player")
  end
  for i = 1, 40 do
    local u = (IsInRaid() and ("raid" .. i)) or ("party" .. i)
    if UnitExists(u) and UnitName(u) == unitOrName then
      return true
    end
  end
  return (UnitName("player") == unitOrName)
end

local function CloneOverlay(baseEntry, macroText, label)
  local e = {}
  for k, v in pairs(baseEntry) do
    e[k] = v
  end
  e.category = "RAID_BUFFS"
  e.bottomText = label
  e.macro = macroText
  e.targeted = true
  return e
end

local function GetSpellName(spellID)
  local name = spellID and C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID)
  if name then
    return name
  end
  if C_Spell and C_Spell.GetSpellInfo then
    local info = C_Spell.GetSpellInfo(spellID)
    return info and info.name or nil
  end
  return nil
end

local function WrapScanIfNeeded()
  if type(ns.scanRaidBuffs) == "function" then
    ns.scanRaidBuffs()
  end
end

local function OnRosterChanged()
  WrapScanIfNeeded()
  if InCombatLockdown() or UnitIsDeadOrGhost("player") then
    return
  end
  if ns.RenderAll then
    ns.RenderAll()
  end
end

local function OnPEW()
  WrapScanIfNeeded()
  if ns.RenderAll then
    ns.RenderAll()
  end
end

local WatchedSpell = {}
local function OnUnitAura(unit, updateInfo)
  if not unit or not updateInfo then
    return
  end
  if not updateInfo.addedAuras and not updateInfo.removedAuraInstanceIDs and not updateInfo.updatedAuraInstanceIDs then
    return
  end

  local raid = ClickableRaidData and ClickableRaidData["RAID_BUFFS"]
  if type(raid) ~= "table" then
    return
  end

  local base = {}
  for k, v in pairs(raid) do
    if type(k) == "number" and v and v.spellID then
      base[k] = v
    end
  end

  for castSpellID, baseEntry in pairs(base) do
    if baseEntry and baseEntry.count and WatchedSpell[castSpellID] then
      local who = clickableRaidBuffCache.targetedRaid[castSpellID]
      if who and InMyGroup(who) then
        local sName = GetSpellName(castSpellID)
        if sName then
          local macroP = "/use [@" .. who .. ",help,nodead] " .. sName
          raid["fixed:" .. tostring(castSpellID)] = CloneOverlay(baseEntry, macroP, ShortNameNoRealm(who))
        end
      end
    end
  end

  if ns.RenderAll then
    ns.RenderAll()
  end
end

function ns.RaidBuffTargeting_OnRosterChanged()
  OnRosterChanged()
end

function ns.RaidBuffTargeting_OnPEW()
  OnPEW()
end

function ns.RaidBuffTargeting_OnUnitAura(unit, updateInfo)
  OnUnitAura(unit, updateInfo)
end
