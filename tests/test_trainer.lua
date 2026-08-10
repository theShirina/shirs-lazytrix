-- Shir's LazyTrix trainer layout and Train All tests for Lua 5.0.3

local root = arg and arg[1] or "."
local named = {}
local createdSkillRows = 0
local bought = {}
local services = {}
local playerMoney = 0
local gossipOptions = {}
local selectedGossip = {}
local shiftDown = false
local tradeskillTrainer = false
local playerSkills = {}
local trainerInfoReads = 0
local trainerInfoMutation = nil
local trainerSkillLineReads = 0
local trainerSkillLineMutation = nil

local function makeFrame(name)
  local frame = {
    name = name,
    shown = true,
    enabled = true,
    scripts = {},
    events = {},
  }
  function frame:SetWidth(value) self.width = value end
  function frame:SetHeight(value) self.height = value end
  function frame:GetWidth() return self.width end
  function frame:GetHeight() return self.height end
  function frame:SetScale(value) self.scale = value end
  function frame:GetScale() return self.scale or 1 end
  function frame:SetPoint(...)
    self.point = arg
    if not self.points then self.points = {} end
    table.insert(self.points, arg)
  end
  function frame:GetPoint() if self.point then return unpack(self.point) end end
  function frame:ClearAllPoints() self.point = nil self.points = {} end
  function frame:SetID(value) self.id = value end
  function frame:SetText(value) self.text = value end
  function frame:GetText() return self.text end
  function frame:SetScript(name, handler) self.scripts[name] = handler end
  function frame:GetScript(name) return self.scripts[name] end
  function frame:RegisterEvent(name) self.events[name] = true end
  function frame:Show() self.shown = true end
  function frame:Hide() self.shown = false end
  function frame:IsVisible() return self.shown end
  function frame:IsShown() return self.shown end
  function frame:Enable() self.enabled = true end
  function frame:Disable() self.enabled = false end
  function frame:IsEnabled() return self.enabled end
  function frame:SetBackdrop(value) self.backdrop = value end
  function frame:SetBackdropColor(...) self.backdropColor = arg end
  function frame:SetBackdropBorderColor(...) self.backdropBorderColor = arg end
  function frame:SetTexture(...) self.texture = arg end
  function frame:SetTexCoord(...) self.texCoord = arg end
  function frame:SetFont(path, size, flags) self.font = { path, size, flags } end
  function frame:GetFont()
    if self.font then return self.font[1], self.font[2], self.font[3] end
  end
  function frame:GetFontString() return self.fontString end
  function frame:GetNormalTexture() return self.normalTexture end

  function frame:CreateTexture(childName, layer)
    local texture = makeFrame(childName)
    texture.parent = self
    texture.layer = layer
    if childName then
      named[childName] = texture
      _G[childName] = texture
    end
    return texture
  end
  return frame
end

function CreateFrame(_, name, parent, template)
  local frame = makeFrame(name)
  frame.parent = parent
  frame.template = template
  if name then
    named[name] = frame
    _G[name] = frame
  end
  if template == "ClassTrainerSkillButtonTemplate" then
    createdSkillRows = createdSkillRows + 1
  end
  return frame
end

function getglobal(name) return named[name] end
function SkinCollapseButton(button) button.pfUISkinned = true end

ClassTrainerFrame = makeFrame("ClassTrainerFrame")
ClassTrainerFrame.width = 384
ClassTrainerFrame.height = 512
ClassTrainerFrame.shown = true
ClassTrainerListScrollFrame = makeFrame("ClassTrainerListScrollFrame")
ClassTrainerListScrollFrame.width = 293
ClassTrainerListScrollFrame.height = 184
ClassTrainerListScrollFrameScrollBarScrollUpButton = makeFrame("ClassTrainerListScrollFrameScrollBarScrollUpButton")
ClassTrainerListScrollFrameScrollBarScrollDownButton = makeFrame("ClassTrainerListScrollFrameScrollBarScrollDownButton")
ClassTrainerDetailScrollFrame = makeFrame("ClassTrainerDetailScrollFrame")
ClassTrainerDetailScrollFrame.width = 296
ClassTrainerDetailScrollFrame.height = 119
ClassTrainerTrainButton = makeFrame("ClassTrainerTrainButton")
ClassTrainerCancelButton = makeFrame("ClassTrainerCancelButton")
ClassTrainerFrameCloseButton = makeFrame("ClassTrainerFrameCloseButton")
ClassTrainerFrameFilterDropDown = makeFrame("ClassTrainerFrameFilterDropDown")
ClassTrainerMoneyFrame = makeFrame("ClassTrainerMoneyFrame")
ClassTrainerMoneyFrame.scale = 1
ClassTrainerMoneyFrame.point = { "BOTTOMLEFT", ClassTrainerFrame, "BOTTOMLEFT", 22, 86 }
local moneyCoins = { "Copper", "Silver", "Gold" }
for i = 1, table.getn(moneyCoins) do
  local coin = moneyCoins[i]
  local button = makeFrame("ClassTrainerMoneyFrame" .. coin .. "Button")
  local texture = makeFrame("ClassTrainerMoneyFrame" .. coin .. "Texture")
  local fontString = makeFrame("ClassTrainerMoneyFrame" .. coin .. "Text")
  button.width = 32
  button.height = 13
  texture.width = 13
  texture.height = 13
  fontString.font = { "Fonts\\FRIZQT__.TTF", 12, "" }
  button.normalTexture = texture
  button.fontString = fontString
  if coin == "Copper" then
    button.point = { "RIGHT", ClassTrainerMoneyFrame, "RIGHT", -13, 0 }
  else
    local previous = coin == "Silver" and "Copper" or "Silver"
    button.point = { "RIGHT", named["ClassTrainerMoneyFrame" .. previous .. "Button"], "LEFT", -4, 0 }
  end
  named[button.name] = button
  _G[button.name] = button
end
ClassTrainerGreetingText = makeFrame("ClassTrainerGreetingText")
ClassTrainerSkillHighlightFrame = makeFrame("ClassTrainerSkillHighlightFrame")
ClassTrainerHorizontalBarLeft = makeFrame("ClassTrainerHorizontalBarLeft")

named.ClassTrainerFrame = ClassTrainerFrame
named.ClassTrainerListScrollFrame = ClassTrainerListScrollFrame
named.ClassTrainerListScrollFrameScrollBarScrollUpButton = ClassTrainerListScrollFrameScrollBarScrollUpButton
named.ClassTrainerListScrollFrameScrollBarScrollDownButton = ClassTrainerListScrollFrameScrollBarScrollDownButton
named.ClassTrainerDetailScrollFrame = ClassTrainerDetailScrollFrame
named.ClassTrainerTrainButton = ClassTrainerTrainButton
named.ClassTrainerCancelButton = ClassTrainerCancelButton
named.ClassTrainerFrameCloseButton = ClassTrainerFrameCloseButton
named.ClassTrainerFrameFilterDropDown = ClassTrainerFrameFilterDropDown
named.ClassTrainerMoneyFrame = ClassTrainerMoneyFrame
named.ClassTrainerGreetingText = ClassTrainerGreetingText
named.ClassTrainerSkillHighlightFrame = ClassTrainerSkillHighlightFrame
named.ClassTrainerHorizontalBarLeft = ClassTrainerHorizontalBarLeft

local i
for i = 1, 11 do
  local button = makeFrame("ClassTrainerSkill" .. i)
  button.id = i
  named[button.name] = button
  _G[button.name] = button
  SkinCollapseButton(button)
end

