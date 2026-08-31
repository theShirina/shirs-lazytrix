local function createText(parent, text, size)
  local label = parent:CreateFontString(nil, "OVERLAY")
  label:SetFont(STANDARD_TEXT_FONT, size or 12)
  label:SetText(text)
  return label
end

local refreshingSettings = false

local function createCheckbox(parent, name, labelText, key, y, x, labelWidth)
  local check = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
  check:SetWidth(24)
  check:SetHeight(24)
  check:SetPoint("TOPLEFT", parent, "TOPLEFT", x or 24, y)
  local label = getglobal(name .. "Text")
  label:SetText(labelText)
  label:SetWidth(labelWidth or 275)
  label:SetJustifyH("LEFT")
  label:SetTextColor(0.9, 0.92, 0.95)
  check:SetScript("OnClick", function()
    ShirsLazyTrixDB[key] = this:GetChecked() and true or false
    if (name == "ShirsLazyTrixExpandTrainers" or name == "ShirsLazyTrixTrainAll") and ShirsLazyTrix.RefreshTrainerFeature then
      ShirsLazyTrix.RefreshTrainerFeature()
    elseif name == "ShirsLazyTrixShowCooldownPanel" and ShirsLazyTrix.RefreshCooldownPanelVisibility then
      ShirsLazyTrix.RefreshCooldownPanelVisibility()
    elseif name == "ShirsLazyTrixShowRaidInfoPanel" then
      if this:GetChecked() and ShirsLazyTrix.RequestRaidInfo then
        ShirsLazyTrix.RequestRaidInfo()
      end
      if ShirsLazyTrix.RefreshRaidInfoPanelVisibility then
        ShirsLazyTrix.RefreshRaidInfoPanelVisibility()
      end
    elseif name == "ShirsLazyTrixHideCooldownPanelInCombat" and ShirsLazyTrix.RefreshCooldownPanelVisibility then
      ShirsLazyTrix.RefreshCooldownPanelVisibility()
    elseif name == "ShirsLazyTrixExpandLootRows" and ShirsLazyTrix.RefreshLootRows then
      ShirsLazyTrix.RefreshLootRows()
    end
  end)
  return check
end

function ShirsLazyTrix.RefreshSettings()
  if not ShirsLazyTrixSettingsFrame then return end
  refreshingSettings = true
  ShirsLazyTrixTurnIn:SetChecked(ShirsLazyTrixDB.turnIn and 1 or nil)
  ShirsLazyTrixPickUp:SetChecked(ShirsLazyTrixDB.pickUp and 1 or nil)
  ShirsLazyTrixShiftAutomation:SetChecked(ShirsLazyTrixDB.automationOnShift and 1 or nil)
  ShirsLazyTrixAutoSellGray:SetChecked(ShirsLazyTrixDB.autoSellGray and 1 or nil)
  ShirsLazyTrixAutoRepairAll:SetChecked(ShirsLazyTrixDB.autoRepairAll and 1 or nil)
  ShirsLazyTrixAutoAcceptOpenWorldRes:SetChecked(ShirsLazyTrixDB.autoAcceptOpenWorldRes and 1 or nil)
  ShirsLazyTrixAutoRemoveImmolationOnStealth:SetChecked(ShirsLazyTrixDB.autoRemoveImmolationOnStealth and 1 or nil)
  ShirsLazyTrixExpandTrainers:SetChecked(ShirsLazyTrixDB.expandTrainers and 1 or nil)
  ShirsLazyTrixTrainAll:SetChecked(ShirsLazyTrixDB.trainAll and 1 or nil)
  ShirsLazyTrixAutoOpenTrainers:SetChecked(ShirsLazyTrixDB.autoOpenTrainers and 1 or nil)
  ShirsLazyTrixShowCooldownPanel:SetChecked(ShirsLazyTrixDB.showCooldownPanel and 1 or nil)
  ShirsLazyTrixShowRaidInfoPanel:SetChecked(ShirsLazyTrixDB.showRaidInfoPanel and 1 or nil)
  ShirsLazyTrixHideCooldownPanelInCombat:SetChecked(ShirsLazyTrixDB.hideCooldownPanelInCombat and 1 or nil)
  ShirsLazyTrixInviteFromWhispers:SetChecked(ShirsLazyTrixDB.inviteFromWhispers and 1 or nil)
  ShirsLazyTrixInviteFromGuild:SetChecked(ShirsLazyTrixDB.inviteFromGuild and 1 or nil)
  if ShirsLazyTrixInvitePhrases.SetText then ShirsLazyTrixInvitePhrases:SetText(ShirsLazyTrixDB.invitePhrases or "") end
  ShirsLazyTrixNotifyOtherMooncloth:SetChecked(ShirsLazyTrixDB.notifyOtherMooncloth and 1 or nil)
  ShirsLazyTrixNotifyOtherArcanite:SetChecked(ShirsLazyTrixDB.notifyOtherArcanite and 1 or nil)
  ShirsLazyTrixNotifyOtherSalt:SetChecked(ShirsLazyTrixDB.notifyOtherSalt and 1 or nil)
  ShirsLazyTrixShowItemIDs:SetChecked(ShirsLazyTrixDB.showItemIDs and 1 or nil)
  ShirsLazyTrixExpandLootRows:SetChecked(ShirsLazyTrixDB.expandLootRows and 1 or nil)
  ShirsLazyTrixConsolidateMinimapButtons:SetChecked(ShirsLazyTrixDB.consolidateMinimapButtons and 1 or nil)
  local lootRows = ShirsLazyTrix.NormalizeLootRows(ShirsLazyTrixDB.lootRows)
  ShirsLazyTrixLootRowsSlider:SetValue(lootRows)
  ShirsLazyTrixLootRowsSliderText:SetText("Loot rows: " .. lootRows)
  local buttonSize = ShirsLazyTrix.NormalizeMinimapButtonSize(ShirsLazyTrixDB.minimapButtonSize)
  ShirsLazyTrixMinimapButtonSizeSlider:SetValue(buttonSize)
  ShirsLazyTrixMinimapButtonSizeSliderText:SetText("Button size: " .. buttonSize)
  refreshingSettings = false
