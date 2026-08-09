local function createText(parent, text, size)
  local label = parent:CreateFontString(nil, "OVERLAY")
  label:SetFont(STANDARD_TEXT_FONT, size or 12)
  label:SetText(text)
  return label
end

local function createCheckbox(parent, name, labelText, key, y)
  local check = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
  check:SetWidth(24)
  check:SetHeight(24)
  check:SetPoint("TOPLEFT", parent, "TOPLEFT", 24, y)
  local label = getglobal(name .. "Text")
  label:SetText(labelText)
  label:SetWidth(275)
  label:SetJustifyH("LEFT")
  label:SetTextColor(0.9, 0.92, 0.95)
  check:SetScript("OnClick", function()
    ShirsLazyTrixDB[key] = this:GetChecked() and true or false
  end)
  return check
end

function ShirsLazyTrix.RefreshSettings()
  if not ShirsLazyTrixSettingsFrame then return end
  ShirsLazyTrixTurnIn:SetChecked(ShirsLazyTrixDB.turnIn and 1 or nil)
  ShirsLazyTrixPickUp:SetChecked(ShirsLazyTrixDB.pickUp and 1 or nil)
  ShirsLazyTrixShiftAutomation:SetChecked(ShirsLazyTrixDB.automationOnShift and 1 or nil)
  ShirsLazyTrixAutoSellGray:SetChecked(ShirsLazyTrixDB.autoSellGray and 1 or nil)
  ShirsLazyTrixAutoRepairAll:SetChecked(ShirsLazyTrixDB.autoRepairAll and 1 or nil)
  ShirsLazyTrixAutoAcceptOpenWorldRes:SetChecked(ShirsLazyTrixDB.autoAcceptOpenWorldRes and 1 or nil)
end

local function createSettingsFrame()
  if ShirsLazyTrixSettingsFrame then return ShirsLazyTrixSettingsFrame end

  local frame = CreateFrame("Frame", "ShirsLazyTrixSettingsFrame", UIParent)
  frame:SetWidth(340)
  frame:SetHeight(390)
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
  frame:SetFrameStrata("DIALOG")
  frame:SetToplevel(true)
  frame:SetClampedToScreen(true)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function() this:StartMoving() end)
  frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
  frame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
  })
  frame:SetBackdropColor(0.025, 0.035, 0.055, 0.98)
  frame:SetBackdropBorderColor(0.3, 0.6, 0.9, 1)

  local title = createText(frame, "Shir's LazyTrix", 18)
  title:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -18)
  title:SetTextColor(0.45, 0.82, 1)

  local subtitle = createText(frame, "Quest and vendor automation", 11)
  subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
  subtitle:SetTextColor(0.62, 0.7, 0.8)

  local close = CreateFrame("Button", "ShirsLazyTrixClose", frame, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, -3)

  local divider = frame:CreateTexture(nil, "ARTWORK")
  divider:SetTexture("Interface\\Buttons\\WHITE8X8")
  divider:SetVertexColor(0.3, 0.6, 0.9, 0.22)
  divider:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -60)
  divider:SetWidth(300)
  divider:SetHeight(1)

  local section = createText(frame, "AUTOMATION", 11)
  section:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -76)
  section:SetTextColor(1, 0.82, 0)

  createCheckbox(frame, "ShirsLazyTrixTurnIn", "Turn in completed quests", "turnIn", -91)
  createCheckbox(frame, "ShirsLazyTrixPickUp", "Pick up quests", "pickUp", -121)
  createCheckbox(frame, "ShirsLazyTrixShiftAutomation", "Only automate while Shift is held", "automationOnShift", -151)

  local note = createText(frame, "When enabled, Shift triggers both pickup and turn-in.", 11)
  note:SetPoint("TOPLEFT", frame, "TOPLEFT", 25, -184)
  note:SetWidth(290)
  note:SetHeight(28)
  note:SetJustifyH("LEFT")
  note:SetTextColor(0.62, 0.7, 0.8)

  createCheckbox(frame, "ShirsLazyTrixAutoAcceptOpenWorldRes", "Automatically accept open-world resurrection requests", "autoAcceptOpenWorldRes", -214)

  local merchantDivider = frame:CreateTexture(nil, "ARTWORK")
  merchantDivider:SetTexture("Interface\\Buttons\\WHITE8X8")
  merchantDivider:SetVertexColor(0.3, 0.6, 0.9, 0.22)
  merchantDivider:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -250)
  merchantDivider:SetWidth(300)
  merchantDivider:SetHeight(1)

  local merchantSection = createText(frame, "MERCHANT", 11)
  merchantSection:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -264)
  merchantSection:SetTextColor(1, 0.82, 0)

  createCheckbox(frame, "ShirsLazyTrixAutoSellGray", "Automatically sell gray items at vendors", "autoSellGray", -279)
  createCheckbox(frame, "ShirsLazyTrixAutoRepairAll", "Automatically repair all gear at repair vendors", "autoRepairAll", -309)

  local merchantNote = createText(frame, "Sells gray-quality items only. Vendor options run independently.", 11)
  merchantNote:SetPoint("TOPLEFT", frame, "TOPLEFT", 25, -343)
  merchantNote:SetWidth(290)
  merchantNote:SetHeight(24)
  merchantNote:SetJustifyH("LEFT")
  merchantNote:SetTextColor(0.62, 0.7, 0.8)

  frame:SetScript("OnShow", ShirsLazyTrix.RefreshSettings)
  frame:Hide()
  table.insert(UISpecialFrames, "ShirsLazyTrixSettingsFrame")
  return frame
