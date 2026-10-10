# Shared plots and industrial UI — Studio test release

Historical pre-persistence checks: for the current save-system update and Studio preview/live modes, see docs/PERSISTENCE_TESTING.md.

This release builds on the Studio-tested door version. Original files and the previous Rojo mapping are preserved in backups/pre-plots-ui. Item names, values and probabilities remain the same. It changes runtime ownership and session inventory, so use a separate copy of your latest working Studio place for validation before adopting it.

## Get the update

Stop Play, save a dated backup of your current Studio place, and stop your local Rojo terminal. Download and extract the latest repository ZIP into a separate folder. Preserve any local script edits; do not overwrite them with an old ZIP. Copy your tools/rojo.exe into the new folder. Start Rojo from the folder containing the new default.project.json using the same serve command in docs/ROJO_SETUP.md, then reconnect Studio's plugin. Keep your latest saved place, warehouse model and markers; do not substitute an older repository test-place snapshot or a scripts-only build.

The new mapping adds server modules PlotRegistry, InventoryState and InteractionRules, shared modules ItemCatalog and UITheme in ReplicatedStorage, and WarehouseHUD in StarterPlayerScripts. It updates the existing gameplay, scanner, door, reveal and notification scripts. Unknown Studio objects are still preserved; Workspace is not synced.

## Runtime plot behavior

The edit-mode Workspace/WITB_StarterWarehousetest model and Workspace/WarehouseMarkers become templates in ServerStorage during Play only. Each player receives a clone under Workspace/WarehousePlots. The original saved Studio objects return on Stop; don't manually delete them from edit mode. Owner signs show player names and plot numbers. Plots are arranged four across, 90 studs apart and 140 studs between rows, with generated concrete grounds to make visiting possible. Assignment reuses free slots. Layout is an initial test layout, not finished world art.

Players spawn at their own plot, and Home returns them there. Visitors can open either door and look around. Only the owner can open, scan or sell sealed packages, or purchase that plot's scanner. Server checks include current allocation, character health, ancestry and interaction distance. Package prizes are held server-side rather than exposing their values in replicated box attributes. Each plot has independent delivery and restocking. When an owner leaves, that plot and its session state are released; a returning player starts fresh until persistence is added.

## New UI

Charcoal/navy panels, steel-blue borders and accents, rarity colors, animated menus, an updated reveal border and notifications share the UITheme palette. The HUD shows cash and discovery progress. Menus are Index, Inventory, Scanner, Shop, Upgrades and Home. PC shortcuts: I for Index and B for Inventory. On touch devices the navigation sits at the top to avoid the movement thumbstick and jump button. Cards switch between one and two columns according to available width; menus scroll.

Opening a package registers its discovery, even if sold immediately. KEEP adds one item to the inventory. Inventory selling removes one owned item and awards its catalog value; repeated requests cannot sell more than the player's owned count. The index shows unlocked names, rarity, value, counts and completion progress. Locked entries conceal item names.

Shop is currently a selling desk linked to the existing inventory and sealed-selling mechanics. It does not introduce paid random boxes or a new purchase economy. Scanner and Upgrades show the existing $2,000 scanner; GO TO STATION returns you to your own scanner. Buying through the menu still requires being nearby and having enough cash. New warehouse expansions/customizations are future additions, not nonfunctional buttons in these menus.

## Required Studio checks

1. Play with one player. Confirm the warehouse clone, owner sign, own spawn, working doors, truck and three packages appear. Verify marker positions and ground height. Check Output for module errors or missing templates.
2. Open a package: the existing 3D preview should still work. Choose KEEP, open Inventory, and verify one item. Sell one and verify the exact cash increase and count reduction. Repeatedly tap Sell and confirm no extra cash after the last copy. Open Index and verify the discovery stays unlocked.
3. Sell a newly revealed item directly; confirm it appears in the index but not retained inventory. Sell a sealed box and confirm $120 with no item discovery. Empty packages and verify restocking.
4. Open Scanner/Upgrades. GO TO STATION should return to your plot. Try buying with insufficient cash or from too far away; verify the notification and no deduction. Earn enough cash, buy once, and confirm only one $2,000 deduction, scanner creation, and status update. Scan your packages normally.
5. Use Studio's Server & Clients test with two clients. Each should have a distinct plot, cash, packages and inventory. Visit the other plot and toggle its doors. Attempt opening, scanning, sealed-selling, and buying its scanner: all should be rejected without changing either player's cash or packages. Keep/sell your own items while the other player does the same and verify isolation.
6. Reset a character and verify respawn at the same owned plot with session data retained. Test leaving/rejoining where your Studio test setup supports it; the old plot should disappear and its slot be reusable, with new session progress starting empty. Check Output during departures and restocking.
7. Use Device Emulator for a narrow portrait phone, landscape phone and tablet. Verify readable cash/navigation, one-column scrolling cards, reachable close buttons, reveal choices and no overlap with movement controls. Check mouse, gamepad focus and touch interactions on menus. Screen layouts have not been rendered in Studio by the assistant.
8. Save the successful test copy. Send screenshots and Output errors before publishing or making this the live baseline.

Progress is session-only: cash, discoveries, kept items and scanner reset after leaving the server. DataStore persistence is the next foundation before releasing this economy publicly. Visitors cannot yet inspect an owner's inventory or display shelves; those are future social features.

## Validation outside Studio

- Standalone Luau inventory tests check original RNG weights, discover/keep/sell, invalid and replayed decisions, forged item IDs, player isolation, and index retention after selling.
- Standalone authorization tests exercise owner/visitor denial, stale/released plots, excessive distance, dead characters and foreign objects using test doubles. They do not substitute for Roblox multiplayer tests.
- All current Luau sources compile, and Rojo 7.5.1 builds the complete mapping.

Run the standalone tests with `luau tests/inventory.luau` and `luau tests/ownership.luau` from the project root when Luau CLI is installed. The assistant has not executed this release in Roblox Studio. Geometry, UI rendering, clone allocation and cross-player interactions still require the checks above.

## Rollback

Stop Play and disconnect Rojo. Restore the source folder and mapping from backups/pre-plots-ui, then run that restored project against your saved pre-update Studio place. Remove only the new mapped modules/HUD from that test copy if necessary; unknown-instance preservation does not delete orphaned instances automatically. Opening the pre-update backup with the pre-update project is the simplest rollback.
