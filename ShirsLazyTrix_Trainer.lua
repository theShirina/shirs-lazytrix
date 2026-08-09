local TRAINER_ROWS = 22
local MAX_COPPER = 2147483647

local trainerFrame = nil
local trainAllActive = false
local trainAllWaiting = false
local lastPurchaseKey = nil
local layoutApplied = false
local originalLayout = nil
local trainerHooksInstalled = false
local originalTradeSkillMode = nil
local originalClassMode = nil

local function exactBoolean(value)
  return value == true
end

local function validCopper(value)
  return type(value) == "number" and value >= 0 and value <= MAX_COPPER
end

local function validPointCost(value)
  return type(value) == "number" and value == 0
end

local function framePoint(frame)
  if not frame or type(frame.GetPoint) ~= "function" then return nil end
  return { frame:GetPoint() }
end

local function saveFrame(frame)
  if not frame then return nil end
  local saved = {
    point = framePoint(frame),
    shown = type(frame.IsShown) == "function" and frame:IsShown() and true or false,
  }
  if type(frame.GetWidth) == "function" then saved.width = frame:GetWidth() end
  if type(frame.GetHeight) == "function" then saved.height = frame:GetHeight() end
  return saved
end

local function restoreFrame(frame, saved)
  if not frame or not saved then return end
  if saved.width and type(frame.SetWidth) == "function" then frame:SetWidth(saved.width) end
  if saved.height and type(frame.SetHeight) == "function" then frame:SetHeight(saved.height) end
  if saved.point and saved.point[1] and type(frame.ClearAllPoints) == "function" and type(frame.SetPoint) == "function" then
    frame:ClearAllPoints()
    frame:SetPoint(unpack(saved.point))
  end
  if saved.shown and type(frame.Show) == "function" then
    frame:Show()
  elseif not saved.shown and type(frame.Hide) == "function" then
    frame:Hide()
  end
end

local function savePanelEntry()
  if type(UIPanelWindows) ~= "table" or type(UIPanelWindows["ClassTrainerFrame"]) ~= "table" then return nil end
  local copy = {}
  local key, value
  for key, value in pairs(UIPanelWindows["ClassTrainerFrame"]) do copy[key] = value end
  return copy
end

local function saveOriginalLayout()
  if originalLayout then return end
  originalLayout = {
    panel = savePanelEntry(),
    frame = saveFrame(ClassTrainerFrame),
    list = saveFrame(ClassTrainerListScrollFrame),
    detail = saveFrame(ClassTrainerDetailScrollFrame),
    train = saveFrame(ClassTrainerTrainButton),
    cancel = saveFrame(ClassTrainerCancelButton),
    close = saveFrame(ClassTrainerFrameCloseButton),
    filter = saveFrame(ClassTrainerFrameFilterDropDown),
    money = saveFrame(ClassTrainerMoneyFrame),
    greeting = saveFrame(ClassTrainerGreetingText),
    horizontal = saveFrame(ClassTrainerHorizontalBarLeft),
  }
end

local function setPoint(frame, point, relative, relativePoint, x, y)
  if not frame or type(frame.ClearAllPoints) ~= "function" or type(frame.SetPoint) ~= "function" then return end
  frame:ClearAllPoints()
  frame:SetPoint(point, relative, relativePoint, x, y)
end

local function ensureTrainerRows()
  local i
  for i = 12, TRAINER_ROWS do
    local name = "ClassTrainerSkill" .. i
    local button = getglobal(name)
    if not button then
      local previous = getglobal("ClassTrainerSkill" .. (i - 1))
      button = CreateFrame("Button", name, ClassTrainerFrame, "ClassTrainerSkillButtonTemplate")
      button:SetID(i)
      button:Hide()
      setPoint(button, "TOPLEFT", previous, "BOTTOMLEFT", 0, 1)
    end
  end
end

local function createDetailsBackdrop()
  local backdrop = getglobal("ShirsLazyTrixTrainerDetailsBackdrop")
  if backdrop then return backdrop end
  backdrop = CreateFrame("Frame", "ShirsLazyTrixTrainerDetailsBackdrop", ClassTrainerFrame)
  backdrop:SetWidth(332)
  backdrop:SetHeight(361)
  backdrop:SetPoint("TOPLEFT", ClassTrainerFrame, "TOPLEFT", 336, -72)
  if type(backdrop.SetBackdrop) == "function" then
    backdrop:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true,
      tileSize = 16,
      edgeSize = 12,
      insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    if type(backdrop.SetBackdropColor) == "function" then backdrop:SetBackdropColor(0.08, 0.06, 0.03, 0.92) end
    if type(backdrop.SetBackdropBorderColor) == "function" then backdrop:SetBackdropBorderColor(0.55, 0.43, 0.24, 1) end
  end
  return backdrop
