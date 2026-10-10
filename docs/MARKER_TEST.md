# Test the existing warehouse integration

Open `build/Whats-in-the-box-marker-test.rbxlx` in Roblox Studio as a separate local place. Do not publish it over the working game yet. The latest uploaded original is preserved byte-for-byte in `backups/Whats-in-the-box-v1-positioned-markers.rbxlx`; previous script sources are in `backups/pre-marker-integration/`.

## What changed

WarehousePrototype now creates only its runtime folder, packages, and the existing simple delivery truck. It no longer creates the warehouse shell, driveway, loading dock, inspection table, or extra spawn point. The imported warehouse and existing SpawnLocation remain unchanged. The runtime folder retains the name WarehousePrototype for compatibility; it contains gameplay objects, not the building.

PackageDrop controls the center package in a three-package row with five-stud spacing. The marker's bottom face defines the bottom of the packages. TruckStop controls the rear bumper at the dock; its bottom face sets the truck's wheel ground level. The truck reverses from 29 studs away along the marker's local Z axis on initial delivery. Rotate TruckStop if that direction needs adjustment. ScannerLocation controls the purchase pad and freestanding scanner; its bottom face defines their placement surface. All three markers are hidden during Play only and remain editable after Stop.

The test place enables the adapted WarehousePrototype script. ScannerUpgrade has explicit prerequisite errors instead of indefinite waits, and its equipment uses ScannerLocation. The two client scripts are unchanged. Reward probabilities, cash awards, keep/sell handling, scanner price, and sealed-sale price are unchanged. Restocking remains the existing package-only restock; repeated truck trips are not implemented.

## Studio checks

1. Open the test place with File > Open from File. Open Explorer, Properties, and Output. Confirm WarehousePrototype is enabled and WarehouseMarkers contains all three Parts.
2. Press Play and wait about ten seconds. Check for a truck and three packages near the chosen markers. Confirm no generated warehouse shell appears and no missing-marker or infinite-yield warnings appear. Verify the truck's direction, ground level, and clearance visually; moving its marker may be needed.
3. Your doors are still unchanged and have no interaction scripts. If they prevent access, Stop and disable CanCollide on the employee door panel only in this disposable test copy, then Play again. Door behavior is a separate task.
4. Open a package with E. Confirm the existing rotating item reveal, rarity, and value appear. Choose Sell and check that Cash increases by the displayed value; open another and choose Keep, checking the reveal closes without a cash increase. Kept items currently live in server memory with no inventory UI.
5. Sell a sealed package with F. Confirm it disappears, Cash increases by $120, and the notification appears. Empty the package row and wait up to about ten seconds for all three replacements.
6. With at least $2,000, buy the scanner at ScannerLocation. Confirm the deduction, equipment placement, and notification. Use R on unopened packages and check the value clue. Check scanning is unavailable before purchase.
7. Stop and Play again to verify a fresh runtime folder and initial delivery. Cash, collection, and scanner unlock reset because persistence is not implemented.
8. Send Output errors and screenshots of any misplaced equipment before we connect Rojo or publish changes.

## Validation performed outside Studio

All four source files passed the official Luau compiler. XML comparison confirmed exactly three changed properties: the two server Source properties and WarehousePrototype's Disabled property. All other serialized instance data, including the Blender model, markers, spawn and client scripts, was preserved. The uploaded original backup is byte-identical. Source comparison confirmed the original item table, player cash/keep/sell handlers, and restock logic remain unchanged.

These checks verify syntax and preservation. Roblox engine behavior, multiplayer behavior, mesh collision, visuals, and gameplay have not been tested in Studio by the assistant.

The earlier STUDIO_IMPORT.md and import-manifest.json describe the original import, before this integration. Use this guide for the adapted test place. No Rojo sync is configured yet.
