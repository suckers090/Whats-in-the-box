# Protected inventory and faster selling

This is the first mechanics-focused milestone after the facility art update.
It finishes inventory control and duplicate selling using the existing reward,
cash, collection and profile systems. Warehouse meshes, baked scenery, marker
positions, delivery timing, starter RNG odds, scanner price and save-store names
stay intact. Pre-change source backups are in `backups/pre-inventory-control`.
See the refreshed [audit and next milestones](GAMEPLAY_ROADMAP.md).

## Complete player flow

Open a package and KEEP it, then open Inventory using the HUD or B.

- **LOCK / UNLOCK** protects that item type, including all owned copies and future
  copies. Sell-one and bulk requests cannot sell it. Finding another locked item
  offers KEEP; its reveal's SELL button is disabled. Unlock from Inventory when
  you want to sell it later.
- **FAVORITE / UNFAVORITE** pins an item ahead of other rows and excludes its entire
  stack from duplicate sales. You can still explicitly sell a favorite using SELL
  ONE; use LOCK for protection against every sale. These flags remain set even if
  a favorite's last owned copy is sold, so future finds retain the preference.
- **SORT** cycles rarity, value, name and count. Favorites remain first. **SHOW**
  cycles all, favorites, unlocked, and each current rarity. View choices are local
  to the session; locks and favorites are saved.
- **SELL ONE** keeps the existing server-price sale. Buttons wait for acknowledgement
  and show the result in Inventory rather than optimistically removing an item.
- **SELL DUPES** requests a server quote, showing the duplicate count and exact
  payout before confirmation. It keeps one of each item, excludes locked/favorite
  stacks and leaves discoveries/collection rewards intact. CANCEL grants nothing.
  Quotes expire after 20 seconds. An inventory update closes the confirmation so
  you review current counts. There is no sell-all button in this stage.

The larger Inventory panel keeps its controls separate from scrolling item cards
on PC and mobile. Touch, keyboard and gamepad callbacks share the same actions.
Existing notifications, cash gain effects and audio hooks are reused; no audio
assets or new world Instances are installed.

## Opening reliability fix

Every pending reveal now has a private, single-use server token sent with that
reveal. KEEP/SELL must match it. An old, replayed, forged or premature choice cannot
consume a later package. Prices still come from ItemCatalog on the server.

If saving pauses, the reveal stays open and its buttons disable. A rejected choice
releases the waiting state and shows a notification; controls recover when saving
resumes. Opening another box with a pending choice now produces a visible notice.
Leaving with an unfinished reward still uses the existing saved pending-item ID
and recovery-to-inventory behavior. Reward tokens are never written to the profile.

## Safe v1 migration

The store names and outer record `{version = 1, data = ..., lock = ...}` remain.
Two optional maps are added to data:

```lua
inventoryLocks = {gold_watch = true}
inventoryFavorites = {headphones = true}
```

Old records missing either map load with an empty map. Migration copies inputs,
preserves cash, item counts, valid unknown item IDs, discoveries, scanner, pending
rewards and collection claim receipts. Valid unknown preference IDs are preserved
too. Each map is bounded and strictly validated; invalid data fails safely instead
of silently becoming a default playable profile. Save snapshots freeze maps before
UpdateAsync can yield. Bulk quantities, quote tokens, request timers and reveal
tokens are private session fields and are excluded from saved data.

Cash and inventory changes use one synchronous server transaction and then the
existing autosave/leave/shutdown path. This stage does not add a DataStore request
per button click or promise that an unsaved transaction survives a server crash.
Existing lease/failure handling still pauses the economy when saving is stale.

**Rollback:** after profiles have saved preferences, retain the new schema/snapshot
writer if reverting other UI code. An older writer would drop the new maps on its
next save. Restore working source only as a coordinated deployment with a plan to
retain those fields; do not reset the store to roll back. Existing old-schema source
backups are for inspection/checkpoints, not a safe live downgrade by themselves.
Keep the receipt-aware BoxClient paired with the token-validating server too;
rolling back their appearance must retain the new choice protocol.

## Server validation

- The requesting Player selects their own session; there is no accepted owner ID.
  Inventory actions can be used away from the warehouse, as before. Physical
  package/scanner actions retain owner, active-plot, health, distance and ancestry
  checks. Visitors can operate doors but cannot operate another player's economy.
- Item IDs and preference values are checked against the server catalog and owned
  counts. Clients cannot supply payout, quantities, loot odds or a target inventory.
- Duplicate-sale quantities remain server-only, tied to one player's expiring
  receipt. Confirming it checks every quoted stack before removing any copies.
  Changed counts, protection, expiry, insufficient cash headroom, another player's
  token and replayed receipts fail without partial sales.
- Inventory commands have their own per-session rate limit. Current DataReady is
  checked on the server; paused requests are acknowledged without changing items.
  Credits are bounded to the profile's existing cash limit.
