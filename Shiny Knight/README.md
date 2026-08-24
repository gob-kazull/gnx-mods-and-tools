Gobs,

Here is a GNX mod adding a new class "Shiny Knight" using the base sprite and hair structure (i.e., she comes in nine flavors: 3 skin x 3 hair).

Knights are still in the game.  Shiny Knights are a rare variant.
Shiny Knights spawn in the Mountain location (with all the other Knights), even rarer in lvl 3 Village, Forest, and Castle.  (Bump weight up +100 in classes.json if you want more to spawn).
All girls get a palette swap, as is shiny tradition.  Golden Knight, Dark Knight, and Crimson Knight.  May come with matching Golden, Plum, or Red locks.
Sorry titty lovers, no boob changes this time.  Spent the time instead updating my scripts so all future shinies will come in three different clothing swaps now.
These Knights are too ashamed to look face-to-face with their lover in the Ride cell.  (Given the hair sprites are used by all three, I couldn't make this secretive to one girl without awkward hair.  I suppose a Miku-style could work in both directions).
Always 5 stars.
Has the same offspring as a regular Knight.  At 666 births, also functionally convenient if you're looking for a specific Knight spawn.
No more shop.  Compensated by a tiny bumping of spawn rates.
Fully compatible with other GNX mods.

State:
See the State.md file in the Repo to check the current status on the Shiny Girl project.  I plan to keep this fairly up-to-date, if only for my own organizational ease.

Along with the Shiny Girl mods, I also plan to release a bunch of Python and Lua scripts that modders may find useful.  An export_class_sprites.lua replacement script is already uploaded, though it needs some better documentation and there's some QOL features I'd like to add [e.g., choose whether to import v1/2 or v3 body size sprites instead of grabbing all].  It's also slightly bugged for Special classes and is pulling in some gob body line/alpha sprites.  But, it's coverage is better (all base, clothing, mon interactions, and birth sprites automatically grabbed), and it has an interface to choose the base class in a combo box.

Install:
Shiny Knight Zip:
https://github.com/gob-kazull/gnx-mods-and-tools/blob/main/Shiny%20Knight/shiny_knight_1.0.zip

Unzip the latest shiny_knight_X.X.zip file and add the uncompressed "shiny_knight" folder into your GNX_Mods folder.

I've set up a Github Repo for all Shiny Girls here:
https://github.com/gob-kazull/gnx-mods-and-tools

Requirements:

Highly recommend using GNF for GNX installation, as it the most user-friendly:
https://github.com/Jadwick/GBF/releases

Otherwise, follow the usual instructions for GNX:
https://github.com/MovaFlow/GNX

Let me know regarding any suggestions, issues, bad frames, garbage drawing, etc. 

Credits to @MovaFlow for the GNX mod framework, @Jadwick for GNF, and BadColor for the game/inspiration.


