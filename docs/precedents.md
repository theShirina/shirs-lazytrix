# Quest automation precedents

## Exact-client source

LazyPig 5.37 declares Interface `11200` and handles `QUEST_GREETING`, `GOSSIP_SHOW`, `QUEST_PROGRESS`, and `QUEST_COMPLETE`. It selects active or available quests through stock Vanilla functions and proves `IsShiftKeyDown()` is available in the exact client. It calls `CompleteQuest()` without checking `IsQuestCompletable()`.

Microbot's effective FrameXML parses `GetGossipActiveQuests()` and `GetGossipAvailableQuests()` as title/level pairs. Those gossip lists do not expose completion state.

## Later-client references

Leatrix Plus 1.13.43 and QuestHaste 0.1 in the local addon archive both declare Interface `11303`. They are useful design references, not Vanilla API proof. Leatrix supplies the chosen safety pattern: turn-ins before pickups, `IsQuestCompletable()` before `CompleteQuest()`, and automatic rewards only when no choice is required.

## v0.0.1 choice

Shir's LazyTrix uses only APIs present in Microbot's 1.12 client. It provides two account-wide switches for pickup and turn-in. Holding physical Shift suppresses every automatic quest action until Shift is released.
