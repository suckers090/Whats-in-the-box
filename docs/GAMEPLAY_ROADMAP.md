# Mechanics audit and development milestones

Inspected baseline: fc2b15e, after the logistics facility polish. This audit uses
current repository scripts and earlier user reports of working Studio gameplay.
The assistant has not run Roblox Studio or verified live production behavior.
Status below distinguishes implemented code from remaining design and validation.

## What exists today

| System | Status at audit | Evidence and remaining work |
| --- | --- | --- |
| Delivery | Working foundation | One serialized truck controller per plot: arrival, three-package unload, departure, repeating replenishment, countdown/status, save pause and cleanup. Needs selectable contracts, capacity/pacing upgrades and route driving. |
| Opening | Working foundation, reliability gap | Private server-selected contents, discovery counts, pending choice, shrinking package, rotating preview and rarity/new-find effects. Choice packets lacked a reward identity and rejected choices could leave client buttons waiting. Fixed in this milestone; anticipation/fast-next flow comes later. |
| Sealed selling/scanning | Implemented | F sells an owned unopened package for $120; R reads actual hidden server contents after the saved $2,000 scanner unlock. Owner/health/distance checks and double-sale guards exist. Scanner has no upgrade levels yet. |
| Inventory | Partial before this stage | Saved stacks, KEEP, sell-one and collection retention worked. Locks, favorites, ordering, filters and confirmed duplicate selling are implemented in this milestone. No item variants, display placement or trading. |
| Collection | Implemented starter progression | Five current collectibles, saved discovery counts, Index cards and one-time claim receipts/rewards at 1/3/5 unique finds. Needs larger themed sets and further goals. Selling retains discoveries. |
| Economy/progression | Limited | Free starter deliveries and server prices/odds; scanner is the only purchased equipment. No package-tier unlocks, delivery upgrades, warehouse expansion or contracts yet. |
| UI buttons | Connected, limited scope | Index claims, Inventory selling, Scanner/Upgrades station navigation and purchase, Shop-to-Inventory and Home all dispatch real actions. Shop is a selling desk and Upgrades shows the same scanner; these are not complete future shops. All new inventory controls are connected in this stage. Device/layout testing remains. |
| Shared map/visitors | Working foundation | Each Player gets a cloned warehouse, slot, owner spawn/sign and isolated session. Visitors may use doors; owner-only economy checks remain. New warehouse allocation reuses baked art. Needs public displays, authored meeting areas and stronger social goals. |
| Persistent saving | Implemented foundation | v1 validation, unknown item-ID preservation, session leases, frozen snapshots, retries/autosave/leave/shutdown, stale-save economy pause and unfinished reward recovery. Cash/items/index/scanner/collection receipts persist. New preference maps are additive. Real reconnect/shutdown/outage/scale testing remains. |
| Security | Existing checks plus this stage | Server RNG/prices, authoritative player sessions, object ancestry/distance/health, stale-session shutdown and repeated reward/claim protection. This stage adds locked-sale checks, private bulk receipts, whole-sale validation and reward-specific choice tokens. No claim of a complete penetration audit. |
| Feedback/audio | Partial | Navy UI, cash feedback, rarity/new-find bursts, notification queue, door indicators and optional audio hooks exist. SoundIds defaults are empty: sound assets must be assigned with permission to use them. More mechanical feedback and accessibility settings can follow. |
| Optimization | Bounded foundation | Anchored decorative models, bounded effect bursts/sounds, no new per-frame environment loops, shared road rows and disposal on plot release. Needs real mobile/multi-client profiling; truck tweens and every inventory snapshot still have scale costs to measure. |
| Long-term systems | Missing | Package tiers, variants/mutations, quests, achievements, events, global leaderboards, warehouse equipment progression and saved displays/customization. These should follow a stable core loop. |

## Milestone 1 — protected inventory and faster selling (this change)

Finish the repeatable opening → keeping → managing → selling flow before extending
it. Players can save stack locks/favorites, sort/filter finds and sell unprotected
duplicates with a server quote and confirmation. One copy of every quoted type
remains. Locked types are protected even when another duplicate is revealed.
Reward choices now belong to one reveal; pauses/rejections recover the UI instead
of leaving it waiting. The existing HUD, collection rewards, scanner and cash
feedback are reused.

Acceptance: no sales of locked items; favorites excluded from bulk; no partial or
replayed bulk payouts; prices/quantities never supplied by clients; migration and
rejoin retain existing progress; both players act only on their own data.
[Installation, changed files and Studio tests](INVENTORY_CONTROL.md).

## Milestone 2 — meaningful delivery progression

