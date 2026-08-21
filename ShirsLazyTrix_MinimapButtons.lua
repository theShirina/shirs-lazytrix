ShirsLazyTrix = ShirsLazyTrix or {}

local DEFAULT_BUTTON_SIZE = 24
local MIN_BUTTON_SIZE = 18
local MAX_BUTTON_SIZE = 32
local BUTTON_GAP = 2
local BUTTONS_PER_ROW = 6
local SCAN_SECONDS = 2
local tray = nil
local driver = nil
local launcher = nil
local scanElapsed = 0
local collected = {}

function ShirsLazyTrix.NormalizeMinimapButtonSize(value)
  value = tonumber(value)
  local text = value and string.lower(tostring(value)) or ""
  if not value or string.find(text, "nan", 1, true) or string.find(text, "inf", 1, true) or
     string.find(text, "#", 1, true) then return DEFAULT_BUTTON_SIZE end
  value = math.floor(value + 0.5)
  if value < MIN_BUTTON_SIZE then value = MIN_BUTTON_SIZE end
  if value > MAX_BUTTON_SIZE then value = MAX_BUTTON_SIZE end
  return value
end

local function buttonSize()
  if type(ShirsLazyTrixDB) ~= "table" then return DEFAULT_BUTTON_SIZE end
  return ShirsLazyTrix.NormalizeMinimapButtonSize(ShirsLazyTrixDB.minimapButtonSize)
end

local ignoredPrefixes = {
  "MiniMapTracking",
  "MiniMapMeetingStone",
  "MiniMapMail",
  "MiniMapBattlefield",
  "MiniMapPing",
  "MinimapZoom",
  "GatherNote",
  "MiniNotePOI",
  "QuestieNote",
  "pfMiniMapPin",
  "pfMinimapButton",
  "ShirsLazyTrixMinimapButton",
}

local function collectorConflict()
  return (type(pfUI) == "table" and type(pfUI.addonbuttons) == "table") or
    MBB_MinimapButtonFrame ~= nil or MBF_Frame ~= nil or MinimapButtonFrame ~= nil
end

local function ignoredName(name)
  if type(name) ~= "string" then return true end
  local index
  for index = 1, table.getn(ignoredPrefixes) do
    if string.find(name, ignoredPrefixes[index], 1, true) == 1 then return true end
  end
  return false
end

local function getScriptSafe(frame, scriptName)
  if not frame or type(frame.GetScript) ~= "function" then return nil end
  local ok, callback = pcall(function() return frame:GetScript(scriptName) end)
  if not ok then return nil end
  return callback
end

local function hasClickableScript(frame)
  return getScriptSafe(frame, "OnClick") ~= nil or
    getScriptSafe(frame, "OnMouseDown") ~= nil or
    getScriptSafe(frame, "OnMouseUp") ~= nil
end

local function getDirectChildren(frame)
  if not frame or type(frame.GetChildren) ~= "function" then return {} end
  return { frame:GetChildren() }
end

local textureGetters = {
  "GetNormalTexture",
  "GetPushedTexture",
  "GetHighlightTexture",
  "GetDisabledTexture",
}

local function getTextureSafe(frame, getterName)
  if not frame or type(frame[getterName]) ~= "function" then return nil end
  local ok, value = pcall(function() return frame[getterName](frame) end)
  if not ok then return nil end
  return value
end

