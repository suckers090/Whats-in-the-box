# What's in the Box?

Existing Roblox warehouse mystery-package game.

The current test release adds persistent profiles to the shared-map warehouse plots and industrial HUD. Follow [persistence setup and testing](docs/PERSISTENCE_TESTING.md) when updating your local project. Ordinary Studio sessions default to preview mode with saving off; real Roblox saves require validation in a private test experience. Studio models and markers stay in the saved place; the gameplay/UI scripts live in src.

Start with [Windows Rojo setup](docs/ROJO_SETUP.md) to connect this folder to a separate copy of the working Studio place. [Marker integration testing](docs/MARKER_TEST.md) explains the current gameplay checks and placement markers.

- default.project.json: Rojo 7.5.1 mapping for existing scripts, preserving other Studio objects.
- src/: current server and client scripts.
- build/Whats-in-the-box-marker-test.rbxlx: prepared test baseline, reported working by the user in Studio. Save any later Studio changes separately.
- backups/: original uploaded places and scripts before integration.
- docs/: import history, testing, and setup guides.

Interactive employee and garage doors are available for Studio testing: see [door testing](docs/DOOR_TESTING.md). Persistent cash/inventory/discoveries/scanner profiles are implemented for testing. Preview mode intentionally resets each server session. Actual Roblox DataStore integration has not been verified by the assistant. Rojo tracks script files, not the Blender warehouse assets.

The current delivery polish update adds repeating truck trips and an owner-specific dock status line. See [delivery update and Studio checks](docs/DELIVERY_POLISH.md). Update just its two source files to preserve your local Studio save configuration.
