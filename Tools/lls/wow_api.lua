---@meta
---@diagnostic disable: undefined-doc-name

-- Minimal WoW API stubs for LuaLS. Extend as needed.

---@type table
C_Timer = C_Timer or {}
---@param delay number
---@param func fun()
function C_Timer.After(delay, func) end
---@param interval number
---@param func fun()
---@return any
function C_Timer.NewTicker(interval, func) end

---@type table
C_Item = C_Item or {}
---@param itemID number
---@param includeBank boolean
---@param includeCharges boolean
---@param includeBuyback boolean
---@param includeBags boolean
---@return number
function C_Item.GetItemCount(itemID, includeBank, includeCharges, includeBuyback, includeBags) end
---@param itemID number
---@return number
function C_Item.GetItemIconByID(itemID) end

---@type table
C_Container = C_Container or {}
---@param bagID number
---@return number
function C_Container.GetContainerNumSlots(bagID) end
---@param bagID number
---@param slotID number
---@return number|nil
function C_Container.GetContainerItemID(bagID, slotID) end

---@type table
C_UnitAuras = C_UnitAuras or {}
---@param unit string
---@param index number
---@param filter string
---@return table|nil
function C_UnitAuras.GetAuraDataByIndex(unit, index, filter) end
---@param spellID number
---@return table|nil
function C_UnitAuras.GetPlayerAuraBySpellID(spellID) end
---@param unit string
---@param auraInstanceID number
---@return table|nil
function C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraInstanceID) end

---@type table
C_Spell = C_Spell or {}
---@param spellID number|string
---@return table|nil
function C_Spell.GetSpellInfo(spellID) end
---@param spellID number|string
---@return string|nil
function C_Spell.GetSpellName(spellID) end
---@param spellID number
---@return table|nil
function C_Spell.GetSpellCooldown(spellID) end

---@type table
C_SpellBook = C_SpellBook or {}
---@param spellID number
---@return boolean|nil
function C_SpellBook.IsSpellKnown(spellID) end

---@type table
C_ChallengeMode = C_ChallengeMode or {}
---@return boolean
function C_ChallengeMode.IsChallengeModeActive() end
---@return table|nil
function C_ChallengeMode.GetMapTable() end
---@param challengeID number
---@return string|nil
function C_ChallengeMode.GetMapUIInfo(challengeID) end

---@type table
C_StableInfo = C_StableInfo or {}
---@param slotIndex number
---@return table|nil
function C_StableInfo.GetStablePetInfo(slotIndex) end

---@type table
C_MountJournal = C_MountJournal or {}
---@param mountID number
---@return ...
function C_MountJournal.GetMountInfoByID(mountID) end

---@type table
C_AddOns = C_AddOns or {}
---@param addonName string
---@return number|nil
function C_AddOns.GetAddOnInfo(addonName) end

---@type table
C_Map = C_Map or {}
---@param unit string
---@return number|nil
function C_Map.GetBestMapForUnit(unit) end

---@type table
C_ChatInfo = C_ChatInfo or {}
---@param prefix string
---@param message string
---@param channelType string
---@param target string|number|nil
function C_ChatInfo.SendAddonMessage(prefix, message, channelType, target) end

---@param frameType string
---@param name string|nil
---@param parent any|nil
---@param template string|nil
---@return any
function CreateFrame(frameType, name, parent, template) end

---@param name string
---@return any
function CreateFont(name) end

---@param itemID number
---@return number, number, number
function GetItemCooldown(itemID) end

---@return number
function GetTime() end

---@return number
function GetTimePreciseSec() end

---@param unit string
---@return number
function UnitLevel(unit) end

---@param unit string
---@return string
function UnitName(unit) end

---@param unit string
---@return boolean
function UnitExists(unit) end

---@param unit string
---@return boolean
function UnitIsDeadOrGhost(unit) end

---@param unit string
---@return boolean
function UnitIsVisible(unit) end

---@param unitA string
---@param unitB string
---@return boolean
function UnitIsUnit(unitA, unitB) end

---@param unit string
---@return string
function UnitGUID(unit) end

---@return boolean
function IsInRaid() end

---@return boolean
function IsInGroup() end

---@return boolean
function IsResting() end

---@return boolean
function InCombatLockdown() end

---@return boolean
function IsEncounterInProgress() end

---@return number
function GetNumGroupMembers() end

---@return number
function GetNumSubgroupMembers() end

---@return ...
function IsInInstance() end

---@return string, string, number, number, number, number, number, number, number
function GetInstanceInfo() end

---@param spellID number
---@return boolean
function IsPlayerSpell(spellID) end

---@param spellID number
---@return boolean
function IsSpellKnown(spellID) end

---@return number
function GetSpecialization() end

---@param specIndex number
---@return number
function GetSpecializationInfo(specIndex) end

---@return boolean, number, number, number, boolean, number
function GetWeaponEnchantInfo() end

---@param unit string
---@param slotId number
---@return string|nil
function GetInventoryItemLink(unit, slotId) end

---@param unit string
---@param slotId number
---@return number, number
function GetInventoryItemDurability(unit, slotId) end

---@param unit string
---@param slotId number
---@return number|nil
function GetInventoryItemID(unit, slotId) end

---@param name string
---@param silent boolean|nil
---@return any
function LibStub(name, silent) end

---@type number
NUM_BAG_SLOTS = NUM_BAG_SLOTS or 0

---@type string
DURABILITY = DURABILITY or "Durability"

---@type string
MINIMAP_TRACKING_REPAIR = MINIMAP_TRACKING_REPAIR or "Repair"

---@type any
UIParent = UIParent

---@type any
GameTooltip = GameTooltip

---@type any
DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME

