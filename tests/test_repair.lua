-- Shir's LazyTrix automatic repair tests for Lua 5.0.3

local root = arg and arg[1] or "."
ShirsLazyTrix = {}
ShirsLazyTrixDB = { autoRepairAll = false }

local merchantCanRepair = true
local repairCost = 500
local repairAvailable = true
local money = 1000
local merchantChecks = 0
local costChecks = 0
local repairs = 0
local messages = {}

function CanMerchantRepair()
  merchantChecks = merchantChecks + 1
  return merchantCanRepair
end

function GetRepairAllCost()
  costChecks = costChecks + 1
  return repairCost, repairAvailable
end

function GetMoney() return money end
function RepairAllItems() repairs = repairs + 1 end
DEFAULT_CHAT_FRAME = {
  AddMessage = function(_, text) table.insert(messages, text) end,
}

assert(loadfile(root .. "/ShirsLazyTrix_Merchant.lua"))()

local repaired, status, cost = ShirsLazyTrix.TryAutoRepairAll()
assert(not repaired and status == "disabled" and cost == nil, "repair must default to opt-in")
assert(merchantChecks == 0 and costChecks == 0 and repairs == 0, "disabled repair queried merchant APIs")

ShirsLazyTrixDB.autoRepairAll = true
merchantCanRepair = false
repaired, status, cost = ShirsLazyTrix.TryAutoRepairAll()
assert(not repaired and status == "merchant" and cost == nil, "non-repair vendor must be ignored")
assert(costChecks == 0 and repairs == 0, "non-repair vendor queried cost or repaired")

merchantCanRepair = "yes"
repaired, status, cost = ShirsLazyTrix.TryAutoRepairAll()
assert(not repaired and status == "merchant", "invalid merchant eligibility must fail closed")
assert(costChecks == 0 and repairs == 0, "invalid merchant eligibility queried cost or repaired")

merchantCanRepair = 1
repairCost = 0
repairAvailable = false
repaired, status, cost = ShirsLazyTrix.TryAutoRepairAll()
assert(not repaired and status == "none" and cost == 0, "Vanilla numeric merchant eligibility must remain valid")

merchantCanRepair = true
repairCost = 0
repairAvailable = false
repaired, status, cost = ShirsLazyTrix.TryAutoRepairAll()
assert(not repaired and status == "none" and cost == 0, "zero-cost or unavailable repair must be a no-op")
assert(repairs == 0 and table.getn(messages) == 0, "no-damage repair produced a side effect")

repairCost = 0 / 0
repairAvailable = true
repaired, status, cost = ShirsLazyTrix.TryAutoRepairAll()
assert(not repaired and status == "none", "NaN repair cost must fail closed")
assert(repairs == 0 and table.getn(messages) == 0, "NaN repair cost produced a side effect")

repairCost = 1 / 0
repaired, status, cost = ShirsLazyTrix.TryAutoRepairAll()
assert(not repaired and status == "none", "infinite repair cost must fail closed")
assert(repairs == 0 and table.getn(messages) == 0, "infinite repair cost produced a side effect")

repairCost = 500
repairAvailable = "yes"
money = 1000
repaired, status, cost = ShirsLazyTrix.TryAutoRepairAll()
assert(not repaired and status == "none" and cost == 500, "invalid repair availability must fail closed")
assert(repairs == 0 and table.getn(messages) == 0, "invalid repair availability produced a side effect")

repairAvailable = false
money = 0
repaired, status, cost = ShirsLazyTrix.TryAutoRepairAll()
assert(not repaired and status == "none" and cost == 500, "unavailable positive-cost repair must be a quiet no-op")
assert(repairs == 0 and table.getn(messages) == 0, "unavailable repair produced a side effect")

repairAvailable = 1
money = 499
repaired, status, cost = ShirsLazyTrix.TryAutoRepairAll()
assert(not repaired and status == "funds" and cost == 500, "insufficient funds must block repair")
assert(repairs == 0, "repair ran without enough money")
assert(table.getn(messages) == 1 and string.find(messages[1], "not enough money to repair", 1, true),
  "insufficient-funds message missing")

GetMoney = nil
repaired, status, cost = ShirsLazyTrix.TryAutoRepairAll()
assert(not repaired and status == "money" and cost == 500, "missing money API must fail closed")
assert(repairs == 0 and table.getn(messages) == 1, "missing money API produced a repair or message")
GetMoney = function() return nil end
repaired, status, cost = ShirsLazyTrix.TryAutoRepairAll()
assert(not repaired and status == "money" and cost == 500, "invalid money data must fail closed")
assert(repairs == 0 and table.getn(messages) == 1, "invalid money data produced a repair or message")
GetMoney = function() return 0 / 0 end
repaired, status, cost = ShirsLazyTrix.TryAutoRepairAll()
assert(not repaired and status == "money" and cost == 500, "NaN money data must fail closed")
assert(repairs == 0 and table.getn(messages) == 1, "NaN money data produced a repair or message")
GetMoney = function() return 1 / 0 end
repaired, status, cost = ShirsLazyTrix.TryAutoRepairAll()
assert(not repaired and status == "money" and cost == 500, "infinite money data must fail closed")
assert(repairs == 0 and table.getn(messages) == 1, "infinite money data produced a repair or message")
GetMoney = function() return money end

money = 1000
repaired, status, cost = ShirsLazyTrix.TryAutoRepairAll()
assert(repaired and status == "repaired" and cost == 500, "eligible repair did not run")
assert(repairs == 1, "RepairAllItems must run exactly once")
assert(table.getn(messages) == 2 and string.find(messages[2], "repaired all gear for 5s.", 1, true),
  "successful repair cost message missing")

print("AUTO_REPAIR_ALL_TEST=PASS")