local function saveButtonTextures(frame)
  local result = {}
  local seen = {}
  local frameWidth = type(frame.GetWidth) == "function" and tonumber(frame:GetWidth()) or DEFAULT_BUTTON_SIZE
  local frameHeight = type(frame.GetHeight) == "function" and tonumber(frame:GetHeight()) or DEFAULT_BUTTON_SIZE
  local function saveTexture(texture, role)
    if not texture or seen[texture] then return end
    seen[texture] = true
    local point = nil
    if type(texture.GetPoint) == "function" then point = { texture:GetPoint() } end
    local width = type(texture.GetWidth) == "function" and tonumber(texture:GetWidth()) or nil
    local height = type(texture.GetHeight) == "function" and tonumber(texture:GetHeight()) or nil
    table.insert(result, {
      texture = texture,
      role = role,
      point = point,
      width = width,
      height = height,
      shown = type(texture.IsShown) ~= "function" or texture:IsShown() and true or false,
      oversized = role == "region" and width and height and
        (width > frameWidth + 8 or height > frameHeight + 8) and true or false,
    })
  end
  local index
  for index = 1, table.getn(textureGetters) do
    local getterName = textureGetters[index]
    local role = getterName == "GetHighlightTexture" and "highlight" or "state"
    saveTexture(getTextureSafe(frame, getterName), role)
  end
  if type(frame.GetRegions) == "function" then
    local regions = { frame:GetRegions() }
    for index = 1, table.getn(regions) do
      local region = regions[index]
      local objectType = nil
      if region and type(region.GetObjectType) == "function" then
        local ok, value = pcall(function() return region:GetObjectType() end)
        if ok then objectType = value end
      end
      if objectType == "Texture" then saveTexture(region, "region") end
    end
  end
  return result
end

local function fitButtonTextures(frame, textures)
  local size = buttonSize()
  local inset = math.max(12, size - 4)
  local index
  for index = 1, table.getn(textures or {}) do
    local state = textures[index]
    local texture = state.texture
    if texture then
      if state.oversized then
        if texture.Hide then texture:Hide() end
      elseif texture.ClearAllPoints then
        texture:ClearAllPoints()
        if state.role == "highlight" and texture.SetAllPoints then
          texture:SetAllPoints(frame)
        else
          if texture.SetWidth then texture:SetWidth(inset) end
          if texture.SetHeight then texture:SetHeight(inset) end
          if texture.SetPoint then texture:SetPoint("CENTER", frame, "CENTER", 0, 0) end
        end
      end
    end
  end
end

local function restoreButtonTextures(textures)
  local index
  for index = 1, table.getn(textures or {}) do
    local state = textures[index]
    local texture = state.texture
    if texture then
      if texture.ClearAllPoints then texture:ClearAllPoints() end
      if texture.SetPoint and state.point and state.point[1] then texture:SetPoint(unpack(state.point)) end
      if texture.SetWidth and state.width then texture:SetWidth(state.width) end
      if texture.SetHeight and state.height then texture:SetHeight(state.height) end
      if state.shown and texture.Show then texture:Show() end
      if not state.shown and texture.Hide then texture:Hide() end
    end
  end
end

local function hasClickableChild(frame)
  local children = getDirectChildren(frame)
  local index
  for index = 1, table.getn(children) do
    if hasClickableScript(children[index]) then return true end
  end
  return false
end

function ShirsLazyTrix.IsMinimapButtonCandidate(frame)
  if not frame or type(frame.GetName) ~= "function" or type(frame.GetParent) ~= "function" then return false end
  local name = frame:GetName()
  if ignoredName(name) then return false end
  local parent = frame:GetParent()
  if parent ~= Minimap and parent ~= MinimapBackdrop then return false end
  local width = type(frame.GetWidth) == "function" and tonumber(frame:GetWidth()) or nil
  local height = type(frame.GetHeight) == "function" and tonumber(frame:GetHeight()) or nil
  local widthText = width and string.lower(tostring(width)) or ""
  local heightText = height and string.lower(tostring(height)) or ""
  if not width or not height or string.find(widthText, "nan", 1, true) or
     string.find(widthText, "inf", 1, true) or string.find(widthText, "#", 1, true) or
     string.find(heightText, "nan", 1, true) or string.find(heightText, "inf", 1, true) or
     string.find(heightText, "#", 1, true) or
     width <= 0 or height <= 0 or width > 50 or height > 50 then return false end
  return hasClickableScript(frame) or hasClickableChild(frame)
end

