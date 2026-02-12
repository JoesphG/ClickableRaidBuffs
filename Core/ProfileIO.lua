-- ====================================
-- \Core\ProfileIO.lua
-- ====================================

local addonName, ns = ...
ns = ns or {}

local SCHEMA_VERSION = 1
local MAX_DEPTH = 12
local MAX_NODES = 20000

local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local b64lookup = {}
for i = 1, #b64chars do
  b64lookup[b64chars:sub(i, i)] = i - 1
end

local function DB()
  return (ns.GetDB and ns.GetDB()) or _G.ClickableRaidBuffsDB or {}
end

local function copyTable(t, seen, depth)
  if type(t) ~= "table" then
    return t
  end
  if depth > MAX_DEPTH then
    return {}
  end
  seen = seen or {}
  if seen[t] then
    return {}
  end
  seen[t] = true
  local o = {}
  for k, v in pairs(t) do
    local kt = type(k)
    if kt == "string" or kt == "number" then
      if type(v) == "table" then
        o[k] = copyTable(v, seen, depth + 1)
      elseif type(v) == "string" or type(v) == "number" or type(v) == "boolean" or v == nil then
        o[k] = v
      end
    end
  end
  return o
end

local function sortedKeys(t)
  local ks = {}
  for k in pairs(t) do
    ks[#ks + 1] = k
  end
  table.sort(ks, function(a, b)
    local ta, tb = type(a), type(b)
    if ta ~= tb then
      return ta < tb
    end
    if ta == "number" then
      return a < b
    end
    return tostring(a) < tostring(b)
  end)
  return ks
end

local function serialize(v)
  local tv = type(v)
  if tv == "nil" then
    return "nil"
  elseif tv == "number" then
    return tostring(v)
  elseif tv == "boolean" then
    return v and "true" or "false"
  elseif tv == "string" then
    return string.format("%q", v)
  elseif tv == "table" then
    local out = { "{" }
    local first = true
    for _, k in ipairs(sortedKeys(v)) do
      local key
      if type(k) == "number" then
        key = "[" .. tostring(k) .. "]"
      else
        key = "[" .. string.format("%q", k) .. "]"
      end
      local val = serialize(v[k])
      if val then
        if not first then
          out[#out + 1] = ","
        end
        first = false
        out[#out + 1] = key .. "=" .. val
      end
    end
    out[#out + 1] = "}"
    return table.concat(out)
  end
  return nil
end

local function deserialize(s)
  if type(s) ~= "string" or s == "" then
    return nil, "empty"
  end
  local chunk, err = loadstring("return " .. s)
  if not chunk then
    return nil, err or "parse failed"
  end
  if setfenv then
    setfenv(chunk, {})
  end
  local ok, value = pcall(chunk)
  if not ok then
    return nil, tostring(value)
  end
  return value
end

local function checksum32(s)
  local sum = 0
  for i = 1, #s do
    sum = (sum + string.byte(s, i)) % 4294967296
  end
  return sum
end

local function toBase64(data)
  local bytes = { string.byte(data, 1, #data) }
  local out = {}
  for i = 1, #bytes, 3 do
    local b1 = bytes[i] or 0
    local b2 = bytes[i + 1] or 0
    local b3 = bytes[i + 2] or 0
    local n = b1 * 65536 + b2 * 256 + b3
    local c1 = math.floor(n / 262144) % 64 + 1
    local c2 = math.floor(n / 4096) % 64 + 1
    local c3 = math.floor(n / 64) % 64 + 1
    local c4 = n % 64 + 1
    out[#out + 1] = b64chars:sub(c1, c1)
    out[#out + 1] = b64chars:sub(c2, c2)
    out[#out + 1] = (bytes[i + 1] and b64chars:sub(c3, c3)) or "="
    out[#out + 1] = (bytes[i + 2] and b64chars:sub(c4, c4)) or "="
  end
  return table.concat(out)
end

local function fromBase64(s)
  local cleaned = s:gsub("%s+", "")
  if cleaned == "" then
    return nil, "empty"
  end
  local out = {}
  for i = 1, #cleaned, 4 do
    local c1 = cleaned:sub(i, i)
    local c2 = cleaned:sub(i + 1, i + 1)
    local c3 = cleaned:sub(i + 2, i + 2)
    local c4 = cleaned:sub(i + 3, i + 3)

    local n1 = b64lookup[c1]
    local n2 = b64lookup[c2]
    if n1 == nil or n2 == nil then
      return nil, "invalid base64"
    end

    local n3 = (c3 == "=") and nil or b64lookup[c3]
    local n4 = (c4 == "=") and nil or b64lookup[c4]
    if (c3 ~= "=" and n3 == nil) or (c4 ~= "=" and n4 == nil) then
      return nil, "invalid base64"
    end

    local n = n1 * 262144 + n2 * 4096 + (n3 or 0) * 64 + (n4 or 0)
    local b1 = math.floor(n / 65536) % 256
    local b2 = math.floor(n / 256) % 256
    local b3 = n % 256
    out[#out + 1] = string.char(b1)
    if c3 ~= "=" then
      out[#out + 1] = string.char(b2)
    end
    if c4 ~= "=" then
      out[#out + 1] = string.char(b3)
    end
  end
  return table.concat(out)
end

local function nodeCount(t, seen)
  if type(t) ~= "table" then
    return 0
  end
  seen = seen or {}
  if seen[t] then
    return 0
  end
  seen[t] = true
  local n = 1
  for _, v in pairs(t) do
    if type(v) == "table" then
      n = n + nodeCount(v, seen)
      if n > MAX_NODES then
        return n
      end
    end
  end
  return n
end

local function collectKnownKeys()
  local out = {}
  local d = (ns.Options and ns.Options.DEFAULTS) or {}
  for k in pairs(d) do
    out[k] = true
  end
  local live = DB()
  for k in pairs(live) do
    out[k] = true
  end
  local extra = {
    exclusions = true,
    raidBuffExclusions = true,
    categoryOrder = true,
    topTextColor = true,
    bottomTextColor = true,
    timerTextColor = true,
    centerTextColor = true,
    cornerTextColor = true,
    glowColor = true,
    specialGlowColor = true,
    minimap = true,
    hunterPets = true,
    tooltips = true,
    mplusThreshold = true,
    mplusThresholdEnabled = true,
    mplusDisableConsumables = true,
    spellThreshold = true,
    itemThreshold = true,
    durabilityThreshold = true,
    healthstoneThreshold = true,
    soulstoneThreshold = true,
  }
  for k, v in pairs(extra) do
    out[k] = v
  end
  return out
end

local function sanitizeProfile(input, knownKeys)
  local dropped = 0
  local function walk(v, depth, root)
    local tv = type(v)
    if tv == "string" or tv == "number" or tv == "boolean" or tv == "nil" then
      return v
    end
    if tv ~= "table" then
      dropped = dropped + 1
      return nil
    end
    if depth > MAX_DEPTH then
      dropped = dropped + 1
      return nil
    end
    local o = {}
    for k, vv in pairs(v) do
      local kt = type(k)
      if kt == "string" or kt == "number" then
        if root and kt == "string" and knownKeys and not knownKeys[k] then
          dropped = dropped + 1
        else
          local sv = walk(vv, depth + 1, false)
          if sv ~= nil then
            o[k] = sv
          end
        end
      else
        dropped = dropped + 1
      end
    end
    return o
  end
  local out = walk(input, 0, true) or {}
  return out, dropped
end

local function diffCount(a, b)
  local changed = 0
  local function walk(x, y)
    local tx, ty = type(x), type(y)
    if tx ~= ty then
      changed = changed + 1
      return
    end
    if tx ~= "table" then
      if x ~= y then
        changed = changed + 1
      end
      return
    end
    local seen = {}
    for k, xv in pairs(x) do
      seen[k] = true
      walk(xv, y[k])
    end
    for k, yv in pairs(y) do
      if not seen[k] then
        walk(nil, yv)
      end
    end
  end
  walk(a or {}, b or {})
  return changed
end

local function applyReplace(profile)
  _G.ClickableRaidBuffsDB = copyTable(profile, nil, 0)
end

function ns.Profile_Export()
  local profile = copyTable(DB(), nil, 0)
  local profileRaw = serialize(profile) or "{}"
  local payload = {
    schemaVersion = SCHEMA_VERSION,
    addonVersion = (GetAddOnMetadata and GetAddOnMetadata(addonName, "Version")) or "unknown",
    timestamp = date("%Y-%m-%d %H:%M:%S"),
    profile = profile,
    checksum = checksum32(profileRaw),
  }
  local raw = serialize(payload)
  if not raw then
    return nil, "serialize_failed"
  end
  return "CRB1:" .. toBase64(raw)
end

function ns.Profile_ImportPreview(rawText)
  if type(rawText) ~= "string" or rawText == "" then
    return nil, "empty"
  end
  local body = rawText:gsub("^%s+", ""):gsub("%s+$", "")
  body = body:gsub("^CRB1:", "")
  local decoded, derr = fromBase64(body)
  if not decoded then
    return nil, derr or "decode_failed"
  end
  local payload, perr = deserialize(decoded)
  if type(payload) ~= "table" then
    return nil, perr or "invalid_payload"
  end
  if type(payload.schemaVersion) ~= "number" then
    return nil, "missing_schema"
  end
  if payload.schemaVersion > SCHEMA_VERSION then
    return nil, "future_schema"
  end
  if type(payload.profile) ~= "table" then
    return nil, "missing_profile"
  end
  if type(payload.checksum) == "number" then
    local got = checksum32(serialize(payload.profile) or "{}")
    if got ~= payload.checksum then
      return nil, "checksum_mismatch"
    end
  end
  if nodeCount(payload.profile) > MAX_NODES then
    return nil, "profile_too_large"
  end
  local known = collectKnownKeys()
  local sanitized, dropped = sanitizeProfile(payload.profile, known)
  local changes = diffCount(DB(), sanitized)
  return {
    schemaVersion = payload.schemaVersion,
    addonVersion = payload.addonVersion or "unknown",
    timestamp = payload.timestamp or "unknown",
    dropped = dropped,
    changes = changes,
    profile = sanitized,
  }
end

function ns.Profile_Import(rawText)
  local preview, err = ns.Profile_ImportPreview(rawText)
  if not preview then
    return nil, err
  end

  _G.ClickableRaidBuffsDB_BackupLastImport = copyTable(DB(), nil, 0)
  applyReplace(preview.profile)

  if ns.Exclusions and ns.Exclusions.MarkDirty then
    ns.Exclusions.MarkDirty()
  end
  if ns.MarkOptionsDirty then
    ns.MarkOptionsDirty()
  end
  if ns.PokeUpdateBus then
    ns.PokeUpdateBus()
  elseif ns.RequestRebuild then
    ns.RequestRebuild()
  end
  if ns.SyncOptions then
    ns.SyncOptions()
  end

  return {
    mode = "replace",
    changes = preview.changes,
    dropped = preview.dropped,
    schemaVersion = preview.schemaVersion,
  }
end
