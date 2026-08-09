# Shir's LazyTrix

A small quality-of-life addon for Microbot's WoW 1.12.1 client. Version 0.0.2 automates safe quest handling and optional gray-item selling.

## Features

- Prioritizes completed quest turn-ins before new quest pickup.
- Checks `IsQuestCompletable()` before continuing a turn-in.
- Remembers failed item-gated turn-ins and retries only after the quest log marks them complete.
- Automatically selects zero or one reward; several reward choices wait for you.
- Separate switches for automatic turn-in and pickup.
- Optional Shift-required automation mode covering both pickup and turn-in.
- By default, holding Shift stops automatic quest actions so you can handle the current quest manually.
- Optional automatic sale of gray-quality items when a vendor opens.
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

## Installation

1. Download [`ShirsLazyTrix-v0.0.2.zip`](https://github.com/theShirina/shirs-lazytrix/releases/download/v0.0.2/ShirsLazyTrix-v0.0.2.zip).
2. Extract the `ShirsLazyTrix` folder into `Interface\AddOns`.
3. Restart the client if the addon was not present when WoW started.
4. Click the LazyTrix **L** icon on the minimap to open settings, or drag it to a new position.

## Compatibility

Built and checked for Microbot WoW 1.12.1, Interface `11200`, and Lua 5.0.3. Other Vanilla clients are not claimed as supported.
