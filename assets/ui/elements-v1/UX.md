# Chop a Tree — screen audit and art assembly

Source audit: client controllers, HUD, Navigation, Config/Products, Daily and Rebirth; 2026-10-02. This is the proposed art/interaction spec. Existing runtime UI remains unchanged by this asset pack. Concepts are illustrative, not screenshots or authoritative item data. Config/services own names, counts, prices and rules.

## Shared visual and interaction rules

- Chestnut/copper wood frame, dark inset, bold outlined English labels, large original item art. Green primary action, gold upgrade/selected tab, red close/destructive action; rarity uses current Config order. Label states as well as color.
- One modal, stable red X at top right, backdrop dim/blur. Keep selected item and scroll offset on timed refresh. One dominant action for the current selection; secondary actions smaller. Artwork sits behind live text, hit targets and focus outlines.
- Desktop: inventory four columns with detail sidebar; shop two or three columns when card text fits; garden plot grid with selected detail; incubator slot cards. More retains secondary systems. Reserve Roblox top bar, chat, joystick and tool hotbar areas.
- Compact view: Menu drawer; two-column cards, scrollable tab row, tap card opens full-width detail with Back. Minimum 48px actions; no hover-only information. Preserve text size instead of shrinking an entire desktop window. Keyboard/gamepad focus order follows reading order; close returns focus to opener. Device behavior is proposed, not tested.
- Loading: keep frame and show Loading; disable repeated action while pending. Empty: explain how to obtain the item plus existing next action. Locked: state requirement. Error: retain selection, show server message and Retry when appropriate. Success: brief toast and refreshed data. Preserve existing confirmations for deletion/release/cut/rebirth.

## Screen coverage

Paths below are relative to repo root; controller/config is the authoritative feature list.

| Screen / source | Existing feature/action | Proposed layout and art |
|---|---|---|
| HUD + ForestController | Coins/Wood/Gems, run stats, Play, manual chop, Auto Attack/Auto Cut, End Run, run result | Compact currency capsules (coins/wood/gems), one clear PLAY in hub; in run show End Run and small automation controls. Results: reward cards + Back to Game; chest art. No timer added to run. |
| NavigationController | Inventory/Pets/Garden/Shop/Rewards; More: Quests/Season/Rebirth/Emotes/Photo/Invite Friends/Settings | Existing woodland nav icons inside menuTile; compact drawer; same frame and labels. Friend invite keeps platform flow. |
| InventoryController — Weapons | Select, preview, Equip, Fuse 3, Delete | Rarity grid + selected pane; green Equip, gold Fuse, separate red confirmed Delete. Keep UID/tier compatibility; no invented item lock or Normal/Huge/Giant variant system. See concepts/inventory.png. |
| InventoryController — Chests/results | Open 1/Open 10 access/capacity, Stardust exchange, rolled results | Large chest cards with count/level/rarity; Open 1 main, Open 10 secondary when eligible; show missing capacity/pass requirement. Results use rarity cards, actual awarded items and live close action. |
| PetController — Incubator/Eggs | Select egg, choose slot, Place, Hatch Ready; progress/theft/protection | Slot-card overview, clear Ready/Growing/Empty; select egg grid then return to chosen slot. Progress + warning below 75%; protect/hatched states follow server. Generic incubator illustration; actual slots from Config. See concepts/pets.png. |
| PetController — Pets | Carry, Add to Pen, Stow, Fuse 3, Mount/Dismount, confirmed Release | Pet grid + detail; Carry primary; pen/store/mount secondary; Fuse selection mode and confirmed Release. Generic pet art denotes category only; individual species use their actual preview/art. |
| PetController — Base | Collect income, lock/cooldown, pen/incubator/lock/trap/guard upgrades, shield/friend permissions, decor place/rotate/remove | Summary bank + Collect; group Protection, Upgrades, Decoration into sections of the Base tab. Shield/clock/wood resources, short cost/status cards. Decor placement instructions stay visible; keep ownership/refund/shrine/festival gates. |
| PetController — Conveyor | Timed egg offers, Coins purchase, Aurora one-event offer | Horizontal offer cards with egg art, actual price and time left. Purchased badge replaces buy; no fabricated urgency or extra offers. |
| GardenController — Garden/Seeds | Choose plot/seed, Plant, Water, Harvest, confirmed Cut, slot upgrade | Plot grid + selected pane; Empty→Select Seed/Plant, growing→Water if useful, ready→Harvest. Put Cut in separate destructive area. Never change underlying harvest/Auto Sell behavior. See concepts/garden.png. |
| GardenController — Shop/Merchant | Seed stock/restock, fruit sale cap/over-cap rate, sell all fruit, timed merchant offers | Seeds as illustrated cards; fruit basket/value summary plus Sell All Fruit. Merchant cart hero + actual offers/currency, arrival/expiry UTC. Show cap/rate before sale. |
| ShopController | 10 passes / 17 products, ownership, Warp, Roblox prompt | Large art cards, live price, exact duration/benefit, Owned badge; use existing monetization artwork. No new products or fake discount. See concepts/shop.png; View Price in concept is a placeholder, runtime shows GetProductInfo price. |
| RewardsController — Daily/Codes/Boards | Seven-day claim, code redeem/boosts, leaderboard metric + server/global scope | 4+3 reward calendar, Today highlight, one Claim Today; centered code input + Redeem; ranked rows with trophy and metric/scope filters. Rewards exactly Config.Daily. See concepts/rewards.png. |
| StoryController — Main/Daily/Weekly | Chapter objective/dialogue, quest progress/claim and UTC reset | Featured current objective card + progress track; smaller completed/other quests; journal/shrine category art. Dialogue portrait card + Next/Skip; actual story text. |
| StoryController — Index | Weapons/Pets/Seeds/Mutations, discovered counts, silhouettes, category bonuses | Four category chips, rarity/discovery gallery, locked silhouette + hint and count; actual collection IDs, no fake variant columns. Reuse inventory cards; no generic fox pretending to be every species. |
| StoryController — Achievements/Warp | Achievement reward/title equip, unlocked destination/access | Achievement medal rows + one claim/equip action; destination cards + requirement/Travel action. Shrine/journal art as category illustration, exact destinations from Config. |
| SeasonController | 30 levels, XP/time left, free/premium tracks, individual/Claim All, premium prompt | Ticket header + XP track; compact scrollable level columns with two reward tracks. Green Claim All; secondary premium card, live price and unlocked state. Actual Config rewards/season dates; no unimplemented cosmetics advertised. |
| RebirthController | Eligibility/cost/token award, six permanent skills, Prepare/Confirm/Cancel | Overview requirement card + New Cycle; skill cards with rank/cost. Confirmation clearly separates Reset/Keeps lists from service rules; retain confirmation token. Shrine/book/category icon only; no new token currency introduced. |
| Navigation Settings | Independent session-local Music/SFX ON/OFF | Small tall wooden frame, two spacious rows and clear toggles; add no unimplemented graphics/accessibility settings. |
| EmoteController | Emote wheel; Photo filters/free camera/hide UI/exit | Wood-framed radial buttons with existing emote symbols; Photo slim filter strip, readable controls and Exit. Touch keeps existing orbit camera. No fake screenshot-saving button or cosmetic shop. |
| WeatherController | Current weather, forecast, festivals/events notifications | Small clock/status pill; short event toast, expanded info only on deliberate open. Keep actual UTC/countdowns; avoid covering quest/action area. |
| ArenaController + arena client | Ranked/Casual, four modes, queue/status/cancel, rank/RP/tokens; combat/match HUD | Four mode cards + queue state and Leave Queue. Separate combat HUD with mode objective and controls. PvP remains disabled until existing live-proof gate; tokens are display-only, no invented token shop. |
| Admin UI | Authorized operator commands and testing | Keep isolated operator view with compact sections/searchable commands; reuse frame/buttons only. Public navigation must not expose privileged actions. |

