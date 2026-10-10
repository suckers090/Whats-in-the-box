# Connect the existing game to Rojo on Windows

Rojo copies script source from a folder on your computer into Roblox Studio. The cloud workspace cannot connect directly to Studio on your PC. Your local copy of this GitHub repository is the bridge.

Use Rojo 7.5.1 for both the command-line program and Studio plugin. Gameplay code has not changed in this setup. The existing gameplay test copy was reported working in Studio by the user; the assistant verified Rojo build/server behavior outside Studio only.

## 1. Get the project folder

Open https://github.com/suckers090/Whats-in-the-box and choose Code > Download ZIP. Right-click the ZIP in Windows and choose Extract All. Open the extracted Whats-in-the-box-main folder. You should see default.project.json, src, build, docs and backups. Do not work directly inside the ZIP. Use a fresh folder if you already have local changes you want to keep.

Save your Studio-tested working place under a new local filename, such as Whats-in-the-box-rojo-test.rbxlx. Open that separate copy in Studio. If you have no additional Studio changes, build/Whats-in-the-box-marker-test.rbxlx is the baseline to open. Do not open a Rojo scripts-only build as your whole game; it does not include your Blender warehouse.

## 2. Install the matching Rojo program and plugin

Download the Windows 64-bit ZIP from the official release:
https://github.com/rojo-rbx/rojo/releases/download/v7.5.1/rojo-7.5.1-windows-x86_64.zip

Extract that ZIP too. In your project folder create a folder named tools and copy rojo.exe into it. Your layout should contain default.project.json and tools/rojo.exe. This local executable is ignored by Git.

In File Explorer, open the project folder, type powershell in the address bar and press Enter. This opens a terminal in that folder. Run:

```powershell
.\tools\rojo.exe --version
.\tools\rojo.exe plugin install
```

The first command should say Rojo 7.5.1. The second installs the matching official plugin; it replaces an existing Rojo plugin installation. Restart Studio so the plugin appears under Plugins. If you already installed Rojo by another method, use one matching plugin rather than enabling duplicate Rojo plugins.

## 3. Start syncing

In that same PowerShell window run:

```powershell
.\tools\rojo.exe serve default.project.json --address 127.0.0.1 --port 34872
```

Leave the window open. In Studio, make sure Play is stopped and the separate test copy is open. Go to Plugins > Rojo and Connect to localhost on port 34872 (or 127.0.0.1 if asked for a host). If Studio requests permission for the plugin's local HTTP connection, allow it. Review the initial sync if the plugin shows a change list before accepting it.

The project intentionally maps only:

- ServerScriptService/WarehousePrototype
- ServerScriptService/ScannerUpgrade
- StarterPlayer/StarterPlayerScripts/BoxClient
- StarterPlayer/StarterPlayerScripts/WarehouseNotifications

All four are enabled with Legacy RunContext, matching the prepared gameplay test. Workspace, the Blender model, WarehouseMarkers, spawn, and other services are not mapped. Every mapped container and script preserves unknown children through $ignoreUnknownInstances. Do not accept unexpected deletions or a plan to replace the warehouse. Stop and send a screenshot if the proposed changes exceed these four scripts and their existing containers.

## 4. Test the first connection

With Play stopped, check that your model and WarehouseMarkers remain present and that each of the four scripts appears only once in its expected location.

To verify live updates, open src/StarterPlayer/StarterPlayerScripts/WarehouseNotifications.client.luau in a text editor or VS Code. Add a harmless comment at the end, such as `-- Rojo connection check`, and save. Look for the comment in the same script in Studio without manually pasting it. Remove the comment in the local file and save again; verify it disappears in Studio. This is only a sync check.

Then press Play and repeat the delivery, reveal, keep/sell, sealed-sale and scanner checks from docs/MARKER_TEST.md. Confirm Output has no new errors. Stop and save the test copy once everything works. Nothing in these steps publishes your game.

## Daily workflow

Treat src files as the source of truth for these four mapped scripts. Edit them in your local project and run Rojo while working. Editing a mapped script only in Studio can be overwritten by later sync. Continue modeling and moving markers in Studio; save the place separately because Rojo does not track those objects.

Use Ctrl+C in PowerShell to stop Rojo. Start the same serve command next time. You can install VS Code and its Luau tooling later; they are optional for this first connection.

Changes made by Codex reach your local files through GitHub, not automatically through the chat. For now, download a fresh repository ZIP into a separate folder when needed, preserve any local script edits, and use the latest local project for the Rojo server. A Git checkout can replace this ZIP workflow later. Do not replace a newer saved Studio place with an older repository test snapshot.

## Troubleshooting

- rojo.exe not found: make sure it is extracted into tools and your terminal is in the folder containing default.project.json.
- Rojo plugin missing: restart Studio after plugin install; check for duplicate or disabled plugins.
- Cannot connect: keep the local serve terminal running, check port 34872, and use localhost. A server running in the cloud workspace is not the server on your Windows PC.
- Missing scripts or duplicates: disconnect and inspect the exact paths and names in Explorer before trying again.
- Missing WarehouseMarkers: open your existing working place or marker-test place, not a blank Rojo build.
- A stale script remains after a later rename/deletion: unknown instances are preserved intentionally. Inspect and remove obsolete scripts only after backing up and confirming the rename; do not disable preservation globally.

## Checks performed by the assistant

Rojo 7.5.1 successfully built the project and generated a sourcemap. The build contains exactly the four intended scripts with byte-equivalent decoded source, Disabled=false and Legacy RunContext. The serve API returned the expected hierarchy and ignoreUnknownInstances=true at every mapped node. The temporary cloud server was stopped after validation. No first-sync or gameplay test in Studio was performed by the assistant.