-- Misc constants seen in data tables.
---@type string
C_FONT_NAME = C_FONT_NAME or ""
---@type string
C_UI = C_UI or {}
---@type string
C_HEALTH = C_HEALTH or ""
---@type string
C_HEALTHSTONE = C_HEALTHSTONE or ""
---@type string
C_GROUP = C_GROUP or ""
---@type string
C_N = C_N or ""

-- Lua 5.1 builtins (to reduce LLS noise in addon context).
---@type table
math = math
---@type table
string = string
---@type table
table = table

---@class stringlib
---@field format fun(self: string, ...): string
---@field gsub fun(self: string, pattern: string, repl: string): string
---@field lower fun(self: string): string
---@field match fun(self: string, pattern: string): string|nil
---@field upper fun(self: string): string
---@alias string stringlib

---@param fmt string
---@param ... any
---@return string
function string.format(fmt, ...) end

---@param value any
---@return string
function tostring(value) end
---@param value any
---@return number|nil
function tonumber(value) end
---@param value any
---@return string
function type(value) end
---@param t table
---@return any, any
function pairs(t) end
---@param t table
---@return number, any
function ipairs(t) end
---@param t table
---@param k any
---@return any, any
function next(t, k) end
---@param f function
---@param ... any
---@return boolean, ...
function pcall(f, ...) end
---@param f function
---@param msgh function
---@param ... any
---@return boolean, ...
function xpcall(f, msgh, ...) end
---@param i number
---@return any
function select(i, ...) end
---@param ... any
function print(...) end
---@param list table
---@param i number|nil
---@param j number|nil
---@return ...
function unpack(list, i, j) end
---@return number
function time() end
---@param fmt string
---@param t table|number|nil
---@return string
function date(fmt, t) end
---@param start number
---@param count number
---@param depth number
---@return string
function debugstack(start, count, depth) end
---@param t table
function wipe(t) end

---@param value any
---@return boolean
function issecretvalue(value) end

---@param ... any
---@return boolean
function hasanysecretvalues(...) end

---@type any
GameFontNormal = GameFontNormal

---@type string
TARGET = TARGET or ""

---@param name string
---@return boolean
function GetCVarBool(name) end

---@return boolean
function IsShiftKeyDown() end

---@return boolean
function IsControlKeyDown() end

---@return boolean
function IsMetaKeyDown() end

---@param t table
---@return any
function getmetatable(t) end

---@param addonName string
---@param field string
---@return string|nil
function GetAddOnMetadata(addonName, field) end

---@type table
StaticPopupDialogs = StaticPopupDialogs or {}

---@param which string
---@param text string|nil
---@param text2 string|nil
---@param data any|nil
function StaticPopup_Show(which, text, text2, data) end

---@type table
SOUNDKIT = SOUNDKIT or {}

---@param kitID number|string
---@return boolean
function PlaySound(kitID) end

---@param path string
---@param channel string|nil
---@return boolean
function PlaySoundFile(path, channel) end

---@return number, number
function GetCursorPosition() end

---@param unit string
---@return string, string, number
function UnitClass(unit) end

---@param unit string
---@return string, string
function UnitFactionGroup(unit) end

---@param spellID number
---@return number|string|nil
function GetSpellTexture(spellID) end

---@param itemID number
---@return number|string|nil
function GetItemIcon(itemID) end

---@param itemID number
---@return number, number, number, string, number, number, number
function GetItemInfoInstant(itemID) end

---@param spellID number|string
---@return string|nil
function GetSpellInfo(spellID) end

---@param unit string
---@return boolean
function UnitInParty(unit) end

---@param unit string
---@return boolean
function UnitInRaid(unit) end

---@param itemID number
---@return boolean
function IsEquippedItem(itemID) end

---@param spellID number
---@return boolean
function IsSpellKnownOrOverridesKnown(spellID) end

---@type table
C_UI = C_UI or {}

function C_UI.Reload() end

function ReloadUI() end

---@type table
Settings = Settings or {}

---@param panel any
---@return any
function Settings.RegisterCanvasLayoutCategory(panel, name) end

---@param category any
function Settings.RegisterAddOnCategory(category) end

---@param categoryID any
function Settings.OpenToCategory(categoryID) end

---@type any
SettingsPanel = SettingsPanel

---@type any
UIErrorsFrame = UIErrorsFrame

---@param msg string
---@param r number
---@param g number
---@param b number
---@param a number
function UIErrorsFrame:AddMessage(msg, r, g, b, a) end

---@type any
GameTooltipText = GameTooltipText

---@type any
GameTooltipHeaderText = GameTooltipHeaderText

---@type any
GameTooltipTextSmall = GameTooltipTextSmall

---@type any
ColorPickerFrame = ColorPickerFrame

---@return number, number, number
function ColorPickerFrame:GetColorRGB() end

---@return number
function ColorPickerFrame:GetColorAlpha() end

---@param panel any
function InterfaceOptionsFrame_OpenToCategory(panel) end

---@param frame any
function HideUIPanel(frame) end

---@type table
ORDER_DEFAULTS = ORDER_DEFAULTS or {}

---@type string
YES = YES or "YES"

---@type string
NO = NO or "NO"

---@type string
INVTYPE_TRINKET = INVTYPE_TRINKET or "INVTYPE_TRINKET"

---@type string
BLIZZARD_COMBAT_LOG_MENU_RESET = BLIZZARD_COMBAT_LOG_MENU_RESET or "Reset"

---@type table
Enum = Enum or {}

---@type table
Enum.ItemClass = Enum.ItemClass or {}

---@type number
Enum.ItemClass.Weapon = Enum.ItemClass.Weapon or 2

---@type number
LE_ITEM_CLASS_WEAPON = LE_ITEM_CLASS_WEAPON or 2

---@type table
SlashCmdList = SlashCmdList or {}