UIPanelWindows = {
  ClassTrainerFrame = { area = "left", pushable = 1, width = 384, height = 512 },
}
CLASS_TRAINER_SKILLS_DISPLAYED = 11
CLASS_TRAINER_SKILL_HEIGHT = 16

function IsTradeskillTrainer() return tradeskillTrainer end
function GetMoney() return playerMoney end
function GetNumTrainerServices() return table.getn(services) end
function GetTrainerServiceInfo(index)
  trainerInfoReads = trainerInfoReads + 1
  if trainerInfoMutation then trainerInfoMutation(trainerInfoReads, index) end
  local row = services[index]
  if not row then return nil end
  return row.name, row.subText, row.serviceType, row.expanded
end
function GetTrainerServiceCost(index)
  local row = services[index]
  if not row then return nil end
  return row.money, row.cp1, row.cp2
end
function GetTrainerServiceSkillLine(index)
  trainerSkillLineReads = trainerSkillLineReads + 1
  if trainerSkillLineMutation then trainerSkillLineMutation(trainerSkillLineReads, index) end
  local row = services[index]
  if not row then return nil end
  return row.skillLine
end
function GetNumSkillLines() return table.getn(playerSkills) end
function GetSkillLineInfo(index) return playerSkills[index] end
function BuyTrainerService(index) table.insert(bought, index) end
function ExpandTrainerSkillLine() end
function ClassTrainerFrame_Update() end
function IsShiftKeyDown() return shiftDown and 1 or nil end
function GetGossipOptions() return unpack(gossipOptions) end
function SelectGossipOption(index) table.insert(selectedGossip, index) end
function ClassTrainer_SetToTradeSkillTrainer()
  CLASS_TRAINER_SKILLS_DISPLAYED = 10
  ClassTrainerListScrollFrame:SetHeight(168)
  ClassTrainerDetailScrollFrame:SetHeight(135)
end
function ClassTrainer_SetToClassTrainer()
  CLASS_TRAINER_SKILLS_DISPLAYED = 11
  ClassTrainerListScrollFrame:SetHeight(184)
  ClassTrainerDetailScrollFrame:SetHeight(119)
end

-- Vanilla trainer UI is load-on-demand; its mode functions may not exist when LazyTrix first loads.
local delayedTradeMode = ClassTrainer_SetToTradeSkillTrainer
local delayedClassMode = ClassTrainer_SetToClassTrainer
ClassTrainer_SetToTradeSkillTrainer = nil
ClassTrainer_SetToClassTrainer = nil

ShirsLazyTrix = {}
ShirsLazyTrixDB = { expandTrainers = false, trainAll = false, autoOpenTrainers = false }
function ShirsLazyTrix.EnsureDatabase() end

assert(loadfile(root .. "/ShirsLazyTrix_Trainer.lua"))()
ClassTrainer_SetToTradeSkillTrainer = delayedTradeMode
ClassTrainer_SetToClassTrainer = delayedClassMode

-- Automatic trainer gossip selection is default-off and text-independent.
gossipOptions = { "Teach me the ways of my class", "trainer" }
assert(ShirsLazyTrix.TryAutoOpenTrainer() == false and table.getn(selectedGossip) == 0,
  "disabled trainer gossip automation selected an option")
ShirsLazyTrixDB.autoOpenTrainers = true
gossipOptions = { "Any localized trainer wording", "trainer" }
assert(ShirsLazyTrix.TryAutoOpenTrainer() == true and selectedGossip[1] == 1,
  "exact trainer gossip type was not selected")
selectedGossip = {}
shiftDown = true
assert(ShirsLazyTrix.TryAutoOpenTrainer() == false and table.getn(selectedGossip) == 0,
  "Shift did not preserve the trainer gossip menu")
shiftDown = false
gossipOptions = { "Reset my talents", "gossip", "Train me", "trainer", "Other trainer", "trainer" }
assert(ShirsLazyTrix.TryAutoOpenTrainer() == false and table.getn(selectedGossip) == 0,
  "ambiguous trainer gossip menu did not fail closed")
gossipOptions = { "Reset my talents", "gossip", "Train me", "trainer" }
assert(ShirsLazyTrix.TryAutoOpenTrainer() == true and selectedGossip[1] == 2,
  "trainer gossip pair index was not preserved")
selectedGossip = {}
local savedGossipApi = GetGossipOptions
GetGossipOptions = nil
assert(ShirsLazyTrix.TryAutoOpenTrainer() == false and table.getn(selectedGossip) == 0,
  "missing gossip API did not fail closed")
GetGossipOptions = savedGossipApi

-- Both settings disabled must leave the stock frame alone.
assert(ShirsLazyTrix.RefreshTrainerFeature() == false, "disabled trainer features must return false")
assert(ClassTrainerFrame.width == 384 and CLASS_TRAINER_SKILLS_DISPLAYED == 11,
  "disabled trainer features changed stock layout")

-- Class expansion preserves stock width and reserves enough space for wrapped details.
ShirsLazyTrixDB.expandTrainers = true
assert(ShirsLazyTrix.RefreshTrainerFeature() == true, "trainer expansion did not apply")
assert(ClassTrainerFrame.width == 384 and ClassTrainerFrame.height == 596,
  "downward trainer frame geometry mismatch")
assert(ClassTrainerListScrollFrame.width == 293 and ClassTrainerListScrollFrame.height == 264,
  "downward trainer list geometry mismatch")
assert(ClassTrainerDetailScrollFrame.width == 296 and ClassTrainerDetailScrollFrame.height == 151,
  "downward trainer detail geometry mismatch")
assert(ClassTrainerCancelButton.point[1] == "BOTTOMRIGHT" and ClassTrainerCancelButton.point[2] == ClassTrainerFrame and
  ClassTrainerCancelButton.point[3] == "BOTTOMRIGHT" and ClassTrainerCancelButton.point[4] == -39 and
  ClassTrainerCancelButton.point[5] == 81 and
  ClassTrainerTrainButton.point[1] == "RIGHT" and ClassTrainerTrainButton.point[2] == ClassTrainerCancelButton and
  ClassTrainerTrainButton.point[3] == "LEFT" and ClassTrainerTrainButton.point[4] == -1 and
  ClassTrainerTrainButton.point[5] == 0,
  "Train and Exit buttons are not centered in the stock artwork sockets")
assert(ClassTrainerDetailScrollFrame.point[1] == "TOPLEFT" and ClassTrainerDetailScrollFrame.point[2] == ClassTrainerListScrollFrame and
  ClassTrainerDetailScrollFrame.point[3] == "BOTTOMLEFT" and ClassTrainerDetailScrollFrame.point[4] == 0 and ClassTrainerDetailScrollFrame.point[5] == -8,
  "detail pane must remain below the trainer list")
assert(CLASS_TRAINER_SKILLS_DISPLAYED == 16, "expanded class trainer row count mismatch")
assert(named.ClassTrainerSkill18 and named.ClassTrainerSkill18.id == 18,
  "additional trainer rows were not created")
assert(named.ClassTrainerSkill17.shown == false and named.ClassTrainerSkill18.shown == false,
  "class detail spacing left stale rows 17-18 visible")
for i = 12, 18 do
  assert(named["ClassTrainerSkill" .. i].pfUISkinned == true,
    "added trainer row did not inherit pfUI collapse-button styling")
  assert(named["ClassTrainerSkill" .. i].point[5] == 0,
    "added trainer row did not preserve the stock 16-pixel pitch")
end
assert(not named.ShirsLazyTrixTrainAllButton or named.ShirsLazyTrixTrainAllButton.shown == false,
  "expansion-only mode exposed Train All")
