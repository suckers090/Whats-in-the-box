# Editable industrial scenery in Studio

For the next environment stage, use [Polish facility](FACILITY_POLISH.md), which
adds logistics details and neutral daylight without clearing your existing bake.

This update turns the existing runtime art into an optional, saved Studio scene.
It adds no new gameplay or save fields. The Blender warehouse, markers, HUD,
package logic and persistence modules are preserved. The original visual scripts
and mapping are backed up in `backups/pre-editor-bake`.

## Install the small update

GitHub/cloud changes do not automatically update your Windows folder or Studio.

1. Stop Play. Save a separate backup of your working place and local Rojo folder.
2. Download and extract `build/WITB-Editor-Bake-Update.zip`. Copy its contents into
   your **existing Rojo project folder**, keeping the same paths. This zip contains
   only the files for this update. It does not contain PersistenceConfig or a place
   file, so your local save settings and warehouse stay intact.
3. Restart Rojo because the mapping changed: Ctrl+C in its terminal, then run
   `tools\rojo.exe serve` from that same project folder. Reconnect in Studio.
4. Install the local plugin: close Studio, press Win+R, enter
   `%LOCALAPPDATA%\Roblox\Plugins`, and copy
   `build\WITB-Visual-Tools.rbxmx` from your project into that folder. Create the
   Plugins folder if it is missing. Reopen your existing place and reconnect Rojo.
5. Open the **Plugins** tab. Look for **WITB Art → Bake visuals / Clear bake**.
   Stop Play, click **Bake visuals** once, inspect the scene, then save the place.
   Output reports success or explains a missing model/marker.

If Studio uses a custom local plugin folder, use its **Plugins Folder** command
to open that folder and copy the same rbxmx there. Install only one copy.
`ServerStorage.WITBVisualTools` is an inert source copy synced by Rojo, not the
installed toolbar. Installing the rbxmx enables the toolbar; the updated runtime
files are also required to reuse the baked scene during Play.

For a manual update, these eight files are the complete source list:

| Path | Change |
| --- | --- |
| `default.project.json` | New builders and inert plugin source mapping |
| `src/ServerScriptService/PlotRegistry.luau` | Move cloned baked dressing into the normal plot runtime |
| `src/ServerScriptService/WarehouseVisuals.server.luau` | Thin runtime adapter; respect baked lighting |
| `src/ServerScriptService/WarehouseExterior.server.luau` | Thin runtime adapter; reuse baked yard |
| `src/ServerScriptService/WarehouseVisualBuilder.luau` | Shared interior/lighting builder |
| `src/ServerScriptService/WarehouseExteriorBuilder.luau` | Shared exterior/yard builder |
| `studio-tools/VisualBake.luau` | Bake, backup, restore and history recording |
| `studio-tools/VisualTools.plugin.luau` | Editor toolbar |

The existing YardLayout, UITheme and VisualConfig are reused. The standalone plugin
package can be rebuilt with `rojo build visual-tools.project.json -o build/WITB-Visual-Tools.rbxmx`.

## What becomes permanent and editable

- `Workspace.WITB_StarterWarehousetest.WITB_BakedDecor.VisualPolish`: removable floor
  and wall finishes, shelves/crates, lights, receiving lettering, signs and lamps.
- `…WITB_BakedDecor.ExteriorPolish`: delivery/parking paint, walkway, container and
  utility cabinet. Named imported exterior meshes also receive the existing palette.
- `Workspace.IndustrialParkRuntime.EstateRow_0`: the shared road, first four lot
  grounds, signs, landscaping and streetlights. Baseplate/spawn finishes are saved.
- Lighting receives the existing industrial preset. Existing artist-authored effects
  are retained; edited baked lighting is respected during Play.
- `ServerStorage.WITB_VisualBakeBackup`: references and original colors, materials,
  lighting and baseplate/spawn transparency needed by Clear. Keep this folder.

Edit scenery in the **stopped** place and save it. Per-warehouse dressing must stay
inside WITB_BakedDecor so every player plot clones it. Shared roads stay in Workspace.
Keep the folder names/version attributes intact. Leave the original warehouse and
placement markers in place; relocating them after baking requires checking alignment.

Player warehouse copies still spawn during Play. Each clone adopts its saved
dressing, updates its bay number and binds its door lamps. Shared roads are reused;
extra road rows are added during Play only when player plots need them. Trucks,
packages, scanners, interactive doors, player inventories and HUD remain runtime.
The template moves to ServerStorage during Play as before and returns when Play stops.

Without a bake, the existing automatic runtime art continues to work. VisualConfig
switches control generation; after baking, edit/remove saved art directly or Clear
and regenerate to apply different switches. Do not copy decorations out of a Play
session on top of a bake.

## Clear, Undo and backups

Bake and Clear each record one Studio history action. Use Ctrl+Z immediately after
either action to undo it. Bake refuses to replace an existing bake, and the tools
refuse to run while Play is active. A failed bake restores its captured originals.

**Clear bake removes generated scenery, including edits you made inside it, and
restores the pre-bake colors/materials and lighting.** Save a separate place copy
before clearing a scene you have customized. Undo Clear should bring that scene
back. Repeated Bake leaves your existing edits intact. No owned backup means Clear
removes nothing; unmanaged folders with the same names are left alone.

## Short Studio checklist

1. With Play stopped, Bake: see roads, warehouse details and lighting immediately.
   Change a shelf/road color. Save, close and reopen: scenery and edits remain.
2. Play: edited colors remain, no duplicate shelves/roads appear, and the HUD,
   deliveries, package opening/selling, scanner and Index still work. Walk through
   both doors; their lamps should respond. Stop Play: the editable template returns.
3. On a backup copy, test Ctrl+Z after Bake, then Bake again. Test Clear followed by
   Ctrl+Z: original finishes restore on Clear and edited scenery returns on Undo.
4. Run two clients: matching dressed warehouses, distinct bay numbers, one shared
   road, and working door lamps. Visit the other plot; ownership rules must remain.
   Check Output and a saved rejoin; do not reset player data for this update.

## Verified outside Studio

`tests/editor_bake.py` runs the real bake/clear builders and runtime adapters with
Roblox doubles: Play/busy guards, duplicate refusal, backup restoration including
Material enums, failure rollback, preservation of existing Lighting effects,
cloned dressing reuse, retained artist edits, bay text and door-lamp rebinding.
Existing world/exterior, plot event, doors and gameplay regressions complement
Luau compilation and game/plugin Rojo builds. These checks do **not** execute
Roblox's plugin host, native Undo, rendering, multiplayer or DataStore service.
