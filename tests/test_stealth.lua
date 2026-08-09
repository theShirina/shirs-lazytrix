-- Shir's LazyTrix stealth immolation cleanup tests for Lua 5.0.3

local root = arg and arg[1] or "."

ShirsLazyTrix = {}
ShirsLazyTrixDB = { autoRemoveImmolationOnStealth = false }
UIParent = {}

local buffs = {}
local cancelled = {}
local created = 0
local scannerAvailable = true
local cancelAvailable = true
local buffApiAvailable = true
local textureApiAvailable = true
local line = { text = nil }
function line:SetText(value) self.text = value end
function line:GetText() return self.text end

function ShirsLazyTrix.EnsureDatabase() end
function getglobal(name)
  if name == "ShirsLazyTrixBuffScannerTextLeft1" then return line end
  return nil
end

local function findByIndex(index)
  local slot, entry
  for slot, entry in pairs(buffs) do
    if entry.index == index then return entry end
  end
  return nil
end

local function installApis()
  if scannerAvailable then
    CreateFrame = function(kind, name, parent, template)
      created = created + 1
      assert(kind == "GameTooltip" and name == "ShirsLazyTrixBuffScanner", "unexpected scanner frame")
      assert(parent == UIParent and template == "GameTooltipTemplate", "scanner must use the stock tooltip template")
      local scanner = {}
      function scanner:SetOwner() end
      function scanner:SetPlayerBuff(index)
        local entry = findByIndex(index)
        line.text = entry and entry.name or nil
      end
      function scanner:Hide() end
      return scanner
    end
  else
    CreateFrame = nil
  end

  if cancelAvailable then
    CancelPlayerBuff = function(index) table.insert(cancelled, index) end
  else
    CancelPlayerBuff = nil
  end

  if buffApiAvailable then
    GetPlayerBuff = function(slot, filter)
      assert(filter == "HELPFUL", "buff enumeration must request helpful player buffs")
      local entry = buffs[slot]
      return entry and entry.index or -1
    end
  else
    GetPlayerBuff = nil
  end

  if textureApiAvailable then
    GetPlayerBuffTexture = function(index)
      local entry = findByIndex(index)
      return entry and entry.texture or nil
    end
  else
    GetPlayerBuffTexture = nil
  end
end

local function reset(enabled)
  ShirsLazyTrixDB.autoRemoveImmolationOnStealth = enabled
  buffs = {}
  cancelled = {}
  created = 0
  scannerAvailable = true
  cancelAvailable = true
  buffApiAvailable = true
  textureApiAvailable = true
  line.text = nil
  installApis()
end

assert(loadfile(root .. "/ShirsLazyTrix_World.lua"))()

reset(false)
buffs[2] = { index = 102, name = "Fire Shield", texture = "Interface\\Icons\\Spell_Fire_Immolation" }
assert(ShirsLazyTrix.HandleStealthBuffMessage("You gain Stealth.") == 0, "disabled cleanup must return zero")
assert(table.getn(cancelled) == 0 and created == 0, "disabled cleanup scanned or cancelled buffs")

reset(true)
buffs[2] = { index = 102, name = "Fire Shield", texture = "Interface\\Icons\\Spell_Fire_Immolation" }
assert(ShirsLazyTrix.HandleStealthBuffMessage("You gain Sprint.") == 0, "unrelated buff message must return zero")
assert(table.getn(cancelled) == 0 and created == 0, "unrelated buff message scanned or cancelled buffs")

reset(true)
scannerAvailable = false
installApis()
assert(ShirsLazyTrix.HandleStealthBuffMessage("You gain Stealth.") == 0, "missing tooltip API must fail closed")

reset(true)
cancelAvailable = false
installApis()
assert(ShirsLazyTrix.HandleStealthBuffMessage("You gain Stealth.") == 0, "missing cancellation API must fail closed")
assert(created == 0, "missing cancellation API should not create a scanner")

reset(true)
buffApiAvailable = false
installApis()
assert(ShirsLazyTrix.HandleStealthBuffMessage("You gain Stealth.") == 0, "missing buff enumeration API must fail closed")

reset(true)
textureApiAvailable = false
installApis()
assert(ShirsLazyTrix.HandleStealthBuffMessage("You gain Stealth.") == 0, "missing texture API must fail closed")

local messages = {
  "You gain Stealth.",
  "You gain Lesser Invisibility.",
  "You gain Invisibility.",
}
local i
reset(true)
for i = 1, table.getn(messages) do
  buffs = {}
  cancelled = {}
  buffs[2] = { index = 102, name = "Fire Shield", texture = "Interface\\Icons\\Spell_Fire_Immolation" }
  buffs[3] = { index = 103, name = "Fire Shield", texture = "Interface\\Icons\\Spell_Fire_FireArmor" }
  buffs[5] = { index = 105, name = "Fire Shield Rank 2", texture = "Interface\\Icons\\Spell_Fire_Immolation" }
  buffs[7] = { index = 107, name = "Oil of Immolation", texture = "Interface\\Icons\\INV_Potion_11" }
  buffs[20] = { index = 120, name = "Immolation Aura", texture = "Interface\\Icons\\Custom_Immolation" }
  buffs[22] = { index = 122, name = "Fire Shield IV", texture = "Interface\\Icons\\Spell_Fire_Immolation" }
  local count = ShirsLazyTrix.HandleStealthBuffMessage(messages[i])
  assert(count == 4, "stealth message did not remove all exact immolation effects")
  assert(table.getn(cancelled) == 4, "stealth cleanup submitted the wrong cancellation count")
  assert(cancelled[1] == 122 and cancelled[2] == 120 and cancelled[3] == 107 and cancelled[4] == 102,
    "buff cancellation must use returned indices in descending slot order")
  assert(created == 1, "buff scanner must be created once and reused")
end

assert(type(SendChatMessage) == "nil", "stealth cleanup must not require chat output")
print("STEALTH_IMMOLATION_CLEANUP_TEST=PASS")