end

local cooldownPanelInCombat = false
local activeCooldownTooltipRow = nil
local activeRaidInfoTooltipRow = nil
local RAID_INFO_ROW_COUNT = 10
local RAID_INFO_ROW_SPACING = 23
local RAID_INFO_PANEL_WIDTH = 250
local RAID_INFO_ROW_WIDTH = 222
local RAID_INFO_PANEL_MIN_HEIGHT = 62
local RAID_INFO_PANEL_EMPTY_HEIGHT = 82

function ShirsLazyTrix.RefreshCooldownRowTooltip(row)
  if not row or not row.cooldownKey or not GameTooltip then return false end
  GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
  GameTooltip:SetText(row.cooldownLabel or row.cooldownKey)
  GameTooltip:AddLine("Click to attempt exactly one craft when ready.", 1, 1, 1)
  if row.cooldownKey == "salt" then
    GameTooltip:AddLine("The Salt Shaker must be in your bags.", 0.7, 0.8, 0.9)
  else
    GameTooltip:AddLine("LazyTrix opens and rechecks the profession first.", 0.7, 0.8, 0.9)
  end
  GameTooltip:AddLine("Account cooldowns", 1, 0.82, 0)
  local rows = ShirsLazyTrix.GetCooldownCharacterStatuses and
    ShirsLazyTrix.GetCooldownCharacterStatuses(row.cooldownKey) or {}
  local index
  for index = 1, table.getn(rows) do
    GameTooltip:AddLine(rows[index].owner .. ": " .. rows[index].status, 0.85, 0.9, 0.96)
  end
  GameTooltip:Show()
  return true
end

local function configureCooldownRow(button, key, labelText, y)
  button:SetWidth(222)
  button:SetHeight(22)
  button:SetPoint("TOPLEFT", button.parent or ShirsLazyTrixCooldownPanel, "TOPLEFT", 14, y)

  local background = button:CreateTexture(nil, "BACKGROUND")
  background:SetAllPoints(button)
  background:SetTexture("Interface\\Buttons\\WHITE8X8")
  background:SetVertexColor(0.09, 0.14, 0.2, 0.9)

  local label = createText(button, labelText, 11)
  label:SetPoint("LEFT", button, "LEFT", 7, 0)
  label:SetTextColor(0.85, 0.9, 0.96)
  button.label = label

  local status = createText(button, "Not known", 11)
  status:SetPoint("RIGHT", button, "RIGHT", -7, 0)
  status:SetTextColor(0.58, 0.64, 0.72)
  button.status = status
  button.cooldownKey = key
  button.cooldownLabel = labelText

  button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
  button:SetScript("OnClick", function()
    ShirsLazyTrix.ClickProfessionCooldown(key)
  end)
  button:SetScript("OnEnter", function()
    activeCooldownTooltipRow = this
    ShirsLazyTrix.RefreshCooldownRowTooltip(this)
  end)
  button:SetScript("OnLeave", function()
    activeCooldownTooltipRow = nil
    GameTooltip:Hide()
  end)
end

