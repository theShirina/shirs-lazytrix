# Quest and merchant automation precedents

## Exact-client source

LazyPig 5.37 declares Interface `11200` and handles `QUEST_GREETING`, `GOSSIP_SHOW`, `QUEST_PROGRESS`, and `QUEST_COMPLETE`. It selects active or available quests through stock Vanilla functions and proves `IsShiftKeyDown()` is available in the exact client. It calls `CompleteQuest()` without checking `IsQuestCompletable()`.

Microbot's effective FrameXML parses `GetGossipActiveQuests()` and `GetGossipAvailableQuests()` as title/level pairs. Those gossip lists do not expose completion state. Exact-client pfQuest code reads the sixth `GetQuestLogTitle()` value as completion state, which provides a safe event-driven signal after `IsQuestCompletable()` rejects an attempted gossip turn-in.

## Later-client references

Leatrix Plus 1.13.43 and QuestHaste 0.1 in the local addon archive both declare Interface `11303`. They are useful design references, not Vanilla API proof. Leatrix supplies the chosen safety pattern: turn-ins before pickups, `IsQuestCompletable()` before `CompleteQuest()`, and automatic rewards only when no choice is required.

## v0.0.1 quest choice

Shir's LazyTrix uses only APIs present in Microbot's 1.12 client. It provides two account-wide switches for pickup and turn-in. Holding physical Shift suppresses every automatic quest action until Shift is released.

## v0.0.2 merchant source and scope

Shir's Inventory 0.5.3 at commit `a8ebe56c921d3896a09944dac66590981e9940a0` declares Interface `11200` and supplies the proven local merchant precedent. Its MIT-licensed sale path builds a queue on `MERCHANT_SHOW`, submits one stack per timed tick, revalidates bag/slot identity and quality, cancels outside the merchant sell tab, and waits for delayed money updates before reporting proceeds.

LazyTrix adapts only that queue and settlement behavior. Its candidate list admits quality `0` items only. It does not read marked-item data, alter item-click behavior, or create a merchant button. The setting is account-wide and defaults off.

## Settings and minimap precedents

| Source | Pin | Client and evidence | Licence | Reuse decision |
|---|---|---|---|---|
| User-supplied Leatrix Plus settings screenshot | Supplied 2026-08-09 | Later-client visual reference: compact hierarchy, dark surface, gold section labels, sparse controls, muted help text | Screenshot reference only | Study only; do not copy branding, textures, layout code, or sidebar structure |
| Shir's Inventory `ShirsInventorySettings.lua` | `a8ebe56c921d3896a09944dac66590981e9940a0` | Interface `11200`; proven local dark navy tooltip backdrop, blue border, blue title, gold section accent | MIT | Adapt the shared addon-family palette and stock backdrop assets |
| Left Interact Vanilla `CreateMinimapButton` / `UpdateMinimapButtonPosition` | `948d004546685e7a48c52eb878d361e6eebd1f3f` | Interface `11200`; released local use of angle-based minimap dragging, SavedVariables persistence, stock tracking border, and stock highlight | MIT | Adapt the movement behavior with original LazyTrix code and artwork |
| CCP Keybind Display `CreateMinimapButton` plus live exact-client comparison | `bda09bc202d759687a300bf1ec707aefca8264f7` | Interface `11200`; standard 32×32 launcher geometry and live evidence that the 24×24 stock-book variant looked undersized and padded | No licence file found in the inspected repository | Study geometry only; copy no source or artwork |
| MinimapButtonFrame-vanilla | `0923f9e4128c6fcdc97df448c7665ca71bca2a18` | Vanilla repository with movable minimap-button behavior; tree includes `MinimapButtonFrame.toc`, Lua, and XML | No root licence found in the pinned tree | Study only; do not copy source |

The LazyTrix redesign uses stock Blizzard border/highlight assets, original UI Lua, and an original 64×64 TGA icon. The gray-only merchant queue adapts first-party MIT-licensed behavior from Shir's Inventory as recorded above. No third-party code, branding, layout, or artwork is copied. The settings panel keeps the released pickup and turn-in switches, adds one optional Shift-required automation mode for both actions, and explains the modifier behavior. The standard 32×32 launcher saves its angle after drag.

## v0.0.2 Shift-required automation mode

The existing exact-client `IsShiftKeyDown()` evidence also supports a modifier-triggered automation policy. The released default remains unchanged: Shift suppresses every automatic quest action. When the new account-wide option is enabled, Shift instead permits active and available quest selection, pickup, completion, and zero/one-choice reward submission. The pickup and turn-in master switches still apply. No third-party policy or code is copied.
