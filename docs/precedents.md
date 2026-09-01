# Quest, vendor, and world automation precedents

## v0.0.17 CCP raid schedule

The installed CCP 4.17 on the exact Microbot 1.12.1 client parses the server reply `ACINFO:SELFLOCK:SCHED` into `CCP_SelfLockData.sched`. Each record supplies a map ID, raid name, seconds until reset, and reset cycle. The exact-client map IDs are `249` Onyxia's Lair, `309` Zul'Gurub, and `509` Ruins of Ahn'Qiraj (AQ20). CCP stores reset times from `GetTime()`, so LazyTrix converts the uptime delta to its wall-clock status model.

LazyTrix reads the existing CCP data path without copying CCP code. Its new default-off setting adds only those three schedule rows when the current character has no matching native lockout, preserves native rows ahead of schedule rows, validates map, time, and cycle bounds, and fails closed when CCP schedule data is absent or malformed. This is exact local source evidence for the mechanism; a live server reply is still required to populate the schedule after a client restart.

## Exact-client source

LazyPig 6.0.4 declares Interface `11200` and handles `QUEST_GREETING`, `GOSSIP_SHOW`, `QUEST_PROGRESS`, and `QUEST_COMPLETE`. It selects active or available quests through stock Vanilla functions and proves `IsShiftKeyDown()` is available in the exact client. It calls `CompleteQuest()` without checking `IsQuestCompletable()`.

Microbot's effective FrameXML parses `GetGossipActiveQuests()` and `GetGossipAvailableQuests()` as title/level pairs. Those gossip lists do not expose completion state. Exact-client pfQuest code reads the sixth `GetQuestLogTitle()` value as completion state, but the quest log exposes no NPC identity. LazyTrix therefore does not use title-only quest-log matches to clear NPC-scoped safety state.

## Later-client references

Leatrix Plus 1.13.43 and QuestHaste 0.1 in the local addon archive both declare Interface `11303`. They are useful design references, not Vanilla API proof. Leatrix supplies the chosen safety pattern: turn-ins before pickups, `IsQuestCompletable()` before `CompleteQuest()`, and automatic rewards only when no choice is required.

## v0.0.1 quest choice

Shir's LazyTrix uses only APIs present in Microbot's 1.12 client. It provides two account-wide switches for pickup and turn-in. Holding physical Shift suppresses every automatic quest action until Shift is released.

## v0.0.2 merchant source and scope

Shir's Inventory 0.5.3 at commit `a8ebe56c921d3896a09944dac66590981e9940a0` declares Interface `11200` and supplies the proven local merchant precedent. Its MIT-licensed sale path builds a queue on `MERCHANT_SHOW`, submits one stack per timed tick, revalidates bag/slot identity and quality, cancels outside the merchant sell tab, and waits for delayed money updates before reporting proceeds.

LazyTrix adapts only that queue and settlement behavior. Its candidate list admits quality `0` items only. It does not read marked-item data, alter item-click behavior, or create a merchant button. The setting is account-wide and defaults off.

## v0.0.3 automatic repair precedent

Microbot's stock Interface `11200` `MerchantFrame.lua` shows repair controls only when `CanMerchantRepair()` succeeds and reads `GetRepairAllCost()` to decide whether the repair-all action is available. The currently installed LazyPig 6.0.4 (`LazyPig.lua` SHA-256 `9839c173fba8be72914925cb6081fe8fccf6372e40becb392bf68a1134b408df`) uses `CanMerchantRepair()`, `GetRepairAllCost()`, `GetMoney()`, and `RepairAllItems()` on this exact client. No licence file was found in that installed LazyPig folder, so it is study-only and no source is copied.

LazyTrix uses an original, narrow implementation. Its account-wide setting defaults off. On `MERCHANT_SHOW`, it first confirms that the vendor repairs gear, reads the full repair cost, checks available money, and calls `RepairAllItems()` at most once. Zero-cost, unavailable, and insufficient-funds paths do not submit a repair. Repair and gray sale settings remain independent.

## v0.0.3 two-attempt turn-in fallback

LazyTrix uses `IsQuestCompletable()` for its first incomplete-turn-in guard. Some custom quests can still report true while refusing completion, so v0.0.3 adds a second runtime fallback keyed by NPC and quest title. It allows two active-quest selections, blocks the third, and shares the count across greeting and gossip dialogs. After a reward attempt, a count clears only when that same NPC's next active-quest list no longer contains the title. Quest-log changes from another NPC and logless custom quests cannot reset it.

## v0.0.4 open-world resurrection precedent