First add enough stable collectibles and distinct procedural previews for a second
package tier. Keep the five existing IDs and starter odds intact. Then implement
one paid tier unlock and a selectable shipment contract in Shop, plus one practical
equipment upgrade in Upgrades. Free starter deliveries remain available.

Prefer choices over unconditional cash multipliers: a higher-tier contract should
trade a known shipment cost for different discoveries; a capacity upgrade should
change batch size while respecting dock space. Prices, loot tables, unlock
requirements, selection and scanner/sealed-sale values must all be server-defined.
Discovery milestones can unlock eligibility so one lucky high payout does not skip
all progression. Expose costs and outcomes before purchase, and apply a selected
contract to the next shipment rather than replacing packages already on the dock.

Acceptance: old saves gain default unlock fields through a tested additive migration;
no new store/reset; purchase/selection/rolls validate on the server; old scanner and
starter package behavior remain; every new shop/upgrade button is backed by a real
purchase, saved unlock and observable gameplay effect. Split catalog/previews and
contracts/upgrades into reviewable checkpoints if the stage grows too large.

## Milestone 3 — a smoother opening rhythm

Use the new reward identity to support a quick keep-and-next flow, short rarity-led
anticipation and useful input feedback. Keep common reveals fast; rare finds get
more attention without forcing long unskippable waits every time. Preview counts
and new-discovery status, and give touch/gamepad the same actions as keyboard.
Approved sound assets can fill the existing hooks. Add user-facing mute/reduced
motion controls only when their state and all effects/audio respect them.

Acceptance: each box grants one result; interruptions, death, pauses, rejoin and
rapid inputs cannot lose or duplicate it; next-box actions choose an eligible
nearby owned box on the server; visuals never decide or reroll rewards.

## Milestone 4 — warehouses worth visiting

Add saved display slots for kept collectibles and a small equipment/cosmetic shop.
Visitors can inspect displays but cannot move or sell them. Keeping a rare item
then creates a visible achievement beyond the Index count. Give display items the
same protection rules as Inventory; avoid a duplicate inventory representation.
Blender assets can replace procedural placeholders later without changing IDs.
Review mesh bounds/markers before any physical expansion upgrade.

Acceptance: displays save safely, owner/visitor permissions hold, decorations do
not obstruct equipment/doors, and all purchase/placement UI is complete.

## Milestone 5 — replay goals and shared excitement

Start with a small set of achievement milestones, then daily delivery contracts
with server timestamps and durable claim receipts. Add one server-local special
cargo event, throttled rare-find announcements and collection rankings alongside
cash. Avoid punishing a missed day or making endless cash farming the only goal.

Acceptance: rejoin/repeated claims cannot pay twice; date/reset behavior is tested;
events end cleanly; notifications remain readable on mobile. Global leaderboards
and trading come after stable transaction recovery, not before.

## Milestone 6 — variants and release hardening

Before Golden/Diamond/Glitched rolls, define stable variant identities and migrate
existing stacks to Normal without deleting counts. Locks, favorites, pricing,
scanner clues, pending rewards, displays and saves must agree on that identity.
Start with one variant instead of three parallel unfinished systems.

Alongside every milestone, test two clients and real saves. Before public release,
run leave/rejoin/shutdown and DataStore failure tests, remote abuse tests, device
performance profiling, input/accessibility checks and multi-plot stress tests.
Reliable claims and ownership are prerequisites for trading.

## Design and economy notes

- Starter packages currently have a $756.75 mean opened sale value versus $120
  sealed selling. Rare rewards dominate that average. Measure typical session
  earnings and time to unlock before setting contracts/upgrades; do not tune only
  against the mean or silently change working odds in a polish patch.
- Safe duplicate selling reserves one owned copy and creates a foundation for
  display shelves and collectible sets. Favorite is a bulk preference; Lock is
  protection against every sale. Keep that distinction visible in the UI.
- A rare find should give players another reason to return: a display goal, tier
  eligibility or set milestone, not just an unusually large cash number.
- Inventory sales remain usable while visiting friends. Physical purchases and
  package actions still belong to the owner's warehouse and require proximity.
- Preserve the current Blender template and baked map. Add future equipment using
  reviewed markers and modular controllers, not a second warehouse generator.

## Save/deployment contract

Use stable IDs, validated optional fields and explicit migration tests. Preserve
valid unknown item IDs/preferences, store names and versioned records. Save related
cash/counts/claims together, and pause rather than create defaults after failed loads.
Do not deploy an older writer that drops newly saved fields. Source backups are
checkpoints; after migration, rollback needs a compatible writer and retained data.
