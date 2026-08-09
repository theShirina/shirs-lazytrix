local checkboxes = {}

local function createText(parent, text, size, point, relative, relativePoint, x, y, width)
  local label = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  label:SetText(text)
  label:SetTextColor(1, 1, 1)
  label:SetFont(STANDARD_TEXT_FONT, size)
  label:SetPoint(point, relative, relativePoint, x, y)
  if width then
    label:SetWidth(width)
    label:SetJustifyH("LEFT")
  end
  return label
end

local function createCheckbox(parent, name, label, key, x, y)
  local box = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
  box:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  local text = getglobal(name .. "Text")
  text:SetText(label)
  text:SetTextColor(0.92, 0.92, 0.92)
  box:SetScript("OnClick", function()
    ShirsLazyTrixDB[key] = this:GetChecked() and true or false
  end)
  box.settingKey = key
  table.insert(checkboxes, box)
  return box
end

function ShirsLazyTrix.RefreshSettings()
  local i
  for i = 1, table.getn(checkboxes) do
    local box = checkboxes[i]
    box:SetChecked(ShirsLazyTrixDB[box.settingKey] and 1 or nil)
  end
end

function ShirsLazyTrix.ToggleSettings()
  if not ShirsLazyTrixSettingsFrame then
    return
  end
  if ShirsLazyTrixSettingsFrame:IsVisible() then
    ShirsLazyTrixSettingsFrame:Hide()
  else
    ShirsLazyTrix.RefreshSettings()
    ShirsLazyTrixSettingsFrame:Show()
  end
end

local function createSettingsFrame()
  local frame = CreateFrame("Frame", "ShirsLazyTrixSettingsFrame", UIParent)
  frame:SetWidth(360)
  frame:SetHeight(210)
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
  frame:SetFrameStrata("DIALOG")
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:SetClampedToScreen(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function() this:StartMoving() end)
  frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
  frame:SetScript("OnShow", ShirsLazyTrix.RefreshSettings)
  frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
  })

  local close = CreateFrame("Button", "ShirsLazyTrixSettingsClose", frame, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)

  local title = createText(frame, "Shir's LazyTrix", 18, "TOPLEFT", frame, "TOPLEFT", 22, -20)
  title:SetTextColor(1, 0.82, 0)
  createText(frame, "Quest automation", 11, "TOPLEFT", title, "BOTTOMLEFT", 0, -4)

  createCheckbox(frame, "ShirsLazyTrixTurnIn", "Turn in completed quests", "turnIn", 28, -86)
  createCheckbox(frame, "ShirsLazyTrixPickUp", "Pick up quests", "pickUp", 28, -116)

  local note = createText(frame, "Hold Shift to handle a quest manually.", 10, "BOTTOMLEFT", frame, "BOTTOMLEFT", 28, 28, 300)
  note:SetTextColor(0.65, 0.65, 0.65)

  frame:Hide()
end

local function createMinimapButton()
  local button = CreateFrame("Button", "ShirsLazyTrixMinimapButton", Minimap)
  button:SetWidth(24)
  button:SetHeight(24)
  button:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -2, -2)
  button:SetFrameStrata("MEDIUM")
  button:SetNormalTexture("Interface\\Icons\\INV_Misc_Book_09")
  local normal = button:GetNormalTexture()
  normal:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  button:SetScript("OnClick", ShirsLazyTrix.ToggleSettings)
  button:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
    GameTooltip:SetText("Shir's LazyTrix")
    GameTooltip:AddLine("Open quest settings", 1, 1, 1)
    GameTooltip:AddLine("Hold Shift to bypass automation", 0.7, 0.7, 0.7)
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

function ShirsLazyTrix.CreateUI()
  if not ShirsLazyTrixSettingsFrame then
    createSettingsFrame()
  end
  if not ShirsLazyTrixMinimapButton then
    createMinimapButton()
  end
end
