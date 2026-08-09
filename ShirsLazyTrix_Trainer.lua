local TRAINER_ROWS = 18
local TRAINER_LIST_HEIGHT = 296
local CLASS_FRAME_HEIGHT = 624
local TRADE_FRAME_HEIGHT = 640
local TRAINER_HORIZONTAL_Y = -387
local TRAINER_MAX_CLEANUP_ROWS = 22
local MAX_COPPER = 2147483647
local TRAINER_PACE_SECONDS = 0.35
local TRAINER_RETRY_SECONDS = 0.75
local TRAINER_TIMEOUT_SECONDS = 3
local TRAINER_MAX_RETRIES = 2

local trainerFrame = nil
local trainAllActive = false
local trainAllWaiting = false
local lastPurchaseKey = nil
local lastPurchaseMoney = nil
local trainAllElapsed = 0
local trainAllStuckElapsed = 0
local trainAllRetryCount = 0
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
  button:SetPoint("BOTTOMLEFT", ClassTrainerFrame, "BOTTOMLEFT", 25, 54)
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

local function isTradeTrainer()
  return type(IsTradeskillTrainer) == "function" and IsTradeskillTrainer() and true or false
end

local function applyExpandedModeGeometry()
  local trade = isTradeTrainer()
  local height = trade and TRADE_FRAME_HEIGHT or CLASS_FRAME_HEIGHT
  ClassTrainerFrame:SetHeight(height)
  ClassTrainerListScrollFrame:SetHeight(TRAINER_LIST_HEIGHT)
  setPoint(ClassTrainerDetailScrollFrame, "TOPLEFT", ClassTrainerListScrollFrame, "BOTTOMLEFT", 0, -8)
  ClassTrainerDetailScrollFrame:SetHeight(trade and 135 or 119)
  setPoint(ClassTrainerCancelButton, "BOTTOMRIGHT", ClassTrainerFrame, "BOTTOMRIGHT", -42, 54)
  setPoint(ClassTrainerTrainButton, "RIGHT", ClassTrainerCancelButton, "LEFT", -1, 0)
  if ClassTrainerHorizontalBarLeft then
    setPoint(ClassTrainerHorizontalBarLeft, "TOPLEFT", ClassTrainerFrame, "TOPLEFT", 15, TRAINER_HORIZONTAL_Y)
    if type(ClassTrainerHorizontalBarLeft.Show) == "function" then ClassTrainerHorizontalBarLeft:Show() end
  end
  local button = getglobal("ShirsLazyTrixTrainAllButton")
  if button then setPoint(button, "BOTTOMLEFT", ClassTrainerFrame, "BOTTOMLEFT", 25, 54) end
  if type(UIPanelWindows) == "table" and type(UIPanelWindows["ClassTrainerFrame"]) == "table" then
    UIPanelWindows["ClassTrainerFrame"].height = height
  end
  CLASS_TRAINER_SKILLS_DISPLAYED = TRAINER_ROWS
end

function ShirsLazyTrix.ApplyTrainerLayout()
  if not trainerFramesAvailable() then return false end
  saveOriginalLayout()
  ensureTrainerRows()

  local oldBackdrop = getglobal("ShirsLazyTrixTrainerDetailsBackdrop")
  if oldBackdrop and type(oldBackdrop.Hide) == "function" then oldBackdrop:Hide() end
  local button = createTrainAllButton()
  button:Show()
  layoutApplied = true
  applyExpandedModeGeometry()
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
  for i = 12, TRAINER_MAX_CLEANUP_ROWS do
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

function ShirsLazyTrix.TryAutoOpenTrainer()
  if ShirsLazyTrix.EnsureDatabase then ShirsLazyTrix.EnsureDatabase() end
  if not ShirsLazyTrixDB or not exactBoolean(ShirsLazyTrixDB.autoOpenTrainers) then return false end
  if type(IsShiftKeyDown) == "function" then
    local held = IsShiftKeyDown()
    if held == true or held == 1 then return false end
  end
  if type(GetGossipOptions) ~= "function" or type(SelectGossipOption) ~= "function" then return false end

  local options = { GetGossipOptions() }
  local size = table.getn(options)
  if math.mod(size, 2) ~= 0 then return false end
  local found = nil
  local count = 0
  local i
  for i = 2, size, 2 do
    if options[i] == "trainer" then
      count = count + 1
      found = i / 2
    end
  end
  if count ~= 1 or not found then return false end
  local ok = pcall(SelectGossipOption, found)
  return ok and true or false
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
  lastPurchaseMoney = nil
  trainAllElapsed = 0
  trainAllStuckElapsed = 0
  trainAllRetryCount = 0
  ShirsLazyTrix.UpdateTrainAllButton()
end

local function submitTrainerService(index, key, money, retry)
  if not trainAllActive or not index or not key or not validCopper(money) then return false end
  if key ~= lastPurchaseKey then
    trainAllRetryCount = 0
    trainAllStuckElapsed = 0
  elseif retry then
    trainAllRetryCount = trainAllRetryCount + 1
  end
  lastPurchaseKey = key
  lastPurchaseMoney = money
  trainAllWaiting = true
  trainAllElapsed = 0
  local ok = pcall(BuyTrainerService, index)
  if not ok then
    ShirsLazyTrix.CancelTrainAll()
    return false
  end
  ShirsLazyTrix.UpdateTrainAllButton()
  return true
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
    return false
  end
  return submitTrainerService(index, key, money, false)
end

function ShirsLazyTrix.HandleTrainerOnUpdate(elapsed)
  if not trainAllActive or not trainAllWaiting then return false end
  if type(elapsed) ~= "number" or elapsed < 0 then elapsed = 0 end
  trainAllElapsed = trainAllElapsed + elapsed
  trainAllStuckElapsed = trainAllStuckElapsed + elapsed
  if trainAllElapsed < TRAINER_PACE_SECONDS then return false end

  local count, total, index, key = ShirsLazyTrix.GetTrainAllPlan()
  local money = type(GetMoney) == "function" and GetMoney() or nil
  if count == 0 or not index or not key then
    ShirsLazyTrix.CancelTrainAll()
    return false
  end
  if not validCopper(money) then
    ShirsLazyTrix.CancelTrainAll()
    return false
  end
  if key ~= lastPurchaseKey then
    if total > money then
      ShirsLazyTrix.CancelTrainAll()
      return false
    end
    trainAllWaiting = false
    return buyNextTrainerService()
  end

  if trainAllStuckElapsed >= TRAINER_TIMEOUT_SECONDS then
    ShirsLazyTrix.CancelTrainAll()
    return false
  end
  if trainAllElapsed >= TRAINER_RETRY_SECONDS and trainAllRetryCount < TRAINER_MAX_RETRIES and money == lastPurchaseMoney then
    return submitTrainerService(index, key, money, true)
  end
  return false
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
  lastPurchaseMoney = nil
  trainAllElapsed = 0
  trainAllStuckElapsed = 0
  trainAllRetryCount = 0
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
      ShirsLazyTrix.UpdateTrainAllButton()
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
      applyExpandedModeGeometry()
    end
  end
  ClassTrainer_SetToClassTrainer = function()
    originalClassMode()
    if layoutApplied and ShirsLazyTrixDB and exactBoolean(ShirsLazyTrixDB.enhanceTrainers) then
      applyExpandedModeGeometry()
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
  trainerFrame:SetScript("OnUpdate", function() ShirsLazyTrix.HandleTrainerOnUpdate(arg1 or 0) end)
  return trainerFrame
end

ShirsLazyTrix.InitializeTrainer()
