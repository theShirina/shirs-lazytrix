# Shir's LazyTrix

A small quality-of-life addon for WoW 1.12 clients. Version 0.0.13 fixes invite matching so only complete configured phrases trigger.

## Features

- Prioritizes completed quest turn-ins before new quest pickup.
- Checks `IsQuestCompletable()` before continuing a turn-in.
- Remembers failed item-gated turn-ins without trusting ambiguous quest-log title matches.
- Stops selecting the same NPC and quest after two unconfirmed turn-in attempts.
- Clears that fallback only when the same NPC's active quest list no longer contains the title after a reward attempt.
- Automatically selects zero or one reward; several reward choices wait for you.
- Separate switches for automatic turn-in and pickup.
- Optional Shift-required automation mode covering both pickup and turn-in.
- By default, holding Shift stops automatic quest actions so you can handle the current quest manually.
- Optional automatic sale of gray-quality items when a vendor opens.
- Optional automatic repair of all gear when a repair vendor opens.
- Repair checks the quoted cost and available money before submitting once.
- Optional automatic acceptance of pending resurrection requests in the open world.
- Never accepts inside a battleground, dungeon, raid, or any ambiguous location.
- Does not release your corpse.
- Optional removal of Oil of Immolation and Immolation Aura when Stealth, Lesser Invisibility, or Invisibility starts.
- Distinguishes Oil's `Fire Shield` from a warlock imp's same-named buff by requiring the Immolation texture.
- Uses the exact client buff index API and does not require SuperMacro.
- Optionally grows stock-width class and profession trainers downward to 18 visible rows.
- Adds a manual Train All button with paced, bounded purchase retries.
- Lets you enable trainer expansion and Train All independently.
- Freezes the exact services and quoted costs when clicked; newly unlocked ranks wait for another click.
- Checks the full plan cost before spending, includes unique recipes and owned profession rank upgrades, and skips new profession skill lines.
- Optionally selects the client-typed trainer gossip entry without matching class-specific text.
- Holding Shift always leaves trainer gossip open for talent resets and other choices.
- Optional movable panel for Mooncloth, Transmute: Arcanite, and Salt Shaker cooldowns.
- Hovering a cooldown row lists the live remaining time for every saved character on the account.
- Clicking a ready row rechecks the live recipe or bag item before requesting exactly one craft or use.
- Stores cooldown observations and panel position per realm and character.
- Refreshes profession cooldown observations while Tailoring or Alchemy remains open, including after manual crafts.
- Ten seconds after login, announces ready saved cooldowns for your other characters; Mooncloth, Arcanite, and Salt Shaker reminders can each be switched on or off.
- Includes a small panel lock and an option to hide the panel during combat and while inside battlegrounds, raids, or dungeons.
- Corrects Salt Shaker cooldowns across the client's uptime wrap instead of showing roughly 50 days.
- Optionally shows `Item ID: <number>` beneath item tooltips from bags, equipment, loot, vendors, quests, professions, and item links.
- Sells one revalidated gray stack per tick and waits for proceeds to settle.
- Does not support marked junk or add a merchant button.
- Minimal dark navy settings panel with the shared blue and gold addon style.
- Standard 32×32 movable minimap button with an original high-contrast LazyTrix icon.
- Optional minimap-button collector with an adjustable 18–32 px button size: left-click opens the collected addon buttons and right-click opens LazyTrix settings.
- Adjustable four-to-twelve-row stock Blizzard loot frame with fixed-size top controls and repeated stock body art; expansion can be disabled for another loot UI, and pfUI-owned loot remains untouched.
- Optional automatic party invites from whisperers and guild chat.
- Invite triggers accept multiple comma-separated phrases, save the text as you type, require the complete incoming message to equal one configured phrase, and use a short per-sender cooldown to prevent repeat invites.

## Shift behavior

By default, hold Shift while using a quest giver to stop LazyTrix from selecting, accepting, completing, or submitting a quest reward. Keep Shift held until you finish the manual step.

When **Only automate while Shift is held** is enabled, LazyTrix waits for Shift before selecting, accepting, completing, or submitting a zero/one-choice reward. The pickup and turn-in switches still control which actions are allowed.

## Defaults

- Automatic turn-in: on.
- Automatic pickup: on.
- Only automate while Shift is held: off.
- Automatically sell gray items at vendors: off.
- Automatically repair all gear at repair vendors: off.
- Automatically accept open-world resurrection requests: off.
- Remove immolation effects on stealth or invisibility: off.
- Expand trainer windows: off.
- Enable Train All: off.
- Automatically open trainer services: off.
- Show profession cooldown panel: off.
- Hide cooldown panel in combat and instances: off.
- Other-character Mooncloth reminder: on.
- Other-character Arcanite reminder: on.
- Other-character Salt Shaker reminder: on.
- Show item IDs in item tooltips: off.
- Expand Blizzard loot rows: on.
- Stock loot rows: 4.
- Collect addon minimap buttons: off.
- Collected minimap button size: 24 px.
- Invite from whispers: off.
- Invite from guild chat: off.
- Invite phrases: `invite`.

## Installation

1. Download [`ShirsLazyTrix-v0.0.13.zip`](https://github.com/theShirina/shirs-lazytrix/releases/download/v0.0.13/ShirsLazyTrix-v0.0.13.zip).
2. Extract the `ShirsLazyTrix` folder into `Interface\AddOns`.
3. Restart the client if the addon was not present when WoW started.
4. Click the LazyTrix **L** icon to open settings. When button collection is enabled, left-click opens the collected buttons and right-click opens settings. Drag the icon to move it.

## Compatibility

Built and checked for a WoW 1.12 client, Interface `11200`, and Lua 5.0.3. Other clients have not been tested.
