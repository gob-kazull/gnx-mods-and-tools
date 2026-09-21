-- ==========================================
-- CONFIGURATION: HARD-CODED PNG FILE LIST
-- ==========================================
local files_to_process = {
  "C:/your/file/syste,/your_strip.aseprite"
}

-- ==========================================
-- CONFIGURATION: HARD-CODED PALETTE MAPS
-- ==========================================
local source_hex = { "e04f4f","a62929","731722","4c0b1b","fff6c5","f3c47d","d68351","af5646","842f2d" }
local target_hex = { "474a66","292c40","181a29","100e1a","e2af66","be6f3f","934e3b","743632","562121" }

-- ==========================================
-- GLOBAL STRING MAP GENERATION
-- ==========================================
local string_color_map = {}
for i = 1, math.min(#source_hex, #target_hex) do
  local src_key = string.lower(source_hex[i])
  local tgt_str = string.lower(target_hex[i])
  
  local tgt_r = tonumber(string.sub(tgt_str, 1, 2), 16)
  local tgt_g = tonumber(string.sub(tgt_str, 3, 4), 16)
  local tgt_b = tonumber(string.sub(tgt_str, 5, 6), 16)
  
  local accurate_rgba_pixel = app.pixelColor.rgba(tgt_r, tgt_g, tgt_b, 255)
  
  string_color_map[src_key] = {
    color_obj = Color{ r=tgt_r, g=tgt_g, b=tgt_b, a=255 },
    rgba_pixel = accurate_rgba_pixel,
    r = tgt_r,
    g = tgt_g,
    b = tgt_b,
    original_target_hex = tgt_str
  }
end

-- ==========================================
-- PRE-FLIGHT VERIFICATION LOOP
-- ==========================================
-- This block ensures that target evaluations haven't tanked to pure black (#000000)
-- unless you explicitly asked for a pure black hex ("000000") in your configuration.
for src_hex, target_data in pairs(string_color_map) do
  if target_data.r == 0 and target_data.g == 0 and target_data.b == 0 then
    if string.lower(target_data.original_target_hex) ~= "000000" then
      local error_msg = string.format(
        "CRITICAL ERROR: Pre-flight check failed!\nTarget color for source #%s evaluated to #000000 (pure black), but config requested #%s.\nExecution aborted to preserve your files.",
        src_hex, target_data.original_target_hex
      )
      print(error_msg)
      return app.alert(error_msg)
    end
  end
end
print("Pre-flight target color verification passed cleanly. Starting batch...")


-- ==========================================
-- INDEXED MODE PROCESSING FUNCTION
-- ==========================================
local function process_indexed_sprite(sprite)
  local pal = sprite.palettes
  if not pal or #pal == 0 then return false end
  local primary_palette = pal[1]
  local modified = false

  for p = 0, #primary_palette - 1 do
    local current_color = primary_palette:getColor(p)
    local current_hex = string.format("%02x%02x%02x", current_color.red, current_color.green, current_color.blue)

    local target_data = string_color_map[current_hex]
    if target_data then
      primary_palette:setColor(p, target_data.color_obj)
      modified = true
    end
  end
  return modified
end

-- ==========================================
-- RGB MODE PROCESSING FUNCTION 
-- ==========================================
local function process_rgb_sprite(sprite)
  local modified = false

  -- Step 1: Safe global cel iterator
  if sprite.cels and #sprite.cels > 0 then
    for i = 1, #sprite.cels do
      local cel = sprite.cels[i]
      if cel and cel.image then
        local img = cel.image
        if not img:isEmpty() then
          for it in img:pixels() do
            local current_color = it() 
            local a = app.pixelColor.rgbaA(current_color)
            
            if a > 0 then
              local r = app.pixelColor.rgbaR(current_color)
              local g = app.pixelColor.rgbaG(current_color)
              local b = app.pixelColor.rgbaB(current_color)
              local current_hex = string.format("%02x%02x%02x", r, g, b)
              
              local target_data = string_color_map[current_hex]
              if target_data then
                local new_pixel_val = target_data.rgba_pixel
                
                if a < 255 then
                  new_pixel_val = app.pixelColor.rgba(target_data.r, target_data.g, target_data.b, a)
                end
                
                img:drawPixel(it.x, it.y, new_pixel_val)
                modified = true
              end
            end
          end
        end
      end
    end
  end
  
  -- Step 2: Corrected layer-by-layer fallback for flat background layers
  if not modified and sprite.layers and #sprite.layers > 0 then
    for l = 1, #sprite.layers do
      local current_layer = sprite.layers[l]
      if current_layer and current_layer.isImage then
        local layer_cels = current_layer.cels
        if layer_cels and #layer_cels > 0 then
          for c = 1, #layer_cels do
            local cel = layer_cels[c]
            if cel and cel.image then
              local img = cel.image
              for it in img:pixels() do
                local current_color = it() 
                local a = app.pixelColor.rgbaA(current_color)
                
                if a > 0 then
                  local r = app.pixelColor.rgbaR(current_color)
                  local g = app.pixelColor.rgbaG(current_color)
                  local b = app.pixelColor.rgbaB(current_color)
                  local current_hex = string.format("%02x%02x%02x", r, g, b)
                  
                  local target_data = string_color_map[current_hex]
                  if target_data then
                    local new_pixel_val = target_data.rgba_pixel
                    if a < 255 then
                      new_pixel_val = app.pixelColor.rgba(target_data.r, target_data.g, target_data.b, a)
                    end
                    
                    img:drawPixel(it.x, it.y, new_pixel_val)
                    modified = true
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  return modified
end


-- ==========================================
-- MAIN BATCH RUNNER
-- ==========================================
local success_count = 0

for _, filepath in ipairs(files_to_process) do
  print("\n----------------------------------------")
  print("RUNNING: " .. filepath)
  print("----------------------------------------")
  
  local sprite = app.open(filepath)

  if sprite then
    local modified = false

    app.transaction("Dual Mode Palette Swap", function()
      if sprite.colorMode == ColorMode.INDEXED then
        print("  Detected Format: INDEXED MODE")
        modified = process_indexed_sprite(sprite)
      elseif sprite.colorMode == ColorMode.RGB then
        print("  Detected Format: RGB MODE")
        modified = process_rgb_sprite(sprite)
      else
        print("  Detected Format: UNSUPPORTED MODE")
      end
    end)

    if modified then
      app.command.SaveFile { ui = false, filename = filepath }
      success_count = success_count + 1
      print("  STATUS: Success! Colors swapped and file updated.")
    else
      print("  STATUS: Completed. No matching hex combinations found.")
    end

    sprite:close()
  else
    print("  CRITICAL ERROR: Could not locate or open file path.")
  end
end

app.refresh()
app.alert(string.format("Batch completed! Successfully updated %d out of %d files.", success_count, #files_to_process))
