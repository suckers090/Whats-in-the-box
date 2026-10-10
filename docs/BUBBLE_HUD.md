# Bubble HUD refinement

This refines the working icon HUD from commit `00ad72c`; the five-button left
layout and all menu handlers remain in place. No server scripts, save formats,
profile settings, warehouse models or Rojo mapping are changed.

## Install

1. Stop Play and back up your current project folder.
2. Extract `build/WITB-Bubble-HUD-Update.zip` and merge its `src` and `docs`
   folders into your existing Rojo folder, replacing only matching files.
   Keep all other files. This update assumes the previous icon HUD is installed.
3. Reconnect Rojo if needed and start a fresh Play session. If restarting Rojo,
   press Ctrl+C in its terminal and run `tools\rojo.exe serve` from your project
   folder. No place import, Studio plugin install or scenery rebake is needed.

## Changes

- `HUDNavigation.luau`: near-circular rounded faces, shallow dark shadows, subtle
  vertical gradients, top highlights, accent rims and round icon badges.
  Hover/focus, tap and selection animate the face, border, badge and icon. The
  collapse arrow uses the same styling and original GUI-shape graphics.
- `HUDLayout.luau`: cash card reduces from 230×96 to 216×84 on desktop, or 68 pixels
  high on compact screens. Narrow phones now use compact spacing too. Compact
  navigation rows are 54 pixels high with 7-pixel gaps; all five remain accessible
  through the existing scrolling stack. The arrow has a 44×44-pixel touch target.
- `WarehouseHUD.client.luau`: tightens cash/status spacing and adds NavigationToggle
  beside the cash card. Collapse slides navigation off the left edge; the arrow
  rotates to expand it again. Cash remains visible. Hidden buttons lose input and
  controller focus. Rapid taps/resize cancel old animations safely.
- `WarehouseNotifications.client.luau`: keeps notices clear of the new arrow as
  well as cash/navigation. All notification messages and audio cues are retained.

The collapse choice is local to the current session and survives respawn because
the existing HUD does. It is not written to player data. Navigation and its toggle
hide during package reveals, then respect the previous collapse choice afterward.
B/I keyboard shortcuts still open their menus while the stack is collapsed.
HOME remains in menu footers. Sorting, locks/favorites, sale confirmations,
scanner actions, Index claims and save-status warnings are unchanged.

New UI objects are limited to bubble faces/shadows, highlight/gradient/rim details,
icon scales and one NavigationToggle button with a rotating chevron. They live
inside the existing PlayerGui.WarehouseHUD. No extra ScreenGui, Workspace objects,
downloaded image assets or animation loops are added. ReducedMotion suppresses
navigation scaling/sliding and makes arrow rotation immediate.

## Studio checks

1. Check the bubble gradients/highlights at normal display brightness. Labels and
   cash must remain readable; test a large cash balance on a narrow device.
2. Hover, click/tap and use controller focus. Open every menu, including Shop →
   Inventory, Scanner/Upgrades → station, Index claims and HOME.
3. Tap the arrow repeatedly. Cash stays visible and navigation ends in the chosen
   state. Collapsing must not trigger a purchase or sale. Test B/I while hidden.
4. Emulate phone portrait, phone landscape and tablet. Rotate/resize with the stack
   expanded and collapsed. Swipe to all five buttons on short screens. Check the
   thumbstick, jump button, native Roblox menus and world interaction prompts.
5. Collapse, open a box, then Keep/Sell: navigation stays collapsed and the arrow
   returns. Repeat with navigation expanded. Test ReducedMotion both on and off.
6. Sell an item and receive a delivery notice; notices must avoid the arrow/cash.
   Respawn and verify exactly one WarehouseHUD and NavigationToggle remain.
7. Confirm inventory locks/favorites and duplicate-sale confirmation, scanner,
   deliveries, doors and rejoining after SAVED still work normally.

Automated GUI-double checks execute the real scripts and cover eight safe-area
sizes, menu actions, focus/hover/tap/selection, collapse and animation timing,
resize/reveal restoration, HUD uniqueness and existing inventory safeguards.
Luau compilation and the Rojo build are checked too. These do not render Roblox
gradients/shadows, emulate native controls or verify Roblox Studio/DataStores.

`backups/pre-bubble-hud/` contains the exact prior four source files and README.
Restore all four together for a UI rollback and begin a fresh Play session.
