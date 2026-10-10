# Test the warehouse doors

This update adds WarehouseDoors.server.luau and maps it in default.project.json. Existing delivery, reward, scanner and client scripts are unchanged. The pre-door Rojo configuration is preserved in backups/pre-door-integration/default.project.json. Your Studio place and imported model are not replaced or republished.

## Get the update on Windows

1. Stop Play and save a new copy of your latest working place, for example Whats-in-the-box-before-doors.rbxlx.
2. Stop your local Rojo server with Ctrl+C.
3. Download a fresh GitHub project ZIP and extract it into a separate folder. Keep the old local folder if it has edits. Use your latest saved Studio place, not an older test-place file from the ZIP.
4. If you installed rojo.exe in the old tools folder, copy it into a tools folder in the new project folder. Open PowerShell in the new folder and run `.\tools\rojo.exe serve default.project.json --address 127.0.0.1 --port 34872`.
5. Reconnect Studio's Rojo plugin. Confirm ServerScriptService contains exactly one WarehouseDoors script in addition to your existing scripts, and your warehouse and markers remain present. The existing four script sources in this update have not changed. If you edited them locally since the last download, preserve those edits before syncing a fresh ZIP.

The script expects Workspace/WITB_StarterWarehousetest with direct children EmployeeDoor_panel and GarageDoor_Panel. Keep their existing names. It moves the employee handle and garage slats explicitly: parenting one MeshPart under another does not make them follow automatically.

## Studio checks

- Press Play. Walk to the employee door and press E (gamepad X; touch uses the prompt). The right edge as seen from outside, nearest the garage, should stay in place as the door swings outward about 90 degrees. Check that the handle follows and the frame stays still. Close it from a position clear of the opening.
- Walk to the garage's control near its edge closest to the employee door and press E. The panel should retract beneath the header over two seconds, with slats disappearing as they reach the top. The prompt remains near the ground so you can close it after it opens.
- Rapidly press E during either animation. Only one motion should run at a time; the prompt is disabled while moving.
- Stand in the open doorway and try closing. It should stay open with a notification. If someone enters during closing, the door should reopen before becoming solid.
- Closed panels now block walking through; their source snapshot had CanCollide=false. During motion and while open they are noncolliding. Handles/slats remain noncolliding decorations. These changes happen only in Play, not in your saved Studio model.
- Stop and Play again. The doors should start closed and controls should appear once. Repeat delivery, package opening, selling and scanner checks to catch regressions.
- Use Studio's Server & Clients test with two clients when convenient. Both should see the same motion; simultaneous triggers should not create competing tweens. Doors currently serve the existing shared warehouse, not per-player ownership.

## Current garage movement

The roof-protrusion fix now simulates roll-up retraction beneath a fixed header instead of lifting a full slab through the roof. The solid mesh contracts and slats progressively hide; it is not an articulated coil. See docs/GARAGE_RETRACTION.md for the source-only update and current validation steps.

## Adjustments

At the top of WarehouseDoors.server.luau, EMPLOYEE_OPEN_ANGLE, EMPLOYEE_DURATION and GARAGE_DURATION control angle and speed. The hinge is at the panel's local -X edge and outward motion is toward local -Z for the imported model. If the model was individually rotated or remodeled after export, send the updated place or a screenshot before changing hinge signs. Moving/rotating the complete warehouse as a unit retains the relative motion.

## Verification and limits

The new script passed Luau compilation and Rojo 7.5.1 build. Checks on the exported geometry confirm the hinge edge is closest to the garage, the open employee panel moves toward the exterior, the garage lift clears its original opening, and the Rojo build retains the four original script sources. These are syntax, geometry and file-preservation checks; the assistant has not executed door behavior in Roblox Studio.

To roll back locally: disconnect Rojo, restore the pre-door project configuration, restart the server, and delete only WarehouseDoors from ServerScriptService while Play is stopped. Unknown-instance preservation means removing the mapping alone may leave that script in Studio. Runtime controls vanish when Play stops. Or open your saved pre-door Studio copy without connecting the door-enabled project.
