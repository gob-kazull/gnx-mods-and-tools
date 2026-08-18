-- export_class_sprites.lua

-- folder-suffix -> gnx key, when they differ
-- All other suffixes: gnx key == folder suffix
local SUFFIX_TO_KEY = {
    ["idle_leg_part"]       = "idle_legp",
    ["loop_leg_part"]       = "loop_legp",
    ["big_start_leg_part"]  = "big_start_legp",
    ["big_idle_leg_part"]   = "big_idle_legp",
    ["big_loop_leg_part"]   = "big_loop_legp",
    ["tent_idle_leg_part"]  = "tent_idle_legp",
    ["tent_loop_leg_part"]  = "tent_loop_legp",
    ["tent_birth_leg_part"] = "tent_birth_legp",
    ["tent_idle_leg_v1"]    = "tent_idle_leg_1",
    ["tent_idle_leg_v2"]    = "tent_idle_leg_2",
    ["tent_loop_leg_v1"]    = "tent_loop_leg_1",
    ["tent_loop_leg_v2"]    = "tent_loop_leg_2",
    ["tent_birth_leg_v1"]   = "tent_birth_leg_1",
    ["tent_birth_leg_v2"]   = "tent_birth_leg_2",
}

-- Global tracking of special class names
local SPECIAL_CLASS_NAMES = {
    ["nyx"] = true, ["cat"] = true, ["cow"] = true, 
    ["morrigan"] = true, ["lilith"] = true, ["giant"] = true
}

-- Vanilla class IDs (used for icon frame offset = class_id * 3)
local SRC_ID_MAP = {
    peasant  = 0,
    cleric   = 1,
    knight   = 2,
    ranger   = 3,
    nun      = 4,
    samurai  = 5,
    mage     = 6,
    shaman   = 6,
    warrior  = 7,
    lilith   = 8,
    cow      = 9,
    nyx      = 10,
    giant    = 11,
    morrigan = 12,
    cat      = 13,
}

-- Cross-platform path separator utility
local function join_path(...)
    return table.concat({...}, app.fs.pathSeparator)
end

-- Replicates sorted(folder.glob("pattern"))
local function glob(dir, pattern)
    local files = app.fs.listFiles(dir)
    local matches = {}
    for _, file in ipairs(files) do
        if file:match(pattern) then
            table.insert(matches, file)
        end
    end
    table.sort(matches)
    return matches
end