## Assembly mapping

`sprites.json` is the source of crop rectangles. Atlas names: frames, controls, systems, resources. Use actual uploaded texture dimensions, never guessed source-grid coordinates.

- Window: windowWide/windowTall → dark woodInset → content Frame; menuTile holds existing nav atlas art.
- Item/reward card: cardCommon/Rare/Epic/Legendary/Mythic → actual model/asset preview → live name/count → optional state badge; emptyPlot for garden empty state.
- Action: buttonGreen/Gold/Red/Blue/Wood background + live label + callback. Red close, add, lock are standalone symbols; lock is a requirement indicator, not a new inventory lock feature.
- Progress: progressTrack background + clipped native fill + live percentage/countdown. Growth/XP values come from server/state.
- Category heroes: chest/incubator/pet/gardenPlot/wateringCan/seedPouch/seasonTicket/shrine/merchant. Resource symbols: coins/wood/gems/arenaToken/questBook/trophy/shield/clock/emptyPlot.

## Implementation order / acceptance

1. Import four final PNGs, record actual IDs/dimensions; integrate shared window/buttons before changing screen structure. Preserve callbacks and text as GUI objects.
2. Garden and Pets first (densest existing action rows), then Inventory/Shop/Rewards, then Story/Season/Rebirth and smaller views using the same patterns.
3. Check every listed view and empty/locked/loading/error state in Play: crops, clipping, contrast, focus, close/reopen, timed refresh and real actions. Desktop/phone/gamepad screenshots required; purchase/save tests remain separate.

Prepared: 36 reusable sprites, five generated concepts, prompts, ImageRect helper. Pending: uploading these four atlases, runtime assembly, individual item/species art and device proof. Generated concept counts/stat values and pet/weapon designs are illustrative, never Config changes.
