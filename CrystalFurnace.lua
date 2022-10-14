--[[
openp/github get EyeDeck ComputerCraft-1.7.10-scripts master CrystalFurnace.lua startup

Primarily intended to automate feeding extractor products to the ChC Crystal Furnace,
but also works on similar machines like a TE Redstone Furnace.

Usage:
Attach computer to AE interface (either directly adjacent, or via CC network cables).
AE interface should be directly adjacent to furnace.
Set ex_dir appropriately.
Pressing 'w'/'b' toggle white/blacklist processing respectively.
--]]

-- Location of furnace relative to interface (default: furnace is on top of interface)
ex_dir = "up"
-- number of items per type to process in a row (to keep from spending too long on bulk items)
limit_per_type = 256
 
me = peripheral.find("tileinterface")
curr = nil

inv_dir = {["up"] = {"down"}, ["down"] = {"up"}, ["north"] = {"south"}, ["south"] = {"north"}, ["east"] = {"west"}, ["west"] = {"east"}}

-- List of smeltable items with item name stored as key, and smeltable metadatas stored as values
-- Evaluated before the blacklist
whitelist = {
  ["GeoStrata:geostrata_rock_granite_cobble"]={0},
  ["GeoStrata:geostrata_rock_basalt_cobble"]={0},
  ["GeoStrata:geostrata_rock_marble_cobble"]={0},
  ["GeoStrata:geostrata_rock_limestone_cobble"]={0},
  ["GeoStrata:geostrata_rock_shale_cobble"]={0},
  ["GeoStrata:geostrata_rock_sandstone_cobble"]={0},
  ["GeoStrata:geostrata_rock_pumice_cobble"]={0},
  ["GeoStrata:geostrata_rock_slate_cobble"]={0},
  ["GeoStrata:geostrata_rock_gneiss_cobble"]={0},
  ["GeoStrata:geostrata_rock_peridotite_cobble"]={0},
  ["GeoStrata:geostrata_rock_quartz_cobble"]={0},
  ["GeoStrata:geostrata_rock_hornfel_cobble"]={0},
  ["GeoStrata:geostrata_rock_migmatite_cobble"]={0},
  ["GeoStrata:geostrata_rock_schist_cobble"]={0},
  ["GeoStrata:geostrata_rock_onyx_cobble"]={0},
  ["GeoStrata:geostrata_rock_opal_cobble"]={0}  
}

-- List of smeltable items with item name stored as key, and NON-smeltable metadatas stored as values
blacklist = {
  ["RotaryCraft:rotarycraft_item_modextracts"]={},
  ["RotaryCraft:rotarycraft_item_extracts"]={33},
}

bl_enabled = true
wl_enabled = false
 
function isOre(name,ID)
  if wl_enabled and whitelist[name] ~= nil then
    for k,v in ipairs(whitelist[name]) do
      if v == ID then
        return true
      end
    end
  end
  
  if bl_enabled and blacklist[name] ~= nil then
    for k,v in ipairs(blacklist[name]) do
      if v == ID then
        return false
      end
    end
    
    return true
  end
  return false
end
 
function extractFlakes()
  return me.pullItem(ex_dir,2,64)
end
 
function mainLoop()
  no_ore = 0
  while true do
    no_ore = math.min(no_ore + 1, 10)
    inv = me.getAvailableItems()
    if inv[1] ~= nil then
      for k,v in ipairs(inv) do
        if isOre(v.fingerprint.id, v.fingerprint.dmg) then
          no_ore = 0
          print("Smelting " .. v.fingerprint.id .. ":" .. v.fingerprint.dmg)
          curr = v
          remaining = v.size < limit_per_type and v.size or limit_per_type
          while remaining > 0 do
            extractFlakes()
            pc, results = pcall(me.exportItem, v.fingerprint, ex_dir, remaining > 64 and 64 or remaining)
            if pc == true then
              remaining = remaining - results.size
              sleep(1)
            else
              remaining = 0
            end
          end
          v = nil
        end -- if isOre()
      end --  for k,v in ipairs(inv) do
    end --  if inv[1] ~= nil then
    if (no_ore > 0) then -- hack to make sure flakes get extracted fully
      ex_rem = 2
      while (ex_rem > 1) do
        ex_rem = ex_rem + extractFlakes()
        ex_rem = ex_rem / 2
        -- print("ex_rem: " .. ex_rem)
        sleep(2)
      end
    end
    sleep(no_ore > 0 and math.min(math.pow(2,no_ore),64) or 0)
  end -- while true do
end

function skipLoop()
  while true do
    event, key = os.pullEvent("key")
      if key == keys.enter then
        if curr ~= nil then
          print("Skipping " .. curr.fingerprint.id .. ":" .. curr.fingerprint.dmg)
          remaining = 0
        else
          print("Nothing to skip")
        end
      elseif key == keys.b then
        bl_enabled = not bl_enabled
        print("Blackist processing " .. tostring(bl_enabled))
      elseif key == keys.w then
        wl_enabled = not wl_enabled
        print("Whitelist processing " .. tostring(wl_enabled))
      end
   end
end
 
extractFlakes()
print("Blacklist enabled: " .. tostring(bl_enabled) .. "\nWhitelist enabled: " .. tostring(wl_enabled) .. "\nWorking...")
parallel.waitForAll(mainLoop,skipLoop)