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
local lastPurchaseListSignature = nil
local trainAllElapsed = 0
local trainAllStuckElapsed = 0
local trainAllRetryCount = 0
local trainAllSnapshot = nil
local trainAllPosition = 0
local trainAllSubmitting = false
local trainAllSawUpdate = false
local layoutApplied = false
local originalLayout = nil
local trainerHooksInstalled = false
local originalTradeSkillMode = nil
local originalClassMode = nil

local function exactBoolean(value)
  return value == true
end

local function validCopper(value)
  if type(value) ~= "number" then return false end
  local text = string.lower(tostring(value))
  if string.find(text, "nan", 1, true) or string.find(text, "inf", 1, true) or string.find(text, "ind", 1, true) then return false end
  if value < 0 or value > MAX_COPPER then return false end
  local ok, whole = pcall(math.floor, value)
  return ok and whole == value
end

local function validPointCost(value)
  return validCopper(value) and value == 0
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
      setPoint(button, "TOPLEFT", previous, "BOTTOMLEFT", 0, 0)
      if type(SkinCollapseButton) == "function" then pcall(SkinCollapseButton, button) end
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
  if ShirsLazyTrix.InstallTrainerHooks then ShirsLazyTrix.InstallTrainerHooks() end
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

local function trainerVisible()
  if not ClassTrainerFrame or type(ClassTrainerFrame.IsVisible) ~= "function" then return false end
  local ok, visible = pcall(ClassTrainerFrame.IsVisible, ClassTrainerFrame)
  return ok and (visible == true or visible == 1)
end

local function safeServiceCount()
  if type(GetNumTrainerServices) ~= "function" then return nil end
  local ok, number = pcall(GetNumTrainerServices)
  if not ok or type(number) ~= "number" or number < 0 or number > 1000 then return nil end
  local wholeOk, whole = pcall(math.floor, number)
  if not wholeOk or whole ~= number then return nil end
  return number
end

local function serviceIdentity(name, subText)
  if type(name) ~= "string" or not string.find(name, "%S") then return nil end
  if subText == nil then subText = "" end
  if type(subText) ~= "string" then return nil end
  if string.find(name, "\029", 1, true) or string.find(name, "\030", 1, true) or string.find(name, "\031", 1, true) or
     string.find(subText, "\029", 1, true) or string.find(subText, "\030", 1, true) or string.find(subText, "\031", 1, true) then return nil end
  return name .. "\031" .. subText
end

local function readServiceInfo(index)
  if type(GetTrainerServiceInfo) ~= "function" then return nil end
  local ok, name, subText, serviceType = pcall(GetTrainerServiceInfo, index)
  if not ok or type(serviceType) ~= "string" then return nil end
  local identity = serviceIdentity(name, subText)
  if not identity then return nil end
  return { identity = identity, name = name, subText = subText or "", serviceType = serviceType }
end

local function readServiceCost(index)
  if type(GetTrainerServiceCost) ~= "function" then return nil end
  local ok, money, cp1, cp2 = pcall(GetTrainerServiceCost, index)
  if not ok or not validCopper(money) or not validCopper(cp1) or not validCopper(cp2) then return nil end
  return money, cp1, cp2
end

local function buildTrainAllSnapshot()
  if not ShirsLazyTrixDB or not exactBoolean(ShirsLazyTrixDB.enhanceTrainers) or
     not trainerVisible() or not trainerApisAvailable() then return nil, nil end
  local number = safeServiceCount()
  if not number then return nil, nil end
  local snapshot = {}
  local seen = {}
  local total = 0
  local i
  for i = 1, number do
    local info = readServiceInfo(i)
    if not info then return nil, nil end
    if info.serviceType == "available" then
      if not string.find(info.subText, "%S") then return nil, nil end
      local money, cp1, cp2 = readServiceCost(i)
      if money == nil then return nil, nil end
      if cp1 == 0 and cp2 == 0 then
        if seen[info.identity] or total > MAX_COPPER - money then return nil, nil end
        seen[info.identity] = true
        total = total + money
        table.insert(snapshot, {
          identity = info.identity,
          name = info.name,
          subText = info.subText,
          money = money,
          initialIndex = i,
        })
      end
    end
  end
  return snapshot, total
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
  local snapshot, total = buildTrainAllSnapshot()
  if not snapshot or table.getn(snapshot) == 0 then return 0, 0, nil, nil end
  local first = snapshot[1]
  return table.getn(snapshot), total, first.initialIndex, first.identity
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
  local ok, money = false, nil
  if type(GetMoney) == "function" then ok, money = pcall(GetMoney) end
  if count > 0 then button:SetText("Train All (" .. count .. ")") else button:SetText("Train All") end
  if count > 0 and ok and validCopper(money) and total <= money then
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
  lastPurchaseListSignature = nil
  trainAllElapsed = 0
  trainAllStuckElapsed = 0
  trainAllRetryCount = 0
  trainAllSnapshot = nil
  trainAllPosition = 0
  trainAllSubmitting = false
  trainAllSawUpdate = false
  ShirsLazyTrix.UpdateTrainAllButton()
