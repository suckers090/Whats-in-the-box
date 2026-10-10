# What's in the Box?

Existing Roblox warehouse mystery-package game.

The [bubble HUD refinement](docs/BUBBLE_HUD.md) adds rounder faces, subtle depth,
compact cash spacing and a collapsible navigation arrow to the existing icon HUD.

The [industrial icon HUD](docs/ICON_HUD.md) replaces the bottom navigation with a
responsive left-side icon stack and polished cash card. Existing menus, inventory
safeguards and Home travel remain connected; server gameplay and saves are unchanged.

The [inventory control milestone](docs/INVENTORY_CONTROL.md) adds saved locks and
favorites, sorting/filtering, confirmed duplicate sales and receipt-aware package
choices. See the refreshed [mechanics audit and roadmap](docs/GAMEPLAY_ROADMAP.md).

The [logistics facility polish](docs/FACILITY_POLISH.md) adds parked vans, freight
staging, waste/utilities, sidewalks, fencing and distant depots with neutral daylight.
Use the additive Polish facility toolbar action to retain your existing baked edits.

The [Studio bake tool](docs/EDITOR_BAKE.md) makes the existing industrial scenery
editable before Play, with backups, Clear and Studio Undo. Runtime plots reuse the
baked warehouse dressing and shared yard; player data and gameplay stay intact.

The [industrial yard update](docs/INDUSTRIAL_YARD.md) adds shared streets, lot
markings, landscaping and matching exterior finishes. It needs only two new
server files plus the updated Rojo mapping; existing save settings stay intact.

The [staged industrial visual polish](docs/VISUAL_POLISH.md) adds disposable world
dressing, lighting, shared UI finishing and action/audio hooks. Its update list
preserves local save settings and the imported warehouse.

See the [current gameplay audit and roadmap](docs/GAMEPLAY_ROADMAP.md). The next
stage adds [one-time collection milestones](docs/COLLECTION_MILESTONES.md) to the
existing Index, preserving v1 saves and the working warehouse gameplay.

The current test release adds persistent profiles to the shared-map warehouse plots and industrial HUD. Follow [persistence setup and testing](docs/PERSISTENCE_TESTING.md) when updating your local project. Ordinary Studio sessions default to preview mode with saving off; real Roblox saves require validation in a private test experience. Studio models and markers stay in the saved place; the gameplay/UI scripts live in src.

Start with [Windows Rojo setup](docs/ROJO_SETUP.md) to connect this folder to a separate copy of the working Studio place. [Marker integration testing](docs/MARKER_TEST.md) explains the current gameplay checks and placement markers.

- default.project.json: Rojo 7.5.1 mapping for existing scripts, preserving other Studio objects.
- src/: current server and client scripts.
- build/Whats-in-the-box-marker-test.rbxlx: prepared test baseline, reported working by the user in Studio. Save any later Studio changes separately.
- backups/: original uploaded places and scripts before integration.
- docs/: import history, testing, and setup guides.

Interactive employee and garage doors are available for Studio testing: see [door testing](docs/DOOR_TESTING.md). Persistent cash/inventory/discoveries/scanner profiles are implemented for testing. Preview mode intentionally resets each server session. Actual Roblox DataStore integration has not been verified by the assistant. Rojo tracks script files, not the Blender warehouse assets.

The current delivery polish update adds repeating truck trips and an owner-specific dock status line. See [delivery update and Studio checks](docs/DELIVERY_POLISH.md). Update just its two source files to preserve your local Studio save configuration.
