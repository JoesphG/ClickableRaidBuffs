-- ====================================
-- \Options\Panel.lua
-- ====================================

local addonName, ns = ...
ns.Options = ns.Options or {}
local O = ns.Options
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

O.LABEL_LEFT_X = O.LABEL_LEFT_X or 12
O.ROW_LEFT_PAD = O.ROW_LEFT_PAD or 10
O.ROW_RIGHT_PAD = O.ROW_RIGHT_PAD or 10
O.ROW_V_GAP = O.ROW_V_GAP or 10
O.SECTION_GAP = O.SECTION_GAP or 12
O.SECTION_CONTENT_TOP_PAD = O.SECTION_CONTENT_TOP_PAD or 36
O.PAGE_CONTENT_TOP_PAD = O.PAGE_CONTENT_TOP_PAD or 0

O.PANEL_FONT_NAME = O.PANEL_FONT_NAME or "FiraSans-Regular"
O.TITLE_FONT_NAME = O.TITLE_FONT_NAME or "FiraSans-ExtraBoldItalic"
O.AUTHOR_LABEL_FONT_NAME = O.AUTHOR_LABEL_FONT_NAME or "FiraSans-Medium"
O.LABEL_ITALIC_FONT_NAME = O.LABEL_ITALIC_FONT_NAME or "FiraSans-Italic"

O.SIZE_TITLE = O.SIZE_TITLE or 50
O.SIZE_SECTION_HEAD = O.SIZE_SECTION_HEAD or 20
O.SIZE_LABEL = O.SIZE_LABEL or 14
O.SIZE_COPY_LABEL = O.SIZE_COPY_LABEL or 10
O.SIZE_EDITBOX = O.SIZE_EDITBOX or 14
O.SIZE_TAB_LABEL = O.SIZE_TAB_LABEL or 15

O.RESET_W = O.RESET_W or 60
O.RESET_H = O.RESET_H or 30

O.AUTHOR_LABEL_TEXT = O.AUTHOR_LABEL_TEXT or "By |cffff7d0FFunki|r"
O.AUTHOR_LABEL_SIZE = O.AUTHOR_LABEL_SIZE or 17
O.AUTHOR_LABEL_X = O.AUTHOR_LABEL_X or 335
O.AUTHOR_LABEL_Y = O.AUTHOR_LABEL_Y or -55
O.WEBSITE_LABEL_TEXT = O.WEBSITE_LABEL_TEXT or "Website"
O.SUPPORT_LABEL_TEXT = O.SUPPORT_LABEL_TEXT or "Report Bugs and Get Support"

O.TAB_HEIGHT = O.TAB_HEIGHT or 24
O.TAB_COUNT = O.TAB_COUNT or 6

local function GetFontPathByName(name)
  if LSM and LSM.Fetch and name then
    local p = LSM:Fetch("font", name, true)
    if p then
      return p
    end
  end
  local fallback = GameFontNormal and select(1, GameFontNormal:GetFont())
  return fallback or "Fonts\\FRIZQT__.TTF"
end
O.GetFontPathByName = GetFontPathByName

function O.ResolvePanelFont()
  return GetFontPathByName(O.PANEL_FONT_NAME) or "Fonts\\FRIZQT__.TTF"
end

O._sections = O._sections or {}
function O.RegisterSection(builder)
  if type(builder) == "function" then
    O._sections[#O._sections + 1] = builder
  end
end

local panel = CreateFrame("Frame", addonName .. "OptionsPanel", UIParent, "BackdropTemplate")
panel.name = "Clickable Raid Buffs"
ns.OptionsFrame = panel
panel:SetFrameStrata("DIALOG")
panel:SetToplevel(true)
panel:SetClampedToScreen(true)
panel:EnableMouse(true)
panel:SetMovable(true)
panel:SetResizable(true)
if panel.SetResizeBounds then
  panel:SetResizeBounds(820, 620)
elseif panel.SetMinResize then
  panel:SetMinResize(820, 620)
end
panel:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8x8",
  edgeFile = "Interface\\Buttons\\WHITE8x8",
  edgeSize = 1,
  insets = { left = 1, right = 1, top = 1, bottom = 1 },
})
panel:SetBackdropColor(0.03, 0.04, 0.06, 0.98)
panel:SetBackdropBorderColor(0.23, 0.26, 0.34, 1)
panel:Hide()
if type(UISpecialFrames) == "table" then
  table.insert(UISpecialFrames, panel:GetName())
