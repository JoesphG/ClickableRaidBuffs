-- ====================================
-- \Core\RaidBuffsScan.lua
-- ====================================

local addonName, ns = ...
local IsSecret = ns.Compat and ns.Compat.IsSecret

clickableRaidBuffCache = clickableRaidBuffCache or {}
clickableRaidBuffCache.playerInfo = clickableRaidBuffCache.playerInfo or {}
clickableRaidBuffCache.displayable = clickableRaidBuffCache.displayable or {}

local function IsNonSecretNumber(v)
  return type(v) == "number" and not (IsSecret and IsSecret(v))
end

local function IsNonSecretString(v)
  return type(v) == "string" and not (IsSecret and IsSecret(v))
end

local function getPlayerClass()
  local _, _, classID = UnitClass("player")
  return classID
end

local function PlayerKnowsSpell(id)
  if not id then
    return false
  end
  if C_SpellBook and C_SpellBook.IsSpellKnown then
    local ok = C_SpellBook.IsSpellKnown(id)
    if ok ~= nil then
      return ok
    end
  end
  if IsPlayerSpell and IsPlayerSpell(id) then
    return true
  end
  if IsSpellKnownOrOverridesKnown and IsSpellKnownOrOverridesKnown(id) then
    return true
  end
  if IsSpellKnown and IsSpellKnown(id) then
    return true
  end
  return false
end

local function IsRowKnown(data, rowKey)
  local k = data and data.isKnown
  if type(k) == "number" then
    return PlayerKnowsSpell(k)
  elseif type(k) == "boolean" then
    return k
  else
    local id = (data and data.spellID) or rowKey
    return PlayerKnowsSpell(id)
  end
end

local function IsItemEquipped(itemID)
  if not itemID then
    return false
  end
  local s13 = GetInventoryItemID("player", 13)
  if s13 and s13 == itemID then
    return true
  end
  local s14 = GetInventoryItemID("player", 14)
  if s14 and s14 == itemID then
    return true
  end
  if IsEquippedItem and IsEquippedItem(itemID) then
    return true
  end
  if C_Item and C_Item.IsEquippedItem and C_Item.IsEquippedItem(itemID) then
    return true
  end
  return false
end

