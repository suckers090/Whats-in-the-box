# Industrial icon HUD

This is a client presentation update to the existing Rojo project. It replaces
the bottom text bar with five left-side rounded buttons while preserving the
existing Inventory, Collection Index, Shop, Upgrades and Scanner menu handlers.
The Shop remains the working selling desk, and Upgrades retains the scanner;
this update does not add new purchases or change their server validation.

## Install into your current folder

1. Stop Play and back up your local project folder and saved Studio place.
2. Download `build/WITB-Icon-HUD-Update.zip`, extract it, and merge its **contents**
   into your existing Rojo folder. Keep the other files in that folder. This
   ZIP contains the files listed below plus this guide; install them together.
3. In the existing Rojo terminal press Ctrl+C, then run `tools\rojo.exe serve`
   from the folder containing `default.project.json`. Reconnect Studio and Play.

No place import, plugin installation or scenery rebake is needed. Rojo syncs
scripts; the new HUD appears during Play. This update excludes PersistenceConfig,
VisualConfig, save modules, warehouse assets, the box client and server gameplay.

## Changed files and Instances

| File | Change |
| --- | --- |
| `src/StarterPlayer/StarterPlayerScripts/WarehouseHUD.client.luau` | Cash card, vertical scrolling navigation, responsive placement, single-controller guard, selected menu state, Home in menu footers, navigation hidden during reveals. Existing menus and request safeguards retained. |
| `src/StarterPlayer/StarterPlayerScripts/WarehouseNotifications.client.luau` | Notices share HUD safe-area measurements and avoid its cash card/navigation. |
| `src/ReplicatedStorage/HUDNavigation.luau` | Reusable rounded buttons, original vector-style graphics, accent colors, hover/focus/press tweens and selected marks. |
| `src/ReplicatedStorage/HUDLayout.luau` | Responsive geometry, compact mode, scroll area and space for touch movement controls. |
| `default.project.json` | Maps the two new modules under ReplicatedStorage. |

`PlayerGui.WarehouseHUD` remains the single ScreenGui, with `ResetOnSpawn=false`.
It contains a transparent `SafeArea`, `CashCard`, `IconNavigation` ScrollingFrame,
scroll hint and the original menu overlay. The five named buttons are InventoryNav,
IndexNav, ShopNav, UpgradesNav and ScannerNav. Each has an accent badge, GUI-shape
icon, label, active mark, border/gradient and UIScale. Cash has a banknote graphic.
The Home action is available in every menu's footer. Native Roblox UI stays enabled.

Icons depict a sealed crate, collection ledger, storefront, rising upgrade bars
and barcode scanner. They use ordinary Frames, UICorners and UIStrokes rather than
text symbols, image IDs or externally uploaded assets. Nothing is added to Workspace.

On desktop and taller tablets the full stack is visible. Short displays use
52-pixel button rows and a scrollable stack. Swipe or scroll to reach lower buttons.
Very short safe areas (under 280 pixels high) show cash without the two secondary
status lines to leave room for movement. Delivery state itself is unchanged.
`VisualConfig.ReducedMotion` disables navigation scaling and menu entrance motion;
existing optional Button audio hooks remain in use.

## Roblox Studio checklist

- **Menus:** Open all five buttons. Check Index reward claims, inventory sorting,
  locks/favorites/selling, Shop → Open Inventory, and Scanner/Upgrades → station.
  Use HOME in a menu footer. Confirm B/I shortcuts and close controls still work.
- **Appearance:** Confirm the old bottom bar is gone, cash is above the left stack,
  icons/labels are readable, hover and taps feel smooth, and the active menu has
  its matching colored border/mark. Check with ReducedMotion both on and off.
- **Sizes:** In Studio's Device Emulator test desktop, tablet, phone portrait and
  phone landscape. Rotate/resize while running. Short screens must scroll to all
  five buttons without covering the thumbstick; check Roblox's top bar, chat,
  jump button and package/door prompts with the actual in-game controls enabled.
- **Notifications/reveals:** Sell something and receive a delivery/notice. Cash and
  notices should stay readable. Open a package: navigation hides during the reveal
  and returns after Keep/Sell. Inventory confirmation must still require approval.
- **Duplicates:** Respawn several times; under PlayerGui there should be exactly
  one WarehouseHUD and one IconNavigation. Each click should open one menu and
  issue one action. Normal StarterPlayerScripts execution is guarded against a
  second copy; remove any manually copied obsolete HUD scripts if present.
- **Regression:** Two-player ownership, scanner purchase/readings, deliveries,
  doors, cash/inventory, index claims and rejoining after SAVED still work.

Automated checks execute actual HUD/navigation/notification callbacks with GUI
doubles: duplicate controller prevention, menu selection, hover/tap/reduced motion,
Home travel, layout bounds/notice exclusion at seven device sizes, and the existing
inventory confirmation, pause/timeout and reveal-token safeguards. Luau compilation
and the Rojo scripts-only build also pass. These checks do **not** render Roblox UI,
simulate native touch controls or verify Studio/network/DataStore behavior. The
Studio checks above are required to assess the finished appearance.

## Backup

`backups/pre-icon-hud/` contains the exact previous HUD, notifications, mapping and
README. This stage changes no save format or server code. If reverting the UI,
restore the paired HUD/notifications and old mapping together with Rojo stopped;
restart Rojo and start a fresh Play session. Keep all unrelated local files.
