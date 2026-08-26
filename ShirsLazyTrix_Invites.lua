local inviteLastBySender = {}
local INVITE_REPEAT_DELAY = 3
local UPTIME_WRAP_SECONDS = (2 ^ 32) / 1000

local function trimInvitePhrase(value)
  return string.gsub(value or "", "^%s*(.-)%s*$", "%1")
end

local function invitePhraseMatches(message)
  local configured = ShirsLazyTrixDB.invitePhrases or ""
  local loweredMessage = string.lower(message or "")
  local phrase
  for phrase in string.gfind(configured, "([^,]+)") do
    phrase = string.lower(trimInvitePhrase(phrase))
    if phrase ~= "" and string.find(loweredMessage, phrase, 1, true) then
      return true
    end
  end
  return false
end

local function inviteSenderAllowed(channel)
  if channel == "WHISPER" then
    return ShirsLazyTrixDB.inviteFromWhispers
  elseif channel == "GUILD" then
    return ShirsLazyTrixDB.inviteFromGuild
  end
  return false
end

local function inviteUptime()
  if type(GetTime) ~= "function" then return 0 end
  local current = GetTime()
  if type(current) ~= "number" or current < 0 or current > UPTIME_WRAP_SECONDS then return 0 end
  return current
end

local function inviteElapsed(now, startedAt)
  if now >= startedAt then return now - startedAt end
  return UPTIME_WRAP_SECONDS - startedAt + now
end

function ShirsLazyTrix.HandleInviteChat(message, sender, channel)
  ShirsLazyTrix.EnsureDatabase()
  if not inviteSenderAllowed(channel) or not invitePhraseMatches(message) then return end
  if not sender or sender == "" then return end
  if type(UnitName) == "function" and UnitName("player") == sender then return end

  local now = inviteUptime()
  local last = inviteLastBySender[sender]
  if last and inviteElapsed(now, last) < INVITE_REPEAT_DELAY then return end
  if type(InviteByName) ~= "function" then return end

  inviteLastBySender[sender] = now
  InviteByName(sender)
end
