# Gameplay audit and development roadmap

Audit baseline: commit 39aa189, before collection milestones. This is an existing
game, not a replacement project. The user has reported working delivery, doors,
scanner/package clues, UI and saves in Studio. The assistant has verified builds
and standalone logic tests, not Roblox runtime behavior or production readiness.

## Feature audit

| Feature | Status | Current implementation and remaining work |
| --- | --- | --- |
| Delivery | Working foundation | Repeating, server-animated truck arrival, three-package unload, departure, HUD status and plot cleanup. Packages appear at the drop marker; no conveyor/physical unloading, routes, upgrades or special cargo. |
| Packages and rewards | Partial | One package tier, five items, four rarities, server RNG and private package contents. Needs more content, tier unlocks and economy tuning. |
| Opening presentation | Partial | Shrinking/glowing box, rotating procedural item preview, rarity border and animated panel. No sound library, particles, suspense sequence or finished collectible art. |
| Inventory | Partial | Persisted item stacks and server-validated sell-one actions. No locks, favorites, sorting, filters, batch selling or item variants. |
| Collection | Partial | Saved discovery counts, undiscovered cards and progress bar. No milestone rewards at audit baseline; implemented in this first stage. |
| Mutations | Missing | No Golden, Diamond or Glitched variants. Current stacks and pending rewards identify only a base item; design a backward-compatible variant format before adding them. |
| Equipment/customization | Partial | Working saved $2,000 scanner and value clues. Shop is a selling desk, Upgrades exposes scanner. No expansion, decorations, cosmetic ownership or placement editor. |
| Shared map/visiting | Working foundation | Per-player warehouse clones, slot allocation, owner signs/spawns, Home navigation, visitor-operable doors and owner-only economy. No authored shared hub, persistent plot layout or display shelves. |
| Quests/achievements | Missing | No daily quests, achievement claims, badges or progression milestones at baseline. |
| Events/social | Missing | No special delivery events, rare announcements, global leaderboard or trading. Cash leaderstats exists, but is not a persistent global leaderboard. |
| UI | Partial | Consistent navy/charcoal theme, responsive scrolling cards, animated menus, touch controls and rarity colors. Needs device testing, richer feedback, inventory tools and accessibility polish. |
| Persistence/security | Working foundation | Validated v1 profiles, session lease, autosave/retries, paused economy on stale saves, pending reward recovery, owner/distance checks, server prices and rolls. Needs real two-client/rejoin/shutdown and failure testing; no live load/scale assurance. |

## Prioritized milestones

Each stage should have a working checkpoint, compatible save changes, pure-rule
tests and a short Studio playtest before the next stage starts.

1. **Collection milestones (this stage).** Claim one-time rewards at 1/3/5 unique
   discoveries in the existing Index. Existing discovery history qualifies.
   Acceptance: server validates eligibility; duplicate/rejoin claims never pay
   twice; legacy cash, inventory, scanner and unfinished rewards survive.
2. **Inventory confidence.** Add stack locking, favorites, sorting and rarity
   filters. Locked stacks cannot be sold by any server action. Start with sell-one;
   add confirmed batch selling later. Acceptance: preferences persist and protected
   items remain protected against forged sell requests.
3. **Content and package contracts.** Expand the collectible catalog/art, then add
   a second unlockable package tier with an explicit server-defined loot table.
   Keep the free starter deliveries and original item IDs. Design unlock costs,
   sealed-sale values and tier selection before implementing paid shipments.
   Acceptance: existing starter odds stay intact; scanner reads actual package
   contents; unlocks/cash are validated and saved. Split content and tier logic
   into separate small changes.
4. **Reveal polish.** Add rarity-scaled anticipation, particles and approved sound
   assets to the existing reveal. Keep results determined on the server before
   animation. Provide reduced-motion/mute options; test small screens and input
   during the reveal. Avoid making every common opening a long unskippable wait.
5. **A warehouse worth visiting.** First add saved display shelves for kept finds,
   then cosmetic color presets/decorations, then one useful equipment upgrade.
   Keep Blender geometry and markers. Defer building expansion until dimensions,
   clearance and imported model structure are reviewed. Acceptance: visitors can
   admire displays but cannot move, sell or claim the owner's items.
6. **Mutations.** Introduce variant-aware inventory and pending reward migration
   before variant RNG. Keep all existing stacks as Normal; implement Golden first,
   then Diamond/Glitched. Variant prices, locks, scanner clues, index and displays
   must agree before enabling rolls.
7. **Return goals.** Add a small set of achievement milestones, then optional daily
   delivery contracts with server timestamps and durable claim receipts. Reward
   play without punishing a missed day. Test resets, rejoin and repeated claims.
8. **Shared excitement.** Add server-local rare-find announcements with throttling,
   one special delivery event, and a collection leaderboard before global systems.
   Rank collection breadth as well as cash so keeping finds feels worthwhile.
   Trading comes later, after variant identities and transaction recovery exist.

## Design decisions and ideas

- Collection rewards add direction now with little disruption. Cosmetic display
  trophies can follow cash rewards once shelves exist; visitors then see a player's
  story rather than only a money total.
- The current starter expected item sale value is **$756.75**, compared with **$120**
  sealed selling. Rare high payouts dominate the average. Measure typical time to
  scanner unlock and collection completion before setting future upgrade prices;
  do not tune solely from the mean or sell expensive luck boosts prematurely.
- The current five-item collection is an introductory goal, not long-term content.
  Add themed sets (electronics, antiques, unusual tech), readable silhouettes and
  new tier goals before relying on dailies to create replayability.
- Distinguish a valuable duplicate from a new discovery in presentation. Show
  "NEW FIND" and collection progress after reveals without obstructing the room.
- Prefer upgrades that change choices (scan detail, delivery capacity, display
  space) over only multiplying cash. Do not require opening a menu every batch.

## Save compatibility

Use stable IDs, additive optional fields and explicit migrations for later shape
changes. Preserve valid unknown IDs and never change the DataStore name to reset
progress. Once new fields are saved, reverting to older writers can discard them;
backups are checkpoints, not permission to downgrade a live save writer blindly.