assert(not named.ShirsLazyTrixTrainerDetailsBackdrop, "horizontal details backdrop must not be created")
assert(createdSkillRows == 7, "expected exactly seven additional trainer rows")

-- Enabling Train All while expanded adds only the independent button/queue feature.
ShirsLazyTrixDB.trainAll = true
assert(ShirsLazyTrix.RefreshTrainerFeature() == true, "combined trainer features did not apply")
assert(named.ShirsLazyTrixTrainAllButton and named.ShirsLazyTrixTrainAllButton.shown == true,
  "combined mode did not show Train All")
assert(named.ShirsLazyTrixTrainAllButton.width == 76 and named.ShirsLazyTrixTrainAllButton.height == 18 and
  named.ShirsLazyTrixTrainAllButton.point[1] == "CENTER" and
  named.ShirsLazyTrixTrainAllButton.point[2] == ClassTrainerFrame and
  named.ShirsLazyTrixTrainAllButton.point[3] == "BOTTOMLEFT" and
  named.ShirsLazyTrixTrainAllButton.point[4] == 56 and named.ShirsLazyTrixTrainAllButton.point[5] == 92 and
  ClassTrainerMoneyFrame.scale == 1 and ClassTrainerMoneyFrame.point[1] == "BOTTOMRIGHT" and
  ClassTrainerMoneyFrame.point[2] == ClassTrainerFrame and ClassTrainerMoneyFrame.point[3] == "BOTTOMLEFT" and
  ClassTrainerMoneyFrame.point[4] == 189 and ClassTrainerMoneyFrame.point[5] == 86,
  "Train All and money were not split across the bottom-left action area")
for i = 1, table.getn(moneyCoins) do
  local button = named["ClassTrainerMoneyFrame" .. moneyCoins[i] .. "Button"]
  local _, fontSize = button.fontString:GetFont()
  assert(button.width == 27 and button.height == 11 and
    button.normalTexture.width == 11 and button.normalTexture.height == 11 and fontSize == 10,
    "trainer money denomination was not reduced by two pixels")
end
assert(named.ClassTrainerMoneyFrameCopperButton.point[4] == -13 and
  named.ClassTrainerMoneyFrameSilverButton.point[4] == -3 and
  named.ClassTrainerMoneyFrameGoldButton.point[4] == -3,
  "compact trainer money spacing did not preserve its right alignment")
local savedSkinCollapseButton = SkinCollapseButton
SkinCollapseButton = nil
ShirsLazyTrix.RefreshTrainerFeature()
local stockLeft = named.ShirsLazyTrixTrainerStockBackgroundLeft
local stockRight = named.ShirsLazyTrixTrainerStockBackgroundRight
assert(stockLeft and stockRight and stockLeft.shown == true and stockRight.shown == true and
  stockLeft.layer == "BORDER" and stockRight.layer == "BORDER" and
  stockLeft.texture[1] == "Interface\\ClassTrainerFrame\\UI-ClassTrainer-BotLeft" and
  stockRight.texture[1] == "Interface\\ClassTrainerFrame\\UI-ClassTrainer-BotRight" and
  stockLeft.point[1] == "TOPLEFT" and stockLeft.point[2] == ClassTrainerFrame and
  stockLeft.point[4] == 0 and stockLeft.point[5] == -256 and
  stockRight.point[1] == "TOPRIGHT" and stockRight.point[2] == ClassTrainerFrame and
  stockRight.point[4] == 0 and stockRight.point[5] == -256 and
  stockLeft.width == 256 and stockRight.width == 128 and
  stockLeft.height == 84 and stockRight.height == 84 and
  stockLeft.texCoord[1] == 0 and stockLeft.texCoord[2] == 1 and stockLeft.texCoord[3] == 0 and
  stockLeft.texCoord[4] == 0.328125 and stockRight.texCoord[4] == 0.328125,
  "stock-only expansion did not extend the exact frame artwork through the gap")
local trainAllSocket = named.ShirsLazyTrixTrainerTrainAllSocket
assert(trainAllSocket and trainAllSocket.shown == true and trainAllSocket.layer == "BORDER" and
  trainAllSocket.texture[1] == "Interface\\ClassTrainerFrame\\UI-ClassTrainer-BotRight" and
  trainAllSocket.point[1] == "BOTTOMLEFT" and trainAllSocket.point[2] == ClassTrainerFrame and
  trainAllSocket.point[3] == "BOTTOMLEFT" and trainAllSocket.point[4] == 14 and trainAllSocket.point[5] == 74 and
  trainAllSocket.width == 90 and trainAllSocket.height == 31 and
  trainAllSocket.texCoord[1] == 0.03125 and trainAllSocket.texCoord[2] == 0.734375 and
  trainAllSocket.texCoord[3] == 0.58984375 and trainAllSocket.texCoord[4] == 0.7109375,
  "Train All did not receive the exact stock action-socket artwork crop")
local listTrackMiddle = named.ShirsLazyTrixTrainerListTrackMiddle
assert(listTrackMiddle and listTrackMiddle.shown == true and listTrackMiddle.layer == "BACKGROUND" and
  listTrackMiddle.texture[1] == "Interface\\ClassTrainerFrame\\UI-ClassTrainer-ScrollBar" and
  listTrackMiddle.width == 30 and table.getn(listTrackMiddle.points) == 2 and
  listTrackMiddle.points[1][1] == "TOP" and
  listTrackMiddle.points[1][2] == ClassTrainerListScrollFrameScrollBarScrollUpButton and
  listTrackMiddle.points[1][3] == "TOP" and listTrackMiddle.points[1][4] == -2 and listTrackMiddle.points[1][5] == -118 and
  listTrackMiddle.points[2][1] == "BOTTOM" and
  listTrackMiddle.points[2][2] == ClassTrainerListScrollFrameScrollBarScrollDownButton and
  listTrackMiddle.points[2][3] == "BOTTOM" and listTrackMiddle.points[2][4] == -2 and listTrackMiddle.points[2][5] == 122 and
  listTrackMiddle.texCoord[1] == 0 and listTrackMiddle.texCoord[2] == 0.46875 and
  listTrackMiddle.texCoord[3] == 0.5 and listTrackMiddle.texCoord[4] == 0.5078125,
  "expanded stock trainer did not fill the fixed scrollbar artwork gap")
SkinCollapseButton = savedSkinCollapseButton
ShirsLazyTrix.RefreshTrainerFeature()
assert(stockLeft.shown == false and stockRight.shown == false,
  "stock artwork extensions were not hidden when pfUI owned the trainer backdrop")
assert(trainAllSocket.shown == false,
  "stock Train All socket was not hidden when pfUI owned the trainer backdrop")
assert(listTrackMiddle.shown == false,
  "stock scrollbar track extension was not hidden when pfUI owned the trainer backdrop")
assert(createdSkillRows == 7, "reapplying trainer layout duplicated rows")
tradeskillTrainer = true
ClassTrainer_SetToTradeSkillTrainer()
assert(CLASS_TRAINER_SKILLS_DISPLAYED == 18 and ClassTrainerFrame.height == 612 and ClassTrainerListScrollFrame.height == 296 and ClassTrainerDetailScrollFrame.height == 135,
  "profession trainer mode reset the expanded row count")
assert(stockLeft.width == 256 and stockRight.width == 128 and stockLeft.height == 100 and stockRight.height == 100 and
  stockLeft.texCoord[4] == 0.390625 and stockRight.texCoord[4] == 0.390625,
  "profession stock artwork extensions did not retain exact bounded geometry")
