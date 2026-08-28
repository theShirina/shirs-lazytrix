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
  invitePhrases = "invite, need group,  raid please, inv ",
}

dofile(root .. "/ShirsLazyTrix_Invites.lua")

-- A configured phrase must be the complete message, not a substring.
ShirsLazyTrix.HandleInviteChat("Can you invite me?", "Mage", "WHISPER")
assert(table.getn(calls) == 0, "phrase inside a sentence triggered an invite")
ShirsLazyTrix.HandleInviteChat("invite", "Mage", "WHISPER")
assert(table.getn(calls) == 1 and calls[1] == "Mage", "exact phrase did not invite")
ShirsLazyTrix.HandleInviteChat("Need group please", "Rogue", "WHISPER")
assert(table.getn(calls) == 1, "non-exact phrase variant triggered an invite")
ShirsLazyTrix.HandleInviteChat("need group", "Rogue", "WHISPER")
assert(table.getn(calls) == 2 and calls[2] == "Rogue", "second exact phrase did not invite")

-- INV is valid only when it is the complete message (outer whitespace is allowed).
ShirsLazyTrix.HandleInviteChat("please inv", "Hunter", "WHISPER")
assert(table.getn(calls) == 2, "inv inside a sentence triggered an invite")
ShirsLazyTrix.HandleInviteChat("  INV  ", "Hunter", "WHISPER")
assert(table.getn(calls) == 3 and calls[3] == "Hunter", "standalone inv phrase did not invite")

ShirsLazyTrix.HandleInviteChat("raid please", "Hunter", "GUILD")
assert(table.getn(calls) == 3, "guild invite fired while guild setting was disabled")
ShirsLazyTrixDB.inviteFromGuild = true
ShirsLazyTrix.HandleInviteChat("raid please now", "Hunter", "GUILD")
assert(table.getn(calls) == 3, "phrase inside a guild sentence triggered an invite")
ShirsLazyTrix.HandleInviteChat("raid please", "Warrior", "GUILD")
assert(table.getn(calls) == 4 and calls[4] == "Warrior", "guild exact phrase did not invite")

ShirsLazyTrix.HandleInviteChat("invite again", "Hunter", "WHISPER")
assert(table.getn(calls) == 4, "non-exact phrase bypassed matching")
now = 14
ShirsLazyTrix.HandleInviteChat("invite", "Hunter", "WHISPER")
assert(table.getn(calls) == 5, "invite did not resume after cooldown")
ShirsLazyTrix.HandleInviteChat("invite", "Shirina", "WHISPER")
assert(table.getn(calls) == 5, "self-invite was not ignored")

ShirsLazyTrixDB.invitePhrases = ""
now = 20
ShirsLazyTrix.HandleInviteChat("invite", "Druid", "WHISPER")
assert(table.getn(calls) == 5, "empty phrase list still triggered invite")

ShirsLazyTrixDB.invitePhrases = "invite"
now = (2 ^ 32) / 1000 - 2
ShirsLazyTrix.HandleInviteChat("invite", "Priest", "WHISPER")
assert(table.getn(calls) == 6, "pre-wrap invite did not fire")
now = 1.1
ShirsLazyTrix.HandleInviteChat("invite", "Priest", "WHISPER")
assert(table.getn(calls) == 7, "repeat invite remained blocked after uptime wrap")

print("invite-trigger: PASS")