local function createCooldownPanel()
  if ShirsLazyTrixCooldownPanel then return ShirsLazyTrixCooldownPanel end

  local panel = CreateFrame("Frame", "ShirsLazyTrixCooldownPanel", UIParent)
  panel:SetWidth(250)
  panel:SetHeight(112)
  panel:SetFrameStrata("DIALOG")
  panel:SetClampedToScreen(true)
  panel:SetMovable(true)
  panel:EnableMouse(true)
  panel:RegisterForDrag("LeftButton")
  panel:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 10,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
  })
  panel:SetBackdropColor(0.025, 0.035, 0.055, 0.96)
  panel:SetBackdropBorderColor(0.3, 0.6, 0.9, 1)

  local point, relativePoint, x, y = ShirsLazyTrix.GetCooldownPanelPosition()
  panel:SetPoint(point, UIParent, relativePoint, x, y)

  local title = createText(panel, "PROFESSION COOLDOWNS", 11)
  title:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -10)
  title:SetTextColor(1, 0.82, 0)

  local dragNote = createText(panel, "drag", 9)
  dragNote:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -36, -11)
  dragNote:SetTextColor(0.48, 0.56, 0.66)

  local lock = CreateFrame("Button", "ShirsLazyTrixCooldownLock", panel)
  lock:SetWidth(18)
  lock:SetHeight(18)
  lock:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -8, -7)
  lock:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
  lock.lockLabel = lock:CreateFontString(nil, "OVERLAY")
  lock.lockLabel:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
  lock.lockLabel:SetPoint("CENTER", lock, "CENTER", 0, 0)
  lock:SetScript("OnClick", function()
    ShirsLazyTrixDB.cooldownPanelLocked = not ShirsLazyTrixDB.cooldownPanelLocked
    ShirsLazyTrix.RefreshCooldownPanelLock()
  end)
  lock:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    if ShirsLazyTrixDB.cooldownPanelLocked then
      GameTooltip:SetText("Unlock cooldown panel")
    else
      GameTooltip:SetText("Lock cooldown panel")
    end
    GameTooltip:Show()
  end)
  lock:SetScript("OnLeave", function() GameTooltip:Hide() end)

  local mooncloth = CreateFrame("Button", "ShirsLazyTrixCooldownMooncloth", panel)
  mooncloth.parent = panel
  configureCooldownRow(mooncloth, "mooncloth", "Mooncloth", -30)
  local arcanite = CreateFrame("Button", "ShirsLazyTrixCooldownArcanite", panel)
  arcanite.parent = panel
  configureCooldownRow(arcanite, "arcanite", "Transmute: Arcanite", -55)
  local salt = CreateFrame("Button", "ShirsLazyTrixCooldownSalt", panel)
  salt.parent = panel
  configureCooldownRow(salt, "salt", "Salt Shaker", -80)

  panel:SetScript("OnDragStart", function()
    if not ShirsLazyTrixDB.cooldownPanelLocked then this:StartMoving() end
  end)
  panel:SetScript("OnDragStop", function()
    if ShirsLazyTrixDB.cooldownPanelLocked then return end
    this:StopMovingOrSizing()
    local savedPoint, _, savedRelativePoint, savedX, savedY = this:GetPoint()
    ShirsLazyTrix.SaveCooldownPanelPosition(savedPoint, savedRelativePoint, savedX, savedY)
  end)
  panel:Hide()
  ShirsLazyTrix.RefreshCooldownPanelLock()
  return panel
end

function ShirsLazyTrix.RefreshCooldownPanelLock()
  if not ShirsLazyTrixCooldownPanel or not ShirsLazyTrixCooldownLock then return end
  local locked = ShirsLazyTrixDB.cooldownPanelLocked and true or false
  ShirsLazyTrixCooldownPanel:SetMovable(not locked)
  if locked then
    ShirsLazyTrixCooldownLock.lockLabel:SetText("L")
    ShirsLazyTrixCooldownLock.lockLabel:SetTextColor(1, 0.82, 0)
  else
    ShirsLazyTrixCooldownLock.lockLabel:SetText("U")
    ShirsLazyTrixCooldownLock.lockLabel:SetTextColor(0.48, 0.72, 1)
  end
end

function ShirsLazyTrix.RefreshCooldownPanel()
  if not ShirsLazyTrixCooldownPanel then return end
  local state = ShirsLazyTrix.GetCurrentCooldowns()
  local rows = {
    mooncloth = ShirsLazyTrixCooldownMooncloth,
    arcanite = ShirsLazyTrixCooldownArcanite,
    salt = ShirsLazyTrixCooldownSalt,
  }
  local key, row
  for key, row in pairs(rows) do
    local text = ShirsLazyTrix.FormatCooldownStatus(state[key])
    row.status:SetText(text)
    if text == "Ready" then
      row.status:SetTextColor(0.35, 1, 0.45)
    elseif text == "Not known" then
      row.status:SetTextColor(0.58, 0.64, 0.72)
    else
      row.status:SetTextColor(1, 0.82, 0)
    end
  end
  if activeCooldownTooltipRow then
    ShirsLazyTrix.RefreshCooldownRowTooltip(activeCooldownTooltipRow)
  end