tradeskillTrainer = false
ClassTrainer_SetToClassTrainer()
assert(CLASS_TRAINER_SKILLS_DISPLAYED == 16 and ClassTrainerFrame.height == 596 and ClassTrainerListScrollFrame.height == 264 and ClassTrainerDetailScrollFrame.height == 151 and
  ClassTrainerHorizontalBarLeft.point[5] == -355 and named.ClassTrainerSkill17.shown == false and named.ClassTrainerSkill18.shown == false,
  "class trainer mode did not preserve protected detail spacing")

local function resetRows(rows, money, skills)
  local i
  for i = 1, table.getn(rows) do
    if rows[i].subText == nil then rows[i].subText = "Rank 1" end
  end
  services = rows
  playerMoney = money
  playerSkills = skills or {}
  bought = {}
  ClassTrainerFrame.shown = true
  ShirsLazyTrixDB.trainAll = true
  ShirsLazyTrix.CancelTrainAll()
  trainerInfoReads = 0
  trainerInfoMutation = nil
  trainerSkillLineReads = 0
  trainerSkillLineMutation = nil
end

local safeRows = {
  { name = "Header", serviceType = "header", money = 0, cp1 = 0, cp2 = 0 },
  { name = "Safe One", subText = "Rank 1", serviceType = "available", money = 100, cp1 = 0, cp2 = 0 },
  { name = "New Profession", serviceType = "available", money = 50, cp1 = 0, cp2 = 1, skillLine = "Blacksmithing" },
  { name = "Already Known", serviceType = "used", money = 10, cp1 = 0, cp2 = 0 },
  { name = "Safe Two", subText = "Rank 1", serviceType = "available", money = 200, cp1 = 0, cp2 = 0 },
  { name = "Malformed", serviceType = "unavailable", money = "free", cp1 = 0, cp2 = 0 },
}

resetRows(safeRows, 500)
local count, total = ShirsLazyTrix.GetTrainAllPlan()
assert(count == 2 and total == 300, "Train All plan included unsafe or unavailable services")
ShirsLazyTrix.UpdateTrainAllButton()
assert(named.ShirsLazyTrixTrainAllButton.enabled == true and named.ShirsLazyTrixTrainAllButton.text == "Train All (2)",
  "affordable Train All plan did not enable the button")

-- Train All remains usable after expansion is independently disabled.
ShirsLazyTrixDB.expandTrainers = false
assert(ShirsLazyTrix.RefreshTrainerFeature() == true, "Train All-only mode did not remain active")
assert(ClassTrainerFrame.height == 512 and CLASS_TRAINER_SKILLS_DISPLAYED == 11,
  "Train All-only mode did not restore stock geometry")
assert(named.ShirsLazyTrixTrainAllButton.shown == true and named.ShirsLazyTrixTrainAllButton.enabled == true and
  named.ShirsLazyTrixTrainAllButton.point[1] == "CENTER" and
  named.ShirsLazyTrixTrainAllButton.point[4] == 56 and named.ShirsLazyTrixTrainAllButton.point[5] == 92 and
  ClassTrainerMoneyFrame.scale == 1 and ClassTrainerMoneyFrame.point[1] == "BOTTOMRIGHT" and
  ClassTrainerMoneyFrame.point[2] == ClassTrainerFrame and ClassTrainerMoneyFrame.point[3] == "BOTTOMLEFT" and
  ClassTrainerMoneyFrame.point[4] == 189 and ClassTrainerMoneyFrame.point[5] == 86,
  "Train All-only mode did not keep its button in the bottom-left socket")

-- Toolbar filter variants must not move the bottom Train All control.
ClassTrainerSortFrame = makeFrame("ClassTrainerSortFrame")
named.ClassTrainerSortFrame = ClassTrainerSortFrame
ShirsLazyTrix.RefreshTrainerFeature()
assert(named.ShirsLazyTrixTrainAllButton.width == 76 and named.ShirsLazyTrixTrainAllButton.height == 18 and
  named.ShirsLazyTrixTrainAllButton.point[4] == 56 and
  named.ShirsLazyTrixTrainAllButton.text == "Train All (2)",
  "stock checkbox filters moved the bottom Train All control")
ClassTrainerSortFrame.shown = false
ShirsLazyTrix.RefreshTrainerFeature()
assert(named.ShirsLazyTrixTrainAllButton.width == 76 and named.ShirsLazyTrixTrainAllButton.height == 18 and
  named.ShirsLazyTrixTrainAllButton.point[4] == 56 and
  named.ShirsLazyTrixTrainAllButton.text == "Train All (2)",
  "dropdown filter layout moved the bottom Train All control")

-- Direct trainer mode setters must preserve the bottom socket and full state text.
ShirsLazyTrixDB.expandTrainers = true
ClassTrainerSortFrame.shown = true
ShirsLazyTrix.RefreshTrainerFeature()
tradeskillTrainer = true
ClassTrainer_SetToTradeSkillTrainer()
assert(named.ShirsLazyTrixTrainAllButton.width == 76 and named.ShirsLazyTrixTrainAllButton.height == 18 and named.ShirsLazyTrixTrainAllButton.point[4] == 56 and
  named.ShirsLazyTrixTrainAllButton.text == "Train All (2)",
  "profession mode setter moved or relabeled bottom Train All")
ClassTrainerSortFrame.shown = false
ShirsLazyTrix.RefreshTrainerFeature()
tradeskillTrainer = false
ClassTrainer_SetToClassTrainer()
assert(named.ShirsLazyTrixTrainAllButton.width == 76 and named.ShirsLazyTrixTrainAllButton.height == 18 and named.ShirsLazyTrixTrainAllButton.point[4] == 56 and
  named.ShirsLazyTrixTrainAllButton.text == "Train All (2)",
  "class mode setter moved or relabeled bottom Train All")
ShirsLazyTrixDB.expandTrainers = false
ShirsLazyTrix.RefreshTrainerFeature()

-- LazyTrix may receive TRAINER_SHOW before Blizzard's frame handler makes the panel visible.
ClassTrainerFrame.shown = false
ShirsLazyTrix.HandleTrainerEvent("TRAINER_SHOW")
assert(named.ShirsLazyTrixTrainAllButton.enabled == false,
  "hidden trainer unexpectedly enabled Train All")
ClassTrainerFrame.shown = true
named.ShirsLazyTrixTrainerEventFrame.scripts.OnUpdate()
assert(named.ShirsLazyTrixTrainAllButton.enabled == true and named.ShirsLazyTrixTrainAllButton.text == "Train All (2)",
  "deferred visible-frame refresh did not recover Train All after event-order inversion")

assert(ShirsLazyTrix.StartTrainAll() == true, "affordable Train All plan did not start")
assert(table.getn(bought) == 1 and bought[1] == 2, "Train All must buy exactly one safe service initially")
services[2].serviceType = "used"
ShirsLazyTrix.HandleTrainerEvent("TRAINER_UPDATE")
assert(table.getn(bought) == 1, "TRAINER_UPDATE bypassed purchase pacing")
ShirsLazyTrix.HandleTrainerOnUpdate(0.4)
assert(table.getn(bought) == 2 and bought[2] == 5, "TRAINER_UPDATE did not buy exactly the next safe service")
services[5].serviceType = "used"
ShirsLazyTrix.HandleTrainerEvent("TRAINER_UPDATE")
ShirsLazyTrix.HandleTrainerOnUpdate(0.4)
assert(table.getn(bought) == 2 and not ShirsLazyTrix.IsTrainAllActive(), "Train All did not stop after the plan completed")

