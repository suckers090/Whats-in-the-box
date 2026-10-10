# Industrial yard and exterior finishes

The optional [Studio bake tool](EDITOR_BAKE.md) now saves this scenery for editing
before Play. The runtime-only behavior below still applies when you have not baked.

This stage addresses the blank grid baseplate and pale imported structural parts.
The reference export was inspected first: the roof, canopy, trims, frames, doors,
columns and dock are neutral MeshParts without TextureIDs. Stone walls and custom
floor surfaces are preserved. The original place is not replaced or rebuilt.

## What changes during Play

- WarehouseExterior recolors only named exterior pieces: charcoal metal roof,
  canopy/roof trim and company-sign backing; steel-blue frames/columns/slats;
  darker door panels; concrete dock and dark bumpers. CFrames, sizes, collision,
  transparency, mesh IDs and texture IDs are unchanged. Imported wall/floor
  materials/colors are untouched by this script.
- The named Baseplate gets muted grass and its grid Texture is hidden. The unused
  root SpawnLocation graphic is hidden; its collision and the owner spawns remain.
  These changes are runtime-only and revert when Studio stops Play.
- Workspace/IndustrialParkRuntime contains shared road rows, asphalt grounds for
  four lots per row, outlined lots with numbered logistics signs, pedestrian links,
  low rear verge/shrubs and four streetlights per row. Grounds and road surfaces
  are collidable to support visitors in empty lots. Other dressing is noncolliding,
  non-touching, non-queryable and casts no shadows. Ground heights match the
  TruckStop bottom face, with a small finish offset to avoid surface flicker.
- Each active plot gets WarehousePrototype/ExteriorPolish: delivery-lane paint,
  parking stripes, a side walkway, one rear container and a utility cabinet.
  Per-plot dressing disappears when the plot is released; shared streets remain
  available for the rest of that server session.

YardLayout is a pure placement module matching PlotRegistry's four-column grid,
90-stud column spacing and 140-stud row spacing. An estate row contains 61 Parts
and four lights, shared by four plots; each active plot adds 23 Parts. No assets,
physics vehicles, terrain writes, per-frame yard loops or persistent fields are
added. Rows are created once as needed, including earlier rows when the script's
first snapshot observes a later plot. Existing truck movement remains its current
straight arrival/unload/departure. The street does not add route driving yet.

The layout targets the currently exported upright warehouse and marker arrangement.
Large changes to plot dimensions, floor position or TruckStop rotation require
rechecking the estate placement; street rows stay on world X/Z like PlotRegistry.

## Update: only three files

Stop Play and back up the working local folder/place. Download these files from
the updated repository into matching paths of your current Rojo folder:

1. Replace `default.project.json`.
2. Add `src/ServerScriptService/WarehouseExterior.server.luau`.
3. Add `src/ServerScriptService/YardLayout.luau`.

Restart Rojo because the mapping adds two nodes: Ctrl+C in its terminal, then
`tools\rojo.exe serve` from the existing folder. Reconnect Studio. ServerScriptService
should show WarehouseExterior and YardLayout before pressing Play.

Keep your current Studio place, PersistenceConfig and other local scripts/settings.
GitHub updates do not sync to your Windows folder automatically. Backups of the
prior mapping are in backups/pre-industrial-yard.

## Short Studio checklist

1. Press Play and walk outside: the gray grid/star should be gone, with asphalt,
   a service road, four outlined lots/signs, lights and greenery in its place.
2. Check roof, canopy, columns, door frames, door panels and dock have the new
   finishes. Verify custom walls and imported shapes still look right. Check the
   earlier corrected receiving text and interior floor finish are unchanged.
3. Watch a complete truck trip and replenishment. Walk into the warehouse through
   both doors and reach your scanner/packages. New props must not overlap the
   truck, door openings or package drop.
4. Run two clients: both warehouses share a street, keep distinct bays/ownership,
   and visitors can walk between plots. If possible, test five clients to inspect
   the second road row. Leave/rejoin: no duplicate props or extra streets/lights.
5. Recheck scanner clues, opening, selling, Index claims and a SAVED rejoin. Test
   mobile/low graphics and Output for errors. The assistant hasn't run Roblox
   rendering, multiplayer or device performance checks.

## Presentation switches

You do not need to replace VisualConfig. Optional fields can be added to its
existing table: `YardEnabled = false` disables estate/plot dressing;
`ExteriorColorsEnabled = false` keeps imported exterior colors/materials;
`BaseplateFinishEnabled = false` retains the original baseplate/spawn visuals.
The existing `WorldEnabled = false` disables the entire exterior script.
Change switches before Play; they default on when omitted. Disabling the
WarehouseExterior Script also restores the original exterior after restarting Play.

The existing SurfaceFinishEnabled option still controls the previous interior
finish separately. You can restore your custom interior texture without losing
the exterior yard. No saved progress needs resetting or migrating.

## Verification

yard_layout.luau checks actual placement descriptors: slot addressing, truck and
employee entrance clearance, warehouse bounds, next-row road clearance, budget
and collidable ground only. exterior_scene.py executes WarehouseExterior using
doubles and actual exported meshes: shared row idempotence, arbitrary startup
snapshot order, palettes, preserved mesh/texture/physics properties and toggles.
Luau compilation, Rojo build and existing regressions complement these checks.
They do not prove the rendered art or multiplayer/device behavior works in Studio.
