# Changelog

## 0.0.17

### Added

- Added an optional CCP schedule view for AQ20, Zul'Gurub, and Onyxia's Lair.
- Shows the server reset countdown and cycle when no personal lockout exists.

### Changed

- Scheduled raids without a personal lockout now show `Ready - resets in ...`.
- Reads CCP's schedule without opening the CCP Raid Lockouts panel.

## 0.0.16

### Added

- Added a Show all option to Raid Reset Info for standard raids without current lockouts.
- Added a compact Raid Reset header toggle between saved lockouts and the full raid list.

### Changed

- Reduced the settings gap above Other-Character Ready Reminders.

## 0.0.15

### Added

- Added an optional Raid Info panel for the current character's saved raid lockouts and reset countdowns.
- Added a separate setting plus saved position and lock state for the Raid Info panel.
- Added hover details for matching raid lockouts last saved by other characters.

## 0.0.14

### Fixed

- Prevented repeated `CompleteQuest()` calls when the client sends the same progress event more than once.
- Prevented repeated reward submissions when a failed quest reward leaves the dialog open, including inventory-full cases.
- Quests that can be completed again now continue after a successful reward even when the same NPC keeps listing the quest.
- Kept the two-attempt safety limit for turn-ins that do not show reward-stage completion evidence.

## 0.0.13

### Fixed

- Invite triggers now require the complete incoming message to equal a configured phrase, so a short trigger such as `inv` no longer matches inside a sentence.

## 0.0.12

### Added

- Added separate settings for party invites from whispers and guild chat.
- Added a text field for one or more comma-separated invite phrases.

### Fixed

- Invite phrases now save as they are typed, so every comma-separated phrase is available immediately.
- Party invites now use the WoW 1.12 `InviteByName` function.
- The short repeat-invite cooldown now remains correct when the client uptime timer wraps.

## 0.0.11

### Fixed

- Extra Blizzard loot rows now use the stock loot button type, so rows beyond four can be clicked, hovered, and used again.

## 0.0.10

### Added

- Added an option to disable the extra Blizzard loot rows when another loot UI is active.

### Fixed

- Fixed an error in multi-loot and raid-group updates when expanded rows lacked the stock `SetSlot` method.

## 0.0.9

- Reworked settings into a compact two-column layout with shorter labels and grouped controls.
- Cooldown-row hover now shows live remaining times for every saved character on the account.
- Added an adjustable four-to-twelve-row stock Blizzard loot frame, with four rows as the default.
- Added rows now repeat the stock body artwork and move the stock bottom edge while the header and item controls remain at full scale.
- Added an optional minimap-button collector using the existing LazyTrix launcher.
- Added an 18–32 px collected-button size control and normalized each button's state textures to its selected frame size.
- When collection is enabled, left-click opens the addon-button tray and right-click opens LazyTrix settings.
- Leaves pfUI-owned loot and active third-party minimap-button collectors untouched.

## 0.0.8

- Added a default-off setting that shows the item ID beneath item tooltips.
- Covers bags, equipped items, loot, vendors, quest items, profession items and reagents, and item links.
- Avoids adding a second line when the same item-ID line already exists or Informant's item-ID option is active.
- Added separate on/off settings for other-character Mooncloth, Arcanite, and Salt Shaker ready reminders.
- Profession cooldown status now refreshes after a craft while the profession window remains open.

## 0.0.7

- Added a default-off movable panel for the current character's Mooncloth, Transmute: Arcanite, and Salt Shaker cooldowns.
- Saves panel position and observed cooldown times per realm and character.
- Clicking a ready row checks the live recipe or bag item before requesting one craft or use.
- Blocks duplicate and reentrant Salt Shaker submissions while the first request is pending.
- Corrects Salt Shaker cooldowns after the client's uptime counter wraps.
- Added a small lock button and moved the drag hint left to make room for it.
- Added a default-off option to hide the cooldown panel during combat.
- Added login notices for ready saved cooldowns on other characters, excluding the character currently logged in.
- Delayed other-character cooldown notices by ten seconds so server welcome text does not bury them.
- Expanded the combat-hide option to hide the panel inside battlegrounds, raids, and dungeons.