Microbot's `WoW.exe` exposes `IsInInstance`, `AcceptResurrect`, and `CancelPlayerBuff`; it does not expose the later `GetInstanceInfo`. The installed LazyPig 6.0.4 (`LazyPig.lua` SHA-256 `9839c173fba8be72914925cb6081fe8fccf6372e40becb392bf68a1134b408df`) registers `RESURRECT_REQUEST`, calls `AcceptResurrect()`, and hides the three exact-client resurrection popups. LazyPig accepts requests inside known instances, which is the opposite of LazyTrix's v0.0.4 policy. No licence file was found in the installed LazyPig folder, so it remains study-only.

Vanilla API references document `IsInInstance()` as returning `1` inside an instance and `nil` outside. Some compatible clients expose boolean values and a second type value. LazyTrix therefore accepts only the explicit outside forms `nil`, `false`, or `0`, with a missing type or `"none"`. It rejects every inside, contradictory, unknown, or missing-API state. The original handler calls `AcceptResurrect()` at most once on `RESURRECT_REQUEST`, hides the pending popup only after acceptance, and never calls `RepopMe()`.

## v0.0.5 stealth immolation cleanup precedent

The user supplied a SuperMacro snippet that listens for `CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS`, matches the exact English messages for Stealth, Lesser Invisibility, and Invisibility, then calls `CancelBuff("Fire Shield")`. The installed SuperMacro 3.14a declares Interface `11200`. Its `SM_Slash.lua` (SHA-256 `421fc8dddd835a129e55c225359a2929501947624d4f12828cb7ed256c21cb57`) resolves buff names through a hidden tooltip and calls `CancelPlayerBuff(index)`. No licence file was found in the installed folder or referenced archive, so its source remains study-only.

The exact Microbot executable exposes `CancelPlayerBuff`, `GetPlayerBuff`, and `GetPlayerBuffTexture`. Stock `BuffFrame.lua` and installed exact-client pfUI enumerate helpful buffs with `GetPlayerBuff`, inspect tooltip text, and cancel the returned index. Exact `Spell.dbc` data distinguishes Oil's `Fire Shield` / `Fire Shield IV` Immolation icon (`Spell_Fire_Immolation`) from a warlock imp's same-named Fire Armor icon (`Spell_Fire_FireArmor`). LazyTrix uses an original private tooltip scanner and a descending `31..0` slot loop. Exact `Oil of Immolation` and `Immolation Aura` names are unambiguous; `Fire Shield` and `Fire Shield IV` also require the Immolation texture. The default-off feature does not call SuperMacro's global `CancelBuff` and does not send chat output.

## v0.0.6 expanded trainer precedent

Microbot's stock Interface `11200` `ClassTrainerFrame.lua` shows 10 profession rows or 11 class rows. It enumerates services through `GetNumTrainerServices()` and `GetTrainerServiceInfo()`, reads money and profession-point costs through `GetTrainerServiceCost()`, and submits one selected service through `BuyTrainerService()`. Its profession and class mode functions reset the row count and scroll-frame heights on each update.

The installed Leatrix Plus 1.13.43 trainer layout declares Interface `11303` and uses later APIs and later-client artwork, so it is behavior evidence only. Its two-column geometry breaks the installed pfUI skin and is not reused. The installed SuperMacro 3.14a contains an exact-client bulk trainer loop but has no located licence and is also study-only. LazyTrix uses original Lua 5.0.3 code: it keeps the stock 384-pixel frame width, grows the list downward to 18 stock trainer-row templates, keeps the detail pane beneath the list, and wraps the two stock mode functions without `hooksecurefunc`. Train All accepts only exact `available` services with bounded copper values and zero profession-point costs. It checks the full plan, paces each submission, rescans the live list, and tolerates intermediate unchanged updates. The same service is retried only when its cost has not left the player's money, with two retries and a three-second timeout. Closure or unclear state stops the queue. No Leatrix or SuperMacro source or artwork is copied.

Stock `GossipFrame.lua` passes text/type pairs from `GetGossipOptions()` to the UI and calls `SelectGossipOption()` with the pair index. LazyTrix's separate default-off shortcut requires exactly one option whose type is the exact lowercase value `trainer`; it does not match class-specific or localized text. Missing APIs, malformed pairs, and several trainer entries fail closed. Physical Shift always bypasses this shortcut before quest gossip handling, leaving talent reset and other gossip choices available.

## Settings and minimap precedents