end

function ShirsLazyTrix.RefreshCooldownPanelVisibility()
  local panel = createCooldownPanel()
  local insideInstance = false
  if ShirsLazyTrixDB.hideCooldownPanelInCombat and type(IsInInstance) == "function" then
    local instanceState = IsInInstance()
    insideInstance = instanceState == true or instanceState == 1
  end
  if ShirsLazyTrixDB.showCooldownPanel and
     not (ShirsLazyTrixDB.hideCooldownPanelInCombat and (cooldownPanelInCombat or insideInstance)) then
    ShirsLazyTrix.RefreshCooldownPanel()
    panel:Show()
  else
    panel:Hide()
  end
end

function ShirsLazyTrix.SetCooldownPanelCombatState(active)
  cooldownPanelInCombat = active and true or false
  ShirsLazyTrix.RefreshCooldownPanelVisibility()
  if ShirsLazyTrix.RefreshRaidInfoPanelVisibility then
    ShirsLazyTrix.RefreshRaidInfoPanelVisibility()
  end
end

function ShirsLazyTrix.RefreshRaidInfoRowTooltip(row)
  if not row or not row.raidName or not GameTooltip then return false end
  GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
  GameTooltip:SetText(row.raidName)
  if row.raidID and row.raidID ~= "" then
    GameTooltip:AddLine("Instance ID: " .. row.raidID, 0.7, 0.8, 0.9)
  end
  GameTooltip:AddLine("This character: " .. (row.statusText or "Not known"), 1, 1, 1)
  GameTooltip:AddLine("Other characters (last saved data)", 1, 0.82, 0)
  local rows = ShirsLazyTrix.GetRaidInfoCharacterStatuses and
    ShirsLazyTrix.GetRaidInfoCharacterStatuses(row.raidName) or {}
  if table.getn(rows) == 0 then
    GameTooltip:AddLine("No saved data for this raid.", 0.7, 0.8, 0.9)
  else
    local index
    for index = 1, table.getn(rows) do
      GameTooltip:AddLine(rows[index].owner .. ": " .. rows[index].status, 0.85, 0.9, 0.96)
    end
  end
  GameTooltip:Show()
  return true
end

local function configureRaidInfoRow(button, panel, index)
  button:SetWidth(RAID_INFO_ROW_WIDTH)
  button:SetHeight(22)
  button:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -32 - ((index - 1) * RAID_INFO_ROW_SPACING))

  local background = button:CreateTexture(nil, "BACKGROUND")
  background:SetAllPoints(button)
  background:SetTexture("Interface\\Buttons\\WHITE8X8")
  background:SetVertexColor(0.09, 0.14, 0.2, 0.9)

  local label = createText(button, "", 11)
  label:SetPoint("LEFT", button, "LEFT", 7, 0)
  label:SetTextColor(0.85, 0.9, 0.96)
  button.label = label

  local status = createText(button, "Not known", 11)
  status:SetPoint("RIGHT", button, "RIGHT", -7, 0)
  status:SetTextColor(0.58, 0.64, 0.72)
  button.status = status

  button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
  button:SetScript("OnEnter", function()
    activeRaidInfoTooltipRow = this
    ShirsLazyTrix.RefreshRaidInfoRowTooltip(this)
  end)
  button:SetScript("OnLeave", function()
    activeRaidInfoTooltipRow = nil
    GameTooltip:Hide()
  end)
end