end

local function buttonTooltip()
  if not GameTooltip or type(GameTooltip.SetOwner) ~= "function" then return end
  local count, total = ShirsLazyTrix.GetTrainAllPlan()
  GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
  GameTooltip:SetText("Train All")
  if count > 0 and type(GetCoinTextureString) == "function" then
    GameTooltip:AddLine("Cost: " .. GetCoinTextureString(total), 1, 1, 1)
  else
    GameTooltip:AddLine("Trains every safe and affordable available service.", 1, 1, 1)
  end
  GameTooltip:AddLine("New primary professions are skipped.", 0.75, 0.82, 0.9)
  GameTooltip:Show()
end

local function createTrainAllButton()
  local button = getglobal("ShirsLazyTrixTrainAllButton")
  if button then return button end
  button = CreateFrame("Button", "ShirsLazyTrixTrainAllButton", ClassTrainerFrame, "UIPanelButtonTemplate")
  button:SetWidth(90)
  button:SetHeight(22)
  button:SetText("Train All")
  button:SetPoint("BOTTOMLEFT", ClassTrainerFrame, "BOTTOMLEFT", 352, 54)
  button:SetScript("OnClick", function() ShirsLazyTrix.StartTrainAll() end)
  button:SetScript("OnEnter", buttonTooltip)
  button:SetScript("OnLeave", function()
    if GameTooltip and type(GameTooltip.Hide) == "function" then GameTooltip:Hide() end
  end)
  return button
end

local function trainerFramesAvailable()
  return ClassTrainerFrame and ClassTrainerListScrollFrame and ClassTrainerDetailScrollFrame and
    ClassTrainerTrainButton and ClassTrainerCancelButton and ClassTrainerFrameCloseButton
end

function ShirsLazyTrix.ApplyTrainerLayout()
  if not trainerFramesAvailable() then return false end
  saveOriginalLayout()
  ensureTrainerRows()

  if type(UIPanelWindows) == "table" then
    UIPanelWindows["ClassTrainerFrame"] = UIPanelWindows["ClassTrainerFrame"] or {}
    local panel = UIPanelWindows["ClassTrainerFrame"]
    panel.area = "override"
    panel.pushable = 1
    panel.xoffset = -16
    panel.yoffset = 12
    panel.bottomClampOverride = 152
    panel.width = 714
    panel.height = 487
    panel.whileDead = 1
  end

  ClassTrainerFrame:SetWidth(714)
  ClassTrainerFrame:SetHeight(487)
  setPoint(ClassTrainerListScrollFrame, "TOPLEFT", ClassTrainerFrame, "TOPLEFT", 25, -75)
  ClassTrainerListScrollFrame:SetWidth(295)
  ClassTrainerListScrollFrame:SetHeight(336)
  setPoint(ClassTrainerDetailScrollFrame, "TOPLEFT", ClassTrainerFrame, "TOPLEFT", 352, -74)
  ClassTrainerDetailScrollFrame:SetWidth(296)
  ClassTrainerDetailScrollFrame:SetHeight(336)
  setPoint(ClassTrainerCancelButton, "BOTTOMRIGHT", ClassTrainerFrame, "BOTTOMRIGHT", -42, 54)
  setPoint(ClassTrainerTrainButton, "RIGHT", ClassTrainerCancelButton, "LEFT", -1, 0)
  setPoint(ClassTrainerFrameCloseButton, "TOPRIGHT", ClassTrainerFrame, "TOPRIGHT", -30, -8)
  if ClassTrainerFrameFilterDropDown then
    setPoint(ClassTrainerFrameFilterDropDown, "TOPLEFT", ClassTrainerFrame, "TOPLEFT", 501, -40)
  end
  if ClassTrainerMoneyFrame then
    setPoint(ClassTrainerMoneyFrame, "TOPLEFT", ClassTrainerFrame, "TOPLEFT", 143, -49)
  end
  if ClassTrainerGreetingText and type(ClassTrainerGreetingText.Hide) == "function" then ClassTrainerGreetingText:Hide() end
  if ClassTrainerHorizontalBarLeft and type(ClassTrainerHorizontalBarLeft.Hide) == "function" then ClassTrainerHorizontalBarLeft:Hide() end
  if ClassTrainerSkillHighlightFrame and type(ClassTrainerSkillHighlightFrame.SetWidth) == "function" then
    ClassTrainerSkillHighlightFrame:SetWidth(290)
  end

  local backdrop = createDetailsBackdrop()
  backdrop:Show()
  local button = createTrainAllButton()
  button:Show()
  CLASS_TRAINER_SKILLS_DISPLAYED = TRAINER_ROWS
  layoutApplied = true
  if type(ClassTrainerFrame_Update) == "function" then ClassTrainerFrame_Update() end
  return true
