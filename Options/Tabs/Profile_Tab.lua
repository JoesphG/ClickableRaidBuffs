-- ====================================
-- \Options\Tabs\Profile_Tab.lua
-- ====================================

local addonName, ns = ...
local O = ns.Options
local _profileApplyPending
local _profileSetText
local _profileRunExport

local function PaintBackdrop(frame, bg, br)
  frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
  frame:SetBackdropColor(unpack(bg))
  frame:SetBackdropBorderColor(unpack(br))
end

local function FontPath()
  if O and O.ResolvePanelFont then
    return O.ResolvePanelFont()
  end
  return "Fonts\\FRIZQT__.TTF"
end

StaticPopupDialogs["CRB_PROFILE_IMPORT_CONFIRM"] = StaticPopupDialogs["CRB_PROFILE_IMPORT_CONFIRM"]
  or {
    text = "%s",
    button1 = "Import",
    button2 = CANCEL,
    OnAccept = function(self, data)
      if data and type(data.run) == "function" then
        data.run()
      end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
  }

O.RegisterSection(function(AddSection)
  AddSection("Profiles", function(content, Row)
    local rowTop = Row(42)
    local title = rowTop:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    title:SetPoint("LEFT", rowTop, "LEFT", 0, 0)
    title:SetFont(FontPath(), 16, "")
    title:SetText("Export or import Clickable Raid Buffs profile strings.")

    local rowMain = Row(360)

    local box = CreateFrame("Frame", nil, rowMain, "BackdropTemplate")
    box:SetPoint("TOPLEFT", rowMain, "TOPLEFT", 0, 0)
    box:SetPoint("BOTTOMRIGHT", rowMain, "BOTTOMRIGHT", 0, 0)
    PaintBackdrop(box, { 0.06, 0.07, 0.10, 1 }, { 0.20, 0.22, 0.28, 1 })

    local scroll = CreateFrame("ScrollFrame", nil, box, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 8, -8)
    scroll:SetPoint("BOTTOMRIGHT", -28, 8)

    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFont(FontPath(), 12, "")
    edit:SetWidth(540)
    edit:SetScript("OnEscapePressed", function(self)
      self:ClearFocus()
    end)
    edit:SetScript("OnCursorChanged", function(self, _, y)
      scroll:SetVerticalScroll(y)
    end)
    scroll:SetScrollChild(edit)

    local rowBtns = Row(42)

    local function MakeBtn(text, x)
      local b = CreateFrame("Button", nil, rowBtns, "UIPanelButtonTemplate")
      b:SetSize(110, 28)
      b:SetPoint("LEFT", rowBtns, "LEFT", x, 0)
      b:SetText(text)
      b:GetFontString():SetFont(FontPath(), 12, "")
      return b
    end

    local bExport = MakeBtn("Export", 0)
    local bCopy = MakeBtn("Copy", 118)
    local bImportReplace = MakeBtn("Import All", 236)
    local bImportMerge = MakeBtn("Import Merge", 354)
    local bClear = MakeBtn("Clear", 472)

    local rowInfo = Row(64)
    local info = rowInfo:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    info:SetPoint("TOPLEFT", rowInfo, "TOPLEFT", 0, 0)
    info:SetWidth(560)
    info:SetJustifyH("LEFT")
    info:SetJustifyV("TOP")
    info:SetFont(FontPath(), 12, "")
    info:SetText("Paste a profile string, then choose Import All or Import Merge.")

    local function getText()
      return edit:GetText() or ""
    end

    local function setText(v)
      edit:SetText(v or "")
      edit:SetCursorPosition(0)
      scroll:SetVerticalScroll(0)
      edit:HighlightText(0, 0)
    end

    local function preview()
      local raw = getText()
      if raw == "" then
        info:SetText("Paste a profile string, then choose Import All or Import Merge.")
        return nil
      end
      if not ns.Profile_ImportPreview then
        info:SetText("Profile import is unavailable.")
        return nil
      end
      local p, err = ns.Profile_ImportPreview(raw)
      if not p then
        info:SetText("Invalid profile string: " .. tostring(err))
        return nil
      end
      info:SetText(
        ("Ready to import: schema v%d, source %s, changed keys %d, dropped keys %d"):format(
          p.schemaVersion or 0,
          tostring(p.addonVersion or "unknown"),
          p.changes or 0,
          p.dropped or 0
        )
      )
      return p
    end

    local function doImport(mode)
      local p = preview()
      if not p then
        return
      end
      local raw = getText()
      local summary = ("Import profile (%s)?\nChanged keys: %d\nDropped keys: %d"):format(
        mode == "merge" and "Merge" or "Replace",
        p.changes or 0,
        p.dropped or 0
      )
      StaticPopup_Show("CRB_PROFILE_IMPORT_CONFIRM", summary, nil, {
        run = function()
          local r, err = nil, nil
          if ns.Profile_Import then
            r, err = ns.Profile_Import(raw, mode)
          end
          if not r then
            info:SetText("Import failed: " .. tostring(err or "unknown"))
            return
          end
          info:SetText(
            ("Import complete (%s). Changed keys: %d, dropped keys: %d"):format(mode, r.changes or 0, r.dropped or 0)
          )
        end,
      })
    end

    local function runExport()
      if not ns.Profile_Export then
        info:SetText("Profile export is unavailable.")
        return
      end
      local s, err = ns.Profile_Export()
      if not s then
        info:SetText("Export failed: " .. tostring(err))
        return
      end
      setText(s)
      edit:SetFocus()
      edit:HighlightText()
      info:SetText(("Export ready. Length: %d"):format(#s))
    end

    bExport:SetScript("OnClick", runExport)

    bCopy:SetScript("OnClick", function()
      edit:SetFocus()
      edit:HighlightText()
      info:SetText("Profile string selected for copy.")
    end)

    bImportReplace:SetScript("OnClick", function()
      doImport("replace")
    end)

    bImportMerge:SetScript("OnClick", function()
      doImport("merge")
    end)

    bClear:SetScript("OnClick", function()
      setText("")
      info:SetText("Cleared.")
    end)

    edit:SetScript("OnTextChanged", function()
      preview()
    end)

    _profileSetText = setText
    _profileRunExport = runExport
    if _profileApplyPending then
      local p = _profileApplyPending
      _profileApplyPending = nil
      C_Timer.After(0, p)
    end
  end)
end)

ns.ProfileUI_ShowImport = function(raw)
  local apply = function()
    if type(raw) == "string" and raw ~= "" and _profileSetText then
      _profileSetText(raw)
    end
  end
  if ns.OpenOptions then
    ns.OpenOptions()
  end
  if _profileSetText then
    apply()
  else
    _profileApplyPending = apply
  end
end

ns.ProfileUI_ShowExport = function()
  local apply = function()
    if _profileRunExport then
      _profileRunExport()
    end
  end
  if ns.OpenOptions then
    ns.OpenOptions()
  end
  if _profileRunExport then
    apply()
  else
    _profileApplyPending = apply
  end
end