local function saveFrame(frame)
  local point = nil
  if type(frame.GetPoint) == "function" then point = { frame:GetPoint() } end
  local width = tonumber(frame:GetWidth()) or DEFAULT_BUTTON_SIZE
  local height = tonumber(frame:GetHeight()) or DEFAULT_BUTTON_SIZE
  local childStates = {}
  local children = getDirectChildren(frame)
  local index
  for index = 1, table.getn(children) do
    local child = children[index]
    if hasClickableScript(child) then
      local childWidth = type(child.GetWidth) == "function" and tonumber(child:GetWidth()) or nil
      local childHeight = type(child.GetHeight) == "function" and tonumber(child:GetHeight()) or nil
      table.insert(childStates, {
        frame = child,
        scale = type(child.GetScale) == "function" and child:GetScale() or nil,
        width = childWidth,
        height = childHeight,
        strata = type(child.GetFrameStrata) == "function" and child:GetFrameStrata() or nil,
        frameLevel = type(child.GetFrameLevel) == "function" and child:GetFrameLevel() or nil,
        textures = saveButtonTextures(child),
      })
    end
  end
  return {
    frame = frame,
    parent = frame:GetParent(),
    point = point,
    scale = type(frame.GetScale) == "function" and frame:GetScale() or 1,
    width = width,
    height = height,
    strata = type(frame.GetFrameStrata) == "function" and frame:GetFrameStrata() or nil,
    frameLevel = type(frame.GetFrameLevel) == "function" and frame:GetFrameLevel() or nil,
    textures = saveButtonTextures(frame),
    children = childStates,
  }
end

local function applyCollectedPresentation(entry)
  local frame = entry.frame
  if not frame then return end
  local size = buttonSize()
  if frame.SetScale then frame:SetScale(1) end
  if frame.SetWidth then frame:SetWidth(size) end
  if frame.SetHeight then frame:SetHeight(size) end
  if frame.SetFrameStrata then frame:SetFrameStrata("HIGH") end
  if frame.SetFrameLevel and tray and tray.GetFrameLevel then
    frame:SetFrameLevel(tray:GetFrameLevel() + 1)
  end
  fitButtonTextures(frame, entry.textures)
  local index
  for index = 1, table.getn(entry.children or {}) do
    local child = entry.children[index]
    if child.frame then
      if child.frame.SetScale then child.frame:SetScale(1) end
      if child.frame.SetWidth then child.frame:SetWidth(size) end
      if child.frame.SetHeight then child.frame:SetHeight(size) end
      if child.frame.SetFrameStrata then child.frame:SetFrameStrata("HIGH") end
      if child.frame.SetFrameLevel and tray and tray.GetFrameLevel then
        child.frame:SetFrameLevel(tray:GetFrameLevel() + 2)
      end
      fitButtonTextures(child.frame, child.textures)
    end
  end
end

local function restoreEntry(entry)
  local frame = entry.frame
  if not frame then return end
  if frame.SetParent then frame:SetParent(entry.parent) end
  if frame.SetScale then frame:SetScale(entry.scale or 1) end
  if frame.SetWidth and entry.width then frame:SetWidth(entry.width) end
  if frame.SetHeight and entry.height then frame:SetHeight(entry.height) end
  if frame.SetFrameStrata and entry.strata then frame:SetFrameStrata(entry.strata) end
  if frame.ClearAllPoints then frame:ClearAllPoints() end
  if frame.SetPoint and entry.point and entry.point[1] then frame:SetPoint(unpack(entry.point)) end
  if frame.SetFrameLevel and entry.frameLevel then frame:SetFrameLevel(entry.frameLevel) end
  restoreButtonTextures(entry.textures)
  local index
  for index = 1, table.getn(entry.children or {}) do
    local child = entry.children[index]
    if child.frame then
      if child.frame.SetScale and child.scale then child.frame:SetScale(child.scale) end
      if child.frame.SetWidth and child.width then child.frame:SetWidth(child.width) end
      if child.frame.SetHeight and child.height then child.frame:SetHeight(child.height) end
      if child.frame.SetFrameStrata and child.strata then child.frame:SetFrameStrata(child.strata) end
      if child.frame.SetFrameLevel and child.frameLevel then child.frame:SetFrameLevel(child.frameLevel) end
      restoreButtonTextures(child.textures)
    end
  end
end

local function restoreAll()
  local name, entry
  for name, entry in pairs(collected) do
    restoreEntry(entry)
    collected[name] = nil
  end
  if tray then tray:Hide() end
end

