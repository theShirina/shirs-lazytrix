Shir's LazyTrix 0.0.10

WoW 1.12 client.

INSTALL
Copy the ShirsLazyTrix folder into Interface\AddOns, then restart WoW if this is a new addon.

USE
Click the blue-and-gold L icon on the minimap or type /lazytrix.
Drag the icon around the minimap to move it; LazyTrix saves the position.

OPTIONS
The minimalist dark navy panel uses the shared blue and gold addon style.
- Turn in completed quests
- Pick up quests
- Only automate while Shift is held
- Automatically sell gray items at vendors
- Automatically repair all gear at repair vendors
- Automatically accept open-world resurrection requests
- Remove immolation effects on stealth or invisibility
- Expand trainer windows
- Enable Train All
- Automatically open trainer services
- Show profession cooldown panel
- Hide cooldown panel in combat and instances
- Other-character Mooncloth ready reminder
- Other-character Arcanite ready reminder
- Other-character Salt Shaker ready reminder
- Show item IDs in item tooltips
- Collect addon minimap buttons under the LazyTrix button
- Choose an 18-32 pixel size for collected minimap buttons
- Choose 4-12 stock Blizzard loot rows
- Disable the extra Blizzard loot rows when another loot UI is active

Turn-ins are checked before pickups. An item-gated or otherwise incomplete turn-in stays blocked instead of trusting a same-title quest-log entry. If the same NPC and quest is selected twice without a confirmed completion, LazyTrix stops retrying it for the rest of the session. A successful reward attempt clears the count when that same NPC no longer lists the quest. Quests with several reward choices wait for you.

MANUAL OVERRIDE
By default, hold Shift while using a quest giver to stop automatic selection, pickup, turn-in, and reward submission. Keep Shift held until you finish the manual step.

When "Only automate while Shift is held" is enabled, Shift triggers both automatic pickup and turn-in. The two action switches still apply.

GRAY ITEMS
"Automatically sell gray items at vendors" is off by default. When enabled, LazyTrix sells only gray-quality items after a vendor opens. It has no item marking and no merchant button.

REPAIRS
"Automatically repair all gear at repair vendors" is off by default. When enabled, LazyTrix checks the full repair cost and your money, then repairs once when an eligible vendor opens. Gray selling and repairs work independently.

RESURRECTION
"Automatically accept open-world resurrection requests" is off by default. When enabled, LazyTrix accepts a pending resurrection only when the client reports that you are outside battlegrounds, dungeons, raids, and other instances. It does not release your corpse.

STEALTH AND INVISIBILITY
"Remove immolation effects on stealth or invisibility" is off by default. When enabled, LazyTrix removes Oil of Immolation and Immolation Aura after the client reports Stealth, Lesser Invisibility, or Invisibility. It checks Oil's Immolation texture so it will not remove a warlock imp's same-named Fire Shield. It works without SuperMacro and does not send a chat message.

TRAINERS
"Expand trainer windows" and "Enable Train All" are separate and off by default. Expansion keeps the stock width and grows class and profession trainers downward to 18 rows. Train All works with either the stock or expanded trainer. It freezes the listed services and quoted costs when clicked, checks the full cost first, paces purchases, retries an unchanged unpaid service at most twice, and skips entries that consume a profession slot. Newly unlocked ranks wait for another click. Closing the trainer stops the queue.

"Automatically open trainer services" is off by default. When enabled, LazyTrix selects the trainer-type gossip entry without relying on class-specific wording. Hold Shift while speaking to the trainer to keep the gossip menu open for talent resets and other choices.

PROFESSION COOLDOWNS
"Show profession cooldown panel" is off by default. When enabled, the movable panel shows this character's Mooncloth, Transmute: Arcanite, and Salt Shaker state. Hover a row to see the live status for every saved character on the account. Open Tailoring or Alchemy once on each character so LazyTrix can save the live recipe cooldown. While that profession window stays open, LazyTrix refreshes its observations twice per second so a completed manual or panel-triggered craft updates without closing the window. Ten seconds after login, LazyTrix announces ready saved cooldowns for your other characters, but not the character you logged into. Mooncloth, Arcanite, and Salt Shaker reminders each have their own switch and default on. These switches affect login reminders only; they do not remove saved cooldowns or panel rows. Clicking a ready row rechecks the live recipe or bag item before requesting exactly one craft or use; the game still checks reagents, location, skill, and bag space. Use the small lock button to keep the panel in place. The separate hide option hides it during combat and while inside battlegrounds, raids, or dungeons, then restores it afterward.

LOOT AND MINIMAP
Loot rows default to four and can be set from four to twelve. The stock header, portrait, close button, text, and item rows stay at full scale. LazyTrix repeats a clean stock body strip for each added row and moves one stock bottom strip to the new edge. It leaves pfUI-owned loot unchanged. The minimap-button collector is off by default. Collected buttons default to 24 pixels and can be set from 18 to 32 pixels. When enabled, left-click the LazyTrix button to open the collected addon buttons and right-click it to open settings. LazyTrix restores collected buttons to their original parent, position, size, scale, textures, frame layer, and frame level when the option is disabled.

ITEM TOOLTIPS
"Show item IDs in item tooltips" is off by default. When enabled, LazyTrix adds an "Item ID: number" line beneath item tooltips from bags, equipment, loot, vendors, quests, profession windows, and item links. If Informant's own item-ID option is active, LazyTrix leaves that line to Informant.