local function createRaidInfoPanel()
  if ShirsLazyTrixRaidInfoPanel then return ShirsLazyTrixRaidInfoPanel end

  local panel = CreateFrame("Frame", "ShirsLazyTrixRaidInfoPanel", UIParent)
  panel:SetWidth(RAID_INFO_PANEL_WIDTH)
  panel:SetHeight(RAID_INFO_PANEL_EMPTY_HEIGHT)
  panel:SetFrameStrata("DIALOG")
  panel:SetClampedToScreen(true)
  panel:SetMovable(true)
  panel:EnableMouse(true)
  panel:RegisterForDrag("LeftButton")
  panel:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 10,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
  })
  panel:SetBackdropColor(0.025, 0.035, 0.055, 0.96)
  panel:SetBackdropBorderColor(0.3, 0.6, 0.9, 1)

  local point, relativePoint, x, y = ShirsLazyTrix.GetRaidInfoPanelPosition()
  panel:SetPoint(point, UIParent, relativePoint, x, y)

  local title = createText(panel, "RAID RESET INFO", 11)
  title:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -10)
  title:SetTextColor(1, 0.82, 0)

  local dragNote = createText(panel, "drag", 9)
  dragNote:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -36, -11)
  dragNote:SetTextColor(0.48, 0.56, 0.66)

  local lock = CreateFrame("Button", "ShirsLazyTrixRaidInfoLock", panel)
  lock:SetWidth(18)
  lock:SetHeight(18)
  lock:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -8, -7)
  lock:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
  lock.lockLabel = lock:CreateFontString(nil, "OVERLAY")
  lock.lockLabel:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
  lock.lockLabel:SetPoint("CENTER", lock, "CENTER", 0, 0)
  lock:SetScript("OnClick", function()
    ShirsLazyTrixDB.raidInfoPanelLocked = not ShirsLazyTrixDB.raidInfoPanelLocked
    ShirsLazyTrix.RefreshRaidInfoPanelLock()
  end)
  lock:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    if ShirsLazyTrixDB.raidInfoPanelLocked then
      GameTooltip:SetText("Unlock raid reset panel")
    else
      GameTooltip:SetText("Lock raid reset panel")
    end
    GameTooltip:Show()
  end)
  lock:SetScript("OnLeave", function() GameTooltip:Hide() end)

  panel.emptyLabel = createText(panel, "Waiting for raid information...", 11)
  panel.emptyLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -34)
  panel.emptyLabel:SetWidth(RAID_INFO_ROW_WIDTH)
  panel.emptyLabel:SetHeight(36)
  panel.emptyLabel:SetJustifyH("LEFT")
  panel.emptyLabel:SetTextColor(0.62, 0.7, 0.8)

  panel.raidRows = {}
  local index
  for index = 1, RAID_INFO_ROW_COUNT do
    local row = CreateFrame("Button", "ShirsLazyTrixRaidInfoRow" .. index, panel)
    panel.raidRows[index] = row
    configureRaidInfoRow(row, panel, index)
    row:Hide()
  end

  panel:SetScript("OnDragStart", function()
    if not ShirsLazyTrixDB.raidInfoPanelLocked then panel:StartMoving() end
  end)
  panel:SetScript("OnDragStop", function()
    if ShirsLazyTrixDB.raidInfoPanelLocked then return end
    panel:StopMovingOrSizing()
    local savedPoint, _, savedRelativePoint, savedX, savedY = panel:GetPoint()
    ShirsLazyTrix.SaveRaidInfoPanelPosition(savedPoint, savedRelativePoint, savedX, savedY)
  end)
  panel:Hide()
  ShirsLazyTrix.RefreshRaidInfoPanelLock()
  return panel
end

function ShirsLazyTrix.RefreshRaidInfoPanelLock()
  if not ShirsLazyTrixRaidInfoPanel or not ShirsLazyTrixRaidInfoLock then return end
  local locked = ShirsLazyTrixDB.raidInfoPanelLocked and true or false
  ShirsLazyTrixRaidInfoPanel:SetMovable(not locked)
  if locked then
    ShirsLazyTrixRaidInfoLock.lockLabel:SetText("L")
    ShirsLazyTrixRaidInfoLock.lockLabel:SetTextColor(1, 0.82, 0)
  else
    ShirsLazyTrixRaidInfoLock.lockLabel:SetText("U")
    ShirsLazyTrixRaidInfoLock.lockLabel:SetTextColor(0.48, 0.72, 1)
  end
end

function ShirsLazyTrix.RefreshRaidInfoPanel()
  if not ShirsLazyTrixRaidInfoPanel then return end
  local state = ShirsLazyTrix.GetCurrentRaidInfo and ShirsLazyTrix.GetCurrentRaidInfo() or {}
  local instances = type(state) == "table" and state.instances or nil
  local visibleRows = 0
  local index
  for index = 1, RAID_INFO_ROW_COUNT do
    local row = ShirsLazyTrixRaidInfoPanel.raidRows[index]
    local entry = type(instances) == "table" and instances[index] or nil
    if type(entry) == "table" and entry.name and entry.name ~= "" then
      row.raidName = entry.name
      row.raidID = entry.id or ""
      row.statusText = ShirsLazyTrix.FormatRaidInfoStatus(entry)
      row.label:SetText(entry.name)
      row.status:SetText(row.statusText)
      if row.statusText == "Ready" then
        row.status:SetTextColor(0.35, 1, 0.45)
      else
        row.status:SetTextColor(1, 0.82, 0)
      end
      row:Show()
      visibleRows = visibleRows + 1
    else
      row.raidName = nil
      row.raidID = nil
      row.statusText = nil
      row:Hide()
    end
  end
  local panelHeight = RAID_INFO_PANEL_EMPTY_HEIGHT
  if visibleRows > 0 then
    panelHeight = RAID_INFO_PANEL_MIN_HEIGHT + ((visibleRows - 1) * RAID_INFO_ROW_SPACING)
  end
  ShirsLazyTrixRaidInfoPanel:SetHeight(panelHeight)
  if state.known == true then
    if visibleRows == 0 then
      ShirsLazyTrixRaidInfoPanel.emptyLabel:SetText("No saved raid lockouts.")
      ShirsLazyTrixRaidInfoPanel.emptyLabel:Show()
    else
      ShirsLazyTrixRaidInfoPanel.emptyLabel:Hide()
    end
  else
    ShirsLazyTrixRaidInfoPanel.emptyLabel:SetText("Waiting for raid information...")
    ShirsLazyTrixRaidInfoPanel.emptyLabel:Show()
  end
  if activeRaidInfoTooltipRow then
    if activeRaidInfoTooltipRow.raidName then
      ShirsLazyTrix.RefreshRaidInfoRowTooltip(activeRaidInfoTooltipRow)
    else
      activeRaidInfoTooltipRow = nil
      GameTooltip:Hide()
    end
  end