end

local function GetWindowState()
  local db = (ns.GetDB and ns.GetDB()) or ClickableRaidBuffsDB
  db = type(db) == "table" and db or {}
  db.optionsWindow = type(db.optionsWindow) == "table" and db.optionsWindow or {}
  local wnd = db.optionsWindow
  local defaults = (O.DEFAULTS and O.DEFAULTS.optionsWindow) or {}
  wnd.width = tonumber(wnd.width) or defaults.width or 940
  wnd.height = tonumber(wnd.height) or defaults.height or 720
  wnd.point = tostring(wnd.point or defaults.point or "CENTER")
  wnd.x = tonumber(wnd.x) or defaults.x or 0
  wnd.y = tonumber(wnd.y) or defaults.y or 0
  return wnd
end

local function SaveWindowState()
  local db = (ns.GetDB and ns.GetDB()) or ClickableRaidBuffsDB
  if type(db) ~= "table" then
    return
  end
  db.optionsWindow = db.optionsWindow or {}
  local wnd = db.optionsWindow
  local point, _, _, x, y = panel:GetPoint(1)
  wnd.point = point or "CENTER"
  wnd.x = tonumber(x) or 0
  wnd.y = tonumber(y) or 0
  wnd.width = math.floor((panel:GetWidth() or 940) + 0.5)
  wnd.height = math.floor((panel:GetHeight() or 720) + 0.5)
end

do
  local wnd = GetWindowState()
  panel:SetSize(wnd.width, wnd.height)
  panel:ClearAllPoints()
  panel:SetPoint(wnd.point, UIParent, wnd.point, wnd.x, wnd.y)
end

panel:SetScript("OnHide", SaveWindowState)

local closeBtn = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -4, -4)

local dragHandle = CreateFrame("Frame", nil, panel)
dragHandle:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -8)
dragHandle:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -34, -8)
dragHandle:SetHeight(28)
dragHandle:EnableMouse(true)
dragHandle:RegisterForDrag("LeftButton")
dragHandle:SetScript("OnDragStart", function()
  panel:StartMoving()
end)
dragHandle:SetScript("OnDragStop", function()
  panel:StopMovingOrSizing()
  SaveWindowState()
end)

local windowTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
windowTitle:SetPoint("LEFT", dragHandle, "LEFT", 6, 0)
windowTitle:SetText("Clickable Raid Buffs")

local resizeGrip = CreateFrame("Button", nil, panel)
resizeGrip:SetSize(16, 16)
resizeGrip:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -4, 4)
resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
resizeGrip:SetScript("OnMouseDown", function()
  panel:StartSizing("BOTTOMRIGHT")
end)
resizeGrip:SetScript("OnMouseUp", function()
  panel:StopMovingOrSizing()
  SaveWindowState()
end)

