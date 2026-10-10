# Polished menus and 60 discoveries

This milestone keeps the bubble navigation, collapse arrow and cash HUD from
`3426024` exactly as they are. It updates the existing functional menus and grows
the single package pool from five items to sixty. Shop remains the selling desk;
Scanner/Upgrades retain the working scanner purchase and station navigation.

## Install together

1. Stop Play. Back up your current Rojo folder and saved Studio place.
2. Extract `build/WITB-Menu-Content-Update.zip` and merge **all its contents** into
   the current Rojo folder, keeping other files. Install the mapping, modules,
   server and client files together; partial installation can stall dependency
   waits or leave new items out of menus/reveals.
3. Restart Rojo: Ctrl+C, then `tools\rojo.exe serve` from the folder containing
   `default.project.json`. Reconnect Studio and start a fresh Play session.

No place import, scenery rebake or Studio plugin update is needed. The ZIP excludes
PersistenceConfig, VisualConfig, profile/save modules, side-button modules,
notifications, doors and warehouse assets. Existing local save settings stay intact.
This package assumes the prior bubble HUD/inventory milestone is installed.

## Menus

- All five menus share rounded industrial panels, a soft shadow, accent header
  illustrations, a vector close control, larger buttons and hover/press/focus/open
  animations. MenuStyle is separate from the unchanged side-button styling.
- Inventory uses category illustrations, rarity badges, readable quantity/value
  lines and larger lock/favorite/sell controls. Existing sorting, protections,
  duplicate-sale confirmation, pause handling and request receipts are retained.
  Epic is now included in rarity filtering and ordering.
- Index starts with Items. Browse all/discovered/missing or individual rarities;
  the rarity filter also reports found/total. Search item names or themes, such as
  `electronics` or `tools`. Missing cards keep a lock illustration and discovery
  prompt. Discovered cards show value, times opened and current copies kept.
- Press REWARDS to see collection milestones separately, with goal bars, claim
  buttons and claimed states. Press ITEMS to return. Five additional goals at
  10/20/35/50/60 unique discoveries offer $1,000/$2,500/$5,000/$9,000/$14,000.
  The original three IDs, requirements and payouts remain unchanged.
- Menus use one column on phones and two on wider screens. They stay within
  Roblox's safe area and scroll their content, with smaller headers on short
  landscape displays. Wide landscape screens place tools alongside the header to
  free more scrolling space. Very short screens require scrolling to reach card controls.
  Text search can open the mobile keyboard; test keyboard dismissal on your device.
- HOME stays in each menu footer. B/I shortcuts, collapse state and box reveal
  handling remain available. ReducedMotion retains immediate menu entrance.

## Content and balance

| Rarity | Items | Total roll chance |
| --- | ---: | ---: |
| Common | 20 | 70% |
| Uncommon | 16 | 17% |
| Rare | 12 | 8% |
| Epic | 8 | 3% |
| Legendary | 4 | 2% |

Themes include electronics, toys, tools, collectibles, household, office,
warehouse junk and mystery valuables. New finds include vintage cameras,
typewriters, a model train, precision tools, a turntable, sapphire pendant,
meteorite fragment, diamond relic, founder's trophy and quantum core.

All 60 items have stable IDs, positive integer values, rarity, weight, category
and preview metadata. Old Toy, Headphones, Gaming Console, Gold Watch and
Mysterious Device retain their IDs/names/rarities/sale prices. Individual chances
change to make room for more discoveries, including Epic. Weighted mean opened
sale value is $739.71 versus $756.75 previously. Sealed sales remain $120 and the
scanner remains $2,000. The table gives rarity totals, not equal odds per item.

Server ItemRoller measures the whole catalog rather than rolling the old fixed
1–100 range. Package contents are still assigned privately when packages arrive;
opening, scanner clues, ownership, cash and reward choices remain server-controlled.
Collection claims also check cash headroom before marking a reward claimed.

Menu illustrations use GUI shapes by category instead of dozens of 3D viewports.
New reveal previews use reusable procedural models of 3–8 noncolliding parts.
The original five reveal models remain unchanged. These are shared preview
families ready for later custom Blender assets, not sixty bespoke imported meshes.

## Changed files

