# What's in the Box?

Existing Roblox warehouse mystery-package game. Studio models and markers stay in the saved place; the gameplay/UI scripts live in src.

Start with [Windows Rojo setup](docs/ROJO_SETUP.md) to connect this folder to a separate copy of the working Studio place. [Marker integration testing](docs/MARKER_TEST.md) explains the current gameplay checks and placement markers.

- default.project.json: Rojo 7.5.1 mapping for existing scripts, preserving other Studio objects.
- src/: current server and client scripts.
- build/Whats-in-the-box-marker-test.rbxlx: prepared test baseline, reported working by the user in Studio. Save any later Studio changes separately.
- backups/: original uploaded places and scripts before integration.
- docs/: import history, testing, and setup guides.

Interactive employee and garage doors are available for Studio testing: see [door testing](docs/DOOR_TESTING.md). Persistent data and inventory UI are future work. Current cash/collections/scanner state reset between server sessions. Rojo tracks script files, not the Blender warehouse assets.