end

local function findSnapshotService(identity)
  local number = safeServiceCount()
  if not number then return nil, nil, nil end
  local matches = 0
  local foundIndex = nil
  local foundInfo = nil
  local i
  for i = 1, number do
    local info = readServiceInfo(i)
    if not info then return nil, nil, nil end
    if info.identity == identity then
      matches = matches + 1
      foundIndex = i
      foundInfo = info
    end
  end
  return matches, foundIndex, foundInfo
end

local function remainingSnapshotCost()
  if not trainAllSnapshot then return nil end
  local total = 0
  local i
  for i = trainAllPosition, table.getn(trainAllSnapshot) do
    local money = trainAllSnapshot[i].money
    if not validCopper(money) or total > MAX_COPPER - money then return nil end
    total = total + money
  end
  return total
end

local function currentTrainerListSignature()
  local number = safeServiceCount()
  if not number then return nil end
  local parts = {}
  local i
  for i = 1, number do
    local info = readServiceInfo(i)
    if not info or string.find(info.serviceType, "\029", 1, true) or
       string.find(info.serviceType, "\030", 1, true) or string.find(info.serviceType, "\031", 1, true) then return nil end
    table.insert(parts, info.identity .. "\030" .. info.serviceType)
  end
  return table.concat(parts, "\029")
end

local function submitCurrentSnapshot(retry)
  if not trainAllActive or trainAllSubmitting or not trainAllSnapshot then return false end
  if not ShirsLazyTrixDB or not exactBoolean(ShirsLazyTrixDB.enhanceTrainers) or
     not trainerVisible() or not trainerApisAvailable() then
    ShirsLazyTrix.CancelTrainAll()
    return false
  end
  local entry = trainAllSnapshot[trainAllPosition]
  if not entry then
    ShirsLazyTrix.CancelTrainAll()
    return false
  end
  local matches, index, info = findSnapshotService(entry.identity)
  if matches ~= 1 or not index or not info or info.serviceType ~= "available" then
    ShirsLazyTrix.CancelTrainAll()
    return false
  end
  local moneyCost, cp1, cp2 = readServiceCost(index)
  if moneyCost == nil or moneyCost ~= entry.money or not validPointCost(cp1) or not validPointCost(cp2) then
    ShirsLazyTrix.CancelTrainAll()
    return false
  end
  local moneyOk, money = pcall(GetMoney)
  local remaining = remainingSnapshotCost()
  local listSignature = currentTrainerListSignature()
  if not moneyOk or not validCopper(money) or not remaining or remaining > money or not listSignature then
    ShirsLazyTrix.CancelTrainAll()
    return false
  end
  if entry.identity ~= lastPurchaseKey then
    trainAllRetryCount = 0
    trainAllStuckElapsed = 0
  elseif retry then
    trainAllRetryCount = trainAllRetryCount + 1
  end
  lastPurchaseKey = entry.identity
  lastPurchaseMoney = money
  lastPurchaseListSignature = listSignature
  trainAllWaiting = true
  trainAllElapsed = 0
  trainAllSawUpdate = false
  trainAllSubmitting = true
  local ok = pcall(BuyTrainerService, index)
  trainAllSubmitting = false
  if not ok or not trainAllActive then
    ShirsLazyTrix.CancelTrainAll()
    return false
  end
  ShirsLazyTrix.UpdateTrainAllButton()
  return true
end