end

function ShirsLazyTrix.RestoreTrainerLayout()
  ShirsLazyTrix.CancelTrainAll()
  if not layoutApplied or not originalLayout then return false end

  if type(UIPanelWindows) == "table" and originalLayout.panel then
    UIPanelWindows["ClassTrainerFrame"] = {}
    local key, value
    for key, value in pairs(originalLayout.panel) do UIPanelWindows["ClassTrainerFrame"][key] = value end
  end
  restoreFrame(ClassTrainerFrame, originalLayout.frame)
  restoreFrame(ClassTrainerListScrollFrame, originalLayout.list)
  restoreFrame(ClassTrainerDetailScrollFrame, originalLayout.detail)
  restoreFrame(ClassTrainerTrainButton, originalLayout.train)
  restoreFrame(ClassTrainerCancelButton, originalLayout.cancel)
  restoreFrame(ClassTrainerFrameCloseButton, originalLayout.close)
  restoreFrame(ClassTrainerFrameFilterDropDown, originalLayout.filter)
  restoreFrame(ClassTrainerMoneyFrame, originalLayout.money)
  restoreFrame(ClassTrainerGreetingText, originalLayout.greeting)
  restoreFrame(ClassTrainerHorizontalBarLeft, originalLayout.horizontal)

  local i
  for i = 12, TRAINER_ROWS do
    local row = getglobal("ClassTrainerSkill" .. i)
    if row and type(row.Hide) == "function" then row:Hide() end
  end
  local backdrop = getglobal("ShirsLazyTrixTrainerDetailsBackdrop")
  if backdrop then backdrop:Hide() end
  local button = getglobal("ShirsLazyTrixTrainAllButton")
  if button then button:Hide() end
  if type(IsTradeskillTrainer) == "function" and IsTradeskillTrainer() then
    CLASS_TRAINER_SKILLS_DISPLAYED = 10
  else
    CLASS_TRAINER_SKILLS_DISPLAYED = 11
  end
  layoutApplied = false
  if type(ClassTrainerFrame_Update) == "function" then ClassTrainerFrame_Update() end
  return true
end

function ShirsLazyTrix.RefreshTrainerFeature()
  if ShirsLazyTrix.EnsureDatabase then ShirsLazyTrix.EnsureDatabase() end
  if not ShirsLazyTrixDB or not exactBoolean(ShirsLazyTrixDB.enhanceTrainers) then
    ShirsLazyTrix.RestoreTrainerLayout()
    return false
  end
  if not trainerFramesAvailable() then return false end
  return ShirsLazyTrix.ApplyTrainerLayout()
end

local function trainerApisAvailable()
  return type(GetNumTrainerServices) == "function" and type(GetTrainerServiceInfo) == "function" and
    type(GetTrainerServiceCost) == "function" and type(GetMoney) == "function" and
    type(BuyTrainerService) == "function"
end

function ShirsLazyTrix.GetTrainAllPlan()
  if not ShirsLazyTrixDB or not exactBoolean(ShirsLazyTrixDB.enhanceTrainers) or not trainerApisAvailable() then
    return 0, 0, nil, nil
  end
  local number = GetNumTrainerServices()
  if type(number) ~= "number" or number < 0 or number > 1000 then return 0, 0, nil, nil end

  local count = 0
  local total = 0
  local firstIndex = nil
  local firstKey = nil
  local i
  for i = 1, number do
    local name, subText, serviceType = GetTrainerServiceInfo(i)
    if type(name) == "string" and serviceType == "available" then
      local money, cp1, cp2 = GetTrainerServiceCost(i)
      if validCopper(money) and validPointCost(cp1) and validPointCost(cp2) and total <= MAX_COPPER - money then
        count = count + 1
        total = total + money
        if not firstIndex then
          firstIndex = i
          firstKey = name .. "\031" .. tostring(subText or "") .. "\031" .. tostring(money)
        end
      end
    end
  end
  return count, total, firstIndex, firstKey
end

function ShirsLazyTrix.IsTrainAllActive()
  return trainAllActive and true or false
end

function ShirsLazyTrix.UpdateTrainAllButton()
  local button = getglobal("ShirsLazyTrixTrainAllButton")
  if not button then return end
  if trainAllActive then
    button:SetText("Training...")
    button:Disable()
    return
  end
  local count, total = ShirsLazyTrix.GetTrainAllPlan()
  local money = type(GetMoney) == "function" and GetMoney() or nil
  if count > 0 then button:SetText("Train All (" .. count .. ")") else button:SetText("Train All") end
  if count > 0 and validCopper(money) and total <= money then
    button:Enable()
  else
    button:Disable()
  end
