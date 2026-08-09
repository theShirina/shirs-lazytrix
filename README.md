# Shir's LazyTrix

A small quality-of-life addon for Microbot's WoW 1.12.1 client. Version 0.0.1 automates safe quest pickup and turn-in while keeping normal and repeatable quests separate.

## Features

- Prioritizes completed quest turn-ins before new quest pickup.
- Checks `IsQuestCompletable()` before continuing a turn-in.
- Automatically selects zero or one reward; several reward choices wait for you.
- Separate pickup and turn-in switches for normal and repeatable quests.
- Compact settings panel opened from a 24×24 minimap button or `/lazytrix`.

## Repeatable quests on 1.12

The Vanilla 1.12 quest APIs do not expose a repeatable flag in quest-giver lists. LazyTrix learns a repeatable quest when the same NPC offers the same title again after a confirmed turn-in. Learned quests are stored separately for each realm and character. Until then, the quest uses the normal category. This avoids a guessed title database and supports Microbot-specific quests after one completed cycle.

## Defaults

- Normal turn-in: on
- Normal pickup: on
- Repeatable turn-in: off
- Repeatable pickup: off

## Installation

1. Extract `ShirsLazyTrix` into `Interface\AddOns`.
2. Restart the client if the addon was not present when WoW started.
3. Click the book icon on the minimap to choose the four quest options.

## Compatibility

Built and checked for Microbot WoW 1.12.1, Interface `11200`, and Lua 5.0.3. Other Vanilla clients are not claimed as supported.
