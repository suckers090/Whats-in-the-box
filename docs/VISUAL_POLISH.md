# Industrial visual polish

Audit baseline: 6456500. The current warehouse export has a named floor, roof,
canopy, door frames and exterior light housings. Its interior is mostly empty and
has no Sound instances. Existing presentation includes a rotating item viewport,
navy menus, rarity colors, delivery HUD and notifications. The latest local Studio
scene is not accessible here; geometry checks use the saved warehouse export.

## Staged plan and changes

### Stage 1: environment and lighting

WarehouseVisuals is an independent server script. Each plot receives one
WarehousePrototype/VisualPolish folder: two rear storage racks, twelve marked
wooden crates, four ceiling housings/diffusers, two exterior diffusers, receiving
boundaries/label, a numbered dock sign, an operations sign and two door lamps.
The reference warehouse creates 45 new parts and six PointLights per plot.
All dressing is anchored, noncolliding, non-touching, non-queryable and has no
shadows. SurfaceGui labels stop drawing past 90 studs. There are no decor physics
loops, permanent particles or per-frame server updates. Plot destruction also
destroys its dressing. Repeated setup doesn't duplicate it.

Positions use the named floor, roof and existing markers. Small floors skip racks;
missing floor/roof skips dressing with an Output warning rather than assuming a
replacement warehouse. The receiving zone, central aisle and station approaches
remain clear in the available exported geometry. Imported MeshParts, textures,
door geometry and gameplay collision are untouched.

Lighting is applied only during runtime: 16.2 ClockTime, Brightness 2.5, cooler
ambient, soft shadows and controlled environmental reflection. WITB_Atmosphere,
WITB_Grade (ColorCorrectionEffect) and WITB_Bloom are created only if that class
doesn't already exist; artist-authored sky/post effects remain. No sun rays,
depth-of-field, renderer/LightingStyle change or fog wall is added. Existing
effects may make the result differ from the reference preset.

**Studio check:** inspect inside/outside on low and high graphics, walk through
both doors, reach the scanner and packages, watch a full truck cycle, and confirm
two players get separate correctly placed bay numbers. Check props/lights don't
clip your latest Blender mesh. Door lamps: blue closed, amber moving, green open.

### Stage 2: unified UI finish

UIStyle adds a restrained vertical gradient, border stroke and rounded corners to
existing panels/cards/buttons; it does not replace their layout or callbacks.
Buttons get cancellable hover, selection, press and tap feedback. WarehouseHUD,
BoxClient and WarehouseNotifications all use it. Notifications animate their
border and fade out with an ID guard so an old timeout cannot hide a newer notice.

**Studio check:** open Index, Inventory, Scanner, Shop and Upgrades, scroll all
cards, claim a reward, sell an item and navigate Home/Go To Station. Test mouse,
touch and gamepad focus. On phone/tablet, verify text/buttons remain readable and
menus do not overlap movement controls.

### Stage 3: action feedback and silent audio hooks

- Cash increases produce one reused short +$ amount and a brief HUD flash. Initial
  loaded cash is not treated as an earning; spending does not play a gain cue.
- Reveal payload adds only isNew, derived from server discovery history before
  recording the open. Rewards, odds, value and pending-item handling are unchanged.
- First discoveries show NEW DISCOVERY. Rare/Epic reveals emit a short strong
  burst; Legendary/Mythic/Secret use the special presentation timing. These extra
  rarity names are display support, not new rollable items. Common repeats stay
  restrained. Bursts are at most twelve GUI sparks, removed after 0.7 seconds.
- Scanner clues and successful scanner unlocks send an optional cue with the
  existing notification. DoorAudio observes existing DoorBusy attributes for
  nearby spatial audio; it cannot operate doors or change collisions.
- Presentation provides sound slots and cleanup, with at most eight simultaneous
  sounds and an eight-second timeout. No ID means no Sound instance or asset fetch.

**Studio check:** compare a first find with a duplicate; open a Rare/Legendary
when naturally rolled; KEEP/SELL still resolve once. Sell inventory/sealed packages
and claim collection rewards: cash feedback must match the actual cash change.
Scan/buy an upgrade, toggle doors and verify saves survive rejoining. A rare/new
reveal should feel special without delaying the next choice excessively.

