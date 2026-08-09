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
  function frame:SetPoint(...) self.point = arg end
  function frame:GetPoint() if self.point then return unpack(self.point) end end
  function frame:ClearAllPoints() self.point = nil end
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
end

UIPanelWindows = {
  ClassTrainerFrame = { area = "left", pushable = 1, width = 384, height = 512 },
}
CLASS_TRAINER_SKILLS_DISPLAYED = 11
CLASS_TRAINER_SKILL_HEIGHT = 16

function IsTradeskillTrainer() return false end
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

ShirsLazyTrix = {}
ShirsLazyTrixDB = { enhanceTrainers = false, autoOpenTrainers = false }
function ShirsLazyTrix.EnsureDatabase() end

assert(loadfile(root .. "/ShirsLazyTrix_Trainer.lua"))()

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

-- Disabled mode must leave the stock frame alone.
assert(ShirsLazyTrix.RefreshTrainerFeature() == false, "disabled trainer enhancement must return false")
assert(ClassTrainerFrame.width == 384 and CLASS_TRAINER_SKILLS_DISPLAYED == 11,
  "disabled trainer enhancement changed stock layout")

-- Enabled layout is double-wide, creates 22 rows, and is idempotent.
ShirsLazyTrixDB.enhanceTrainers = true
assert(ShirsLazyTrix.RefreshTrainerFeature() == true, "enabled trainer enhancement did not apply")
assert(ClassTrainerFrame.width == 714 and ClassTrainerFrame.height == 487,
  "expanded trainer frame geometry mismatch")
assert(ClassTrainerListScrollFrame.width == 295 and ClassTrainerListScrollFrame.height == 336,
  "expanded trainer list geometry mismatch")
assert(ClassTrainerDetailScrollFrame.width == 296 and ClassTrainerDetailScrollFrame.height == 336,
  "expanded trainer detail geometry mismatch")
assert(CLASS_TRAINER_SKILLS_DISPLAYED == 22, "expanded trainer row count mismatch")
assert(named.ClassTrainerSkill22 and named.ClassTrainerSkill22.id == 22,
  "additional trainer rows were not created")
assert(named.ShirsLazyTrixTrainAllButton, "Train All button was not created")
assert(createdSkillRows == 11, "expected exactly eleven additional trainer rows")
ShirsLazyTrix.RefreshTrainerFeature()
assert(createdSkillRows == 11, "reapplying trainer layout duplicated rows")
ClassTrainer_SetToTradeSkillTrainer()
assert(CLASS_TRAINER_SKILLS_DISPLAYED == 22 and ClassTrainerListScrollFrame.height == 336 and ClassTrainerDetailScrollFrame.height == 336,
  "profession trainer mode reset the expanded row count")
ClassTrainer_SetToClassTrainer()
assert(CLASS_TRAINER_SKILLS_DISPLAYED == 22 and ClassTrainerListScrollFrame.height == 336 and ClassTrainerDetailScrollFrame.height == 336,
  "class trainer mode reset the expanded row count")

local function resetRows(rows, money)
  services = rows
  playerMoney = money
  bought = {}
  ShirsLazyTrix.CancelTrainAll()
end

local safeRows = {
  { name = "Header", serviceType = "header", money = 0, cp1 = 0, cp2 = 0 },
  { name = "Safe One", subText = "Rank 1", serviceType = "available", money = 100, cp1 = 0, cp2 = 0 },
  { name = "New Profession", serviceType = "available", money = 50, cp1 = 1, cp2 = 0 },
  { name = "Already Known", serviceType = "used", money = 10, cp1 = 0, cp2 = 0 },
  { name = "Safe Two", subText = "Rank 1", serviceType = "available", money = 200, cp1 = 0, cp2 = 0 },
  { name = "Malformed", serviceType = "available", money = "free", cp1 = 0, cp2 = 0 },
}

resetRows(safeRows, 500)
local count, total = ShirsLazyTrix.GetTrainAllPlan()
assert(count == 2 and total == 300, "Train All plan included unsafe or unavailable services")
ShirsLazyTrix.UpdateTrainAllButton()
assert(named.ShirsLazyTrixTrainAllButton.enabled == true and named.ShirsLazyTrixTrainAllButton.text == "Train All (2)",
  "affordable Train All plan did not enable the button")

assert(ShirsLazyTrix.StartTrainAll() == true, "affordable Train All plan did not start")
assert(table.getn(bought) == 1 and bought[1] == 2, "Train All must buy exactly one safe service initially")
services[2].serviceType = "used"
ShirsLazyTrix.HandleTrainerEvent("TRAINER_UPDATE")
assert(table.getn(bought) == 2 and bought[2] == 5, "TRAINER_UPDATE did not buy exactly the next safe service")
services[5].serviceType = "used"
ShirsLazyTrix.HandleTrainerEvent("TRAINER_UPDATE")
assert(table.getn(bought) == 2 and not ShirsLazyTrix.IsTrainAllActive(), "Train All did not stop after the plan completed")

-- Repeated unchanged service after an update must stop rather than buy twice.
resetRows({
  { name = "Sticky", subText = "Rank 1", serviceType = "available", money = 25, cp1 = 0, cp2 = 0 },
}, 100)
assert(ShirsLazyTrix.StartTrainAll() == true, "single safe service did not start")
ShirsLazyTrix.HandleTrainerEvent("TRAINER_UPDATE")
assert(table.getn(bought) == 1 and not ShirsLazyTrix.IsTrainAllActive(),
  "unchanged trainer result was purchased twice")

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
