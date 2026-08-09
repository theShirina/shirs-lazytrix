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