- A four-second UI response timeout requests a fresh snapshot and releases controls;
  it does not automatically replay a mutation. Check the shown counts before retrying.

## Install into your existing Rojo folder

1. Stop Play and save separate backups of your working place and local project.
2. Download/extract `build/WITB-Inventory-Control-Update.zip`. Copy its contents into
   your existing Rojo folder, keeping the paths. Install all paired server/client
   files together: an old reveal client cannot send the new server's reward token.
3. Restart Rojo because two modules were added: Ctrl+C in its terminal, then
   `tools\rojo.exe serve` from the same folder. Reopen/reconnect Studio if needed.
4. Verify `ServerScriptService.InventoryActions` and
   `ReplicatedStorage.InventoryView` appear, then Play and open Inventory.

No local plugin reinstall or rebake is needed. The zip excludes PersistenceConfig,
VisualConfig, the Studio place, warehouse assets and environment builders. Keep
your own Studio saving/audio settings. Two unchanged facility modules are included
as mapping dependencies if you skipped the previous environment zip; they do not
rebuild scenery. GitHub updates do not automatically update your Windows folder.

| File | Change |
| --- | --- |
| `default.project.json` | Map InventoryActions and InventoryView |
| `src/ServerScriptService/InventoryState.luau` | Preferences, protected sales, duplicate quoting and atomic removal |
| `src/ServerScriptService/InventoryActions.luau` | New server-only transaction/receipt rules |
| `src/ServerScriptService/ProfileSchema.luau` | Optional validated v1 preference maps |
| `src/ServerScriptService/WarehousePrototype.server.luau` | Remote acknowledgements, prices/receipts, snapshots and reward tokens |
| `src/ReplicatedStorage/InventoryView.luau` | New pure ordering/filtering helper |
| `src/StarterPlayer/StarterPlayerScripts/WarehouseHUD.client.luau` | Inventory tools, item controls, confirmation, status and response recovery |
| `src/StarterPlayer/StarterPlayerScripts/BoxClient.client.luau` | Receipt-aware choices, lock display and paused/rejected-choice recovery |

## Studio checklist for this milestone

1. Open packages and KEEP several common copies. Inventory should show accurate
   counts and prices. Cycle SORT and SHOW; check Favorites pins rows, filters empty
   gracefully, and Index/Scanner/Shop/Upgrades/Home still work.
2. LOCK one type and FAVORITE another. A locked SELL ONE button disables; duplicate
   quotes exclude both protected stacks. Open another copy of the locked type:
   SELL stays disabled and KEEP still grants it.
3. With an unprotected stack of three or more, SELL DUPES quotes only count minus
   one. CANCEL changes nothing. Confirm the quote: cash increases by exactly the
   quote and one copy remains. Discoveries and claimed Index milestones remain.
   Repeated taps must not grant additional cash without additional owned items.
4. Leave/rejoin using your existing test save configuration after status says SAVED:
   verify cash, counts, discoveries, scanner, collection claims, locks and favorites.
   Test an existing pre-update account too. If it says STUDIO PREVIEW / SAVING OFF,
   progress intentionally resets; this zip does not change that local setting.
5. Run two clients. Each manages only their own inventory/cash/preferences; attempt
   another player's open/scan/sealed-sale/scanner purchase and confirm denial.
   Shared doors and warehouse visits should keep working.
6. In a disposable Studio test session, simulate a pause by setting DataReady=false
   on the **server** for the test Player while a reveal is open. Choices and sales
   should disable/deny without loss. Restore true: KEEP works. This tests the UI
   guard, not a real DataStore outage; test live save failures separately.
7. Test small mobile screens, landscape scrolling and gamepad selection. Close or
   switch menus during a quote, let one expire, and check Output. Delivery trips,
   sealed selling, scanner clues, HUD feedback and baked art should remain intact.

For a server-validation check in a disposable session, use the **client** Command
Bar to fire an invented SellDuplicates token or locked SellInventory ID. Cash and
counts must not change. Do not grant test money/items to a live player save.

## Verified in the cloud

- `tests/inventory_control.luau`: real rule modules; locks/favorites, whole-sale
  validation, stale/expired/replayed/foreign receipts, rate/cash limits, v1 migration,
  snapshot isolation and display ordering/filtering.
- `tests/server_commands.py`: actual remote handler code with two player doubles;
  server prices/counts, ownership, paused responses, stale reward choices and actual
  profile snapshot fields.
- `tests/inventory_ui.py`: real HUD/reveal callbacks with GUI doubles; preferences,
  filtering/sorting, confirmation/cancel, timeout/pause recovery and token matching.
- Actual profile-service tests now cover preference maps through yielding save
  snapshots and rejoin; existing gameplay, save, delivery, doors and art regressions
  complement compilation and Rojo build checks.

These do not run Roblox's layout, network transport, DataStore or multiplayer host.
The assistant has not tested this milestone in Roblox Studio.
