-- ====================================
-- \Core\BagScan.lua
-- ====================================

local addonName, ns = ...
clickableRaidBuffCache = clickableRaidBuffCache or {}
clickableRaidBuffCache.playerInfo = clickableRaidBuffCache.playerInfo or {}
clickableRaidBuffCache.displayable = clickableRaidBuffCache.displayable or {}
clickableRaidBuffCache.functions = clickableRaidBuffCache.functions or {}

local Now = (ns.Compat and ns.Compat.Now) or GetTime
local After = (ns.Compat and ns.Compat.After) or (C_Timer and C_Timer.After)

local function DB()
  return (ns.GetDB and ns.GetDB()) or _G.ClickableRaidBuffsDB or {}
end

local function GetWellFedIDs()
  local wf = ClickableRaidData and ClickableRaidData["WELLFED"]
  if type(wf) == "table" and #wf > 0 then
    return wf
  end
  return nil
end

local function GetWellFedExpire()
  local wfIDs = GetWellFedIDs()
  if not wfIDs then
    return nil
  end
  return ns.GetPlayerBuffExpire and ns.GetPlayerBuffExpire(wfIDs, true, false) or nil
end

local function GetSlotExpire(hand)
  local hasMH, mhMs, _, _, hasOH, ohMs = GetWeaponEnchantInfo()
  local now = Now()
  if hand == "mainHand" then
    if hasMH and type(mhMs) == "number" and mhMs > 0 then
      return now + (mhMs / 1000)
    end
  else
    if hasOH and type(ohMs) == "number" and ohMs > 0 then
      return now + (ohMs / 1000)
    end
  end
  return nil
end

local function ConsumablesSuppressed()
  if ns.MPlus_DisableConsumablesActive and ns.MPlus_DisableConsumablesActive() then
    return true
  end
  local inInst = select(1, IsInInstance())
  if inInst then
    local _, _, diffID = GetInstanceInfo()
    if diffID == 8 then
      local db = DB()
      if db and db.mplusDisableConsumables == true then
        return true
      end
    end
  end
  return false
end

local pools = { FOOD = {}, FLASK = {}, MAIN_HAND = {}, OFF_HAND = {} }

local function Acquire(cat, data)
  local p = pools[cat]
  local entry = p and table.remove(p) or {}
  setmetatable(entry, nil)
  if data then
    setmetatable(entry, { __index = data })
  end
  return entry
end

