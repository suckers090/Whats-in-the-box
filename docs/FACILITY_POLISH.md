# Logistics facility: additive environment stage

The current scene already has a shared service road, lot markings, walkways,
containers, cabinets, lighting and a saved warehouse dressing template. This pass
adds organized logistics activity around that layout. It leaves the Blender model,
plot spacing, original road geometry, UI, rewards and save schema intact.
The latest Studio edits are not accessible from the cloud; the stage therefore
adds separate folders rather than rebuilding your existing baked scenery.

## What to look for

- A parked fleet van inside the left parking bay of each occupied warehouse.
  Its cab faces the road. It is anchored scenery; the working delivery truck keeps
  its existing arrival/unload/departure behavior.
- A recycling dumpster on the outer left side, wrapped pallet freight behind the
  warehouse, and ventilation equipment beside the existing right-side utilities.
- A front sidewalk joining the existing employee-side walkway, with short curbs
  outside the delivery entrance and road. Central dock approaches remain open.
- Open perimeter fence runs with posts, rails and thin wire members. Rear gaps
  and the cross-row visitor walkway remain open. These are decorative boundaries.
- A loading-bay/visitor direction sign at the west entry, a container holding area
  outside the fence, and two distant industrial depots beyond the player columns.
  Each new estate row gets the same organized perimeter treatment.
- Neutral early-afternoon daylight: RGB 105/104/100 ambient, 125/126/122 outdoor
  ambient, Brightness 2.1, ClockTime 14.3, lower atmospheric density/haze, and a
  subtly warm generated color grade. Existing artist-authored effects remain intact.
  This reduces the preset's blue contribution; the final look needs Studio review.

The new layer adds **30 Parts per occupied plot and 112 shared Parts per road row**.
Related parts are grouped into reusable named Models. All additions are anchored,
noncolliding, non-touching, non-queryable and shadowless. There are no new lights,
assets, physics vehicles, constraints, scripts inside props, or per-frame loops.
Existing collidable estate ground and road still support players. Models remain
editable; decorative props are not gameplay obstacles.

## Update your current folder and plugin

1. Stop Play. Save a separate copy of your working place and Rojo folder.
2. Download and extract `build/WITB-Facility-Polish-Update.zip`. Copy its contents
   into the **existing Rojo folder**, preserving the paths. It contains only this
   stage's files; PersistenceConfig, player data modules, HUD and warehouse/place
   files are excluded. Keep your current local save settings.
3. Restart Rojo: Ctrl+C in its terminal, then `tools\rojo.exe serve` from the same
   project folder. Reconnect Studio after reopening it.
4. Close Studio. Press Win+R, enter `%LOCALAPPDATA%\Roblox\Plugins`, and replace
   the existing `WITB-Visual-Tools.rbxmx` with the new file from your project's
   `build` folder. Reopen your working place and reconnect Rojo. Use Studio's
   Plugins Folder command if you configured another plugin directory.
5. With Play stopped, click **Plugins → WITB Art → Polish facility** once, then save.
   Your existing baked scene is reused. **Do not Clear bake or rebake to install
   this stage**. If you have never baked, first use Bake visuals, then Polish facility.

The new buttons are **Polish facility** and **Clear facility**. The inert copy
under ServerStorage is source for the plugin; replacing that source through Rojo
does not replace your installed local plugin. GitHub changes do not automatically
update your Windows folder. No new Studio place or save-data reset is needed.

## Files and new Instances

| Path | Change |
| --- | --- |
| `src/ServerScriptService/FacilityLayout.luau` | New pure reusable logistics placement plan |
| `src/ServerScriptService/FacilityPolish.luau` | New idempotent editor/server layer builder |
| `src/ServerScriptService/WarehouseExteriorBuilder.luau` | Shared model grouping, finishes and shape support |
| `src/ServerScriptService/WarehouseExterior.server.luau` | Apply/reuse the new layer after existing yard setup |
| `src/ServerScriptService/WarehouseVisualBuilder.luau` | Neutral daylight; explicit refinement of owned effects |
| `studio-tools/VisualBake.luau` | Additive polish, separate backup/clear, rollback and Undo recordings |
| `studio-tools/VisualTools.plugin.luau` | Two new toolbar actions |
| `default.project.json` | Map the two new modules in runtime and plugin source |
| `visual-tools.project.json` | Include those modules in the standalone plugin build |

