# What's in the Box?

Existing Roblox warehouse mystery-package game.

The current test release adds shared-map player plots and a dark industrial HUD with session inventory and a collection index. Follow [plots/UI testing](docs/PLOTS_UI_TESTING.md) when updating your local project. This release needs Studio validation. Studio models and markers stay in the saved place; the gameplay/UI scripts live in src.

Start with [Windows Rojo setup](docs/ROJO_SETUP.md) to connect this folder to a separate copy of the working Studio place. [Marker integration testing](docs/MARKER_TEST.md) explains the current gameplay checks and placement markers.

- default.project.json: Rojo 7.5.1 mapping for existing scripts, preserving other Studio objects.
- src/: current server and client scripts.
- build/Whats-in-the-box-marker-test.rbxlx: prepared test baseline, reported working by the user in Studio. Save any later Studio changes separately.
- backups/: original uploaded places and scripts before integration.
- docs/: import history, testing, and setup guides.

Interactive employee and garage doors are available for Studio testing: see [door testing](docs/DOOR_TESTING.md). Persistent data is future work. Current cash/inventory/discoveries/scanner state reset between server sessions. Rojo tracks script files, not the Blender warehouse assets.
