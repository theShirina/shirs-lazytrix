# Changelog

## 0.0.6

- Added a default-off expanded layout for class and profession trainers.
- Increased the visible trainer list to 22 rows and moved details into a second pane.
- Added a manual Train All button with a full-plan affordability check.
- Buys one service per trainer update and stops when the trainer closes or results stop changing.
- Skips services that consume a profession slot or return malformed cost data.

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