Saved template additions live in
`Workspace.WITB_StarterWarehousetest.WITB_BakedDecor.FacilityPolish`:
ParkedDeliveryVan, WasteStation, FreightStaging and UtilityPlant Models.
Shared additions live in each
`Workspace.IndustrialParkRuntime.EstateRow_n.FacilityPolish`:
PedestrianLinks, SecurityFence, Wayfinding, WestFreightDepot, EastWorkshop and
ContainerHolding Models.

`ServerStorage.WITB_FacilityBakeBackup` records the new folder references and the
lighting immediately before this stage, including settings of generated effects.
Keep it with `WITB_VisualBakeBackup`. Runtime player plots clone and reuse the
saved facility layer; missing future row layers generate once when needed.
Artist edits to existing and new scenery remain intact on repeat calls and Play.
Keep the top-level FacilityPolish folder names/version attributes intact; you can
freely move, recolor or rename the Models and Parts inside them.

## Undo and controls

Polish and Clear facility each record one Studio Undo action. Polish refuses to
replace an existing layer. A failed polish removes its partial additions and
restores its lighting snapshot. All toolbar actions refuse to run during Play.

**Clear facility deletes edits inside the new FacilityPolish folders** and restores
the lighting from before this stage. Your earlier baked shelves, roads, markings,
colors and decorations remain. Ctrl+Z after Clear should restore the added layer.
The original Clear bake action clears both stages and restores the original scene;
use it only when you intend that full reset. Save a separate place copy before
clearing a customized layer.

Optional `FacilityDetailsEnabled = false` in your existing VisualConfig prevents
generation of missing facility details during Play and disables editor polishing.
It does not remove saved art; use Clear facility to remove the saved layer.
`LightingEnabled = false` lets Polish add details without adjusting lighting.
Baked lighting stays authoritative during Play, including later manual adjustments.

## Short Studio checklist for this stage

1. Polish while stopped: inspect the van, recycling area, freight pallets, utility
   unit, sidewalks/curbs, fencing, direction sign and distant depots. Check sunlight
   and steel-blue surfaces are readable and no longer washed out. Adjust Lighting
   manually after polishing if your Sky or artist-authored grade still dominates.
2. Save/reopen the place: additions stay visible. Edit a van color; Play must retain
   it and your earlier road/interior edits, without duplicated props or lights.
3. Walk both entrances, the dock, scanner and package area, all sidewalks and the
   link between lots. Watch a complete delivery trip: no props intersect its route.
4. On a backup copy, Clear facility: earlier art remains and previous lighting
   returns. Ctrl+Z should restore the facility layer. Test Undo immediately after
   Polish as well. Keep the customized copy saved before testing either clear action.
5. Test two clients for shared scenery, distinct warehouses/bays and working doors,
   scanner, opening/selling, HUD, Index and saving. If feasible, five clients should
   create the second row without scenery entering that row's delivery road.
6. Check Output, mobile controls and low graphics. The assistant has not tested
   Roblox rendering, native Undo, multiplayer, DataStore or device performance.

## Cloud verification

`tests/facility_layout.luau` checks actual descriptors against warehouse bounds,
truck/employee approaches, side/cross-row walks, current/future roads and budgets.
`tests/exterior_scene.py` runs the actual server adapter with exported meshes and
checks shared layers, idempotence, disabled generation, imported assets/physics
preservation and grouping. `tests/editor_bake.py` exercises the actual editor
actions with Roblox doubles: retained old/new edits, lighting refinement and
restoration, separate clear, rollback after partial failure, runtime clone reuse,
owned effects and missing object references. Compilation, Rojo builds and existing
gameplay/save regressions complement these checks; they do not render the scene.

Pre-stage source backups are in `backups/pre-facility-polish`.
