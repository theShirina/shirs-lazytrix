local STEALTH_START_MESSAGES = {
  ["You gain Stealth."] = true,
  ["You gain Lesser Invisibility."] = true,
  ["You gain Invisibility."] = true,
}

local function isImmolationEffect(name, texture)
  if name == "Oil of Immolation" or name == "Immolation Aura" then return true end
  if name ~= "Fire Shield" and name ~= "Fire Shield IV" then return false end
  if type(texture) ~= "string" then return false end
  return string.find(string.lower(texture), "spell_fire_immolation", 1, true) ~= nil
end

local buffScanner = nil

local function getBuffScanner()
  if buffScanner then return buffScanner end
  if type(CreateFrame) ~= "function" or not UIParent then return nil end

  local scanner = CreateFrame("GameTooltip", "ShirsLazyTrixBuffScanner", UIParent, "GameTooltipTemplate")
  if not scanner or type(scanner.SetPlayerBuff) ~= "function" then return nil end
  if type(scanner.SetOwner) == "function" then
    scanner:SetOwner(UIParent, "ANCHOR_NONE")
  end
  buffScanner = scanner
  return buffScanner
end

local function cancelImmolationBuffs()
  if type(CancelPlayerBuff) ~= "function" or
     type(GetPlayerBuff) ~= "function" or
     type(GetPlayerBuffTexture) ~= "function" or
     type(getglobal) ~= "function" then
    return 0
  end

  local scanner = getBuffScanner()
  if not scanner then return 0 end
  local nameLine = getglobal("ShirsLazyTrixBuffScannerTextLeft1")
  if not nameLine or type(nameLine.GetText) ~= "function" or type(nameLine.SetText) ~= "function" then return 0 end

  local cancelled = 0
  local slot
  for slot = 31, 0, -1 do
    local buffIndex = GetPlayerBuff(slot, "HELPFUL")
    if type(buffIndex) == "number" and buffIndex >= 0 then
      nameLine:SetText(nil)
      scanner:SetPlayerBuff(buffIndex)
      local name = nameLine:GetText()
      local texture = GetPlayerBuffTexture(buffIndex)
      if isImmolationEffect(name, texture) then
        CancelPlayerBuff(buffIndex)
        cancelled = cancelled + 1
      end
    end
  end
  if type(scanner.Hide) == "function" then scanner:Hide() end
  return cancelled
end

function ShirsLazyTrix.HandleStealthBuffMessage(message)
  ShirsLazyTrix.EnsureDatabase()
  if ShirsLazyTrixDB.autoRemoveImmolationOnStealth ~= true then return 0 end
  if not STEALTH_START_MESSAGES[message] then return 0 end
  return cancelImmolationBuffs()
end

local function explicitlyOutsideInstance()
  if type(IsInInstance) ~= "function" then return false end

  local inside, instanceType = IsInInstance()
  local outside = inside == nil or inside == false or inside == 0
  if not outside then return false end
  if instanceType ~= nil and instanceType ~= "none" then return false end
  return true
end

function ShirsLazyTrix.TryAutoAcceptResurrection()
  ShirsLazyTrix.EnsureDatabase()
  if ShirsLazyTrixDB.autoAcceptOpenWorldRes ~= true then return false end
  if not explicitlyOutsideInstance() then return false end
  if type(AcceptResurrect) ~= "function" then return false end

  AcceptResurrect()
  if type(StaticPopup_Hide) == "function" then
    StaticPopup_Hide("RESURRECT_NO_TIMER")
    StaticPopup_Hide("RESURRECT_NO_SICKNESS")
    StaticPopup_Hide("RESURRECT")
  end
  return true
end
