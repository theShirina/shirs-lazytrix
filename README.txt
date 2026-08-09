Shir's LazyTrix 0.0.6

Microbot WoW 1.12.1 only.

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
- Expand trainer windows and add Train All
- Automatically open trainer services

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
"Expand trainer windows and add Train All" is off by default. When enabled, class and profession trainers keep their stock width, grow downward to 18 rows, and gain a manual Train All button. LazyTrix checks the full cost first, paces purchases, retries an unchanged unpaid service at most twice, and skips entries that consume a profession slot. Closing the trainer stops the queue.

"Automatically open trainer services" is off by default. When enabled, LazyTrix selects the trainer-type gossip entry without relying on class-specific wording. Hold Shift while speaking to the trainer to keep the gossip menu open for talent resets and other choices.