local function DebugGateEval(data, playerLevel, inInstance, rested)
  local reasons = {}
  local suppressed = false
  if not data then
    return true, reasons, suppressed
  end

  local gates = data.gates
  local hasEvenRested, hasEvenDead = false, false
  if gates and #gates > 0 then
    for i = 1, #gates do
      local name = gates[i]
      if name == "evenRested" then
        hasEvenRested = true
      elseif name == "evenDead" then
        hasEvenDead = true
      end
    end
  end

  local isDead = UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") or false
  if isDead and not hasEvenDead then
    reasons[#reasons + 1] = "dead"
    return false, reasons, suppressed
  end

  if rested == nil then
    rested = IsResting and IsResting() or false
  end
  if rested and not hasEvenRested then
    reasons[#reasons + 1] = "rested"
    return false, reasons, suppressed
  end

  if data.minLevel and not (ns.Gate_Level and ns.Gate_Level(data.minLevel, playerLevel)) then
    reasons[#reasons + 1] = "minLevel"
    return false, reasons, suppressed
  end

  if not gates or #gates == 0 then
    return true, reasons, suppressed
  end

  local ctx = { playerLevel = playerLevel, inInstance = inInstance, rested = rested }
  for i = 1, #gates do
    local name = gates[i]
    if name ~= "evenRested" and name ~= "evenDead" then
      if (name == "rested" and hasEvenRested) or (name == "alive" and hasEvenDead) then
      else
        local fn = ns._GateHandlers and ns._GateHandlers[name]
        if fn and not fn(ctx, data) then
          reasons[#reasons + 1] = name
          if ctx.suppress then
            suppressed = true
          end
        end
      end
    end
  end

  return (#reasons == 0), reasons, suppressed
end

function ns.RebuildRaidBuffWatch()
  ns._raidBuffWatch = { spellId = {}, name = {} }

  local classID = clickableRaidBuffCache.playerInfo.playerClassId or getPlayerClass()
  local classBuffs = classID and ClickableRaidData and ClickableRaidData[classID]
  if not classBuffs then
    return
  end

  local function addTable(tbl)
    if not tbl then
      return
    end
    for _, data in pairs(tbl) do
      local ids = data and data.buffID
      if ids and #ids > 0 then
        if data.nameMode then
          local n = ns.GetLocalizedBuffName and ns.GetLocalizedBuffName(ids[1])
            or (C_Spell.GetSpellInfo(ids[1]) or {}).name
          if n then
            ns._raidBuffWatch.name[n] = true
          end
        else
          for _, id in ipairs(ids) do
            ns._raidBuffWatch.spellId[id] = true
          end
        end
      end
    end
  end

  addTable(classBuffs)
end

function ns.DebugRaidBuffVisibility()
  if InCombatLockdown and InCombatLockdown() then
    print("|cFF00ccffCRB:|r /crb debug is unavailable during combat.")
    return
  end

  if type(scanRaidBuffs) == "function" then
    scanRaidBuffs()
  end

  local classID = clickableRaidBuffCache.playerInfo.playerClassId or getPlayerClass()
  local classBuffs = classID and ClickableRaidData and ClickableRaidData[classID]
  if not classBuffs then
    print("|cFF00ccffCRB:|r No raid buff table found for your class.")
    return
  end

  local playerLevel = clickableRaidBuffCache.playerInfo.playerLevel or UnitLevel("player") or 0
  local inInstance = clickableRaidBuffCache.playerInfo.inInstance
  local rested = clickableRaidBuffCache.playerInfo.restedXPArea
  local disp = clickableRaidBuffCache.displayable and clickableRaidBuffCache.displayable.RAID_BUFFS or {}
  local now = GetTime()

  print("|cFF00ccffCRB Debug:|r Hidden raid buff reasons")
  local hidden = 0

  for rowKey, data in pairs(classBuffs) do
    if data then
      local checkID = data.isKnown ~= nil and data.isKnown or (data.spellID or rowKey)
      local include
      if data.type == "trinket" then
        include = IsItemEquipped(data.itemID or rowKey)
      else
        include = IsRowKnown(data, checkID)
      end
      if include then
        local reasons = {}
        local ok, gateReasons, suppressed = DebugGateEval(data, playerLevel, inInstance, rested)
        if not ok then
          reasons[#reasons + 1] = "gate:" .. table.concat(gateReasons, "+")
          if suppressed then
            reasons[#reasons + 1] = "range-suppressed"
          end
        end

        local entry = disp[rowKey]
        if not entry then
          local dup = false
          for _, e in pairs(disp) do
            if type(e) == "table" and e.spellID and data.spellID and e.spellID == data.spellID then
              dup = true
              break
            end
          end
          if dup then
            reasons[#reasons + 1] = "deduped-alt-variant"
          else
            reasons[#reasons + 1] = "not-in-displayable"
          end
        else
          if entry.expireTime == math.huge then
            reasons[#reasons + 1] = "already-covered"
          end
          if entry.showAt and now < entry.showAt then
            reasons[#reasons + 1] = "below-threshold"
          end
          if ns.IsDisplayableExcluded and ns.IsDisplayableExcluded("RAID_BUFFS", entry) then
            reasons[#reasons + 1] = "excluded"
          end
        end

        if #reasons > 0 then
          hidden = hidden + 1
          local sid = data.spellID or rowKey
          local name = data.name or (sid and C_Spell.GetSpellInfo(sid) or {}).name or tostring(sid)
          print(("  - %s (%s): %s"):format(tostring(name), tostring(sid), table.concat(reasons, ", ")))
        end
      end
    end
  end

  if hidden == 0 then
    print("|cFF00ccffCRB:|r No hidden raid buff entries detected.")
  else
    print(("|cFF00ccffCRB:|r %d hidden raid buff entries listed."):format(hidden))
  end
end

function ns.HandleRaidBuff_UNIT_AURA(unit, updateInfo)
  if InCombatLockdown() then
    return
  end

  if not unit or (unit ~= "player" and not unit:match("^party%d") and not unit:match("^raid%d")) then
    return
  end

  if not ns._raidBuffWatch then
    ns.RebuildRaidBuffWatch()
  end
  local watch = ns._raidBuffWatch or { spellId = {}, name = {} }
  local watchSpell = watch.spellId or {}
  local watchName = watch.name or {}

  local function auraMatches(aura)
    if not aura then
      return false
    end
    local auraSpellID = aura.spellId
    if IsNonSecretNumber(auraSpellID) and watchSpell[auraSpellID] then
      return true
    end
    local auraName = aura.name
    if IsNonSecretString(auraName) and watchName[auraName] then
      return true
    end
    return false
  end

  local shouldPoke = false
  if updateInfo then
    if updateInfo.addedAuras and not shouldPoke then
      for _, a in ipairs(updateInfo.addedAuras) do
        if auraMatches(a) then
          shouldPoke = true
          break
        end
      end
    end
    if updateInfo.updatedAuraInstanceIDs and not shouldPoke then
      for k, v in pairs(updateInfo.updatedAuraInstanceIDs) do
        local id = (type(v) == "number") and v or k
        local a = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, id)
        if auraMatches(a) then
          shouldPoke = true
          break
        end
      end
    end
    if updateInfo.removedAuraInstanceIDs and not shouldPoke then
      if next(updateInfo.removedAuraInstanceIDs) ~= nil then
        shouldPoke = true
      end
    end
    if updateInfo.isFullUpdate and not shouldPoke then
      local i = 1
      while true do
        local a = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")
        if not a then
          break
        end
        if auraMatches(a) then
          shouldPoke = true
          break
        end
        i = i + 1
      end
    end
  else
    shouldPoke = true
  end

  if shouldPoke then
    if ns.MarkAurasDirty then
      ns.MarkAurasDirty(unit)
    end
    if ns.PokeUpdateBus then
      ns.PokeUpdateBus()
    end
  end
end

function scanRaidBuffs()
  clickableRaidBuffCache.displayable.RAID_BUFFS = {}

  local classID = clickableRaidBuffCache.playerInfo.playerClassId or getPlayerClass()
  if not classID then
    return
  end

  local classBuffs = ClickableRaidData and ClickableRaidData[classID]
  if not classBuffs then
    return
  end

  local playerLevel = clickableRaidBuffCache.playerInfo.playerLevel or UnitLevel("player") or 0
  local inInstance = clickableRaidBuffCache.playerInfo.inInstance
  local rested = clickableRaidBuffCache.playerInfo.restedXPArea
  local db = ns.GetDB and ns.GetDB() or {}

  local threshold = (
    ns.MPlus_GetEffectiveThresholdSecs and ns.MPlus_GetEffectiveThresholdSecs("spell", db.spellThreshold or 15)
  ) or ((db.spellThreshold or 15) * 60)

  local function passesGates(data, playerLevelX, inInstanceX, restedX)
    return ns.PassesGates(data, playerLevelX, inInstanceX, restedX)
  end

  local function normalizeExpire(v)
    if v == nil then
      return nil
    end
    if v == math.huge then
      return math.huge
    end
    if type(v) ~= "number" then
      return nil
    end
    local now = GetTime()
    if v > (now + 1) then
      return v
    end
    return now + math.max(0, v)
  end

  local function CountByName(name, countRequired)
    if not name then
      return nil
    end
    local units = (ns.GetGroupUnits and ns.GetGroupUnits({ includePlayer = true, onlyExisting = true })) or { "player" }
    local have, total = 0, #units
    for _, u in ipairs(units) do
      local i = 1
      while true do
        local a = C_UnitAuras.GetAuraDataByIndex(u, i, "HELPFUL")
        if not a then
          break
        end
        local auraName = a and a.name
        if IsNonSecretString(auraName) and auraName == name then
          have = have + 1
          break
        end
        i = i + 1
      end
    end
    if countRequired then
      return (have >= countRequired) and math.huge or nil
    else
      return (have == total) and math.huge or nil
    end
  end

  local function CountCoverageForData(data)
    local buffIDs = data and data.buffID
    if not buffIDs then
      return 0, 0
    end

    local units = (ns.GetGroupUnits and ns.GetGroupUnits({ includePlayer = true, onlyExisting = true })) or { "player" }

    local wantById
    local targetName
    if data.nameMode then
      local first = (type(buffIDs) == "table") and buffIDs[1] or buffIDs
      targetName = ns.GetLocalizedBuffName and ns.GetLocalizedBuffName(first)
        or (C_Spell.GetSpellInfo(first) or {}).name
    else
      wantById = {}
      if type(buffIDs) == "table" then
        for i = 1, #buffIDs do
          local id = buffIDs[i]
          if id then
            wantById[id] = true
          end
        end
      elseif type(buffIDs) == "number" then
        wantById[buffIDs] = true
      end
    end

    local have, total = 0, #units
    for _, u in ipairs(units) do
      local i = 1
      local found = false
      while true do
        local a = C_UnitAuras.GetAuraDataByIndex(u, i, "HELPFUL")
        if not a then
          break
        end
        if targetName then
          local auraName = a and a.name
          if IsNonSecretString(auraName) and auraName == targetName then
            found = true
            break
          end
        else
          local auraSpellID = a and a.spellId
          if IsNonSecretNumber(auraSpellID) and wantById[auraSpellID] then
            found = true
            break
          end
        end
        i = i + 1
      end
      if found then
        have = have + 1
      end
    end
    return have, total
  end

  local function addEntry(rowKey, data, catName)
    local entry = (ns.copyItemData and ns.copyItemData(data)) or {}
    entry.category = catName
    entry.spellID = data.spellID or rowKey

    local function buildUnits()
      if data.check == "player" then
        return { "player" }
      end
      return (ns.GetGroupUnits and ns.GetGroupUnits({ includePlayer = true, onlyExisting = true })) or { "player" }
    end

    local function buildSets()
      local idSet, nameSet, nameMode
      nameMode = (data.nameMode and true) or false
      local ids = data.buffID
      if nameMode then
        nameSet = {}
        if type(ids) == "table" then
          for i = 1, #ids do
            local id = ids[i]
            if id then
              local n = (ns.GetLocalizedBuffName and ns.GetLocalizedBuffName(id))
                or (C_Spell.GetSpellInfo(id) or {}).name
              if n then
                nameSet[n] = true
              end
            end
          end
        elseif type(ids) == "number" then
          local n = (ns.GetLocalizedBuffName and ns.GetLocalizedBuffName(ids)) or (C_Spell.GetSpellInfo(ids) or {}).name
          if n then
            nameSet[n] = true
          end
        end
      else
        idSet = {}
        if type(ids) == "table" then
          for i = 1, #ids do
            local v = ids[i]
            if v then
              idSet[v] = true
            end
          end
        elseif type(ids) == "number" then
          idSet[ids] = true
        end
      end
      return idSet, nameSet, nameMode
    end

    local function normalizeExpire(v)
      if v == nil then
        return nil
      end
      if v == math.huge then
        return math.huge
      end
      if type(v) ~= "number" then
        return nil
      end
      local now = GetTime()
      if v > (now + 1) then
        return v
      end
      return now + math.max(0, v)
    end

    local db = (ns.GetDB and ns.GetDB()) or {}
    local threshold = (
      ns.MPlus_GetEffectiveThresholdSecs and ns.MPlus_GetEffectiveThresholdSecs("spell", db.spellThreshold or 15)
    ) or ((db.spellThreshold or 15) * 60)

    local mineOnlyActive = (ns.MineOnly_IsActive and ns.MineOnly_IsActive(data)) or false

    local ex
    if mineOnlyActive then
      local units = buildUnits()
      local idSet, nameSet, nameMode = buildSets()
      local foundExpire
      for i = 1, #units do
        local u = units[i]
        local ok, expire = false, nil
        if ns.MineOnly_UnitHasBuff then
          ok, expire = ns.MineOnly_UnitHasBuff(u, idSet, nameSet, nameMode)
        end
        if ok then
          if expire and expire > 0 then
            foundExpire = expire
          else
            foundExpire = math.huge
          end
          break
        end
      end
      ex = foundExpire
    else
      if data.nameMode then
        local first = (type(data.buffID) == "table") and data.buffID[1] or data.buffID
        local spellName = (ns.GetLocalizedBuffName and ns.GetLocalizedBuffName(first))
          or (C_Spell.GetSpellInfo(first) or {}).name
        local function CountByName(name, countRequired)
          if not name then
            return nil
          end
          local units = buildUnits()
          local have, total = 0, #units
          for _, u in ipairs(units) do
            local idx, matched = 1, false
            while true do
              local a = C_UnitAuras.GetAuraDataByIndex(u, idx, "HELPFUL")
              if not a then
                break
              end
              local auraName = a and a.name
              if IsNonSecretString(auraName) and auraName == name then
                matched = true
                break
              end
              idx = idx + 1
            end
            if matched then
              have = have + 1
            end
          end
          if countRequired then
            return (have >= countRequired) and math.huge or nil
          else
            return (have == total) and math.huge or nil
          end
        end
        ex = CountByName(spellName, data.count)
      elseif data.check == "player" then
        ex = ns.GetPlayerBuffExpire and ns.GetPlayerBuffExpire(data.buffID, data.nameMode, data.infinite) or nil
      elseif data.check == "raid" then
        ex = ns.GetRaidBuffExpire and ns.GetRaidBuffExpire(data.buffID, data.nameMode, data.infinite) or nil
      end
    end

    entry.expireTime = normalizeExpire(ex)

    local useThreshold = threshold
    if entry.spellID == 20707 then
      local ssMin = db.soulstoneThreshold or 5
      useThreshold = (ssMin or 5) * 60
    end

    if entry.expireTime and entry.expireTime ~= math.huge then
      entry.showAt = entry.expireTime - useThreshold
    else
      entry.showAt = nil
    end

    if
      catName == "RAID_BUFFS"
      and (data.count == nil)
      and (data.check ~= "player")
      and (not entry.centerText or entry.centerText == "")
    then
      local units = buildUnits()
      local total, have = #units, 0
      if mineOnlyActive then
        local idSet, nameSet, nameMode = buildSets()
        for i = 1, total do
          local u = units[i]
          local ok = false
          if ns.MineOnly_UnitHasBuff then
            ok = (ns.MineOnly_UnitHasBuff(u, idSet, nameSet, nameMode))
          end
          if ok then
            have = have + 1
          end
        end
      else
        if data.nameMode then
          local nameSet = {}
          local ids = data.buffID
          if type(ids) == "table" then
            for i = 1, #ids do
              local id = ids[i]
              if id then
                local n = (ns.GetLocalizedBuffName and ns.GetLocalizedBuffName(id))
                  or (C_Spell.GetSpellInfo(id) or {}).name
                if n then
                  nameSet[n] = true
                end
              end
            end
          elseif type(ids) == "number" then
            local n = (ns.GetLocalizedBuffName and ns.GetLocalizedBuffName(ids))
              or (C_Spell.GetSpellInfo(ids) or {}).name
            if n then
              nameSet[n] = true
            end
          end
          for i = 1, total do
            local u = units[i]
            local idx, matched = 1, false
            while true do
              local a = C_UnitAuras.GetAuraDataByIndex(u, idx, "HELPFUL")
              if not a then
                break
              end
              local auraName = a and a.name
              if IsNonSecretString(auraName) and nameSet[auraName] then
                matched = true
                break
              end
              idx = idx + 1
            end
            if matched then
              have = have + 1
            end
          end
        else
          local idSet = {}
          local ids = data.buffID
          if type(ids) == "table" then
            for i = 1, #ids do
              local v = ids[i]
              if v then
                idSet[v] = true
              end
            end
          elseif type(ids) == "number" then
            idSet[ids] = true
          end
          for i = 1, total do
            local u = units[i]
            local idx, matched = 1, false
            while true do
              local a = C_UnitAuras.GetAuraDataByIndex(u, idx, "HELPFUL")
              if not a then
                break
              end
              local auraSpellID = a and a.spellId
              if IsNonSecretNumber(auraSpellID) and idSet[auraSpellID] then
                matched = true
                break
              end
              idx = idx + 1
            end
            if matched then
              have = have + 1
            end
          end
        end
      end
      local _, _, _, _, _, _, _, _, _, _, numPlayers = GetInstanceInfo()
      if numPlayers and numPlayers > 0 then
        total = math.min(total, numPlayers)
      end

      entry.centerText = tostring(have) .. " / " .. tostring(total)
    elseif catName == "RAID_BUFFS" and (data.count ~= nil) then
      entry.centerText = ""
    end

    if data.type == "trinket" then
      entry.itemID = data.itemID or rowKey
      local tgt = (data.target == "player") and "player" or "target"
      if tgt == "target" then
        entry.macro = "/use [@target,help,nodead] item:" .. tostring(entry.itemID)
      else
        entry.macro = "/use [@player] item:" .. tostring(entry.itemID)
      end
    end

    clickableRaidBuffCache.displayable[catName][rowKey] = entry
  end

  for rowKey, data in pairs(classBuffs) do
    if data then
      local include
      local checkID
      if data.isKnown ~= nil then
        checkID = data.isKnown
      else
        if type(rowKey) == "number" and C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(rowKey) then
          checkID = rowKey
        else
          checkID = data.spellID or rowKey
        end
      end
      if data.type == "trinket" then
        local itemID = data.itemID or rowKey
        include = IsItemEquipped(itemID)
      else
        include = PlayerKnowsSpell(checkID)
      end
      if include and passesGates(data, playerLevel, inInstance, rested) then
        addEntry(rowKey, data, "RAID_BUFFS")
      end
    end
  end

  do
    local disp = clickableRaidBuffCache.displayable.RAID_BUFFS or {}
    local byKey = {}
    local function hasInstanceGate(e)
      local g = e and e.gates
      if not g then
        return false
      end
      for i = 1, #g do
        if g[i] == "instance" then
          return true
        end
      end
      return false
    end
    for k, e in pairs(disp) do
      if type(e) == "table" then
        local nm = e.name
        if not nm and e.spellID then
          local si = C_Spell.GetSpellInfo(e.spellID)
          nm = si and si.name or tostring(e.spellID)
        end
        local key = tostring(e.spellID or 0) .. "|" .. tostring(nm or "")
        local grp = byKey[key]
        if not grp then
          byKey[key] = { { key = k, e = e } }
        else
          grp[#grp + 1] = { key = k, e = e }
        end
      end
    end
    for _, grp in pairs(byKey) do
      if #grp > 1 then
        local winner = 1
        if inInstance then
          for i = 1, #grp do
            if hasInstanceGate(grp[i].e) then
              winner = i
              break
            end
          end
        else
          for i = 1, #grp do
            if not hasInstanceGate(grp[i].e) then
              winner = i
              break
            end
          end
        end
        for i = 1, #grp do
          if i ~= winner then
            disp[grp[i].key] = nil
          end
        end
      end
    end
  end
end