local function advanceTrainAllSnapshot()
  trainAllPosition = trainAllPosition + 1
  if not trainAllSnapshot or trainAllPosition > table.getn(trainAllSnapshot) then
    ShirsLazyTrix.CancelTrainAll()
    return false
  end
  trainAllWaiting = false
  trainAllElapsed = 0
  trainAllStuckElapsed = 0
  trainAllRetryCount = 0
  lastPurchaseKey = nil
  lastPurchaseMoney = nil
  lastPurchaseListSignature = nil
  return submitCurrentSnapshot(false)
end

function ShirsLazyTrix.HandleTrainerOnUpdate(elapsed)
  if not trainAllActive or not trainAllWaiting or trainAllSubmitting then return false end
  if not ShirsLazyTrixDB or not exactBoolean(ShirsLazyTrixDB.enhanceTrainers) or
     not trainerVisible() or not trainerApisAvailable() then
    ShirsLazyTrix.CancelTrainAll()
    return false
  end
  if type(elapsed) ~= "number" or elapsed < 0 then elapsed = 0 end
  trainAllElapsed = trainAllElapsed + elapsed
  trainAllStuckElapsed = trainAllStuckElapsed + elapsed
  if trainAllElapsed < TRAINER_PACE_SECONDS then return false end

  local entry = trainAllSnapshot and trainAllSnapshot[trainAllPosition] or nil
  if not entry then
    ShirsLazyTrix.CancelTrainAll()
    return false
  end
  local matches, index, info = findSnapshotService(entry.identity)
  if matches == nil or matches > 1 then
    ShirsLazyTrix.CancelTrainAll()
    return false
  end
  if matches == 0 then
    if trainAllSawUpdate then return advanceTrainAllSnapshot() end
  elseif info.serviceType == "used" then
    if trainAllSawUpdate then return advanceTrainAllSnapshot() end
  elseif info.serviceType ~= "available" then
    ShirsLazyTrix.CancelTrainAll()
    return false
  else
    local moneyCost, cp1, cp2 = readServiceCost(index)
    if moneyCost == nil or moneyCost ~= entry.money or not validPointCost(cp1) or not validPointCost(cp2) then
      ShirsLazyTrix.CancelTrainAll()
      return false
    end
    local moneyOk, money = pcall(GetMoney)
    if not moneyOk or not validCopper(money) then
      ShirsLazyTrix.CancelTrainAll()
      return false
    end
    if trainAllElapsed >= TRAINER_RETRY_SECONDS and trainAllSawUpdate and
       trainAllRetryCount < TRAINER_MAX_RETRIES and money == lastPurchaseMoney then
      local listSignature = currentTrainerListSignature()
      if not listSignature or listSignature ~= lastPurchaseListSignature then
        ShirsLazyTrix.CancelTrainAll()
        return false
      end
      return submitCurrentSnapshot(true)
    end
  end

  if trainAllStuckElapsed >= TRAINER_TIMEOUT_SECONDS then
    ShirsLazyTrix.CancelTrainAll()
  end
  return false
end

function ShirsLazyTrix.StartTrainAll()
  if ShirsLazyTrix.EnsureDatabase then ShirsLazyTrix.EnsureDatabase() end
  if trainAllActive or not ShirsLazyTrixDB or not exactBoolean(ShirsLazyTrixDB.enhanceTrainers) or
     not trainerVisible() then return false end
  if type(ExpandTrainerSkillLine) == "function" then ExpandTrainerSkillLine(0) end
  local snapshot, total = buildTrainAllSnapshot()
  local moneyOk, money = false, nil
  if type(GetMoney) == "function" then moneyOk, money = pcall(GetMoney) end
  if not snapshot or table.getn(snapshot) == 0 or not moneyOk or not validCopper(money) or total > money then
    ShirsLazyTrix.UpdateTrainAllButton()
    return false
  end
  trainAllActive = true
  trainAllWaiting = false
  trainAllSnapshot = snapshot
  trainAllPosition = 1
  trainAllSubmitting = false
  trainAllSawUpdate = false
  lastPurchaseKey = nil
  lastPurchaseMoney = nil
  lastPurchaseListSignature = nil
  trainAllElapsed = 0
  trainAllStuckElapsed = 0
  trainAllRetryCount = 0
  return submitCurrentSnapshot(false)
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
    if trainAllActive then trainAllSawUpdate = true end
    ShirsLazyTrix.UpdateTrainAllButton()
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
  if trainerFrame then
    ShirsLazyTrix.InstallTrainerHooks()
    return trainerFrame
  end
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