-- An intermediate unchanged update must wait, then retry in a bounded way.
resetRows({
  { name = "Sticky", subText = "Rank 1", serviceType = "available", money = 25, cp1 = 0, cp2 = 0 },
}, 100)
assert(ShirsLazyTrix.StartTrainAll() == true, "single safe service did not start")
ShirsLazyTrix.HandleTrainerEvent("TRAINER_UPDATE")
assert(table.getn(bought) == 1 and ShirsLazyTrix.IsTrainAllActive(),
  "intermediate unchanged update cancelled Train All")
ShirsLazyTrix.HandleTrainerOnUpdate(0.4)
assert(table.getn(bought) == 1, "unchanged service retried too quickly")
ShirsLazyTrix.HandleTrainerOnUpdate(0.4)
assert(table.getn(bought) == 2 and ShirsLazyTrix.IsTrainAllActive(),
  "unchanged service did not receive one paced retry")
services[1].serviceType = "used"
ShirsLazyTrix.HandleTrainerEvent("TRAINER_UPDATE")
ShirsLazyTrix.HandleTrainerOnUpdate(0.4)
assert(not ShirsLazyTrix.IsTrainAllActive(), "completed retry queue did not stop")

-- An unchanged acknowledgement may retry only if the complete trainer list is unchanged.
resetRows({
  { name = "Mutation A", serviceType = "available", money = 25, cp1 = 0, cp2 = 0 },
  { name = "Mutation B", serviceType = "available", money = 25, cp1 = 0, cp2 = 0 },
}, 100)
assert(ShirsLazyTrix.StartTrainAll() == true, "mutation snapshot did not start")
table.insert(services, 1, { name = "Inserted Mutation", subText = "Rank 1", serviceType = "unavailable", money = 1, cp1 = 0, cp2 = 0 })
ShirsLazyTrix.HandleTrainerEvent("TRAINER_UPDATE")
ShirsLazyTrix.HandleTrainerOnUpdate(0.8)
assert(table.getn(bought) == 1 and not ShirsLazyTrix.IsTrainAllActive(),
  "changed trainer list retried an unchanged destructive purchase")

-- More than three services must complete without a built-in queue limit.
local longRows = {}
for i = 1, 6 do
  table.insert(longRows, { name = "Long " .. i, serviceType = "available", money = 10, cp1 = 0, cp2 = 0 })
end
resetRows(longRows, 1000)
assert(ShirsLazyTrix.StartTrainAll() == true, "long queue did not start")
for i = 1, 6 do
  services[i].serviceType = "used"
  ShirsLazyTrix.HandleTrainerEvent("TRAINER_UPDATE")
  ShirsLazyTrix.HandleTrainerOnUpdate(0.4)
end
assert(table.getn(bought) == 6 and not ShirsLazyTrix.IsTrainAllActive(),
  "Train All stopped before completing more than three services")

-- The click freezes an unavailable-only unlock allowlist; listed ranks may enter bounded follow-up passes.
resetRows({
  { name = "Rank One", subText = "Rank 1", serviceType = "available", money = 10, cp1 = 0, cp2 = 0 },
  { name = "Rank Two", subText = "Rank 2", serviceType = "unavailable", money = 20, cp1 = 0, cp2 = 0 },
  { name = "Rank Three", subText = "Rank 3", serviceType = "unavailable", money = 30, cp1 = 0, cp2 = 0 },
}, 100)
assert(ShirsLazyTrix.StartTrainAll() == true, "unlock snapshot did not start")
services[1].serviceType = "used"
services[2].serviceType = "available"
ShirsLazyTrix.HandleTrainerEvent("TRAINER_UPDATE")
ShirsLazyTrix.HandleTrainerOnUpdate(0.4)
assert(table.getn(bought) == 2 and bought[2] == 2 and ShirsLazyTrix.IsTrainAllActive(),
  "first newly unlocked rank did not enter a follow-up pass")
services[2].serviceType = "used"
services[3].serviceType = "available"
ShirsLazyTrix.HandleTrainerEvent("TRAINER_UPDATE")
ShirsLazyTrix.HandleTrainerOnUpdate(0.4)
assert(table.getn(bought) == 3 and bought[3] == 3 and ShirsLazyTrix.IsTrainAllActive(),
  "second newly unlocked rank did not enter another follow-up pass")
services[3].serviceType = "used"
ShirsLazyTrix.HandleTrainerEvent("TRAINER_UPDATE")
ShirsLazyTrix.HandleTrainerOnUpdate(0.4)
assert(table.getn(bought) == 3 and not ShirsLazyTrix.IsTrainAllActive(),
  "bounded unlock passes did not stop after the click-time unlock allowlist was exhausted")

-- A row that was already used at click time cannot enter a later pass.
resetRows({
  { name = "Used Gate", subText = "Rank 1", serviceType = "available", money = 10, cp1 = 0, cp2 = 0 },
  { name = "Previously Used", subText = "Rank 2", serviceType = "used", money = 20, cp1 = 0, cp2 = 0 },
}, 100)
assert(ShirsLazyTrix.StartTrainAll() == true, "used-gate snapshot did not start")
services[1].serviceType = "used"
services[2].serviceType = "available"
ShirsLazyTrix.HandleTrainerEvent("TRAINER_UPDATE")
ShirsLazyTrix.HandleTrainerOnUpdate(0.4)
assert(table.getn(bought) == 1 and not ShirsLazyTrix.IsTrainAllActive(),
  "used-at-click service entered a follow-up pass")

-- An initially available but excluded row cannot become eligible in a later pass.
resetRows({
  { name = "Excluded Gate", subText = "Rank 1", serviceType = "available", money = 10, cp1 = 0, cp2 = 0 },
  { name = "Excluded Point Cost", subText = "Rank 2", serviceType = "available", money = 20, cp1 = 1, cp2 = 0 },
}, 100)
assert(ShirsLazyTrix.StartTrainAll() == true, "excluded-gate snapshot did not start")
services[1].serviceType = "used"
services[2].cp1 = 0
ShirsLazyTrix.HandleTrainerEvent("TRAINER_UPDATE")
ShirsLazyTrix.HandleTrainerOnUpdate(0.4)
assert(table.getn(bought) == 1 and not ShirsLazyTrix.IsTrainAllActive(),
  "initially excluded available service entered a follow-up pass")

-- The click-time available snapshot and unlock allowlist must come from one atomic census.
resetRows({
  { name = "Atomic Used Gate", subText = "Rank 1", serviceType = "available", money = 10, cp1 = 0, cp2 = 0 },
  { name = "Atomic Used Candidate", subText = "Rank 2", serviceType = "used", money = 20, cp1 = 0, cp2 = 0 },
}, 100)
trainerInfoMutation = function(readCount)
  if readCount == 3 then
    services[2].serviceType = "available"
    trainerInfoMutation = nil
  end
end
assert(ShirsLazyTrix.StartTrainAll() == true, "atomic used snapshot did not start")
services[1].serviceType = "used"
ShirsLazyTrix.HandleTrainerEvent("TRAINER_UPDATE")
ShirsLazyTrix.HandleTrainerOnUpdate(0.4)
assert(table.getn(bought) == 1 and not ShirsLazyTrix.IsTrainAllActive(),
  "used identity changed between click-time scans and was purchased")

resetRows({
  { name = "Atomic Insert Gate", subText = "Rank 1", serviceType = "available", money = 10, cp1 = 0, cp2 = 0 },
  { name = "Atomic Existing", subText = "Rank 2", serviceType = "used", money = 20, cp1 = 0, cp2 = 0 },
}, 100)
trainerInfoMutation = function(readCount)
  if readCount == 3 then
    table.insert(services, 2, {
      name = "Atomic Inserted", subText = "Rank 9", serviceType = "available", money = 1, cp1 = 0, cp2 = 0,
    })
    trainerInfoMutation = nil
  end
