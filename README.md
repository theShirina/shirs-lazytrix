# Shir's LazyTrix

A small quality-of-life addon for Microbot's WoW 1.12.1 client. Version 0.0.6 adds an optional expanded trainer window with a guarded Train All queue.

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
- Optionally expands class and profession trainers from 10/11 visible rows to 22.
- Adds a manual Train All button that buys one safe service per trainer update.
- Checks the full plan cost before spending and skips services that consume a profession slot.
- Optionally selects the client-typed trainer gossip entry without matching class-specific text.
- Holding Shift always leaves trainer gossip open for talent resets and other choices.
- Sells one revalidated gray stack per tick and waits for proceeds to settle.
- Does not support marked junk or add a merchant button.
- Minimal dark navy settings panel with the shared blue and gold addon style.
- Standard 32×32 movable minimap button with an original high-contrast LazyTrix icon.

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
- Expand trainer windows and add Train All: off.
- Automatically open trainer services: off.

## Installation

1. Download [`ShirsLazyTrix-v0.0.6.zip`](https://github.com/theShirina/shirs-lazytrix/releases/download/v0.0.6/ShirsLazyTrix-v0.0.6.zip).
2. Extract the `ShirsLazyTrix` folder into `Interface\AddOns`.
3. Restart the client if the addon was not present when WoW started.
4. Click the LazyTrix **L** icon on the minimap to open settings, or drag it to a new position.

## Compatibility

Built and checked for Microbot WoW 1.12.1, Interface `11200`, and Lua 5.0.3. Other Vanilla clients are not claimed as supported.
