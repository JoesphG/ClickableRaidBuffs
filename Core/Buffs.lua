-- ====================================
-- \Core\Buffs.lua
-- ====================================

local addonName, ns = ...

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

function ns.GetPlayerBuffExpire(spellIDs, nameMode, infinite)
    local function safeExpiration(aura)
        if not aura then return nil end
        local exp = aura.expirationTime
        if infinite or exp == 0 then
            return math.huge
        end
        return exp
    end

    if nameMode then
        local nameLookup = BuildNameLookup(spellIDs)
        if not nameLookup then return nil end
        local index = 1
        while true do
            local aura = C_UnitAuras.GetAuraDataByIndex("player", index, "HELPFUL")
            if not aura then break end

            if aura.name and type(aura.name) == "string"
               and nameLookup[aura.name]
               and type(aura.spellId) == "number"
               and not NAME_MODE_EXCLUDE[aura.spellId]
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
            if not aura then break end

            local sid = aura.spellId
            if type(sid) == "number" and spellLookup[sid] then
                return safeExpiration(aura)
            end

            index = index + 1
        end
    end

    return nil
end

local function GetGroupUnits()
    local units = {}

    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            units[#units+1] = "raid"..i
        end
    elseif IsInGroup() then
        for i = 1, GetNumGroupMembers() - 1 do
            units[#units+1] = "party"..i
        end
        units[#units+1] = "player"
    else
        units[#units+1] = "player"
    end

    return units
end

function ns.GetRaidBuffExpire(spellIDs, nameMode, infinite)
    local spellLookup, nameLookup
    if nameMode then
        nameLookup = BuildNameLookup(spellIDs)
        if not nameLookup then return nil end
    else
        spellLookup = {}
        for _, id in ipairs(spellIDs or {}) do
            spellLookup[id] = true
        end
    end

    local earliest = nil
    for _, unit in ipairs(GetGroupUnits()) do
        local found = false
        local idx = 1
        while true do
            local aura = C_UnitAuras.GetAuraDataByIndex(unit, idx, "HELPFUL")
            if not aura then break end

            local sid = aura.spellId
            if type(sid) == "number" then
                if nameMode then
                    if aura.name and type(aura.name) == "string"
                       and nameLookup[aura.name]
                       and not NAME_MODE_EXCLUDE[sid]
                    then
                        found = true
                        local exp = (infinite or aura.expirationTime == 0) and math.huge or aura.expirationTime
                        if not earliest or exp < earliest then
                            earliest = exp
                        end
                        break
                    end
                else
                    if spellLookup[sid] then
                        found = true
                        local exp = (infinite or aura.expirationTime == 0) and math.huge or aura.expirationTime
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
    local units = {}

    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            units[#units+1] = "raid"..i
        end
    else
        for i = 1, GetNumSubgroupMembers() do
            units[#units+1] = "party"..i
        end
        units[#units+1] = "player"
    end

    local spellLookup, nameLookup
    if nameMode then
        nameLookup = BuildNameLookup(spellIDs)
        if not nameLookup then return nil end
    else
        spellLookup = {}
        for _, id in ipairs(spellIDs or {}) do
            spellLookup[id] = true
        end
    end

    for _, unit in ipairs(units) do
        local idx = 1
        while true do
            local aura = C_UnitAuras.GetAuraDataByIndex(unit, idx, "HELPFUL")
            if not aura then break end

            if type(aura.spellId) == "number"
               and UnitGUID(aura.sourceUnit) == playerGUID
            then
                if nameMode then
                    if aura.name and type(aura.name) == "string"
                       and nameLookup[aura.name]
                       and not NAME_MODE_EXCLUDE[aura.spellId]
                    then
                        return infinite or aura.expirationTime == 0 and math.huge or aura.expirationTime
                    end
                else
                    if spellLookup[aura.spellId] then
                        return infinite or aura.expirationTime == 0 and math.huge or aura.expirationTime
                    end
                end
            end

            idx = idx + 1
        end
    end

    return nil
end
 