end

function ShirsLazyTrix.CancelTrainAll()
  trainAllActive = false
  trainAllWaiting = false
  lastPurchaseKey = nil
  ShirsLazyTrix.UpdateTrainAllButton()
end

local function buyNextTrainerService()
  if not trainAllActive or trainAllWaiting then return false end
  local count, total, index, key = ShirsLazyTrix.GetTrainAllPlan()
  local money = type(GetMoney) == "function" and GetMoney() or nil
  if count == 0 or not index or not key or not validCopper(money) or total > money then
    ShirsLazyTrix.CancelTrainAll()
    return false
  end
  if key == lastPurchaseKey then
    ShirsLazyTrix.CancelTrainAll()
    return false
  end
  lastPurchaseKey = key
  trainAllWaiting = true
  local ok = pcall(BuyTrainerService, index)
  if not ok then
    ShirsLazyTrix.CancelTrainAll()
    return false
  end
  ShirsLazyTrix.UpdateTrainAllButton()
  return true
end

function ShirsLazyTrix.StartTrainAll()
  if ShirsLazyTrix.EnsureDatabase then ShirsLazyTrix.EnsureDatabase() end
  if trainAllActive or not ShirsLazyTrixDB or not exactBoolean(ShirsLazyTrixDB.enhanceTrainers) then return false end
  if type(ExpandTrainerSkillLine) == "function" then ExpandTrainerSkillLine(0) end
  local count, total = ShirsLazyTrix.GetTrainAllPlan()
  local money = type(GetMoney) == "function" and GetMoney() or nil
  if count == 0 or not validCopper(money) or total > money then
    ShirsLazyTrix.UpdateTrainAllButton()
    return false
  end
  trainAllActive = true
  trainAllWaiting = false
  lastPurchaseKey = nil
  return buyNextTrainerService()
end

function ShirsLazyTrix.HandleTrainerEvent(name)
  if name == "TRAINER_CLOSED" then
    ShirsLazyTrix.CancelTrainAll()
    return
  end
  if name == "TRAINER_SHOW" then
    ShirsLazyTrix.CancelTrainAll()
    if ShirsLazyTrix.RefreshTrainerFeature() and type(ExpandTrainerSkillLine) == "function" then
      ExpandTrainerSkillLine(0)
    end
    ShirsLazyTrix.UpdateTrainAllButton()
    return
  end
  if name == "TRAINER_UPDATE" then
    if trainAllActive then
      trainAllWaiting = false
      buyNextTrainerService()
    else
      ShirsLazyTrix.UpdateTrainAllButton()
    end
  end
end

function ShirsLazyTrix.InstallTrainerHooks()
  if trainerHooksInstalled then return true end
  if type(ClassTrainer_SetToTradeSkillTrainer) ~= "function" or type(ClassTrainer_SetToClassTrainer) ~= "function" then
    return false
  end
  originalTradeSkillMode = ClassTrainer_SetToTradeSkillTrainer
  originalClassMode = ClassTrainer_SetToClassTrainer
  ClassTrainer_SetToTradeSkillTrainer = function()
    originalTradeSkillMode()
    if layoutApplied and ShirsLazyTrixDB and exactBoolean(ShirsLazyTrixDB.enhanceTrainers) then
      CLASS_TRAINER_SKILLS_DISPLAYED = TRAINER_ROWS
      ClassTrainerListScrollFrame:SetHeight(336)
      ClassTrainerDetailScrollFrame:SetHeight(336)
    end
  end
  ClassTrainer_SetToClassTrainer = function()
    originalClassMode()
    if layoutApplied and ShirsLazyTrixDB and exactBoolean(ShirsLazyTrixDB.enhanceTrainers) then
      CLASS_TRAINER_SKILLS_DISPLAYED = TRAINER_ROWS
      ClassTrainerListScrollFrame:SetHeight(336)
      ClassTrainerDetailScrollFrame:SetHeight(336)
    end
  end
  trainerHooksInstalled = true
  return true
end

function ShirsLazyTrix.InitializeTrainer()
  if trainerFrame then return trainerFrame end
  ShirsLazyTrix.InstallTrainerHooks()
  trainerFrame = CreateFrame("Frame", "ShirsLazyTrixTrainerEventFrame")
  trainerFrame:RegisterEvent("TRAINER_SHOW")
  trainerFrame:RegisterEvent("TRAINER_UPDATE")
  trainerFrame:RegisterEvent("TRAINER_CLOSED")
  trainerFrame:SetScript("OnEvent", function() ShirsLazyTrix.HandleTrainerEvent(event) end)
  return trainerFrame
end

ShirsLazyTrix.InitializeTrainer()
