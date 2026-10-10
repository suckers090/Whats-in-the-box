# Collection milestone stage

The existing Index now includes First Find (1 unique item, $100), Getting Started
(3 unique items, $500), and Original Five (5 unique items, $1,500). These are
one-time account rewards, not per-session or repeat-opening bonuses. Current
players qualify from their saved discovery history, even for sold items.

The client sends only a milestone ID. CollectionProgress verifies the player's
server-side discovery count and unclaimed status. The existing ready-profile gate
and rate limit apply; marking claimed and adding cash run without yielding.
Cash and claim flags are captured together by the existing save snapshot. This
uses the same autosave durability window as ordinary sales; it does not promise
an immediate durable write after every click.

ProfileSchema adds optional collectionClaims to v1 records. Missing means an
empty claim map; original cash, stacks, discovery counts, scanner and pending
reward recovery are preserved. Valid unknown milestone IDs are retained. No
DataStore names, original item odds/prices or warehouse geometry change.

## Update your local Rojo project

1. Stop Play and save a backup of your working place/folder.
2. Update default.project.json and these existing files: ProfileSchema.luau,
   WarehousePrototype.server.luau and WarehouseHUD.client.luau.
3. Add src/ServerScriptService/CollectionProgress.luau and
   src/ReplicatedStorage/CollectionMilestones.luau. All existing files keep their
   original paths. Download the repository ZIP to a separate folder and copy only
   these six files into your connected project, preserving other local edits.
4. Keep your local PersistenceConfig.luau unchanged, including your enabled Studio
   saving setting. Keep your current Studio place; do not load the older build
   snapshot. Restart Rojo with the updated mapping and reconnect Studio. Both new
   ModuleScripts should appear before you press Play.

Backups of changed existing files are in backups/pre-collection-milestones.
After saving claim flags, keep a claim-aware ProfileSchema and snapshot writer:
older scripts discard the field and could allow repeat claims after an upgrade.
To disable rewards, remove/disable the claim UI and handler while retaining the
new save field. Do not revert the full save writer on live data.

## Short Studio checklist (assistant has not run these)

- Join with existing saved progress: verify cash, inventory, discoveries and scanner
  before claiming. Eligible rewards should appear without opening new packages.
- On a fresh preview profile, open one item and claim First Find: exactly +$100.
  Reopening the same item must not advance the unique count; selling must not erase
  progress. At three/five different discoveries, claim +$500/+$1,500 once each.
- Double-click a claim and reopen Index: one payout, then CLAIMED. With saving
  enabled, wait for SAVED, stop/rejoin and confirm cash/claims persist without paying
  again. Studio preview resets are expected when saving is off.
- Test two clients: each player's progress/rewards stay separate. Recheck package
  opening, sealed sales, scanner clues, repeated deliveries and both doors.
- Use Device Emulator: Index scrolls through rewards and items on phone/tablet;
  buttons and labels fit. Output should have no new errors.

## Automated checks

Run tests/collection.luau with the Luau CLI. It exercises the actual collection,
schema and transaction modules: old-save migration, distinct counting, forged and
repeat claims, independent player state, snapshot isolation, cash/claim roundtrip,
pending reward recovery and malformed claim data. Existing inventory, persistence,
profile-service, ownership, plot-event, garage and delivery checks also remain
applicable. These checks use standalone logic/doubles, not Roblox services.