| Source | Pin | Client and evidence | Licence | Reuse decision |
|---|---|---|---|---|
| User-supplied Leatrix Plus settings screenshot | Supplied 2026-08-09 | Later-client visual reference: compact hierarchy, dark surface, gold section labels, sparse controls, muted help text | Screenshot reference only | Study only; do not copy branding, textures, layout code, or sidebar structure |
| Shir's Inventory `ShirsInventorySettings.lua` | `a8ebe56c921d3896a09944dac66590981e9940a0` | Interface `11200`; proven local dark navy tooltip backdrop, blue border, blue title, gold section accent | MIT | Adapt the shared addon-family palette and stock backdrop assets |
| Left Interact Vanilla `CreateMinimapButton` / `UpdateMinimapButtonPosition` | `948d004546685e7a48c52eb878d361e6eebd1f3f` | Interface `11200`; released local use of angle-based minimap dragging, SavedVariables persistence, stock tracking border, and stock highlight | MIT | Adapt the movement behavior with original LazyTrix code and artwork |
| CCP Keybind Display `CreateMinimapButton` plus live exact-client comparison | `bda09bc202d759687a300bf1ec707aefca8264f7` | Interface `11200`; standard 32×32 launcher geometry and live evidence that the 24×24 stock-book variant looked undersized and padded | No licence file found in the inspected repository | Study geometry only; copy no source or artwork |
| MinimapButtonFrame-vanilla | `0923f9e4128c6fcdc97df448c7665ca71bca2a18` | Vanilla repository with movable minimap-button behavior; tree includes `MinimapButtonFrame.toc`, Lua, and XML | No root licence found in the pinned tree | Study only; do not copy source |

The LazyTrix redesign uses stock Blizzard border/highlight assets, original UI Lua, and an original 64×64 TGA icon. The gray-only merchant queue adapts first-party MIT-licensed behavior from Shir's Inventory as recorded above. No third-party code, branding, layout, or artwork is copied. The settings panel keeps the released pickup and turn-in switches, adds one optional Shift-required automation mode for both actions, and explains the modifier behavior. The standard 32×32 launcher saves its angle after drag.

## v0.0.8 item-ID tooltip precedent

Informant 3.9.0.1003 at repository commit `35cbf9f6d1693cf0edfdb1fd4fa097abae1aa37c` declares Interface `11200`. Its `Tooltip.lua` hooks the stock bag, equipment, loot, vendor, quest, profession, and hyperlink tooltip paths, while `Informant.lua` extracts the first numeric field from an `item:` link and can show it as an item-ID line. The files are GPL-2.0-or-later and the repository has no root licence response, so LazyTrix uses Informant only as behavior and exact-client API evidence.

LazyTrix uses original Lua 5.0.3 code and stock tooltip methods, including `ItemRefTooltip` for clicked chat links. Its account-wide setting defaults off. It extracts only positive bounded item IDs from complete raw or colored item-link fields, preserves each original tooltip method's arguments and return values, and adds one muted `Item ID: number` line. Missing APIs, malformed links, non-item links, and invalid IDs add nothing. It avoids an exact duplicate line and yields to Informant only when Informant and its item-ID filter are both active.

## v0.0.9 cooldown hover, loot rows, and minimap collection

LazyTrix v0.0.8 already stores Mooncloth, Arcanite, and Salt Shaker observations in account-wide SavedVariables keyed by realm and character, and refreshes its panel every 0.25 seconds. v0.0.9 extends that original data path: hovering one cooldown row lists that cooldown's formatted status for every valid saved character and refreshes the open tooltip through the existing panel update.

Blizzard's WoW 1.12.1 `LootFrame.lua` and `LootFrame.xml` were inspected at MOUZU/Blizzard-WoW-Interface commit `d162a4c0d198a4381b5b6573d975635ed7316702`. The stock frame declares four `LootButtonTemplate` rows, reads `LOOTFRAME_NUMBUTTONS` during update and pagination, and derives hover slots from the same value. No repository licence was found, so the extract is API and behavior evidence only. LazyTrix uses original code to create extra stock-template buttons and change the row count; it copies no Blizzard source. pfUI loot at MIT-licensed commit `b2f6df84a93a4ce6adbe1fd8f0372454795151f1` confirms that an exact-client loot frame can enumerate every loot slot, but it replaces the frame and is not reused because this feature keeps Blizzard styling.

MinimapButtonBag-vanilla at commit `6a89b32044cb0c3ef9ba8c2184af6689ed48b2a2` scans named interactive children of the minimap, moves them under one launcher, and keeps an ignore list for stock pins. No repository licence was found, so it is study-only. LazyTrix uses an original narrower collector: it does not replace button scripts or override `Show`, `Hide`, `SetPoint`, or `ClearAllPoints`; it saves and restores each collected frame's parent, anchor, scale, and frame level. Active pfUI, MBB, or MBF collectors make it fail closed rather than compete for ownership.

## v0.0.2 Shift-required automation mode

The existing exact-client `IsShiftKeyDown()` evidence also supports a modifier-triggered automation policy. The released default remains unchanged: Shift suppresses every automatic quest action. When the new account-wide option is enabled, Shift instead permits active and available quest selection, pickup, completion, and zero/one-choice reward submission. The pickup and turn-in master switches still apply. No third-party policy or code is copied.
