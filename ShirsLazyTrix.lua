local frame = CreateFrame("Frame", "ShirsLazyTrixEventFrame")

frame:RegisterEvent("VARIABLES_LOADED")
frame:RegisterEvent("GOSSIP_SHOW")
frame:RegisterEvent("QUEST_GREETING")
frame:RegisterEvent("QUEST_DETAIL")
frame:RegisterEvent("QUEST_PROGRESS")
frame:RegisterEvent("QUEST_COMPLETE")
frame:RegisterEvent("QUEST_LOG_UPDATE")
frame:RegisterEvent("MERCHANT_SHOW")
frame:RegisterEvent("MERCHANT_CLOSED")

frame:SetScript("OnEvent", function()
  if event == "VARIABLES_LOADED" then
    ShirsLazyTrix.EnsureDatabase()
    ShirsLazyTrix.CreateUI()
  elseif event == "GOSSIP_SHOW" then
    ShirsLazyTrix.HandleGossipShow()
  elseif event == "QUEST_GREETING" then
    ShirsLazyTrix.HandleQuestGreeting()
  elseif event == "QUEST_DETAIL" then
    ShirsLazyTrix.HandleQuestDetail()
  elseif event == "QUEST_PROGRESS" then
    ShirsLazyTrix.HandleQuestProgress()
  elseif event == "QUEST_COMPLETE" then
    ShirsLazyTrix.HandleQuestComplete()
  elseif event == "QUEST_LOG_UPDATE" then
    ShirsLazyTrix.HandleQuestLogUpdate()
  elseif event == "MERCHANT_SHOW" then
    ShirsLazyTrix.TryAutoRepairAll()
    ShirsLazyTrix.StartAutoGraySale()
  elseif event == "MERCHANT_CLOSED" then
    ShirsLazyTrix.CancelGraySale()
  end
end)

local merchantElapsed = 0
frame:SetScript("OnUpdate", function()
  if not ShirsLazyTrix.GetGraySaleState() then
    merchantElapsed = 0
    return
  end

  merchantElapsed = merchantElapsed + (arg1 or 0)
  if merchantElapsed < 0.25 then return end
  merchantElapsed = 0
  ShirsLazyTrix.SellNextGray()
end)

SLASH_SHIRSLAZYTRIX1 = "/lazytrix"
SLASH_SHIRSLAZYTRIX2 = "/slt"
SlashCmdList["SHIRSLAZYTRIX"] = function()
  ShirsLazyTrix.ToggleSettings()
end