local function layoutButtons()
  if not tray then return 0 end
  local size = buttonSize()
  local names = {}
  local name
  for name in pairs(collected) do table.insert(names, name) end
  table.sort(names)
  local shown = 0
  local index
  for index = 1, table.getn(names) do
    local entry = collected[names[index]]
    local frame = entry.frame
    local included = not frame.IsShown or frame:IsShown()
    if included then
      applyCollectedPresentation(entry)
      local column = math.mod(shown, BUTTONS_PER_ROW)
      local row = math.floor(shown / BUTTONS_PER_ROW)
      frame:ClearAllPoints()
      frame:SetPoint(
        "TOPLEFT", tray, "TOPLEFT",
        6 + column * (size + BUTTON_GAP),
        -6 - row * (size + BUTTON_GAP)
      )
      shown = shown + 1
    end
  end
  local columns = math.min(math.max(shown, 1), BUTTONS_PER_ROW)
  local rows = math.max(1, math.ceil(shown / BUTTONS_PER_ROW))
  tray:SetWidth(12 + columns * size + (columns - 1) * BUTTON_GAP)
  tray:SetHeight(12 + rows * size + (rows - 1) * BUTTON_GAP)
  return shown
end

local function collectFrame(frame)
  local name = frame:GetName()
  if collected[name] then return false end
  collected[name] = saveFrame(frame)
  frame:SetParent(tray)
  applyCollectedPresentation(collected[name])
  return true
end

local function scanParent(parent)
  if not parent or type(parent.GetChildren) ~= "function" then return end
  local children = { parent:GetChildren() }
  local index
  for index = 1, table.getn(children) do
    if ShirsLazyTrix.IsMinimapButtonCandidate(children[index]) then collectFrame(children[index]) end
  end
end

function ShirsLazyTrix.RefreshMinimapButtonCollector()
  if type(ShirsLazyTrixDB) ~= "table" or not ShirsLazyTrixDB.consolidateMinimapButtons then
    restoreAll()
    return true
  end
  if collectorConflict() or not tray then
    ShirsLazyTrixDB.consolidateMinimapButtons = false
    restoreAll()
    return false
  end
  scanParent(Minimap)
  scanParent(MinimapBackdrop)
  layoutButtons()
  return true
end

function ShirsLazyTrix.ApplyMinimapButtonSize(value)
  if type(ShirsLazyTrixDB) ~= "table" then ShirsLazyTrixDB = {} end
  ShirsLazyTrixDB.minimapButtonSize = ShirsLazyTrix.NormalizeMinimapButtonSize(value)
  return ShirsLazyTrix.RefreshMinimapButtonCollector()
end

function ShirsLazyTrix.ToggleMinimapButtonTray()
  if not tray or type(ShirsLazyTrixDB) ~= "table" or not ShirsLazyTrixDB.consolidateMinimapButtons then
    return false
  end
  ShirsLazyTrix.RefreshMinimapButtonCollector()
  if tray:IsShown() then
    tray:Hide()
    return false
  end
  tray:Show()
  return true
end

function ShirsLazyTrix.InitializeMinimapButtonCollector(button)
  launcher = button or launcher
  if tray then return tray end
  if type(CreateFrame) ~= "function" or not launcher then return nil end
  tray = CreateFrame("Frame", "ShirsLazyTrixMinimapButtonTray", UIParent)
  tray:SetFrameStrata("HIGH")
  tray:SetFrameLevel(20)
  tray:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 10,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
  })
  tray:SetBackdropColor(0.025, 0.035, 0.055, 0.96)
  tray:SetBackdropBorderColor(0.3, 0.6, 0.9, 1)
  tray:SetPoint("TOPRIGHT", launcher, "BOTTOMRIGHT", 0, -4)
  tray:Hide()

  driver = CreateFrame("Frame", "ShirsLazyTrixMinimapButtonDriver", UIParent)
  driver:SetScript("OnUpdate", function()
    local elapsed = tonumber(arg1) or 0
    if elapsed < 0 then elapsed = 0 end
    scanElapsed = scanElapsed + elapsed
    if scanElapsed >= SCAN_SECONDS then
      scanElapsed = 0
      ShirsLazyTrix.RefreshMinimapButtonCollector()
    end
  end)
  ShirsLazyTrix.RefreshMinimapButtonCollector()
  return tray
end