end

function ShirsLazyTrix.ToggleSettings()
  local frame = createSettingsFrame()
  if frame:IsVisible() then
    frame:Hide()
  else
    ShirsLazyTrix.RefreshSettings()
    frame:Show()
  end
end

function ShirsLazyTrix.UpdateMinimapButtonPosition()
  if not ShirsLazyTrixMinimapButton or not Minimap then return end
  local angle = math.rad(ShirsLazyTrixDB.minimapAngle or 220)
  ShirsLazyTrixMinimapButton:ClearAllPoints()
  ShirsLazyTrixMinimapButton:SetPoint(
    "CENTER", Minimap, "CENTER",
    math.cos(angle) * 80,
    math.sin(angle) * 80
  )
end

function ShirsLazyTrix.UpdateMinimapButtonFromCursor()
  if not Minimap then return end
  local minimapX, minimapY = Minimap:GetCenter()
  local cursorX, cursorY = GetCursorPosition()
  local scale = UIParent:GetEffectiveScale()
  if not scale or scale == 0 then scale = 1 end
  cursorX = cursorX / scale
  cursorY = cursorY / scale
  local angle = math.deg(math.atan2(cursorY - minimapY, cursorX - minimapX))
  if angle < 0 then angle = angle + 360 end
  ShirsLazyTrixDB.minimapAngle = angle
  ShirsLazyTrix.UpdateMinimapButtonPosition()
end

local function createMinimapButton()
  if ShirsLazyTrixMinimapButton or not Minimap then return ShirsLazyTrixMinimapButton end

  local button = CreateFrame("Button", "ShirsLazyTrixMinimapButton", Minimap)
  button:SetWidth(32)
  button:SetHeight(32)
  button:SetFrameStrata("MEDIUM")
  button:SetFrameLevel(Minimap:GetFrameLevel() + 8)
  button:RegisterForClicks("LeftButtonUp")
  button:RegisterForDrag("LeftButton")

  local icon = button:CreateTexture(nil, "ARTWORK")
  icon:SetWidth(20)
  icon:SetHeight(20)
  icon:SetPoint("CENTER", button, "CENTER", 0, 0)
  icon:SetTexture("Interface\\AddOns\\ShirsLazyTrix\\LazyTrixIcon")

  local border = button:CreateTexture(nil, "OVERLAY")
  border:SetWidth(52)
  border:SetHeight(52)
  border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

  button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  button:SetScript("OnClick", function() ShirsLazyTrix.ToggleSettings() end)
  button:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
    GameTooltip:SetText("Shir's LazyTrix")
    GameTooltip:AddLine("Left click: Open settings", 1, 1, 1)
    GameTooltip:AddLine("Shift: Manual bypass or automation trigger", 0.7, 0.8, 0.9)
    GameTooltip:AddLine("Drag: Move this button", 0.7, 0.7, 0.7)
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave", function() GameTooltip:Hide() end)
  button:SetScript("OnDragStart", function()
    button:SetScript("OnUpdate", function() ShirsLazyTrix.UpdateMinimapButtonFromCursor() end)
  end)
  button:SetScript("OnDragStop", function()
    button:SetScript("OnUpdate", nil)
    ShirsLazyTrix.UpdateMinimapButtonFromCursor()
  end)

  ShirsLazyTrix.UpdateMinimapButtonPosition()
  return button
end

function ShirsLazyTrix.CreateUI()
  if ShirsLazyTrix.EnsureDatabase then ShirsLazyTrix.EnsureDatabase() end
  createSettingsFrame()
  createMinimapButton()
end