-- Replicates Python's `name.endswith(tuple(special_class_names))`
local function ends_with_special(str)
    for key, _ in pairs(SPECIAL_CLASS_NAMES) do
        if str:sub(-#key) == key then return true end
    end
    return false
end

-- Replicates Python's `any(s in name for s in special_class_names)`
local function contains_special_substring(str)
    for key, _ in pairs(SPECIAL_CLASS_NAMES) do
        if str:find(key, 1, true) then return true end
    end
    return false
end

-- True if `str` starts with any prefix in the given array.
local function starts_with_any(str, prefixes)
    for _, p in ipairs(prefixes) do
        if str:find(p, 1, true) == 1 then return true end
    end
    return false
end

-- True if `str` ends with any suffix in the given array.
local function ends_with_any(str, suffixes)
    for _, s in ipairs(suffixes) do
        if str:sub(-#s) == s then return true end
    end
    return false
end

-- Replicates Path.mkdir(parents=True, exist_ok=True)
local function mkdir_p(path)
    if not app.fs.isDirectory(path) then
        app.fs.makeDirectory(path)
    end
end

-- Replicates Python's str.replace(old, new, 1): replaces the first
-- occurrence of `old` anywhere in the string, not just at position 1.
local function replace_first(str, old, new)
    local start_idx, end_idx = str:find(old, 1, true)
    if start_idx then
        return str:sub(1, start_idx - 1) .. new .. str:sub(end_idx + 1)
    end
    return str
end

-- Replicates Python's pathlib Path.parent
local function parent_dir(path)
    local trimmed = path:gsub("[/\\]+$", "")
    local idx = nil
    for i = #trimmed, 1, -1 do
        local c = trimmed:sub(i, i)
        if c == "/" or c == "\\" then idx = i break end
    end
    if idx then
        return trimmed:sub(1, idx - 1)
    end
    return trimmed
end

-- Replicates Python's str.title(): each maximal run of alphabetic
-- characters gets its first letter capitalized and the rest lowercased.
local function title_case(s)
    local out = {}
    local prev_alpha = false
    for i = 1, #s do
        local c = s:sub(i, i)
        if c:match("%a") then
            out[#out + 1] = prev_alpha and c:lower() or c:upper()
            prev_alpha = true
        else
            out[#out + 1] = c
            prev_alpha = false
        end
    end
    return table.concat(out)
end

-- Internal binary copier mimicking shutil.copy2
local function copy_file(src, dst)
    local rf = io.open(src, "rb")
    if not rf then return false end
    local df = io.open(dst, "wb")
    if not df then rf:close() return false end
    df:write(rf:read("*all"))
    rf:close()
    df:close()
    return true
end

-- Copy all PNGs from src_folder to dst_folder, renaming src_prefix -> dst_prefix
local function copy_sprite_folder(src_folder, dst_folder, src_prefix, dst_prefix)
    mkdir_p(dst_folder)
    local files = glob(src_folder, "%.png$")
    local copied = 0
    for _, filename in ipairs(files) do
        local src_file = join_path(src_folder, filename)
        local new_name = replace_first(filename, src_prefix, dst_prefix)
        local dst_file = join_path(dst_folder, new_name)
        if copy_file(src_file, dst_file) then
            copied = copied + 1
        end
    end
    return copied
end

-- Read height of the first frame string item in a sprite folder list
local function frame_height(folder, prefix)
    local pngs = glob(folder, "%.png$")
    if #pngs == 0 then return 90 end
    local ok, result = pcall(function()
        local img = app.open(join_path(folder, pngs[1]))
        if not img then return 90 end
        local h = img.height
        img:close()
        return h
    end)
    if ok then return result end
    return 90
end

-- Simple frame count lookup
local function frame_count(folder)
    return #glob(folder, "%.png$")
end

-- Python json.dumps formatting replica
local function format_json(tbl, indent)
    indent = indent or ""
    local parts = {}
    for k, v in pairs(tbl) do
        local val_str
        if type(v) == "table" then
            val_str = format_json(v, indent .. "  ")
        elseif type(v) == "string" then
            val_str = '"' .. v .. '"'
        else
            val_str = tostring(v)
        end
        table.insert(parts, indent .. '  "' .. k .. '": ' .. val_str)
    end
    return "{\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "}"
end

-- Constructs metadata entries matching python's return dict
local function build_sprite_entry(gnx_key, dst_name, folder_name, frames, xorig, yorig, canvas_w, canvas_h)
    local entry = {
        strip = "strips/" .. dst_name .. ".png",
        frames = frames,
        xorig = xorig,
        yorig = yorig
    }
    if canvas_w then entry.canvas_w = canvas_w entry.canvas_h = canvas_h end
    if folder_name ~= dst_name then entry.folder = folder_name end
    return entry
end

-- Returns the list of directory items under `dir` (from `items`) for which
-- `predicate(item)` is true. Centralizes the scan step that every "warn if
-- nothing matches, then process what matched" section needs, so the match
-- condition only has to be written once instead of once for the check and
-- once for the loop (those two copies drifting apart is what caused the
-- tent-birth overmatch bug).
local function find_matches(dir, items, predicate)
    local out = {}
    for _, item in ipairs(items) do
        if app.fs.isDirectory(join_path(dir, item)) and predicate(item) then
            out[#out + 1] = item
        end
    end
    return out
end

-- Initialize runtime argument configurations mimicking your default context
local dlg = Dialog("Export Class Sprites")
dlg:combobox{ id="src", label="Source Class Name:", option="nun", 
              options={ "peasant", "cleric", "knight", "ranger", "nun", "samurai", "shaman", "mage", "warrior", "lilith", "cow", "nyx", "giant", "morrigan", "cat" } 
}
dlg:entry{ id="dst", label="Target Class Name:", text="shiny_nun" }
dlg:entry{ id="sprites", label="UMT Sprites/ Folder:", text="D:/Projects/GN/Game/Sprites" }
dlg:entry{ id="output", label="Destination sprites/ Folder:", text="D:/Temp/shiny_nun/sprites" }
dlg:check{ id="print_json", label="Print out Json", selected=false }
dlg:button{ id="ok", text="Run Process" }
dlg:button{ id="cancel", text="Cancel" }
dlg:show()

if not dlg.data.ok then return end
local data = dlg.data

local src = data.src
local src_id = SRC_ID_MAP[src:lower()]
if not src_id then
    print("  WARNING: No known class ID for --src " .. src .. "; defaulting to 0.")
    src_id = 0
end
local dst = data.dst
local sprites_dir = data.sprites
local out_dir = data.output
local print_json = data.print_json

-- If src is mage/shaman and folder is big/standard,tent then swap to shaman/mage
if src:lower() == "mage" or src:lower() == "shaman" then
    print("  WARNING: --src " .. src .. " sprites are split between mage and shaman names, so run twice with both values to get all sprites.")
end

-- Flag special classes for unique class folders
local is_special = SPECIAL_CLASS_NAMES[src:lower()] ~= nil

local src_prefix = "spr_h_" .. src
local dst_prefix = "spr_h_" .. dst

mkdir_p(out_dir)

local sprites_json = {}
local total_copied = 0

local all_items = app.fs.listFiles(sprites_dir)
table.sort(all_items)

-- Copies a sprite folder, builds its classes.json entry, registers it under
-- gnx_key in sprites_json, and prints the standard progress line.
--
--   item        - source folder name (relative to sprites_dir)
--   copy_src / copy_dst
--               - prefix strings passed through to copy_sprite_folder for
--                 the per-file rename (sometimes the whole-class prefix,
--                 sometimes the source/destination folder name itself)
--   dst_name    - destination folder name (also used as the classes.json key's "strip" name)
--   gnx_key     - key under which this entry is stored in sprites_json
--   raw_suffix  - the folder-name suffix gnx_key was derived from, used only
--                 to decide whether ".folder" needs to be recorded (nil when
--                 not applicable, e.g. fixed keys like "carry_base")
--   xorig       - entry's xorig value
--   yorig_or_prefix
--               - either a literal yorig number, or a string prefix to feed
--                 into frame_height() so yorig is derived from frame height
--   folder_mode - "auto" (default): entry.folder = dst_name only when
--                 gnx_key ~= raw_suffix. "force": always set entry.folder.
--                 "never": never set entry.folder.
local function register_sprite(item, copy_src, copy_dst, dst_name, gnx_key, raw_suffix, xorig, yorig_or_prefix, folder_mode)
    local dst_folder = join_path(out_dir, dst_name)
    local n = copy_sprite_folder(join_path(sprites_dir, item), dst_folder, copy_src, copy_dst)
    total_copied = total_copied + n

    local yorig = yorig_or_prefix
    if type(yorig_or_prefix) == "string" then
        yorig = frame_height(dst_folder, yorig_or_prefix)
    end

    local entry = build_sprite_entry(gnx_key, dst_name, dst_name, frame_count(dst_folder), xorig, yorig)

    if folder_mode == "force" then
        entry.folder = dst_name
    elseif folder_mode ~= "never" and gnx_key ~= raw_suffix then
        entry.folder = dst_name
    end

    sprites_json[gnx_key] = entry
    print("  " .. item .. " -> " .. dst_name .. " (" .. n .. " frames)")
    return n
end

-- Body sprites
local body_matches = find_matches(sprites_dir, all_items, function(item)
    return item:find(src_prefix .. "_", 1, true) == 1
end)
if #body_matches == 0 then
    print("ERROR: No folders matching " .. src_prefix .. "_* in " .. sprites_dir)
    return
end
for _, item in ipairs(body_matches) do
    local suffix = item:sub(#src_prefix + 2)
    local dst_name = dst_prefix .. "_" .. suffix
    local gnx_key = SUFFIX_TO_KEY[suffix] or suffix
    local xorig, yorig = 0, dst_prefix
    if suffix == "hand" then xorig, yorig = 3, 1 end
    register_sprite(item, src_prefix, dst_prefix, dst_name, gnx_key, suffix, xorig, yorig, "auto")
end

-- Base Body sprites
local base_src_prefix = "spr_h_base"
if is_special then
    -- Special Class Base Body sprites add a unique suffix
    local base_matches = find_matches(sprites_dir, all_items, function(item)
        return item:find(base_src_prefix .. "_", 1, true) == 1 and item:sub(-#src) == src
    end)
    if #base_matches == 0 then
        print("ERROR: No folders matching " .. base_src_prefix .. "_*_" .. src .. " in " .. sprites_dir)
        return
    end
    for _, item in ipairs(base_matches) do
        local suffix = item:sub(#base_src_prefix + 2, -(#src + 2))
        local dst_name = dst_prefix .. "_" .. suffix
        local gnx_key = SUFFIX_TO_KEY[suffix] or suffix
        local xorig, yorig = 0, dst_prefix
        if suffix == "hand" then xorig, yorig = 3, 1 end
        register_sprite(item, base_src_prefix, dst_prefix, dst_name, gnx_key, suffix, xorig, yorig, "auto")
    end
else
    -- Non-Special Class Base Body sprites
    local base_matches = find_matches(sprites_dir, all_items, function(item)
        return item:find(base_src_prefix .. "_", 1, true) == 1
    end)
    if #base_matches == 0 then
        print("ERROR: No folders matching " .. base_src_prefix .. "_* in " .. sprites_dir)
        return
    end
    for _, item in ipairs(base_matches) do
        if not ends_with_special(item) then
            local suffix = item:sub(#base_src_prefix + 2)
            local dst_name = base_src_prefix .. "_" .. suffix .. "_" .. dst
            local gnx_key = SUFFIX_TO_KEY[suffix] or suffix
            register_sprite(item, item, dst_name, dst_name, gnx_key, suffix, 0, dst_prefix, "auto")
        end
    end
end

-- GB1 Breast alternate sprites
local gb1_prefix = "spr_h_gb_1_big_loop_breast"
if is_special then
    local gb1_src_name = gb1_prefix .. "_" .. src
    if app.fs.isDirectory(join_path(sprites_dir, gb1_src_name)) then
        local gb1_dst_name = gb1_prefix .. "_" .. dst
        register_sprite(gb1_src_name, gb1_src_name, gb1_dst_name, gb1_dst_name, "gb1_blb", nil, 0, gb1_dst_name, "force")
    else
        print("  WARNING: No folders matching " .. gb1_src_name .. " - skipped")
    end
else
    local gb1_matches = find_matches(sprites_dir, all_items, function(item)
        return item:find(gb1_prefix .. "_", 1, true) == 1 and item:sub(-2) == "d2"
    end)
    for _, item in ipairs(gb1_matches) do
        local suffix = item:sub(#gb1_prefix + 2, -4)
        local gnx_key = (suffix == "v3") and ("gb1_blb_" .. suffix) or "gb1_blb"
        local dst_name = item:gsub("d2", dst)
        register_sprite(item, item, dst_name, dst_name, gnx_key, nil, 0, dst_name, "force")
    end
end

-- Extracts `frame_count` frames starting at `offset` from the shared
-- spr_unit_icon_{kind} sheet, renames them under the new class, and
-- registers an icon_{kind} classes.json entry. kind is "head" or "hair".
local function extract_icon(kind)
    local icon_src = join_path(sprites_dir, "spr_unit_icon_" .. kind)
    if not app.fs.isDirectory(icon_src) then
        print("  WARNING: " .. icon_src .. " not found - icon " .. (kind == "hair" and "hair " or "") .. "not extracted")
        return
    end

    local offset, frame_cnt
    if src == "lilith" then offset, frame_cnt = 24, 1
    elseif src == "cow" then offset, frame_cnt = 25, 1
    elseif src == "nyx" then offset, frame_cnt = 26, 1
    elseif src == "giant" then offset, frame_cnt = 27, 1
    elseif src == "morrigan" then offset, frame_cnt = 28, 1
    elseif src == "cat" then offset, frame_cnt = 29, 1
    else offset, frame_cnt = src_id * 3, 3 end

    local dst_name = "spr_unit_icon_" .. dst .. "_" .. kind
    local dst_dir = join_path(out_dir, dst_name)
    mkdir_p(dst_dir)

    local ok = 0
    for i = 0, frame_cnt - 1 do
        local src_frame = join_path(icon_src, "spr_unit_icon_" .. kind .. "_" .. (offset + i) .. ".png")
        local dst_frame = join_path(dst_dir, dst_name .. "_" .. i .. ".png")
        if app.fs.isFile(src_frame) and copy_file(src_frame, dst_frame) then
            ok = ok + 1
        else
            print("  WARNING: icon " .. (kind == "hair" and "hair " or "") .. "frame not found: " .. src_frame)
        end
    end

    total_copied = total_copied + ok
    print("  spr_unit_icon_" .. kind .. "[" .. offset .. "-" .. (offset + frame_cnt - 1) .. "] -> " .. dst_name .. " (" .. ok .. " frames)")

    local img = app.open(join_path(dst_dir, dst_name .. "_0.png"))
    if img then
        sprites_json["icon_" .. kind] = build_sprite_entry("icon_" .. kind, dst_name, dst_name, ok, 10, 13, img.width, img.height)
        img:close()
    end
end

extract_icon("head")
extract_icon("hair")

-- Monster sprites w/woman body frames
local monsters = {"goblin", "hobgoblin", "ogre", "tent"}
local tent_prefixes = {"spr_h_tent_idle_", "spr_h_tent_loop_", "spr_h_tent_birth_"}
local mon_suffixes = {"drink_base", "drink_loop_touch", "enter_start", "enter_loop", "enter_loop_anal", "gb_2_loop_enter", "gb_3_loop_enter", "touch_ej", "touch_loop", "touch_loop_anal", "touch_start", "touch_start_anal"}

for _, mon_name in ipairs(monsters) do
    local mon_src_prefix = "spr_h_" .. mon_name

    if is_special then
        -- Most monster sprites interactions covered here
        local interaction_matches = find_matches(sprites_dir, all_items, function(item)
            if item:find(mon_src_prefix .. "_", 1, true) ~= 1 then return false end
            local suffix_match = "_" .. src
            return item:sub(-#suffix_match) == suffix_match or item:find(suffix_match .. "_") ~= nil
        end)
        if #interaction_matches == 0 and mon_name ~= "tent" then
            print("WARNING: No folders matching " .. mon_src_prefix .. "_*_" .. src .. "* in " .. sprites_dir)
        end
        for _, item in ipairs(interaction_matches) do
            local suffix = item:sub(#mon_src_prefix + 2, -(#src + 2))
            local dst_name = item:gsub(src, dst)
            local gnx_key = SUFFIX_TO_KEY[suffix] or suffix
            register_sprite(item, item, dst_name, dst_name, gnx_key, suffix, 0, mon_src_prefix, "auto")
        end

        -- Birthing the given monster sprites
        local birth_match = mon_src_prefix .. "_" .. src .. "_"
        local birth_matches = find_matches(sprites_dir, all_items, function(item)
            return item:find(birth_match, 1, true) == 1 and item:find("_birth", #birth_match + 1, true) ~= nil
        end)
        if #birth_matches == 0 then
            print("WARNING: No folders matching " .. mon_src_prefix .. "_" .. src .. "_*_birth* in " .. sprites_dir)
        end
        for _, item in ipairs(birth_matches) do
            local suffix = item:sub(#mon_src_prefix + #src + 3)
            local dst_name = item:gsub(src, dst, 1)
            local gnx_key = SUFFIX_TO_KEY[suffix] or suffix
            register_sprite(item, item, dst_name, dst_name, gnx_key, suffix, 0, mon_src_prefix, "auto")
        end

    else
        -- Non-Special Class Base Body sprites
        local has_mon_matches = #find_matches(sprites_dir, all_items, function(item)
            return item:find(mon_src_prefix .. "_", 1, true) == 1
        end) > 0
        if not has_mon_matches then
            print("WARNING: No folders matching " .. mon_src_prefix .. "_* in " .. sprites_dir)
        end

        -- Tent-Base sprites exist under the Mon prefix - exception to other mons
        if mon_name == "tent" then
            local tent_matches = find_matches(sprites_dir, all_items, function(item)
                return item:find(mon_src_prefix .. "_", 1, true) == 1 and starts_with_any(item, tent_prefixes)
            end)
            for _, item in ipairs(tent_matches) do
                local suffix = item:sub(#mon_src_prefix + 2)
                local dst_name = "spr_h_base_" .. mon_name .. "_" .. suffix .. "_" .. dst
                local gnx_key = SUFFIX_TO_KEY[suffix] or suffix
                register_sprite(item, item, dst_name, dst_name, gnx_key, suffix, 0, dst_prefix, "auto")
            end
        else
            -- Mon-Base interaction sprites
            local interaction_matches = find_matches(sprites_dir, all_items, function(item)
                return item:find(mon_src_prefix .. "_", 1, true) == 1 and ends_with_any(item, mon_suffixes)
            end)
            for _, item in ipairs(interaction_matches) do
                local suffix = item:sub(#mon_src_prefix + 2)
                if suffix == "drink_base" then suffix = "drink" end
                local dst_name = (suffix == "gb_3_loop_enter") and (mon_src_prefix .. "_" .. dst .. "_" .. suffix) or (mon_src_prefix .. "_" .. suffix .. "_" .. dst)
                local gnx_key = SUFFIX_TO_KEY[suffix] or suffix
                register_sprite(item, item, dst_name, dst_name, gnx_key, suffix, 0, dst_prefix, "auto")
            end
        end

        -- Mon-Base Birth sprites
        -- Replicates Python's glob("{mon_src_prefix}_*_birth*"): prefix at the
        -- start, "_birth" appearing anywhere after it.
        local birth_matches_raw = find_matches(sprites_dir, all_items, function(item)
            return item:find(mon_src_prefix .. "_", 1, true) == 1
               and item:find("_birth", #mon_src_prefix + 2, true) ~= nil
        end)
        if #birth_matches_raw == 0 then
            print("WARNING: No folders matching " .. mon_src_prefix .. "_*_birth* in " .. sprites_dir)
        end
        for _, item in ipairs(birth_matches_raw) do
            if not contains_special_substring(item) then
                local suffix = item:sub(#mon_src_prefix + 2)
                local dst_name = mon_src_prefix .. "_" .. dst .. "_" .. suffix
                local gnx_key = SUFFIX_TO_KEY[suffix] or suffix
                register_sprite(item, item, dst_name, dst_name, gnx_key, suffix, 0, mon_src_prefix, "auto")
            end
        end
    end
end

-- Ogre Carry sprites have a different format
local carry_prefix = "spr_ogre_carry"
if is_special then
    local carry_src_name = carry_prefix .. "_base_" .. src
    if app.fs.isDirectory(join_path(sprites_dir, carry_src_name)) then
        local dst_name = carry_prefix .. "_base_" .. dst
        register_sprite(carry_src_name, carry_src_name, dst_name, dst_name, "carry_base", nil, 0, carry_prefix, "never")
    end
else
    -- Non-special Class sprites have carry_base{_v3}, carry_hand{_v3}
    local c_types = {"base", "hand"}
    for _, ct in ipairs(c_types) do
        local carry_src = carry_prefix .. "_" .. ct
        if app.fs.isDirectory(join_path(sprites_dir, carry_src)) then
            local dst_name = carry_src .. "_" .. dst
            register_sprite(carry_src, carry_src, dst_name, dst_name, "carry_" .. ct, nil, 0, carry_prefix, "never")
        end

        local carry_src_v3 = carry_prefix .. "_" .. ct .. "_v3"
        if app.fs.isDirectory(join_path(sprites_dir, carry_src_v3)) then
            local dst_name = carry_prefix .. "_" .. ct .. "_v3_" .. dst
            register_sprite(carry_src_v3, carry_src_v3, dst_name, dst_name, "carry_" .. ct .. "_v3", nil, 0, carry_prefix, "never")
        end
    end

    -- Non-special Class sprites have carry_hair_{class}, carry_head_{class}
    local c_classes = {"hair", "head"}
    for _, cc in ipairs(c_classes) do
        local carry_class_src = carry_prefix .. "_" .. cc .. "_" .. src
        if app.fs.isDirectory(join_path(sprites_dir, carry_class_src)) then
            local dst_name = carry_prefix .. "_" .. cc .. "_" .. dst
            register_sprite(carry_class_src, carry_class_src, dst_name, dst_name, "carry_" .. cc, nil, 0, carry_prefix, "never")
        end
    end
end

-- Calculate slot count manually to avoid dictionary table length # counting errors
local total_slots = 0
for _ in pairs(sprites_json) do total_slots = total_slots + 1 end

print("\nDone. " .. total_copied .. " files copied to " .. out_dir)
print("      " .. total_slots .. " sprite slots exported.\n")
print("Next: run scaffold_class.py to generate the full classes.json entry:")
print("  python scaffold_class.py --name \"" .. title_case(dst) .. "\" --prefix spr_h_" .. dst .. " --mod-dir \"" .. parent_dir(out_dir) .. "\"")
if print_json then
    print(format_json(sprites_json))
end