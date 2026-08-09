# Shir's LazyTrix

A small quality-of-life addon for Microbot's WoW 1.12.1 client. Version 0.0.1 automates safe quest pickup and turn-in while preserving a manual override.

## Features

- Prioritizes completed quest turn-ins before new quest pickup.
- Checks `IsQuestCompletable()` before continuing a turn-in.
- Automatically selects zero or one reward; several reward choices wait for you.
- Separate switches for automatic turn-in and pickup.
- Holding Shift stops automatic quest actions so you can handle the current quest manually.
- Compact settings panel opened from a 24×24 minimap button or `/lazytrix`.

## Shift override

Hold Shift while using a quest giver to stop LazyTrix from selecting, accepting, completing, or submitting a quest reward. Keep Shift held until you finish the manual step.

## Defaults

- Automatic turn-in: on.
- Automatic pickup: on.

## Installation

1. Download [`ShirsLazyTrix-v0.0.1.zip`](https://github.com/theShirina/shirs-lazytrix/releases/download/v0.0.1/ShirsLazyTrix-v0.0.1.zip).
2. Extract the `ShirsLazyTrix` folder into `Interface\AddOns`.
3. Restart the client if the addon was not present when WoW started.
4. Click the book icon on the minimap to choose the two quest options.

## Compatibility

Built and checked for Microbot WoW 1.12.1, Interface `11200`, and Lua 5.0.3. Other Vanilla clients are not claimed as supported.