## 0.0.6

- Added a default-off downward layout for class and profession trainers.
- Trainer expansion and Train All now have separate default-off settings and work independently.
- Shows 16 class-training rows and 18 profession-training rows while preserving stock width.
- Reserves extra class-detail space so wrapped descriptions stay clear of the money bar.
- Centers the Train and Exit buttons in the matching stock artwork sockets.
- Extends the exact stock bottom-left and bottom-right artwork through the added middle band, while leaving pfUI's backdrop in charge when enabled.
- Refreshes Train All after Blizzard makes its load-on-demand trainer frame visible.
- Added a manual Train All button with a guarded click-time service and cost snapshot.
- Continues through already-listed ranks that unlock after earlier purchases, with an eight-pass limit.
- Centers a smaller Train All button within its matching bottom-left socket and reduces the money text and coin icons by two pixels to fit beside it.
- Fills the exposed middle of the expanded stock scrollbar track and leaves pfUI artwork unchanged.
- Trains unique blank-rank recipes while rejecting duplicate service identities.
- Paces purchases and tolerates intermediate trainer updates without stopping after a few abilities.
- Retries an unchanged unpaid service at most twice, then stops after a bounded timeout.
- Cancels an unchanged retry if the ordered trainer list changed after submission.
- Includes owned profession rank upgrades, skips new profession skill lines, and blocks malformed or ambiguous trainer data.
- Reuses pfUI's trainer-row skin for the seven added rows.
- Retries trainer mode hooks after Blizzard's load-on-demand trainer UI becomes available.
- Added a separate default-off option that opens the exact trainer-type gossip entry.
- Holding Shift always bypasses trainer gossip selection so talent reset choices remain available.

## 0.0.5

- Added a default-off setting that removes immolation effects when stealth or invisibility starts.
- Handles Stealth, Lesser Invisibility, and Invisibility messages from the exact client.
- Removes exact Oil of Immolation and Immolation Aura effects without requiring SuperMacro.
- Requires the Immolation texture for same-named Fire Shield buffs, preserving a warlock imp's Fire Shield.
- Scans from the highest buff slot down and cancels the exact index returned by the client.
- Does not send a chat message.

## 0.0.4

- Added a default-off setting that accepts pending resurrection requests in the open world.
- Leaves resurrection requests untouched inside battlegrounds, dungeons, raids, and ambiguous locations.
- Accepts player and companion requests through the stock pending-resurrection event.
- Never releases the player's corpse.

## 0.0.3

- Added an opt-in setting that repairs all gear when an eligible repair vendor opens.
- Checks the full repair cost and available money before submitting one repair action.
- Reports successful repairs and insufficient funds in the chat frame.
- Keeps automatic repair independent from gray-item selling and quest Shift behavior.
- Stops retrying an NPC and quest after two turn-in selections without confirmation from that same NPC's next quest list.

## 0.0.2

- Redesigned the settings panel with the shared dark navy, blue, and gold addon style.
- Replaced the padded stock book with an original blue-and-gold LazyTrix icon in standard 32×32 launcher chrome.
- Added minimap dragging with a saved position.
- Added one optional Shift-required automation mode covering both quest pickup and turn-in.
- Prevented item-gated or otherwise incomplete gossip quests from entering a repeated turn-in loop.
- Added an opt-in vendor action that sells gray-quality items only.
- Handles vendor sales with slot checks, cancellation, and delayed proceeds.
- Excluded item marking and merchant-button controls.

## 0.0.1

- Added safe automatic turn-in for completed quests.
- Added automatic quest pickup.
- Prioritized turn-ins and left incomplete quests or multiple reward choices untouched.
- Added a physical Shift override for manual quest handling.
- Added a compact two-option settings panel with a minimap button.