local function Release(cat, entry)
  if not entry then
    return
  end
  entry.quantity, entry.itemID, entry.category = nil, nil, nil
  entry.expireTime, entry.showAt = nil, nil
  entry.cooldownStart, entry.cooldownDuration = nil, nil
  entry.macro = nil
  setmetatable(entry, nil)
  local p = pools[cat]
  if p then
    p[#p + 1] = entry
  end
end

local function applyItemCooldownFields(entry, itemID)
  local start, duration, enable = GetItemCooldown(itemID)
  if enable == 1 and duration and duration > 1.5 and start and start > 0 then
    entry.cooldownStart, entry.cooldownDuration = start, duration
  else
    entry.cooldownStart, entry.cooldownDuration = nil, nil
  end
end

local function EffectiveItemThresholdSecs()
  local baseMin = DB().itemThreshold or 15
  return (ns.MPlus_GetEffectiveThresholdSecs and ns.MPlus_GetEffectiveThresholdSecs("item", baseMin)) or (baseMin * 60)
end

local function applyThreshold(entry, expireAbs, thresholdSecs)
  local threshold = thresholdSecs or EffectiveItemThresholdSecs()
  entry.expireTime = expireAbs
  if not expireAbs then
    entry.showAt = nil
    return true
  end
  if expireAbs == math.huge then
    entry.showAt = nil
    return false
  end
  local showAt = expireAbs - threshold
  if Now() < showAt then
    entry.showAt = showAt
    return false
  end
  entry.showAt = nil
  return true
end

local function passesGates(data, playerLevel, inInstance, rested)
  return ns.PassesGates(data, playerLevel, inInstance, rested)
end

local function UpsertFoodOrFlask(cat, itemID, data, qty, wellFedExpire, flaskExpire, playerLevel, inInstance, rested)
  if ns.IsExcluded and ns.IsExcluded(itemID) then
    local map = clickableRaidBuffCache.displayable[cat]
    if map and map[itemID] then
      Release(cat, map[itemID])
      map[itemID] = nil
    end
    return
  end
  if qty <= 0 or not passesGates(data, playerLevel, inInstance, rested) then
    local map = clickableRaidBuffCache.displayable[cat]
    if map and map[itemID] then
      Release(cat, map[itemID])
      map[itemID] = nil
    end
    return
  end

  local map = clickableRaidBuffCache.displayable[cat] or {}
  clickableRaidBuffCache.displayable[cat] = map
  local entry = map[itemID]
  if not entry then
    entry = Acquire(cat, data)
    map[itemID] = entry
  else
    setmetatable(entry, nil)
    setmetatable(entry, { __index = data })
  end

  entry.itemID, entry.category, entry.quantity = itemID, cat, qty
  applyItemCooldownFields(entry, itemID)

  local expire = (cat == "FOOD") and wellFedExpire or (cat == "FLASK" and flaskExpire or nil)
  local allow = applyThreshold(entry, expire)
  if not allow then
    return
  end
end

local function UpsertWeaponEnchant(cat, itemID, data, hand, qty, playerLevel, inInstance, rested)
  local handType, enchantable = ns.WeaponEnchants_EquippedHandTypeAndEnchantable(hand)
  if not enchantable then
    local map = clickableRaidBuffCache.displayable[cat]
    if map and map[itemID] then
      Release(cat, map[itemID])
      map[itemID] = nil
    end
    return
  end
  local reqSlot = ns.WeaponEnchants_NormalizeSlotType(data and data.slotType)
  if reqSlot and handType and reqSlot ~= handType then
    local map = clickableRaidBuffCache.displayable[cat]
    if map and map[itemID] then
      Release(cat, map[itemID])
      map[itemID] = nil
    end
    return
  end

  local reqCat = data and data.weaponType
  if reqCat and not ns.WeaponEnchants_MatchesCategory(hand, reqCat) then
    local map = clickableRaidBuffCache.displayable[cat]
    if map and map[itemID] then
      Release(cat, map[itemID])
      map[itemID] = nil
    end
    return
  end

  if ns.IsExcluded and ns.IsExcluded(itemID) then
    local map = clickableRaidBuffCache.displayable[cat]
    if map and map[itemID] then
      Release(cat, map[itemID])
      map[itemID] = nil
    end
    return
  end
  if qty <= 0 or not passesGates(data, playerLevel, inInstance, rested) then
    local map = clickableRaidBuffCache.displayable[cat]
    if map and map[itemID] then
      Release(cat, map[itemID])
      map[itemID] = nil
    end
    return
  end

  local map = clickableRaidBuffCache.displayable[cat] or {}
  clickableRaidBuffCache.displayable[cat] = map
  local entry = map[itemID]
  if not entry then
    entry = Acquire(cat, data)
    map[itemID] = entry
  else
    setmetatable(entry, nil)
    setmetatable(entry, { __index = data })
  end

  entry.itemID, entry.category, entry.quantity = itemID, cat, qty
  applyItemCooldownFields(entry, itemID)

  local expire = GetSlotExpire(hand)
  local slot = (hand == "mainHand") and 16 or 17
  entry.macro = "/use item:" .. tostring(itemID) .. "\n/use " .. tostring(slot)

  local allow = applyThreshold(entry, expire)
  if not allow then
    map[itemID] = nil
    Release(cat, entry)
    return
  end
end

local _enchantNextAt
function ScheduleEnchantThresholdCheck()
  local now = Now()

  if ns._inCombat then
    if _enchantNextAt and _enchantNextAt > now then
      if After then
        After(0.30, ScheduleEnchantThresholdCheck)
      end
    end
    return
  end

  local threshold = EffectiveItemThresholdSecs()

  local function nextCross(expire)
    if not expire or expire == math.huge then
      return nil
    end
    local t = expire - threshold
    if t and t > now then
      return t
    end
    return nil
  end

  local mhExpire = GetSlotExpire("mainHand")
  local ohExpire = GetSlotExpire("offHand")

  local tNext
  local t1 = nextCross(mhExpire)
  if t1 then
    tNext = t1
  end
  local t2 = nextCross(ohExpire)
  if t2 and (not tNext or t2 < tNext) then
    tNext = t2
  end

  if tNext and (not _enchantNextAt or tNext < _enchantNextAt - 0.01) then
    _enchantNextAt = tNext
    local delay = math.max(0.01, tNext - now)
    if not After then
      return
    end
    After(delay, function()
      if ns._inCombat then
        if After then
          After(0.30, ScheduleEnchantThresholdCheck)
        end
        return
      end

      _enchantNextAt = nil
      scanAllBags()
      if ns.PushRender then
        ns.PushRender()
      end
      ScheduleEnchantThresholdCheck()
    end)
  end
end

function ns.ReapplyBagThresholds()
  local pi = clickableRaidBuffCache.playerInfo or {}
  local wf = GetWellFedExpire()
  local flask = pi.flaskExpireTime
  local threshold = EffectiveItemThresholdSecs()

  local mapF = clickableRaidBuffCache.displayable.FOOD or {}
  for _, entry in pairs(mapF) do
    applyThreshold(entry, wf, threshold)
  end

  local mapPh = clickableRaidBuffCache.displayable.FLASK or {}
  for _, entry in pairs(mapPh) do
    applyThreshold(entry, flask, threshold)
  end

  local mhMap = clickableRaidBuffCache.displayable.MAIN_HAND or {}
  local ohMap = clickableRaidBuffCache.displayable.OFF_HAND or {}

  local mhExpire = GetSlotExpire("mainHand")
  local ohExpire = GetSlotExpire("offHand")

  local purgeMH, purgeOH = {}, {}
  for itemID, entry in pairs(mhMap) do
    if not applyThreshold(entry, mhExpire, threshold) then
      purgeMH[#purgeMH + 1] = itemID
    end
  end
  for itemID, entry in pairs(ohMap) do
    if not applyThreshold(entry, ohExpire, threshold) then
      purgeOH[#purgeOH + 1] = itemID
    end
  end
  for i = 1, #purgeMH do
    local id = purgeMH[i]
    Release("MAIN_HAND", mhMap[id])
    mhMap[id] = nil
  end
  for i = 1, #purgeOH do
    local id = purgeOH[i]
    Release("OFF_HAND", ohMap[id])
    ohMap[id] = nil
  end

  ScheduleEnchantThresholdCheck()
end

function scanAllBags()
  if ConsumablesSuppressed() then
    local d = clickableRaidBuffCache.displayable
    d.FOOD, d.FLASK, d.MAIN_HAND, d.OFF_HAND = {}, {}, {}, {}
    return
  end

  local playerLevel = clickableRaidBuffCache.playerInfo.playerLevel or UnitLevel("player") or 999
  local inInstance = clickableRaidBuffCache.playerInfo.inInstance or select(1, IsInInstance())
  local rested = clickableRaidBuffCache.playerInfo.restedXPArea or IsResting()
  local FOOD = ClickableRaidData and ClickableRaidData["FOOD"] or nil
  local FLASK = ClickableRaidData and ClickableRaidData["FLASK"] or nil
  local MH = ClickableRaidData and ClickableRaidData["MAIN_HAND"] or nil
  local OH = ClickableRaidData and ClickableRaidData["OFF_HAND"] or nil

  local dirty, haveDirty = {}, false
  if ns.ConsumeDirtyBags then
    haveDirty = (ns.ConsumeDirtyBags(dirty) or 0) > 0
  end
  if not haveDirty then
    for b = 0, NUM_BAG_SLOTS do
      dirty[b] = true
    end
  end

  local seen = {}
  for bagID in pairs(dirty) do
    local numSlots = C_Container.GetContainerNumSlots(bagID)
    if numSlots and numSlots > 0 then
      for slot = 1, numSlots do
        local itemID = C_Container.GetContainerItemID(bagID, slot)
        if itemID then
          seen[itemID] = true
        end
      end
    end
  end

  -- Incremental dirty-bag scans can miss tracked items that sit in untouched bags.
  -- Include known tracked IDs so oils/weapon buffs remain discoverable on partial updates.
  if haveDirty then
    local function markKnown(tbl)
      if type(tbl) ~= "table" then
        return
      end
      for itemID in pairs(tbl) do
        if type(itemID) == "number" then
          seen[itemID] = true
        end
      end
    end
    markKnown(FOOD)
    markKnown(FLASK)
    markKnown(MH)
    markKnown(OH)
  end

  local count = {}
  for itemID in pairs(seen) do
    count[itemID] = C_Item.GetItemCount(itemID, false, false, false, false) or 0
  end

  local wfExpire = GetWellFedExpire()
  local flaskExpire = clickableRaidBuffCache.playerInfo.flaskExpireTime

  local touched = { FOOD = {}, FLASK = {}, MAIN_HAND = {}, OFF_HAND = {} }

  for itemID in pairs(seen) do
    local qty = count[itemID] or 0
    local foodRow = FOOD and FOOD[itemID]
    if foodRow and (not ns.IsExpansionEnabled or ns.IsExpansionEnabled(foodRow.expansionId)) then
      UpsertFoodOrFlask("FOOD", itemID, foodRow, qty, wfExpire, flaskExpire, playerLevel, inInstance, rested)
      touched.FOOD[itemID] = true
    end
    local flaskRow = FLASK and FLASK[itemID]
    if flaskRow and (not ns.IsExpansionEnabled or ns.IsExpansionEnabled(flaskRow.expansionId)) then
      UpsertFoodOrFlask("FLASK", itemID, flaskRow, qty, wfExpire, flaskExpire, playerLevel, inInstance, rested)
      touched.FLASK[itemID] = true
    end
    local mhRow = MH and MH[itemID]
    if mhRow and (not ns.IsExpansionEnabled or ns.IsExpansionEnabled(mhRow.expansionId)) then
      UpsertWeaponEnchant("MAIN_HAND", itemID, mhRow, "mainHand", qty, playerLevel, inInstance, rested)
      touched.MAIN_HAND[itemID] = true
    end
    local ohRow = OH and OH[itemID]
    if ohRow and (not ns.IsExpansionEnabled or ns.IsExpansionEnabled(ohRow.expansionId)) then
      UpsertWeaponEnchant("OFF_HAND", itemID, ohRow, "offHand", qty, playerLevel, inInstance, rested)
      touched.OFF_HAND[itemID] = true
    end
  end

  local disp = clickableRaidBuffCache.displayable
  local sourceByCat = { FOOD = FOOD, FLASK = FLASK, MAIN_HAND = MH, OFF_HAND = OH }
  for cat, mark in pairs(touched) do
    local map = disp[cat]
    if map then
      for itemID, entry in pairs(map) do
        if not mark[itemID] and not (ns.IsExcluded and ns.IsExcluded(itemID)) then
          local src = sourceByCat[cat]
          local row = src and src[itemID]
          if row and ns.IsExpansionEnabled and not ns.IsExpansionEnabled(row.expansionId) then
            map[itemID] = nil
            Release(cat, entry)
          else
            local qty = count[itemID]
            if qty == nil then
              qty = C_Item.GetItemCount(itemID, false, false, false, false) or 0
            end
            if qty <= 0 then
              map[itemID] = nil
              Release(cat, entry)
            end
          end
        end
      end
    end
  end

  ScheduleEnchantThresholdCheck()
end

function markBagsForScan(bagID)
  if ns.MarkBagsDirty then
    ns.MarkBagsDirty(bagID)
  end
  if ns.PokeUpdateBus then
    ns.PokeUpdateBus()
  end
end

function processPendingBags()
  scanAllBags()
end
