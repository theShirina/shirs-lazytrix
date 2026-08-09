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
ClassTrainerGreetingText = makeFrame("ClassTrainerGreetingText")
ClassTrainerSkillHighlightFrame = makeFrame("ClassTrainerSkillHighlightFrame")
ClassTrainerHorizontalBarLeft = makeFrame("ClassTrainerHorizontalBarLeft")

named.ClassTrainerFrame = ClassTrainerFrame
named.ClassTrainerListScrollFrame = ClassTrainerListScrollFrame
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
  local row = services[index]
  if not row then return nil end
  return row.name, row.subText, row.serviceType, row.expanded
end
function GetTrainerServiceCost(index)
  local row = services[index]
  if not row then return nil end
  return row.money, row.cp1, row.cp2
end
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
assert(named.ShirsLazyTrixTrainAllButton.width == 82 and named.ShirsLazyTrixTrainAllButton.height == 23 and
  named.ShirsLazyTrixTrainAllButton.point[1] == "CENTER" and
  named.ShirsLazyTrixTrainAllButton.point[2] == ClassTrainerFrame and
  named.ShirsLazyTrixTrainAllButton.point[3] == "BOTTOMLEFT" and
  named.ShirsLazyTrixTrainAllButton.point[4] == 59 and named.ShirsLazyTrixTrainAllButton.point[5] == 92 and
  ClassTrainerMoneyFrame.scale == 1 and ClassTrainerMoneyFrame.point[1] == "BOTTOMRIGHT" and
  ClassTrainerMoneyFrame.point[2] == ClassTrainerFrame and ClassTrainerMoneyFrame.point[3] == "BOTTOMLEFT" and
  ClassTrainerMoneyFrame.point[4] == 194 and ClassTrainerMoneyFrame.point[5] == 86,
  "Train All and money were not split across the bottom-left action area")
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
SkinCollapseButton = savedSkinCollapseButton
ShirsLazyTrix.RefreshTrainerFeature()
assert(stockLeft.shown == false and stockRight.shown == false,
  "stock artwork extensions were not hidden when pfUI owned the trainer backdrop")
assert(trainAllSocket.shown == false,
  "stock Train All socket was not hidden when pfUI owned the trainer backdrop")
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

local function resetRows(rows, money)
  local i
  for i = 1, table.getn(rows) do
    if rows[i].subText == nil then rows[i].subText = "Rank 1" end
  end
  services = rows
  playerMoney = money
  bought = {}
  ClassTrainerFrame.shown = true
  ShirsLazyTrixDB.trainAll = true
  ShirsLazyTrix.CancelTrainAll()
end

local safeRows = {
  { name = "Header", serviceType = "header", money = 0, cp1 = 0, cp2 = 0 },
  { name = "Safe One", subText = "Rank 1", serviceType = "available", money = 100, cp1 = 0, cp2 = 0 },
  { name = "New Profession", serviceType = "available", money = 50, cp1 = 1, cp2 = 0 },
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
  named.ShirsLazyTrixTrainAllButton.point[4] == 59 and named.ShirsLazyTrixTrainAllButton.point[5] == 92 and
  ClassTrainerMoneyFrame.scale == 1 and ClassTrainerMoneyFrame.point[1] == "BOTTOMRIGHT" and
  ClassTrainerMoneyFrame.point[2] == ClassTrainerFrame and ClassTrainerMoneyFrame.point[3] == "BOTTOMLEFT" and
  ClassTrainerMoneyFrame.point[4] == 194 and ClassTrainerMoneyFrame.point[5] == 86,
  "Train All-only mode did not keep its button in the bottom-left socket")

-- Toolbar filter variants must not move the bottom Train All control.
ClassTrainerSortFrame = makeFrame("ClassTrainerSortFrame")
named.ClassTrainerSortFrame = ClassTrainerSortFrame
ShirsLazyTrix.RefreshTrainerFeature()
assert(named.ShirsLazyTrixTrainAllButton.width == 82 and named.ShirsLazyTrixTrainAllButton.height == 23 and
  named.ShirsLazyTrixTrainAllButton.point[4] == 59 and
  named.ShirsLazyTrixTrainAllButton.text == "Train All (2)",
  "stock checkbox filters moved the bottom Train All control")
