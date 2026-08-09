# Changelog

## 0.0.6

- Added a default-off downward layout for class and profession trainers.
- Trainer expansion and Train All now have separate default-off settings and work independently.
- Shows 16 class-training rows and 18 profession-training rows while preserving stock width.
- Reserves extra class-detail space so wrapped descriptions stay clear of the money bar.
- Centers the Train and Exit buttons in the matching stock artwork sockets.
- Extends the exact stock bottom-left and bottom-right artwork through the added middle band, while leaving pfUI's backdrop in charge when enabled.
- Refreshes Train All after Blizzard makes its load-on-demand trainer frame visible.
- Added a manual Train All button with a fixed click-time service and cost snapshot.
- Places Train All in the measured top control slot, compacting it beside All when the stock checkbox filter strip is present.
- Leaves name-only services manual without disabling safe ranked services.
- Paces purchases and tolerates intermediate trainer updates without stopping after a few abilities.
- Retries an unchanged unpaid service at most twice, then stops after a bounded timeout.
- Cancels an unchanged retry if the ordered trainer list changed after submission.
- Skips services that consume a profession slot and blocks malformed or ambiguous trainer data.
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
- Reused the proven asynchronous queue, slot revalidation, cancellation, and delayed-proceeds handling from Shir's Inventory.
- Excluded item marking and merchant-button controls.

## 0.0.1

- Added safe automatic turn-in for completed quests.
- Added automatic quest pickup.
- Prioritized turn-ins and left incomplete quests or multiple reward choices untouched.
- Added a physical Shift override for manual quest handling.
- Added a compact two-option settings panel with a minimap button.