end

function ShirsLazyTrix.RefreshRaidInfoPanelVisibility()
  local panel = createRaidInfoPanel()
  local insideInstance = false
  if ShirsLazyTrixDB.hideCooldownPanelInCombat and type(IsInInstance) == "function" then
    local instanceState = IsInInstance()
    insideInstance = instanceState == true or instanceState == 1
  end
  if ShirsLazyTrixDB.showRaidInfoPanel and
     not (ShirsLazyTrixDB.hideCooldownPanelInCombat and (cooldownPanelInCombat or insideInstance)) then
    ShirsLazyTrix.RefreshRaidInfoPanel()
    panel:Show()
  else
    panel:Hide()
  end
end

local function createSettingsFrame()
  if ShirsLazyTrixSettingsFrame then return ShirsLazyTrixSettingsFrame end

  local frame = CreateFrame("Frame", "ShirsLazyTrixSettingsFrame", UIParent)
  frame:SetWidth(620)
  frame:SetHeight(600)
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
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

  local subtitle = createText(frame, "Quest, vendor, and world automation", 11)
  subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
  subtitle:SetTextColor(0.62, 0.7, 0.8)

  local close = CreateFrame("Button", "ShirsLazyTrixClose", frame, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, -3)

  local divider = frame:CreateTexture(nil, "ARTWORK")
  divider:SetTexture("Interface\\Buttons\\WHITE8X8")
  divider:SetVertexColor(0.3, 0.6, 0.9, 0.22)
  divider:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -60)
  divider:SetWidth(580)
  divider:SetHeight(1)

  local verticalDivider = frame:CreateTexture(nil, "ARTWORK")
  verticalDivider:SetTexture("Interface\\Buttons\\WHITE8X8")
  verticalDivider:SetVertexColor(0.3, 0.6, 0.9, 0.18)
  verticalDivider:SetPoint("TOPLEFT", frame, "TOPLEFT", 310, -70)
  verticalDivider:SetWidth(1)
  verticalDivider:SetHeight(510)

  local section = createText(frame, "QUESTING", 11)
  section:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -76)
  section:SetTextColor(1, 0.82, 0)

  createCheckbox(frame, "ShirsLazyTrixTurnIn", "Turn in completed quests", "turnIn", -91, 24, 260)
  createCheckbox(frame, "ShirsLazyTrixPickUp", "Pick up quests", "pickUp", -119, 24, 260)
  createCheckbox(frame, "ShirsLazyTrixShiftAutomation", "Only automate while Shift is held", "automationOnShift", -147, 24, 260)

  local note = createText(frame, "Shift can trigger both pickup and turn-in.", 11)
  note:SetPoint("TOPLEFT", frame, "TOPLEFT", 25, -178)
  note:SetWidth(270)
  note:SetHeight(24)
  note:SetJustifyH("LEFT")
  note:SetTextColor(0.62, 0.7, 0.8)

  local worldSection = createText(frame, "WORLD", 11)
  worldSection:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -220)
  worldSection:SetTextColor(1, 0.82, 0)
  createCheckbox(frame, "ShirsLazyTrixAutoAcceptOpenWorldRes", "Accept open-world resurrection requests", "autoAcceptOpenWorldRes", -235, 24, 260)
  createCheckbox(frame, "ShirsLazyTrixAutoRemoveImmolationOnStealth", "Remove immolation on stealth or invisibility", "autoRemoveImmolationOnStealth", -263, 24, 260)

  local inviteSection = createText(frame, "INVITES", 11)
  inviteSection:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -306)
  inviteSection:SetTextColor(1, 0.82, 0)
  createCheckbox(frame, "ShirsLazyTrixInviteFromWhispers", "Invite from whispers", "inviteFromWhispers", -321, 24, 260)
  createCheckbox(frame, "ShirsLazyTrixInviteFromGuild", "Invite from guild chat", "inviteFromGuild", -349, 24, 260)
  local invitePhrases = CreateFrame("EditBox", "ShirsLazyTrixInvitePhrases", frame, "InputBoxTemplate")
  invitePhrases:SetWidth(270)
  invitePhrases:SetHeight(24)
  invitePhrases:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -379)
  if invitePhrases.SetAutoFocus then invitePhrases:SetAutoFocus(false) end
  if invitePhrases.SetMaxLetters then invitePhrases:SetMaxLetters(255) end
  invitePhrases:SetScript("OnTextChanged", function()
    if refreshingSettings then return end
    ShirsLazyTrixDB.invitePhrases = this:GetText() or ""
  end)
  invitePhrases:SetScript("OnEnterPressed", function()
    ShirsLazyTrixDB.invitePhrases = this:GetText()
    this:ClearFocus()
  end)
  invitePhrases:SetScript("OnEditFocusLost", function()
    ShirsLazyTrixDB.invitePhrases = this:GetText()
  end)
  local inviteNote = createText(frame, "Comma-separated phrases. A matching whisper or guild message triggers one invite.", 10)
  inviteNote:SetPoint("TOPLEFT", frame, "TOPLEFT", 25, -410)
  inviteNote:SetWidth(270)
  inviteNote:SetHeight(30)
  inviteNote:SetJustifyH("LEFT")
  inviteNote:SetTextColor(0.62, 0.7, 0.8)

  local trainerSection = createText(frame, "TRAINERS", 11)
  trainerSection:SetPoint("TOPLEFT", frame, "TOPLEFT", 326, -76)
  trainerSection:SetTextColor(1, 0.82, 0)
  createCheckbox(frame, "ShirsLazyTrixExpandTrainers", "Expand trainer windows", "expandTrainers", -91, 326, 260)
  createCheckbox(frame, "ShirsLazyTrixTrainAll", "Enable Train All", "trainAll", -119, 326, 260)
  createCheckbox(frame, "ShirsLazyTrixAutoOpenTrainers", "Automatically open trainer services", "autoOpenTrainers", -147, 326, 260)

  local merchantSection = createText(frame, "MERCHANT", 11)
  merchantSection:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -455)
  merchantSection:SetTextColor(1, 0.82, 0)

  createCheckbox(frame, "ShirsLazyTrixAutoSellGray", "Sell gray items", "autoSellGray", -470, 24, 260)
  createCheckbox(frame, "ShirsLazyTrixAutoRepairAll", "Repair all gear", "autoRepairAll", -498, 24, 260)

  local merchantNote = createText(frame, "Gray-only selling. Vendor actions stay independent.", 11)
  merchantNote:SetPoint("TOPLEFT", frame, "TOPLEFT", 25, -529)
  merchantNote:SetWidth(270)
  merchantNote:SetHeight(24)
  merchantNote:SetJustifyH("LEFT")
  merchantNote:SetTextColor(0.62, 0.7, 0.8)

  local cooldownSection = createText(frame, "PROFESSION COOLDOWNS", 11)
  cooldownSection:SetPoint("TOPLEFT", frame, "TOPLEFT", 326, -190)
  cooldownSection:SetTextColor(1, 0.82, 0)

  createCheckbox(frame, "ShirsLazyTrixShowCooldownPanel", "Show movable cooldown panel", "showCooldownPanel", -205, 326, 260)
  createCheckbox(frame, "ShirsLazyTrixHideCooldownPanelInCombat", "Hide in combat and instances", "hideCooldownPanelInCombat", -233, 326, 260)

  local raidSection = createText(frame, "RAID RESET INFO", 11)
  raidSection:SetPoint("TOPLEFT", frame, "TOPLEFT", 326, -292)
  raidSection:SetTextColor(1, 0.82, 0)
  createCheckbox(frame, "ShirsLazyTrixShowRaidInfoPanel", "Show raid reset panel", "showRaidInfoPanel", -307, 326, 260)

  local reminderLabel = createText(frame, "OTHER-CHARACTER READY REMINDERS", 10)
  reminderLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 326, -349)
  reminderLabel:SetTextColor(0.62, 0.7, 0.8)

  createCheckbox(frame, "ShirsLazyTrixNotifyOtherMooncloth", "Mooncloth", "notifyOtherMooncloth", -364, 326, 70)
  createCheckbox(frame, "ShirsLazyTrixNotifyOtherArcanite", "Arcanite", "notifyOtherArcanite", -364, 416, 70)
  createCheckbox(frame, "ShirsLazyTrixNotifyOtherSalt", "Salt", "notifyOtherSalt", -364, 500, 65)

  local tooltipSection = createText(frame, "TOOLTIPS", 11)
  tooltipSection:SetPoint("TOPLEFT", frame, "TOPLEFT", 326, -406)
  tooltipSection:SetTextColor(1, 0.82, 0)

  createCheckbox(frame, "ShirsLazyTrixShowItemIDs", "Show item IDs in tooltips", "showItemIDs", -421, 326, 260)

  local interfaceSection = createText(frame, "LOOT & MINIMAP", 11)
  interfaceSection:SetPoint("TOPLEFT", frame, "TOPLEFT", 326, -464)
  interfaceSection:SetTextColor(1, 0.82, 0)

  createCheckbox(frame, "ShirsLazyTrixExpandLootRows", "Expand Blizzard loot rows", "expandLootRows", -492, 326, 260)
  createCheckbox(
    frame,
    "ShirsLazyTrixConsolidateMinimapButtons",
    "Collect addon minimap buttons",
    "consolidateMinimapButtons",
    -479,
    326,
    260
  )
  ShirsLazyTrixConsolidateMinimapButtons:SetScript("OnClick", function()
    ShirsLazyTrixDB.consolidateMinimapButtons = this:GetChecked() and true or false
    if ShirsLazyTrix.RefreshMinimapButtonCollector and
       not ShirsLazyTrix.RefreshMinimapButtonCollector() and this:GetChecked() then
      this:SetChecked(nil)
      if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(
          "|cff73cfffLazyTrix:|r Disable the active minimap-button collector before enabling this option."
        )
      end
    end
  end)

  local lootSlider = CreateFrame("Slider", "ShirsLazyTrixLootRowsSlider", frame, "OptionsSliderTemplate")
  lootSlider:SetWidth(110)
  lootSlider:SetPoint("TOPLEFT", frame, "TOPLEFT", 334, -540)
  lootSlider:SetMinMaxValues(4, 12)
  lootSlider:SetValueStep(1)
  getglobal("ShirsLazyTrixLootRowsSliderLow"):SetText("4")
  getglobal("ShirsLazyTrixLootRowsSliderHigh"):SetText("12")
  lootSlider:SetScript("OnValueChanged", function()
    if refreshingSettings then return end
    local rows = ShirsLazyTrix.NormalizeLootRows(this:GetValue())
    if ShirsLazyTrix.ApplyLootRows then ShirsLazyTrix.ApplyLootRows(rows) end
    ShirsLazyTrixLootRowsSliderText:SetText("Loot rows: " .. rows)
  end)

  local buttonSizeSlider = CreateFrame("Slider", "ShirsLazyTrixMinimapButtonSizeSlider", frame, "OptionsSliderTemplate")
  buttonSizeSlider:SetWidth(110)
  buttonSizeSlider:SetPoint("TOPLEFT", frame, "TOPLEFT", 480, -540)
  buttonSizeSlider:SetMinMaxValues(18, 32)
  buttonSizeSlider:SetValueStep(1)
  getglobal("ShirsLazyTrixMinimapButtonSizeSliderLow"):SetText("18")
  getglobal("ShirsLazyTrixMinimapButtonSizeSliderHigh"):SetText("32")
  buttonSizeSlider:SetScript("OnValueChanged", function()
    if refreshingSettings then return end
    local size = ShirsLazyTrix.NormalizeMinimapButtonSize(this:GetValue())
    if ShirsLazyTrix.ApplyMinimapButtonSize then ShirsLazyTrix.ApplyMinimapButtonSize(size) end
    ShirsLazyTrixMinimapButtonSizeSliderText:SetText("Button size: " .. size)
  end)

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
  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
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
  button:SetScript("OnClick", function()
    if arg1 == "RightButton" then
      ShirsLazyTrix.ToggleSettings()
    elseif ShirsLazyTrixDB.consolidateMinimapButtons and ShirsLazyTrix.ToggleMinimapButtonTray then
      ShirsLazyTrix.ToggleMinimapButtonTray()
    else
      ShirsLazyTrix.ToggleSettings()
    end
  end)
  button:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
    GameTooltip:SetText("Shir's LazyTrix")
    if ShirsLazyTrixDB.consolidateMinimapButtons then
      GameTooltip:AddLine("Left click: Open addon buttons", 1, 1, 1)
      GameTooltip:AddLine("Right click: Open settings", 0.7, 0.8, 0.9)
    else
      GameTooltip:AddLine("Left click: Open settings", 1, 1, 1)
    end
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
  local minimapButton = createMinimapButton()
  if ShirsLazyTrix.InitializeMinimapButtonCollector then
    ShirsLazyTrix.InitializeMinimapButtonCollector(minimapButton)
  end
  if ShirsLazyTrix.RefreshLootRows then ShirsLazyTrix.RefreshLootRows() end
  createCooldownPanel()
  ShirsLazyTrix.RefreshCooldownPanelVisibility()
  createRaidInfoPanel()
  ShirsLazyTrix.RefreshRaidInfoPanelVisibility()
end