end
assert(ShirsLazyTrix.StartTrainAll() == true, "atomic insertion snapshot did not start")
services[1].serviceType = "used"
ShirsLazyTrix.HandleTrainerEvent("TRAINER_UPDATE")
ShirsLazyTrix.HandleTrainerOnUpdate(0.4)
assert(table.getn(bought) == 1 and not ShirsLazyTrix.IsTrainAllActive(),
  "inserted identity changed between click-time scans and was purchased")

resetRows({
  { name = "Atomic Excluded Gate", subText = "Rank 1", serviceType = "available", money = 10, cp1 = 0, cp2 = 0 },
  { name = "Atomic Excluded Candidate", subText = "Rank 2", serviceType = "available", money = 20, cp1 = 1, cp2 = 0 },
}, 100)
trainerInfoMutation = function(readCount)
  if readCount == 3 then
    services[2].cp1 = 0
    trainerInfoMutation = nil
  end
end
assert(ShirsLazyTrix.StartTrainAll() == true, "atomic excluded snapshot did not start")
services[1].serviceType = "used"
ShirsLazyTrix.HandleTrainerEvent("TRAINER_UPDATE")
ShirsLazyTrix.HandleTrainerOnUpdate(0.4)
assert(table.getn(bought) == 1 and not ShirsLazyTrix.IsTrainAllActive(),
  "excluded identity changed between click-time scans and was purchased")

-- A list mutation during the pre-submit signature census must not leave a stale purchase index.
resetRows({
  { name = "Signature Target", subText = "Rank 1", serviceType = "available", money = 10, cp1 = 0, cp2 = 0 },
  { name = "Signature Guard", subText = "Rank 2", serviceType = "used", money = 20, cp1 = 0, cp2 = 0 },
}, 100)
trainerInfoMutation = function(readCount)
  if readCount == 5 then
    table.insert(services, 1, {
      name = "Inserted During Signature", subText = "Rank 9", serviceType = "available", money = 1, cp1 = 0, cp2 = 0,
    })
    trainerInfoMutation = nil
  end
end
assert(ShirsLazyTrix.StartTrainAll() == false and table.getn(bought) == 0 and not ShirsLazyTrix.IsTrainAllActive(),
  "signature-time insertion shifted the resolved index into a destructive purchase")

-- The last service-info validation must be followed by an identity-only check before purchase.
resetRows({
  { name = "Final Identity Target", subText = "Rank 1", serviceType = "available", money = 10, cp1 = 0, cp2 = 0 },
  { name = "Final Identity Guard", subText = "Rank 2", serviceType = "used", money = 20, cp1 = 0, cp2 = 0 },
}, 100)
trainerSkillLineMutation = function(readCount)
  if readCount == 7 then
    table.insert(services, 1, {
      name = "Inserted During Final Skill Read", subText = "Rank 9", serviceType = "available", money = 1, cp1 = 0, cp2 = 0,
    })
    trainerSkillLineMutation = nil
  end
end
assert(ShirsLazyTrix.StartTrainAll() == false and table.getn(bought) == 0 and not ShirsLazyTrix.IsTrainAllActive(),
  "final skill-line read shifted the validated index into a destructive purchase")

-- Follow-up rescans have a hard eight-pass bound even when the server keeps unlocking ranks.
local boundedRows = {}
for i = 1, 10 do
  table.insert(boundedRows, {
    name = "Bounded Rank", subText = "Rank " .. i,
    serviceType = i == 1 and "available" or "unavailable", money = 1, cp1 = 0, cp2 = 0,
  })
end
resetRows(boundedRows, 100)
assert(ShirsLazyTrix.StartTrainAll() == true, "bounded pass snapshot did not start")
for i = 1, 8 do
  services[i].serviceType = "used"
  if services[i + 1] then services[i + 1].serviceType = "available" end
  ShirsLazyTrix.HandleTrainerEvent("TRAINER_UPDATE")
  ShirsLazyTrix.HandleTrainerOnUpdate(0.4)
end
assert(table.getn(bought) == 8 and not ShirsLazyTrix.IsTrainAllActive(),
  "Train All exceeded or failed to reach its eight-pass unlock bound")

-- Insertions outside the click-time identity universe remain ignored while original identities may move.
resetRows({
  { name = "Snapshot A", subText = "Rank 1", serviceType = "available", money = 10, cp1 = 0, cp2 = 0 },
  { name = "Snapshot B", subText = "Rank 1", serviceType = "available", money = 20, cp1 = 0, cp2 = 0 },
}, 100)
assert(ShirsLazyTrix.StartTrainAll() == true, "insertion snapshot did not start")
services[1].serviceType = "used"
table.insert(services, 1, { name = "Inserted", serviceType = "available", money = 1, cp1 = 0, cp2 = 0 })
ShirsLazyTrix.HandleTrainerEvent("TRAINER_UPDATE")
ShirsLazyTrix.HandleTrainerOnUpdate(0.4)
assert(table.getn(bought) == 2 and bought[2] == 3,
  "Train All bought an inserted service instead of the moved snapshot identity")
services[3].serviceType = "used"
ShirsLazyTrix.HandleTrainerEvent("TRAINER_UPDATE")
ShirsLazyTrix.HandleTrainerOnUpdate(0.4)
assert(table.getn(bought) == 2 and not ShirsLazyTrix.IsTrainAllActive(),
  "follow-up pass absorbed an identity inserted after the physical click")

-- A quoted cost change cancels the remaining snapshot.
resetRows({
  { name = "Cost A", serviceType = "available", money = 10, cp1 = 0, cp2 = 0 },
  { name = "Cost B", serviceType = "available", money = 20, cp1 = 0, cp2 = 0 },
}, 500)
assert(ShirsLazyTrix.StartTrainAll() == true, "cost snapshot did not start")
services[1].serviceType = "used"
services[2].money = 25
ShirsLazyTrix.HandleTrainerEvent("TRAINER_UPDATE")
ShirsLazyTrix.HandleTrainerOnUpdate(0.4)
assert(table.getn(bought) == 1 and not ShirsLazyTrix.IsTrainAllActive(),
  "changed snapshot cost was purchased")

-- Money and profession-point drift stop before the next snapshot service.
resetRows({
  { name = "Money A", serviceType = "available", money = 10, cp1 = 0, cp2 = 0 },
  { name = "Money B", serviceType = "available", money = 20, cp1 = 0, cp2 = 0 },
}, 100)
assert(ShirsLazyTrix.StartTrainAll() == true, "money snapshot did not start")
services[1].serviceType = "used"
playerMoney = 15
ShirsLazyTrix.HandleTrainerEvent("TRAINER_UPDATE")
ShirsLazyTrix.HandleTrainerOnUpdate(0.4)
assert(table.getn(bought) == 1 and not ShirsLazyTrix.IsTrainAllActive(),
  "reduced money allowed a partial snapshot purchase")

resetRows({
  { name = "Point A", serviceType = "available", money = 10, cp1 = 0, cp2 = 0 },
  { name = "Point B", serviceType = "available", money = 20, cp1 = 0, cp2 = 0 },
}, 100)
assert(ShirsLazyTrix.StartTrainAll() == true, "profession-point snapshot did not start")
services[1].serviceType = "used"
services[2].cp1 = 1
ShirsLazyTrix.HandleTrainerEvent("TRAINER_UPDATE")
ShirsLazyTrix.HandleTrainerOnUpdate(0.4)
assert(table.getn(bought) == 1 and not ShirsLazyTrix.IsTrainAllActive(),
  "profession-point drift was purchased")