| File | Purpose |
| --- | --- |
| `default.project.json` | Adds the five new modules below; keeps existing mappings. |
| `ReplicatedStorage/ItemCatalog.luau` | 60 stable item definitions and metadata. |
| `ReplicatedStorage/CollectionMilestones.luau` | Five additive goals, existing claims retained. |
| `ReplicatedStorage/InventoryView.luau` | Epic ordering/filter. |
| `ReplicatedStorage/CollectionView.luau` (new) | Pure collection summaries and literal search/filtering. |
| `ReplicatedStorage/MenuStyle.luau` (new) | Menu surfaces/buttons and responsive geometry. |
| `ReplicatedStorage/ItemArt.luau` (new) | Lightweight category/locked card graphics. |
| `ReplicatedStorage/ItemPreview.luau` (new) | Bounded new reveal props. |
| `ServerScriptService/ItemRoller.luau` (new) | Authoritative full-pool weighted rolls. |
| `ServerScriptService/WarehousePrototype.server.luau` | Uses full-pool roller; guards collection credit limit. |
| `ServerScriptService/CollectionProgress.luau` | Optional cash-headroom check without consuming a failed claim. |
| `StarterPlayerScripts/WarehouseHUD.client.luau` | Existing menu presentation and collection browsing. |
| `StarterPlayerScripts/BoxClient.client.luau` | ID-based preview selection for new items; old models/choices retained. |

All source paths above start at `src`; StarterPlayerScripts is under StarterPlayer.
UI Instances are inside the existing WarehouseHUD: MenuPanel, MenuShadow,
MenuBadge, CloseMenu, IndexTools/search and item cards. Preview geometry lives
only in the existing BoxRevealUI's WorldModel. No scenery or extra HUD is created.

## Saves and deployment

No store names or v1 profile format change. Existing cash, inventory, discoveries,
scanner, claims, locks/favorites and pending rewards remain valid. Old `5/5`
Index progress becomes `5/60` because the collection grew; those five finds remain
discovered. New IDs fit the existing count/flag maps and new claims use existing
claim flags. Unknown valid IDs remain preserved by the unchanged schema.

For a published game, validate in a private test copy first and restart running
servers when deploying the paired update so clients/servers share one catalog.
An old five-item server cannot display/sell new finds, and its schema rejects an
unknown pending new reward. After saving new content, keep the expanded catalog
and compatible preview/roller dependencies when rolling back presentation. Do
not blindly restore the five-item catalog or reset player stores. Exact pre-change
files are in `backups/pre-menu-content/` for review and pre-deployment recovery.

## Studio checklist

1. **Existing account:** Join with prior data. Cash, kept items, scanner,
   locks/favorites and old claimed milestones must remain. Expect the Index
   denominator to grow to 60, with the original discoveries still unlocked.
2. **Menus:** Inspect Inventory/Index/Shop/Scanner/Upgrades, close controls, HOME,
   hover/tap/controller focus and ReducedMotion. Side buttons/cash/collapse must
   look exactly as before. Check Inventory sorting, Epic filtering, locks,
   favorites, Sell One, duplicate quote/cancel/confirm and empty-filter states.
3. **Index:** Search a name/theme; cycle missing/found/rarity filters. Check totals,
   kept/opened counts and Rewards view. Claim an eligible goal once, try again,
   sell an item and confirm the discovery stays. Rejoin after SAVED: claims persist.
4. **New content:** Open enough packages to see varied themes; check scanner
   clues, previews, names, prices and rarity effects, including Epic. For rare
   coverage use a disposable test session rather than granting items to live saves.
   Preview props must clear between reveals and after Keep/Sell.
5. **Mobile:** Emulate phone portrait/landscape and tablet, resize with each menu
   open, search with the keyboard and swipe to the bottom. Headers/tools/list/
   footer must remain separate and card controls reachable. Check native menus,
   prompts and real touchscreen input on a device.
6. **Multiplayer/rejoin:** Two-player cash/inventory/discovery isolation, station
   ownership, delivery loop, doors and saving still work. Keep/Sell and claims
   remain server validated. There should still be one WarehouseHUD.

Automated checks exercise all 10,000 possible roll tickets, legacy/new item save
roundtrips and pending recovery, every milestone, cash-cap rejection, Epic
ordering, literal searches, real client menu callbacks/geometry and all 60
procedural previews, along with the existing remote/profile/delivery safeguards.
Luau compilation and the Rojo build are also checked. These are not Roblox Studio
rendering, mobile keyboard/touch, native networking or live DataStore tests.