local settingsCategory
local settingsProxy = CreateFrame("Frame", addonName .. "OptionsSettingsProxy", UIParent)
settingsProxy.name = panel.name
settingsProxy:SetScript("OnShow", function(self)
  if self._built then
    return
  end
  self._built = true

  local title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOP", self, "TOP", 0, -22)
  title:SetFontObject("GameFontNormalHuge")
  title:SetText("|cff00ccffClickable Raid Buffs|r |cffff7d0Ffunki.gg|r")
  title:SetJustifyH("CENTER")

  local logo = self:CreateTexture(nil, "ARTWORK")
  logo:SetSize(192, 192)
  logo:SetPoint("TOP", title, "BOTTOM", 0, -14)
  logo:SetTexture("Interface\\AddOns\\ClickableRaidBuffs\\Media\\funkiggLogo")

  local shortcutLine = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  shortcutLine:SetPoint("TOP", logo, "BOTTOM", 0, -10)
  shortcutLine:SetWidth(760)
  shortcutLine:SetJustifyH("CENTER")
  shortcutLine:SetFontObject("GameFontNormalHuge")
  shortcutLine:SetText("|cff00e5ff/crb      /buff      /funki|r")

  local desc = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  desc:SetWidth(620)
  desc:SetPoint("CENTER", self, "CENTER", 0, -78)
  desc:SetJustifyH("LEFT")
  desc:SetFontObject("GameFontNormalLarge")
  desc:SetText(
    "Commands:\n"
      .. "  |cff00e5ff/crb /buff /funki|r |cffffa500unlock|r  -  Toggle icon lock\n"
      .. "  |cff00e5ff/crb /buff /funki|r |cffffa500lock|r  -  Toggle icon lock\n"
      .. "  |cff00e5ff/crb /buff /funki|r |cffffa500minimap|r  -  Toggle minimap icon\n"
      .. "  |cff00e5ff/crb /buff /funki|r |cffffa500reset|r  -  Reset all settings to default and reload UI\n"
      .. "  |cff00e5ff/crb /buff /funki|r |cffffa500debug|r  -  Print hidden raid buff reasons"
  )

  local openBtn = CreateFrame("Button", nil, self, "BackdropTemplate")
  openBtn:SetSize(220, 42)
  openBtn:SetPoint("TOP", desc, "BOTTOM", 0, -18)
  openBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
  openBtn:SetBackdropColor(0.15, 0.20, 0.29, 1)
  openBtn:SetBackdropBorderColor(0.30, 0.45, 0.66, 1)
  local openLabel = openBtn:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  openLabel:SetPoint("CENTER")
  openLabel:SetText("Options")
  openLabel:SetFontObject("GameFontNormalLarge")
  openLabel:SetTextColor(0.90, 0.95, 1.00, 1)
  openBtn:SetScript("OnEnter", function(btn)
    btn:SetBackdropColor(0.19, 0.28, 0.40, 1)
  end)
  openBtn:SetScript("OnLeave", function(btn)
    btn:SetBackdropColor(0.15, 0.20, 0.29, 1)
  end)
  openBtn:SetScript("OnMouseDown", function(btn)
    btn:SetBackdropColor(0.12, 0.17, 0.25, 1)
  end)
  openBtn:SetScript("OnMouseUp", function(btn)
    if btn:IsMouseOver() then
      btn:SetBackdropColor(0.19, 0.28, 0.40, 1)
    else
      btn:SetBackdropColor(0.15, 0.20, 0.29, 1)
    end
  end)
  openBtn:SetScript("OnClick", function()
    if ns and ns.OpenOptions then
      ns.OpenOptions()
    end
  end)

end)

if Settings and Settings.RegisterCanvasLayoutCategory then
  settingsCategory = Settings.RegisterCanvasLayoutCategory(settingsProxy, settingsProxy.name)
  Settings.RegisterAddOnCategory(settingsCategory)
elseif InterfaceOptions_AddCategory then
  InterfaceOptions_AddCategory(settingsProxy)
end

ns.OpenOptions = function()
  if InCombatLockdown and InCombatLockdown() then
    UIErrorsFrame:AddMessage("Cannot open Clickable Raid Buffs options in combat.", 1, 0.2, 0.2, 1)
    return
  end
  panel:Show()
  panel:Raise()
  if ns.SyncOptions then
    ns.SyncOptions()
  end
end

ns.CloseOptions = function()
  if panel and panel:IsShown() then
    panel:Hide()
  end
end

ns.ToggleOptions = function()
  if panel and panel:IsShown() then
    ns.CloseOptions()
  else
    ns.OpenOptions()
  end
end
O.OpenOptions = ns.OpenOptions

