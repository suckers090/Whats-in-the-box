# Existing Studio project import

This is an import of the existing game, not a replacement game. No gameplay code has been changed. No Rojo project or sync is configured yet.

## Files preserved

`backups/Whats-in-the-box-v1.rbxlx` is a byte-for-byte copy of the supplied place. Keep your separate local Studio backup too. The place may reference Roblox-hosted meshes/textures; this XML does not archive those asset binaries or grant asset permissions.

The four scripts in `src/` preserve their Studio hierarchy and exact decoded source text. `.server.luau` represents a Script; `.client.luau` represents a LocalScript. `docs/import-manifest.json` records paths, original enabled state, RunContext, and SHA-256 hashes.

| Studio location | File | Original state |
| --- | --- | --- |
| ServerScriptService/WarehousePrototype | src/ServerScriptService/WarehousePrototype.server.luau | Disabled |
| ServerScriptService/ScannerUpgrade | src/ServerScriptService/ScannerUpgrade.server.luau | Enabled |
| StarterPlayer/StarterPlayerScripts/BoxClient | src/StarterPlayer/StarterPlayerScripts/BoxClient.client.luau | Enabled |
| StarterPlayer/StarterPlayerScripts/WarehouseNotifications | src/StarterPlayer/StarterPlayerScripts/WarehouseNotifications.client.luau | Enabled |

## What the scripts do

- WarehousePrototype creates BoxEvent, session cash and collections, weighted item rolls, opening and keep/sell handling, a generated warehouse, truck, package prompts, initial animated delivery, and subsequent package restocking. Only the initial delivery moves the truck.
- ScannerUpgrade creates WarehouseNotice and waits for WarehousePrototype/Packages. It adds $120 sealed selling, a $2,000 scanner purchase, scan clues, and a generated scanner. The scanner unlock is shared by the server session.
- BoxClient waits for BoxEvent and builds the reveal UI and rotating item previews, with Keep/Sell decisions sent to the server.
- WarehouseNotifications waits for WarehouseNotice and builds timed notification UI.

Cash and kept items exist only in memory. There is no DataStore implementation or persistent inventory/index in these scripts. Packages are shared, and no per-player warehouse ownership is implemented here. These are observations, not changes.

## Imported warehouse and doors

Workspace/WITB_StarterWarehousetest contains 53 MeshParts, including EmployeeDoor_panel (with Employee_DoorHandle) and GarageDoor_Panel (with slats). No door scripts, door prompts, or hinge constraints were found in this export. The existing prototype code builds a separate WarehousePrototype folder rather than driving this imported model.

## Important startup detail

WarehousePrototype is disabled in the supplied XML. Workspace does not contain its generated WarehousePrototype folder, and ReplicatedStorage does not contain BoxEvent. ScannerUpgrade waits for that folder, and BoxClient waits for that event. The imported baseline therefore has a startup dependency gap visible in the saved data. Do not silently enable the script or assume this export is the latest working version.

A future Rojo mapping must preserve the disabled state and existing Studio objects. A source-only sync would otherwise risk enabling the prototype. Agree on the intended baseline before syncing.

## Safe Studio verification

1. In Studio, use File > Open from File to open a separate copy of the exported place. Use Save to File to give the testing copy a distinct name. Do not publish it over the live game.
2. Enable Explorer, Properties, and Output. Verify the four script locations and WarehousePrototype's Disabled/Enabled setting against the table above.
3. Press Play on the unmodified copy. Record Output warnings/errors and which systems appear; the dependency gap above is expected from static inspection, not a Studio-tested result. Press Stop.
4. If this prototype is the intended gameplay baseline, enable WarehousePrototype only in this disposable testing copy and press Play again. It creates a separate generated warehouse, which may overlap the imported model. This is a diagnostic step, not a recommended change to the live game.
5. In that diagnostic copy, wait roughly ten seconds for the truck/packages. Open a package with E; verify the item preview and Keep/Sell closing behavior. Selling should increase Cash by the shown item value. Sell an unopened package with F and check the $120 increase and notification. Empty the package area and wait for restocking.
6. Earn $2,000, purchase the scanner, verify the cash deduction, and use R on an unopened package to check the value-clue notification. Do not change balances or code in the baseline just to speed up this check.
7. Stop and restart to observe the current session-only data reset. Door interaction is not implemented in this export.

No Roblox Studio execution has been performed by the assistant. Extraction hashes establish source preservation, not gameplay correctness. No manual script copying or further exports are needed for these four scripts; if this is an older snapshot, export the latest working place before we change the baseline.