## Files to install into your existing local Rojo folder

Stop Play, save a backup of your working place/folder, and download/extract the
latest GitHub ZIP into a separate folder. Copy only this list to matching paths:

| File | Change |
| --- | --- |
| default.project.json | Maps the new visual modules/scripts; does not map Workspace/Lighting |
| src/ReplicatedStorage/VisualConfig.luau | New presentation toggles/audio slots |
| src/ReplicatedStorage/UIStyle.luau | New reusable UI finish |
| src/ReplicatedStorage/Presentation.luau | New audio/burst helper |
| src/ReplicatedStorage/RevealStyle.luau | New rarity presentation rules |
| src/ReplicatedStorage/UITheme.luau | Preserves colors; adds future rarity display colors |
| src/ServerScriptService/WarehouseVisuals.server.luau | New independent environment/lighting script |
| src/ServerScriptService/WarehousePrototype.server.luau | Adds isNew display metadata only |
| src/ServerScriptService/ScannerUpgrade.server.luau | Adds optional scanner/upgrade audio cue only |
| src/StarterPlayer/StarterPlayerScripts/DoorAudio.client.luau | New optional door sound observer |
| src/StarterPlayer/StarterPlayerScripts/WarehouseHUD.client.luau | Shared finish and cash feedback |
| src/StarterPlayer/StarterPlayerScripts/BoxClient.client.luau | Shared finish, discovery/rarity feedback |
| src/StarterPlayer/StarterPlayerScripts/WarehouseNotifications.client.luau | Shared finish and optional cues |

Keep your existing PersistenceConfig.luau, all profile/schema/save modules and
current Studio place. Do not load the repository's older build place. Restart
Rojo from the existing folder after replacing the mapping, reconnect Studio, and
confirm the new modules/scripts appear in Explorer before pressing Play.
**Pushing GitHub changes does not update your local Rojo folder or Studio.**

## Art controls and assigning audio

Edit VisualConfig: WorldEnabled disables set dressing, LightingEnabled preserves
your place's existing lighting, EffectsEnabled disables added bursts/cash visuals,
ReducedMotion skips new bursts, reduces reveal motion and makes button transitions
instant. It isn't a complete accessibility overhaul of existing animations.
AudioEnabled mutes the new sound hooks. Lower light range/brightness or remove
fixtures in WarehouseVisuals if your maximum-player/mobile test needs it.

SoundIds keys are Button, Cash, BoxOpen, RareReveal, Scanner, Upgrade and Door.
Assign a numeric ID string (for example, the ID portion of an audio asset URL) to a
slot only after uploading/choosing an asset you own or may use and granting the
experience access. No sound assets ship with this update. Preview levels in the
test experience, including two-client spatial door audio; unavailable assets are
bounded/cleaned up but Studio may report access errors. Keep effects short and
quiet rather than stacking loud jingles over every action.

Backups of modified original files are under backups/pre-visual-polish. Reverting
this visual update does not require restoring or resetting any player records.
Disable the new script/config toggles to compare the scene; existing meshes are
unchanged. Close/restart Play when changing world/lighting toggles.

## Verification and remaining limits

Luau compilation and Rojo build validate source/mapping. world_visuals.py executes
the actual decoration script with doubles and exported mesh bounds: budget,
noncollision, station clearance, mesh preservation, existing effect preservation,
idempotence and toggles. presentation.py tests actual silent/muted hooks, sound
capacity/cleanup and bounded sparks; reveal_style.luau tests display rules. The
existing collection, inventory, saving, ownership, plot-event, delivery and garage
regressions should pass as well.

These tests do not render Roblox lighting/UI or measure device FPS. The assistant
has not run this update in Studio. Final placement, animation, audio permissions,
multiplayer replication, readability and maximum-player performance need the
stage checklists above. Customization, collectible display shelves and a designed
shared outdoor hub remain future gameplay/art stages; these racks are decoration.