ClassTrainerSortFrame.shown = false
ShirsLazyTrix.RefreshTrainerFeature()
assert(named.ShirsLazyTrixTrainAllButton.width == 82 and named.ShirsLazyTrixTrainAllButton.height == 23 and
  named.ShirsLazyTrixTrainAllButton.point[4] == 59 and
  named.ShirsLazyTrixTrainAllButton.text == "Train All (2)",
  "dropdown filter layout moved the bottom Train All control")

-- Direct trainer mode setters must preserve the bottom socket and full state text.
ShirsLazyTrixDB.expandTrainers = true
ClassTrainerSortFrame.shown = true
ShirsLazyTrix.RefreshTrainerFeature()
tradeskillTrainer = true
ClassTrainer_SetToTradeSkillTrainer()
assert(named.ShirsLazyTrixTrainAllButton.width == 82 and named.ShirsLazyTrixTrainAllButton.height == 23 and named.ShirsLazyTrixTrainAllButton.point[4] == 59 and
  named.ShirsLazyTrixTrainAllButton.text == "Train All (2)",
  "profession mode setter moved or relabeled bottom Train All")
ClassTrainerSortFrame.shown = false
ShirsLazyTrix.RefreshTrainerFeature()
tradeskillTrainer = false
ClassTrainer_SetToClassTrainer()
assert(named.ShirsLazyTrixTrainAllButton.width == 82 and named.ShirsLazyTrixTrainAllButton.height == 23 and named.ShirsLazyTrixTrainAllButton.point[4] == 59 and
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

-- The physical click freezes its service set; newly unlocked rows are not absorbed.
resetRows({
  { name = "Rank One", subText = "Rank 1", serviceType = "available", money = 10, cp1 = 0, cp2 = 0 },
  { name = "Rank Two", subText = "Rank 2", serviceType = "unavailable", money = 20, cp1 = 0, cp2 = 0 },
}, 100)
assert(ShirsLazyTrix.StartTrainAll() == true, "unlock snapshot did not start")
services[1].serviceType = "used"
services[2].serviceType = "available"
ShirsLazyTrix.HandleTrainerEvent("TRAINER_UPDATE")
ShirsLazyTrix.HandleTrainerOnUpdate(0.4)
assert(table.getn(bought) == 1 and not ShirsLazyTrix.IsTrainAllActive(),
  "newly unlocked service was absorbed into the click snapshot")

-- Insertions are ignored while the original identity can move to a new index.
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
  { name = "   ", subText = "", serviceType = "available", money = 10, cp1 = 0, cp2 = 0 },
}, 500)
assert(ShirsLazyTrix.StartTrainAll() == false and table.getn(bought) == 0,
  "blank snapshot identity was accepted")
resetRows({
  { name = "Blank Rank", subText = "", serviceType = "available", money = 10, cp1 = 0, cp2 = 0 },
}, 500)
assert(ShirsLazyTrix.StartTrainAll() == false and table.getn(bought) == 0,
  "blank snapshot rank was accepted")
resetRows({
  { name = "Whitespace Rank", subText = "   ", serviceType = "available", money = 10, cp1 = 0, cp2 = 0 },
}, 500)
assert(ShirsLazyTrix.StartTrainAll() == false and table.getn(bought) == 0,
  "whitespace snapshot rank was accepted")

-- Name-only services stay manual without disabling safe ranked services.
resetRows({
  { name = "Manual Name Only", subText = "", serviceType = "available", money = 10, cp1 = 0, cp2 = 0 },
  { name = "Ranked Safe", subText = "Rank 2", serviceType = "available", money = 20, cp1 = 0, cp2 = 0 },
}, 500)
local mixedCount, mixedTotal, mixedIndex = ShirsLazyTrix.GetTrainAllPlan()
assert(mixedCount == 1 and mixedTotal == 20 and mixedIndex == 2,
  "name-only service disabled the safe ranked snapshot")
ShirsLazyTrix.UpdateTrainAllButton()
assert(named.ShirsLazyTrixTrainAllButton.enabled == true and named.ShirsLazyTrixTrainAllButton.text == "Train All (1)",
  "name-only service left the ranked Train All plan disabled")
assert(ShirsLazyTrix.StartTrainAll() == true and bought[1] == 2,
  "mixed plan did not buy only the ranked service")
ShirsLazyTrix.CancelTrainAll()

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