-- Blank and duplicate identities reject the click before spending.
resetRows({
  { name = "Same", subText = "Rank 1", serviceType = "available", money = 10, cp1 = 0, cp2 = 0 },
  { name = "Same", subText = "Rank 1", serviceType = "available", money = 20, cp1 = 0, cp2 = 0 },
}, 500)
assert(ShirsLazyTrix.StartTrainAll() == false and table.getn(bought) == 0,
  "duplicate snapshot identity was accepted")
resetRows({
  { name = "Duplicate Recipe", subText = "", serviceType = "available", money = 10, cp1 = 0, cp2 = 0 },
  { name = "Duplicate Recipe", subText = "", serviceType = "available", money = 20, cp1 = 0, cp2 = 0 },
}, 500)
assert(ShirsLazyTrix.StartTrainAll() == false and table.getn(bought) == 0,
  "duplicate blank-rank recipe identity was accepted")
resetRows({
  { name = "   ", subText = "", serviceType = "available", money = 10, cp1 = 0, cp2 = 0 },
}, 500)
assert(ShirsLazyTrix.StartTrainAll() == false and table.getn(bought) == 0,
  "blank snapshot identity was accepted")
resetRows({
  { name = "Blank Rank Recipe", subText = "", serviceType = "available", money = 10, cp1 = 0, cp2 = 0 },
}, 500)
assert(ShirsLazyTrix.GetTrainAllPlan() == 1,
  "unique blank-rank recipe was not accepted")
resetRows({
  { name = "Whitespace Rank Recipe", subText = "   ", serviceType = "available", money = 10, cp1 = 0, cp2 = 0 },
}, 500)
assert(ShirsLazyTrix.GetTrainAllPlan() == 1,
  "unique whitespace-rank recipe was not accepted")

-- Unique name-only recipes are safe under the frozen full-list signature.
resetRows({
  { name = "Unique Recipe", subText = "", serviceType = "available", money = 10, cp1 = 0, cp2 = 0,
    skillLine = "Tailoring" },
  { name = "Ranked Safe", subText = "Rank 2", serviceType = "available", money = 20, cp1 = 0, cp2 = 0 },
}, 500)
local mixedCount, mixedTotal, mixedIndex = ShirsLazyTrix.GetTrainAllPlan()
assert(mixedCount == 2 and mixedTotal == 30 and mixedIndex == 1,
  "unique name-only recipe was excluded from the frozen snapshot")
ShirsLazyTrix.UpdateTrainAllButton()
assert(named.ShirsLazyTrixTrainAllButton.enabled == true and named.ShirsLazyTrixTrainAllButton.text == "Train All (2)",
  "unique recipe and ranked service did not enable Train All")
assert(ShirsLazyTrix.StartTrainAll() == true and bought[1] == 1,
  "mixed profession plan did not start with its frozen unique recipe")
ShirsLazyTrix.CancelTrainAll()

-- Existing profession rank upgrades are safe; new profession skill lines remain manual.
resetRows({
  { name = "Expert Tailor", subText = "(Journeyman)", serviceType = "available", money = 4500,
    cp1 = 0, cp2 = 1, skillLine = "Tailoring" },
}, 10000, { "Tailoring" })
local professionCount, professionTotal, professionIndex = ShirsLazyTrix.GetTrainAllPlan()
assert(professionCount == 1 and professionTotal == 4500 and professionIndex == 1,
  "owned profession rank upgrade was excluded from Train All")
assert(ShirsLazyTrix.StartTrainAll() == true and table.getn(bought) == 1 and bought[1] == 1,
  "owned profession rank upgrade did not start")
ShirsLazyTrix.CancelTrainAll()

resetRows({
  { name = "Apprentice Blacksmith", subText = "(Apprentice)", serviceType = "available", money = 100,
    cp1 = 0, cp2 = 1, skillLine = "Blacksmithing" },
}, 10000, { "Tailoring" })
professionCount = ShirsLazyTrix.GetTrainAllPlan()
assert(professionCount == 0 and ShirsLazyTrix.StartTrainAll() == false and table.getn(bought) == 0,
  "new profession skill line was accepted by Train All")

resetRows({
  { name = "Expert Tailor", subText = "(Journeyman)", serviceType = "available", money = 4500,
    cp1 = 0, cp2 = 1, skillLine = "Tailoring" },
}, 10000, { "Tailoring" })
local savedSkillLineApi = GetTrainerServiceSkillLine
GetTrainerServiceSkillLine = nil
assert(ShirsLazyTrix.GetTrainAllPlan() == 0,
  "profession rank upgrade did not fail closed without its service skill-line API")
GetTrainerServiceSkillLine = savedSkillLineApi

-- The frozen profession rank snapshot must reject a changed skill line before another purchase.
resetRows({
  { name = "Expert Tailor", subText = "(Journeyman)", serviceType = "available", money = 4500,
    cp1 = 0, cp2 = 1, skillLine = "Tailoring" },
  { name = "Artisan Tailor", subText = "(Expert)", serviceType = "available", money = 5000,
    cp1 = 0, cp2 = 1, skillLine = "Tailoring" },
}, 20000, { "Tailoring" })
assert(ShirsLazyTrix.StartTrainAll() == true and table.getn(bought) == 1,
  "owned profession rank snapshot did not start")
services[1].serviceType = "used"
services[2].skillLine = "Blacksmithing"
ShirsLazyTrix.HandleTrainerEvent("TRAINER_UPDATE")
ShirsLazyTrix.HandleTrainerOnUpdate(0.4)
assert(table.getn(bought) == 1 and not ShirsLazyTrix.IsTrainAllActive(),
  "changed profession skill line was purchased from a frozen snapshot")

-- Frame disappearance, feature disable, and throwing APIs cancel before another purchase.
resetRows({
  { name = "Visible A", serviceType = "available", money = 10, cp1 = 0, cp2 = 0 },
  { name = "Visible B", serviceType = "available", money = 10, cp1 = 0, cp2 = 0 },
}, 500)
assert(ShirsLazyTrix.StartTrainAll() == true, "visibility snapshot did not start")
services[1].serviceType = "used"
ClassTrainerFrame.shown = false
ShirsLazyTrix.HandleTrainerOnUpdate(0.4)
assert(table.getn(bought) == 1 and not ShirsLazyTrix.IsTrainAllActive(),
  "hidden trainer frame allowed another purchase")

resetRows({
  { name = "Disable A", serviceType = "available", money = 10, cp1 = 0, cp2 = 0 },
  { name = "Disable B", serviceType = "available", money = 10, cp1 = 0, cp2 = 0 },
}, 500)
assert(ShirsLazyTrix.StartTrainAll() == true, "disable snapshot did not start")
services[1].serviceType = "used"
ShirsLazyTrixDB.expandTrainers = true
ShirsLazyTrixDB.trainAll = false
ShirsLazyTrix.RefreshTrainerFeature()
assert(table.getn(bought) == 1 and not ShirsLazyTrix.IsTrainAllActive() and
  named.ShirsLazyTrixTrainAllButton.shown == false and ClassTrainerFrame.height == 596 and
  ClassTrainerMoneyFrame.scale == 1 and ClassTrainerMoneyFrame.point[1] == "BOTTOMLEFT" and
  ClassTrainerMoneyFrame.point[4] == 22 and ClassTrainerMoneyFrame.point[5] == 86 and
  trainAllSocket.shown == false,
  "disabling Train All did not stop its queue, restore money, and preserve expansion")
