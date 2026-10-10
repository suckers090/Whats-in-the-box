# Persistent player progress — test before live release

This update adds server-side profile saving for cash, inventory, discoveries, scanner unlocks and unfinished reveal rewards. The door animation, plot geometry, reward probabilities, item prices, reveal UI and ownership rules are preserved. Source and mapping backups are in backups/pre-persistence.

## Get the update

Stop Play, save a backup of your current working Studio place, and stop your local Rojo server. Download the latest repository ZIP into a separate folder and preserve any local script edits. Copy tools/rojo.exe into that folder, start the usual Rojo serve command there, and reconnect Studio to your latest saved place. Do not replace your saved place with an older repository test-place snapshot. Four new server modules appear: PersistenceConfig, ProfileSchema, ProfileTransactions and PlayerProfiles; existing gameplay/scanner integration and the HUD save-status labels update.

## Default Studio preview

PersistenceConfig.StudioPersistenceEnabled defaults to false. Ordinary Studio Play uses in-memory profiles with the footer STUDIO PREVIEW / SAVING OFF. This makes it possible to test the current game without touching stored progress or requiring Roblox API access. In this mode, progress intentionally resets when the server stops. Do not interpret preview tests as successful persistence tests.

Published Roblox servers use real saves automatically. That code path must be tested in a separate private test experience before adopting or publishing this update to a live game. The assistant has not published anything or executed Roblox DataStore requests.

## Test actual saving in Studio

1. Create/open a separate private test experience with your working warehouse place, and publish that test copy through Studio. Do not publish over a live game to enable testing.
2. In that test experience, open Game Settings > Security and enable Studio Access to API Services. Save the setting. Roblox's API-access setting is required; no API keys or secret values are needed in the scripts.
3. In your LOCAL src/ServerScriptService/PersistenceConfig.luau, change StudioPersistenceEnabled from false to true. Stop Play, allow Rojo to sync, and then start Play again. Do not edit only the synced Studio copy of the module.
4. Studio uses the separate WITB_PlayerData_Studio_v1 datastore; published servers use WITB_PlayerData_v1. Studio tests therefore do not share the production records even when conducted inside the same experience. Keep testing in a separate experience anyway.
5. Open an item and KEEP it, open another and SELL it, sell a sealed package, and unlock the scanner after earning $2,000. Record cash, inventory counts, index entries and scanner state. Wait at least 50 seconds so an autosave can occur. The menu footer should progress from LOADED to SAVING to SAVED, not STUDIO PREVIEW. Check Output for DataStore warnings.
6. Stop and restart Play with the same test player UserId. Verify the exact cash and kept counts, discoveries (including sold finds), scanner model and enabled scan prompts restore. Scanner restoration must not deduct another $2,000. Plot numbers/positions are assigned per session rather than saved.
7. Open a package, leave the KEEP/SELL reveal unresolved, wait for autosave, then stop/rejoin. The pending item should be recovered into Inventory once, with a notification, and its discovery should remain. Rejoin a second time and verify it is not granted twice.
8. Reset your character during Play: progress must stay unchanged. Use Server & Clients with two players to verify independent profiles and that cross-player ownership restrictions still hold. For actual rejoin tests, ensure the same UserId is used in both runs; Studio may use different synthetic users in different test modes.
9. Observe normal leave and shutdown saves. If a crashed session's lock persists, allow up to three minutes for its lease to expire before retrying. Do not delete datastore entries or disable locking to force a join.
10. Test on the private published experience through the Roblox client as well, then rejoin. This checks the production-mode path, which uses a separate datastore from the Studio test namespace. Studio test progress is not copied into it.

After testing, restore StudioPersistenceEnabled to false if you want ordinary Studio sessions to return to preview mode. Keep any intentional local setting change when downloading the next ZIP; a new repository copy defaults to preview again.

## Failure behavior

- Loads use UpdateAsync to acquire a session lease. A record owned by another active server, an unsupported schema, corrupt data, or exhausted request retries prevents gameplay and produces a reconnect message. The code never starts a blank playable profile after a failed read or writes defaults over an existing unsupported record.
- Autosave runs every 45 seconds and renews the 180-second lease. Save retries are bounded. If no save is confirmed close to lease expiry, money/package/upgrade actions pause, with SAVE PAUSED in the HUD, until a valid save renews ownership. Doors can still operate. A server that discovers its session token was replaced cannot overwrite the new server's record.
- Leave/shutdown snapshots are frozen before requests yield, including counts and cash together. Saves use UpdateAsync with token checks rather than unconditional SetAsync. Shutdown saving is best effort within Roblox's shutdown time limit.
- Pending reveal IDs are saved and recovered into kept inventory after rejoin. The index does not award a second discovery during recovery.
- A sudden crash or extended service outage can still lose changes newer than the last successful autosave. Do not advertise guaranteed zero data loss. The new code needs Roblox integration/failure testing before public use.

## Checks performed outside Roblox

Standalone tests passed for schema validation, data roundtrips, live/expired session leases, denied/stale writes, corrupt/future schema protection, snapshot isolation and one-time pending recovery. A deterministic adapter executes the actual PlayerProfiles service with injected network failures to test retries, failed loads, failed writes, saved-state rejoin, lost-session blocking and Studio preview isolation. Existing inventory and ownership tests passed. Luau compilation and Rojo build passed.

These tests use doubles and do not contact Roblox. Actual API access, throttling, autosave timing, shutdown behavior, scanner restoration and player rejoin remain untested in Studio by the assistant. Required checks above must pass before claiming live persistence works.

Commands from the project root (Luau CLI installed):

- luau tests/persistence.luau
- python tests/profile_service.py /path/to/luau
- luau tests/inventory.luau
- luau tests/ownership.luau

## Rollback

Stop Play and disconnect Rojo. Restore source and mapping from backups/pre-persistence and use the saved pre-update Studio place. Remove only the newly mapped profile modules if orphaned instances remain; preservation settings do not delete them automatically. Do not delete or reset saved datastore records as part of rollback. The old runtime uses session-only data and will not read them.
