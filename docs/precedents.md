# Quest automation precedents

## Exact-client source

LazyPig 5.37 declares Interface `11200` and handles `QUEST_GREETING`, `GOSSIP_SHOW`, `QUEST_PROGRESS`, and `QUEST_COMPLETE`. It selects active or available quests through the stock Vanilla functions, but calls `CompleteQuest()` without checking `IsQuestCompletable()`. Its repeatable workflow records a title and interaction sequence after the player holds Shift.

Microbot's effective FrameXML parses `GetGossipActiveQuests()` and `GetGossipAvailableQuests()` as title/level pairs. It does not expose repeatable or completion fields in those gossip lists.

## Later-client references

Leatrix Plus 1.13.43 and QuestHaste 0.1 in the local addon archive both declare Interface `11303`. They are useful design references, not Vanilla API proof. Leatrix supplies the chosen safety pattern: turn-ins before pickups, `IsQuestCompletable()` before `CompleteQuest()`, and automatic rewards only when no choice is required.

## v0.0.1 choice

Shir's LazyTrix uses only APIs present in Microbot's 1.12 client. It learns repeatable titles from a confirmed turn-in followed by the same title reappearing at the same NPC. Unknown titles stay in the normal category; no copied or guessed quest database is bundled.
