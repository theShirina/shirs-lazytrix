-- Invite trigger tests for Vanilla 1.12 Lua 5.0.3
local root = arg and arg[1] or "."
local calls = {}
local now = 10
local player = "Shirina"

function GetTime() return now end
function UnitName(unit) if unit == "player" then return player end end
function InviteByName(name) table.insert(calls, name) end

ShirsLazyTrix = {
  EnsureDatabase = function() end,
}
ShirsLazyTrixDB = {
  inviteFromWhispers = true,
  inviteFromGuild = false,
  invitePhrases = "invite, need group,  raid please ",
}

dofile(root .. "/ShirsLazyTrix_Invites.lua")

ShirsLazyTrix.HandleInviteChat("Can you invite me?", "Mage", "WHISPER")
assert(table.getn(calls) == 1 and calls[1] == "Mage", "matching whisper did not invite")
ShirsLazyTrix.HandleInviteChat("Need group please", "Rogue", "WHISPER")
assert(table.getn(calls) == 2 and calls[2] == "Rogue", "second comma-separated phrase did not invite")
ShirsLazyTrix.HandleInviteChat("invite", "Hunter", "GUILD")
assert(table.getn(calls) == 2, "guild invite fired while guild setting was disabled")
ShirsLazyTrixDB.inviteFromGuild = true
ShirsLazyTrix.HandleInviteChat("raid please", "Hunter", "GUILD")
assert(table.getn(calls) == 3 and calls[3] == "Hunter", "guild invite did not fire when enabled")
ShirsLazyTrix.HandleInviteChat("invite again", "Hunter", "WHISPER")
assert(table.getn(calls) == 3, "repeat invite cooldown failed")
now = 14
ShirsLazyTrix.HandleInviteChat("invite again", "Hunter", "WHISPER")
assert(table.getn(calls) == 4, "invite did not resume after cooldown")
ShirsLazyTrix.HandleInviteChat("invite", "Shirina", "WHISPER")
assert(table.getn(calls) == 4, "self-invite was not ignored")
ShirsLazyTrixDB.invitePhrases = ""
now = 20
ShirsLazyTrix.HandleInviteChat("invite", "Druid", "WHISPER")
assert(table.getn(calls) == 4, "empty phrase list still triggered invite")

ShirsLazyTrixDB.invitePhrases = "invite"
now = (2 ^ 32) / 1000 - 2
ShirsLazyTrix.HandleInviteChat("invite", "Priest", "WHISPER")
assert(table.getn(calls) == 5, "pre-wrap invite did not fire")
now = 1.1
ShirsLazyTrix.HandleInviteChat("invite", "Priest", "WHISPER")
assert(table.getn(calls) == 6, "repeat invite remained blocked after uptime wrap")

print("invite-trigger: PASS")