for i = 1, table.getn(moneyCoins) do
  local button = named["ClassTrainerMoneyFrame" .. moneyCoins[i] .. "Button"]
  local _, fontSize = button.fontString:GetFont()
  assert(button.width == 32 and button.height == 13 and
    button.normalTexture.width == 13 and button.normalTexture.height == 13 and fontSize == 12,
    "disabling Train All did not restore stock money denomination geometry")
end
assert(named.ClassTrainerMoneyFrameCopperButton.point[4] == -13 and
  named.ClassTrainerMoneyFrameSilverButton.point[4] == -4 and
  named.ClassTrainerMoneyFrameGoldButton.point[4] == -4,
  "disabling Train All did not restore stock money spacing")

resetRows({
  { name = "Throw A", serviceType = "available", money = 10, cp1 = 0, cp2 = 0 },
  { name = "Throw B", serviceType = "available", money = 10, cp1 = 0, cp2 = 0 },
}, 500)
assert(ShirsLazyTrix.StartTrainAll() == true, "throwing API snapshot did not start")
services[1].serviceType = "used"
local savedInfo = GetTrainerServiceInfo
GetTrainerServiceInfo = function() error("injected trainer API failure") end
local safeCall = pcall(ShirsLazyTrix.HandleTrainerOnUpdate, 0.4)
GetTrainerServiceInfo = savedInfo
assert(safeCall and table.getn(bought) == 1 and not ShirsLazyTrix.IsTrainAllActive(),
  "throwing trainer API escaped or left Train All active")

resetRows({
  { name = "Missing A", serviceType = "available", money = 10, cp1 = 0, cp2 = 0 },
  { name = "Missing B", serviceType = "available", money = 10, cp1 = 0, cp2 = 0 },
}, 500)
assert(ShirsLazyTrix.StartTrainAll() == true, "missing API snapshot did not start")
services[1].serviceType = "used"
local savedCost = GetTrainerServiceCost
GetTrainerServiceCost = nil
ShirsLazyTrix.HandleTrainerEvent("TRAINER_UPDATE")
safeCall = pcall(ShirsLazyTrix.HandleTrainerOnUpdate, 0.4)
GetTrainerServiceCost = savedCost
assert(safeCall and table.getn(bought) == 1 and not ShirsLazyTrix.IsTrainAllActive(),
  "missing trainer cost API escaped or allowed another purchase")

resetRows({
  { name = "Bad Buy", serviceType = "available", money = 10, cp1 = 0, cp2 = 0 },
}, 500)
local plainBuy = BuyTrainerService
BuyTrainerService = function() error("injected purchase failure") end
safeCall = pcall(ShirsLazyTrix.StartTrainAll)
BuyTrainerService = plainBuy
assert(safeCall and table.getn(bought) == 0 and not ShirsLazyTrix.IsTrainAllActive(),
  "throwing purchase escaped or left Train All active")

-- Synchronous TRAINER_UPDATE from BuyTrainerService cannot recurse into more buys.
resetRows({
  { name = "Reentrant A", serviceType = "available", money = 10, cp1 = 0, cp2 = 0 },
  { name = "Reentrant B", serviceType = "available", money = 10, cp1 = 0, cp2 = 0 },
}, 500)
plainBuy = BuyTrainerService
local depth = 0
local maxDepth = 0
BuyTrainerService = function(index)
  depth = depth + 1
  if depth > maxDepth then maxDepth = depth end
  table.insert(bought, index)
  ShirsLazyTrix.HandleTrainerEvent("TRAINER_UPDATE")
  depth = depth - 1
end
assert(ShirsLazyTrix.StartTrainAll() == true, "reentrant snapshot did not start")
BuyTrainerService = plainBuy
assert(table.getn(bought) == 1 and maxDepth == 1,
  "synchronous TRAINER_UPDATE recursively drained Train All")

-- Insufficient funds block the whole plan before spending anything.
resetRows({
  { name = "One", serviceType = "available", money = 150, cp1 = 0, cp2 = 0 },
  { name = "Two", serviceType = "available", money = 200, cp1 = 0, cp2 = 0 },
}, 300)
ShirsLazyTrix.UpdateTrainAllButton()
assert(named.ShirsLazyTrixTrainAllButton.enabled == false, "unaffordable Train All plan remained enabled")
assert(ShirsLazyTrix.StartTrainAll() == false and table.getn(bought) == 0,
  "unaffordable Train All plan spent money")

-- Non-finite service and skill-line counts must fail before enumeration on the exact Windows Lua 5.0.3 runtime.
local invalidCounts = { 0/0, 1/0, -1/0 }
local savedServiceCountApi = GetNumTrainerServices
local savedTrainerInfoApi = GetTrainerServiceInfo
for i = 1, table.getn(invalidCounts) do
  resetRows({
    { name = "Invalid Count", serviceType = "available", money = 10, cp1 = 0, cp2 = 0 },
  }, 100)
  local trainerInfoCalls = 0
  GetNumTrainerServices = function() return invalidCounts[i] end
  GetTrainerServiceInfo = function()
    trainerInfoCalls = trainerInfoCalls + 1
    error("invalid service count reached trainer enumeration")
  end
  local countSafe, countStarted = pcall(ShirsLazyTrix.StartTrainAll)
  GetNumTrainerServices = savedServiceCountApi
  GetTrainerServiceInfo = savedTrainerInfoApi
  assert(countSafe and countStarted == false and trainerInfoCalls == 0 and table.getn(bought) == 0,
    "non-finite trainer service count reached enumeration or purchase")
end

local savedSkillCountApi = GetNumSkillLines
local savedSkillInfoApi = GetSkillLineInfo
for i = 1, table.getn(invalidCounts) do
  resetRows({
    { name = "Invalid Skill Count", serviceType = "available", money = 10, cp1 = 0, cp2 = 1,
      skillLine = "Tailoring" },
  }, 100, { "Tailoring" })
  local skillInfoCalls = 0
  GetNumSkillLines = function() return invalidCounts[i] end
  GetSkillLineInfo = function()
    skillInfoCalls = skillInfoCalls + 1
    error("invalid skill-line count reached enumeration")
  end
  local skillSafe, skillStarted = pcall(ShirsLazyTrix.StartTrainAll)
  GetNumSkillLines = savedSkillCountApi
  GetSkillLineInfo = savedSkillInfoApi
  assert(skillSafe and skillStarted == false and skillInfoCalls == 0 and table.getn(bought) == 0,
    "non-finite skill-line count reached enumeration or purchase")
end

-- Missing APIs fail closed.
local savedCost = GetTrainerServiceCost
GetTrainerServiceCost = nil
resetRows({
  { name = "Unknown", serviceType = "available", money = 0, cp1 = 0, cp2 = 0 },
}, 100)
assert(ShirsLazyTrix.StartTrainAll() == false and table.getn(bought) == 0,
  "missing trainer cost API did not fail closed")
GetTrainerServiceCost = savedCost

-- Closing the trainer cancels an active queue.
resetRows({
  { name = "Close Test", serviceType = "available", money = 10, cp1 = 0, cp2 = 0 },
}, 100)
assert(ShirsLazyTrix.StartTrainAll() == true, "close test did not start")
ShirsLazyTrix.HandleTrainerEvent("TRAINER_CLOSED")
assert(not ShirsLazyTrix.IsTrainAllActive(), "trainer close did not cancel Train All")

-- Event driver must register exact stock trainer events.
local driver = ShirsLazyTrix.InitializeTrainer()
assert(driver.events.TRAINER_SHOW and driver.events.TRAINER_UPDATE and driver.events.TRAINER_CLOSED,
  "trainer event driver is missing stock events")

print("TRAINER_LAYOUT_AND_QUEUE_TEST=PASS")
