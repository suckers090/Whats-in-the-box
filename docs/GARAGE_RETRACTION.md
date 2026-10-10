# Garage shutter roof-protrusion fix

## Inspection and cause

The existing exported Blender model has one solid GarageDoor_Panel MeshPart and 14 decorative GarageDoor_Slat01 children. It is not built as independently articulated shutter segments. DoorFrame_Top, the frame sides, FrontWall_Top and LoadingBay_Canopy are siblings, so they should remain stationary. The previous animation lifted the complete panel by its height plus 0.5 studs, putting visible geometry through the roof.

The fix uses a temporary roll-up effect suited to those meshes: the slats advance upward and progressively hide as they reach the fixed header. The solid panel's visible height contracts upward beneath that header. Fully retracted pieces are transparent, remain inside the original opening, and cannot collide, touch or participate in queries. Closing restores their exact original sizes, transforms and transparency. This is a simulated retraction, not a fully articulated coil or overhead track.

The employee door's hinge, motion, timings and controls are unchanged. Only WarehouseDoors.server.luau changed among runtime source files. No Rojo mapping changes or model replacements are needed. The previous source is preserved in backups/pre-garage-retraction/WarehouseDoors.server.luau.

## Update just the local door script

1. Stop Play in Studio and save your current working place as a separate backup. Keep your current Rojo server running.
2. Back up your local src/ServerScriptService/WarehouseDoors.server.luau outside src, so Rojo does not create an extra Script for the backup.
3. Open the updated file on GitHub: https://github.com/suckers090/Whats-in-the-box/blob/main/src/ServerScriptService/WarehouseDoors.server.luau
4. Use Download raw file. Replace only WarehouseDoors.server.luau in your local project's src/ServerScriptService folder. Check that the downloaded filename ends in .server.luau, not .luau.txt. Preserve any local customizations before replacement.
5. Rojo should sync the changed source automatically. Confirm the Studio WarehouseDoors script contains shutterSlice and retractGarage. No new ZIP folder, plugin reinstall or server restart is required for this source-only change.
6. Press Play to create fresh runtime doors. Do not test this by replacing source while a Play session is running.

## Studio checks required

- From outside, open the garage with E and watch the entire animation. No panel or slat should rise above the fixed header or through the roof. Watch from inside too.
- Check that the frame, canopy and front wall stay stationary and the ground-level control stays reachable.
- Walk fully through the open doorway both ways. Inspect GarageDoor_Panel and its slats under your runtime Workspace/WarehousePlots clone: CanCollide, CanTouch and CanQuery should all be false while open. The closed panel becomes solid again; decorative slats remain noncolliding.
- Open/close several times and verify the closed shape and textures restore without drifting. Rapid E presses should not start competing animations.
- Stand in the doorway and attempt to close. The door should refuse or reopen if someone enters during closing. This check now uses the captured original opening size rather than the animated panel's changing height.
- Use Server & Clients with two clients. One player opens/closes the door while the other observes and walks through it. Both should see the same shutter state. Visitors can still use doors; ownership restrictions on packages/upgrades are unchanged.
- Check the employee door, cash HUD, index, inventory, delivery and selling still work. Send Output errors and screenshots if anything differs.

## Verified outside Roblox

The actual shutterSlice function passed tests using all 15 meshes' exported bounds across 201 opening and 201 closing samples: visible geometry stays below the header, every mesh disappears at full retraction, and the closed geometry is restored. The actual collision function passed property-double tests for open/closed garage settings. Luau compilation and Rojo build passed. Previous source preservation and the unchanged HUD/package sources and mapping were checked.

Motion and visual properties are updated on the server, retaining the existing multiplayer replication path, server distance checks, animation lock and obstruction handling. No Roblox Studio execution or actual multiplayer replication test was performed by the assistant. Mesh appearance, passage through the opening and two-client motion require the Studio checks above.

To run the geometry/collision regression check outside Roblox: python tests/garage_shutter.py /path/to/luau.