local combatHider = CreateFrame("Frame")
combatHider:RegisterEvent("PLAYER_REGEN_DISABLED")
combatHider:SetScript("OnEvent", function()
  if panel and panel:IsShown() then
    ns.CloseOptions()
  end
end)

local TAB_CFG = {
  h = O.TAB_HEIGHT or 24,
  padX = 10,
  gap = 8,
  bg = { 0.10, 0.11, 0.15, 1 },
  border = { 0.22, 0.24, 0.30, 1 },
  borderHover = { 0.35, 0.80, 1.00, 1 },
  bgSel = { 0.14, 0.16, 0.22, 1 },
  borderSel = { 0.20, 0.65, 1.00, 1 },
  text = { 0.85, 0.90, 1.00, 1 },
  textSel = { 1.00, 1.00, 1.00, 1 },
}

local function StyleTab(btn, selected)
  if not btn.bg then
    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
  end
  if selected then
    btn.bg:SetColorTexture(unpack(TAB_CFG.bgSel))
    btn:SetBackdropBorderColor(unpack(TAB_CFG.borderSel))
    btn.txt:SetTextColor(unpack(TAB_CFG.textSel))
  else
    btn.bg:SetColorTexture(unpack(TAB_CFG.bg))
    btn:SetBackdropBorderColor(unpack(TAB_CFG.border))
    btn.txt:SetTextColor(unpack(TAB_CFG.text))
  end
end

local function ApplyTabOrder(collected)
  if type(O.TAB_ORDER) ~= "table" or #O.TAB_ORDER == 0 then
    for _, it in ipairs(collected) do
      it.tabLabel = it.title
    end
    return collected
  end
  local byMatch = {}
  for idx, spec in ipairs(O.TAB_ORDER) do
    if type(spec) == "table" and spec.match then
      byMatch[spec.match] = { idx = idx, text = spec.text }
    elseif type(spec) == "string" then
      byMatch[spec] = { idx = idx, text = spec }
    end
  end
  table.sort(collected, function(a, b)
    local aa = byMatch[a.title] and byMatch[a.title].idx or math.huge
    local bb = byMatch[b.title] and byMatch[b.title].idx or math.huge
    if aa ~= bb then
      return aa < bb
    end
    return a._order < b._order
  end)
  for _, it in ipairs(collected) do
    local spec = byMatch[it.title]
    it.tabLabel = (spec and spec.text and spec.text ~= "") and spec.text or it.title
  end
  return collected
end

