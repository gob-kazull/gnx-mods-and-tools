# Aseprite Lua Scripts
These Lua scripts are tools intended for Goblin Nest modding using Aseprite software.  

# Export_class_sprites

Description: Exports out related class sprites from a UMT GN sprite set.

Requirement: A directory of Goblin Nest sprites in the standard output format from UMT.  
Necessary as the script heavily depends on filename formatting.



# Palette_swap_Adhoc

Description: Swaps any specified hex color code to another.  Works with both RGB and INDEXED color mode sprites.  Intended to work with Aseprite.

Requirement: Sprite list and Color list are hard-coded into the script.  You will need to manually update them before running it.

I.E., to run, replace these below with your intended files/colors:

-- ==========================================
-- CONFIGURATION: HARD-CODED PNG FILE LIST
-- ==========================================
local files_to_process = {
  "C:/your/file/system/your_strip.aseprite"
}

-- ==========================================
-- CONFIGURATION: HARD-CODED PALETTE MAPS
-- ==========================================
local source_hex = { "e04f4f","a62929","731722","4c0b1b","fff6c5","f3c47d","d68351","af5646","842f2d" }
local target_hex = { "474a66","292c40","181a29","100e1a","e2af66","be6f3f","934e3b","743632","562121" }






