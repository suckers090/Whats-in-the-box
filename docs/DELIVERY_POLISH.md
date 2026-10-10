# Repeating delivery loop and truck polish

This update changes only WarehousePrototype.server.luau and WarehouseHUD.client.luau. Their prior versions are backed up in backups/pre-delivery-polish. The working shutter, profile saves, item catalog/odds, cash prices, package opening, scanner and inventory rules are unchanged. Display shelves remain a later feature.

## Easy local update — preserve your saving setting

Stop Play and save a Studio backup. Keep your current project folder and Rojo server. Back up these two local source files OUTSIDE src, then download their updated versions from GitHub using Download raw file and replace only:

- src/ServerScriptService/WarehousePrototype.server.luau
- src/StarterPlayer/StarterPlayerScripts/WarehouseHUD.client.luau

There are no new mapped modules or project configuration changes, so Rojo should sync the source automatically without a server restart. Do not replace PersistenceConfig.luau: keep your existing StudioPersistenceEnabled=true setting if you're testing real saves. If you prefer a full ZIP update, preserve that local flag and any other local edits before changing folders.

Use your latest saved Studio place. The old repository marker-test place is an earlier snapshot and should not replace it.

## Behavior

Each plot has one delivery controller. When its package area is empty and the owner's previous reveal choice is resolved, a truck queues for three seconds, reverses to the dock over five seconds, unloads three packages one by one, and drives out over five seconds. The truck disappears at the end of the road between trips. If packages remain, no new batch is delivered. If progress saving is paused, new deliveries wait rather than continuing the economy unattended. An active batch's package interactions still respect the existing DataReady/ownership checks.

The original three-package capacity and all item values/weights remain unchanged. Unlike the old package-only restock, replacement batches now take an actual arrival trip; players see the wait and movement. Deliveries can repeat after the previous truck departs and the package area is empty. There is no client-requested delivery remote or paid speed upgrade in this release.

The truck keeps the existing model shape with a navy/steel palette, windshield, headlights, rear lamps, bumpers and warehouse branding. It remains an anchored visual delivery prop, not a drivable physics vehicle. All truck parts are noncolliding/non-touching/non-queryable so the scripted motion doesn't shove players or block the dock. Vehicle handling and realistic suspension are separate future work.

A small HUD line shows queued countdown, arrival, unloading, departure, packages ready, reveal-choice waiting or saving pause. On touch devices the menu dock is moved slightly down to accommodate the extra line while staying away from movement controls. Status is owner-specific; truck motion is performed on the server so visitors can observe each other's deliveries.

## Studio checks

1. Press Play. Watch the three-second queue/countdown, five-second approach, unloading, departure and disappearance. Check that the truck's new details follow its body, signage does not float when it is hidden, and there are no Output errors.
2. Open/keep/sell all three packages or sell them sealed. Finish any outstanding reveal choice. A new truck should run the complete cycle and create exactly three replacements. Repeat at least three batches; no parked duplicate trucks or extra packages should accumulate.
3. Leave one unopened package: the controller should wait and not fill over capacity. Clear it but leave a reveal choice pending: it should wait for KEEP/SELL before the next batch.
4. Stand near the dock while the truck moves, and walk through the open garage. The truck should not push/trap you. Watch from both sides for bumper/model clipping; the TruckStop marker still controls docking and orientation.
5. Use two Studio clients. Each plot should have independent delivery status and packages; visitors should see the other truck move, and ownership restrictions must remain intact. Leave during arrival/unloading and check that a deleted plot does not continue creating packages or errors.
6. Check the HUD on a portrait/landscape phone and desktop. Confirm the status remains readable and mobile navigation doesn't overlap cash or movement controls.
7. Recheck earning/selling, saved inventory/index/scanner restoration, and the working shutter. This update did not change those sources or the save configuration.

## Verification and limits

Tests execute the actual delivery-cycle function with deterministic lifecycle doubles: ordered queue/arrival/unload/departure, repeated three-package batches, save-paused cancellation, and plot deletion during queue/arrival/unloading/departure. Source comparison confirmed unchanged package-opening and monetary/profile handlers. Both changed scripts compile with Luau and build through Rojo. Runtime source backups are byte-identical to the previous versions.

No visual, motion, physics or multiplayer checks were executed in Roblox Studio by the assistant. The Studio checks above are required to validate this release. Run the outside-Roblox lifecycle test with `python tests/delivery_cycle.py /path/to/luau`.

To roll back this update, Stop Play and restore just the two source files from backups/pre-delivery-polish into their original local src locations; Rojo will sync them. Keep your current save configuration and Studio place.