local function Build()
  if panel._built then
    return
  end
  panel._built = true

  local card = CreateFrame("Frame", nil, panel, "BackdropTemplate")
  card:SetPoint("TOPLEFT", 8, -8)
  card:SetPoint("BOTTOMRIGHT", -8, 8)
  card:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
  })
  card:SetBackdropColor(0.06, 0.07, 0.10, 0.96)
  card:SetBackdropBorderColor(0.18, 0.20, 0.26, 1)

  local body = CreateFrame("Frame", addonName .. "OptionsBody", card)
  body:SetPoint("TOPLEFT", 10, -10)
  body:SetPoint("BOTTOMRIGHT", -10, 10)

  local titleBox
  do
    titleBox = CreateFrame("Frame", nil, body, "BackdropTemplate")
    titleBox:SetPoint("TOPLEFT", 0, 0)
    titleBox:SetPoint("RIGHT", 0, 0)
    titleBox:SetBackdrop({
      bgFile = "Interface\\Buttons\\WHITE8x8",
      edgeFile = "Interface\\Buttons\\WHITE8x8",
      edgeSize = 1,
    })
    titleBox:SetBackdropColor(0.09, 0.10, 0.14, 0.95)
    titleBox:SetBackdropBorderColor(0.20, 0.22, 0.28, 1)

    local content = CreateFrame("Frame", nil, titleBox)
    local topPadTitle = O.SECTION_CONTENT_TOP_PAD
    content:SetPoint("TOPLEFT", O.ROW_LEFT_PAD, -topPadTitle)
    content:SetPoint("TOPRIGHT", -O.ROW_RIGHT_PAD, -topPadTitle)

    local contentY, last = 0, nil
    local function Row(h)
      local r = CreateFrame("Frame", nil, content)
      local hh = h or 36
      r:SetHeight(hh)
      r:SetPoint("LEFT")
      r:SetPoint("RIGHT")
      if not last then
        r:SetPoint("TOP", content, "TOP", 0, 0)
      else
        r:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -O.ROW_V_GAP)
      end
      contentY = contentY + hh + (last and O.ROW_V_GAP or 0)
      last = r
      return r
    end

    if #O._sections >= 1 then
      local titleBuilder = O._sections[1]
      titleBuilder(function(_, inner)
        inner(content, Row)
      end)
    end

    local height = O.SECTION_CONTENT_TOP_PAD + contentY + 12
    titleBox:SetHeight(height)
    content:SetHeight(contentY)
  end

  local tabsBar = CreateFrame("Frame", nil, body)
  tabsBar:SetPoint("TOPLEFT", 0, -titleBox:GetHeight() - O.SECTION_GAP)
  tabsBar:SetPoint("TOPRIGHT", 0, -titleBox:GetHeight() - O.SECTION_GAP)
  tabsBar:SetHeight(TAB_CFG.h)

  local pagesHolder = CreateFrame("Frame", nil, body, "BackdropTemplate")
  pagesHolder:SetPoint("TOPLEFT", tabsBar, "BOTTOMLEFT", 0, 0)
  pagesHolder:SetPoint("TOPRIGHT", tabsBar, "BOTTOMRIGHT", 0, 0)
  pagesHolder:SetPoint("BOTTOMRIGHT", 0, 0)
  pagesHolder:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
  })
  pagesHolder:SetBackdropColor(0.09, 0.10, 0.14, 0.95)
  pagesHolder:SetBackdropBorderColor(0.20, 0.22, 0.28, 1)

  local pages, tabs, current = {}, {}, 0
  local totalTabsForLayout = 0

  local function ShowPage(i)
    if i == current or not pages[i] then
      return
    end
    for k = 1, #pages do
      if pages[k] then
        pages[k]:Hide()
      end
    end
    for k = 1, #tabs do
      if tabs[k] then
        StyleTab(tabs[k], k == i)
      end
    end
    pages[i]:Show()
    current = i
  end

  local function CreateTab(parent, text, index, totalTabs)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")

    local total = tabsBar:GetWidth() or 480
    local count = math.max(1, tonumber(totalTabs) or O.TAB_COUNT or 1)
    local gaps = TAB_CFG.gap * (count - 1)
    local each = (total - gaps) / count
    local w = math.max(80, math.floor(each + 0.5))

    b:SetSize(w, TAB_CFG.h)
    b:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    b:SetBackdropColor(0, 0, 0, 0)
    b:SetBackdropBorderColor(unpack(TAB_CFG.border))

    b.bg = b:CreateTexture(nil, "BACKGROUND")
    b.bg:SetAllPoints()
    b.bg:SetColorTexture(unpack(TAB_CFG.bg))

    b.txt = b:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    b.txt:SetPoint("CENTER")
    b.txt:SetText(text or "")
    if O and O.ResolvePanelFont then
      b.txt:SetFont(O.ResolvePanelFont(), O.SIZE_TAB_LABEL or 12, "")
    end

    b:SetScript("OnClick", function()
      ShowPage(index)
    end)
    b:SetScript("OnEnter", function(self)
      if index ~= current then
        self:SetBackdropBorderColor(unpack(TAB_CFG.borderHover))
      end
    end)
    b:SetScript("OnLeave", function(self)
      StyleTab(self, index == current)
    end)
    StyleTab(b, false)
    return b
  end

  local function AddPage(sectionTitle, buildFunc, totalTabs)
    local page = CreateFrame("Frame", nil, pagesHolder)
    page:SetPoint("TOPLEFT", 0, 0)
    page:SetPoint("TOPRIGHT", 0, 0)
    page:SetPoint("BOTTOMRIGHT", 0, 0)

    local content = CreateFrame("Frame", nil, page)
    local topPadPage = O.PAGE_CONTENT_TOP_PAD or O.SECTION_CONTENT_TOP_PAD
    content:SetPoint("TOPLEFT", O.ROW_LEFT_PAD, -topPadPage)
    content:SetPoint("TOPRIGHT", -O.ROW_RIGHT_PAD, -topPadPage)
    content:SetPoint("BOTTOM", 0, 12)

    local last, contentY = nil, 0
    local function Row(h)
      local r = CreateFrame("Frame", nil, content)
      local hh = h or 36
      r:SetHeight(hh)
      r:SetPoint("LEFT")
      r:SetPoint("RIGHT")
      if not last then
        r:SetPoint("TOP", content, "TOP", 0, 0)
      else
        r:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -O.ROW_V_GAP)
      end
      contentY = contentY + hh + (last and O.ROW_V_GAP or 0)
      last = r
      return r
    end

    buildFunc(content, Row)

    local id = #pages + 1
    pages[id] = page

    local tab = CreateTab(tabsBar, sectionTitle or ("Tab " .. id), id, totalTabs)
    if id == 1 then
      tab:SetPoint("LEFT", tabsBar, "LEFT", 0, 0)
    else
      tab:SetPoint("LEFT", tabs[id - 1], "RIGHT", TAB_CFG.gap, 0)
    end

    if id == totalTabs then
      local total = tabsBar:GetWidth() or 480
      local w = tab:GetWidth()
      local used = (w + TAB_CFG.gap) * (totalTabs - 1)
      local lastW = math.max(80, total - used)
      tab:SetWidth(lastW)
    end

    tabs[id] = tab
    page:Hide()
  end

  local function RelayoutTabs()
    if #tabs == 0 then
      return
    end
    local total = tabsBar:GetWidth() or 480
    local count = math.max(1, totalTabsForLayout or #tabs)
    local gaps = TAB_CFG.gap * (count - 1)
    local each = (total - gaps) / count
    local w = math.max(80, math.floor(each + 0.5))
    for i = 1, #tabs do
      local tab = tabs[i]
      if tab then
        tab:SetHeight(TAB_CFG.h)
        tab:SetWidth(w)
        tab:ClearAllPoints()
        if i == 1 then
          tab:SetPoint("LEFT", tabsBar, "LEFT", 0, 0)
        else
          tab:SetPoint("LEFT", tabs[i - 1], "RIGHT", TAB_CFG.gap, 0)
        end
      end
    end
    if tabs[count] then
      local used = (w + TAB_CFG.gap) * (count - 1)
      local lastW = math.max(80, total - used)
      tabs[count]:SetWidth(lastW)
    end
  end

  local collected = {}
  for i = 2, #O._sections do
    local builder = O._sections[i]
    if type(builder) == "function" then
      builder(function(sectionTitle, innerBuilder)
        if sectionTitle and sectionTitle:lower():find("healthstone") then
          return
        end
        table.insert(collected, {
          title = sectionTitle or ("Tab " .. (#collected + 1)),
          build = innerBuilder,
          _order = #collected + 1,
        })
      end)
    end
  end
  ApplyTabOrder(collected)
  local totalTabs = math.max(1, #collected)
  totalTabsForLayout = totalTabs
  for _, info in ipairs(collected) do
    AddPage(info.title, info.build, totalTabs)
  end
  RelayoutTabs()
  panel._relayoutTabs = RelayoutTabs

  if #pages > 0 then
    ShowPage(1)
  end
end

panel:SetScript("OnShow", Build)
panel:HookScript("OnSizeChanged", function(_, width, height)
  if width and height and width > 0 and height > 0 then
    SaveWindowState()
  end
  if panel._relayoutTabs then
    panel._relayoutTabs()
  end
end)
  desc:SetJustifyH("LEFT")
