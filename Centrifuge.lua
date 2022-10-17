--[[
openp/github get EyeDeck ComputerCraft-1.7.10-scripts master Centrifuge.lua startup

Basically the same as CrystalFurnace.lua, but set up for controlling a RotaryCraft
centrifuge instead. Mostly for processing vast quantities of bee products.
--]]

-- Location of machine relative to interface
ex_dir = "down"
-- limit of items per type to do in a row
limit_per_type = 256
 
wl_enabled = true
bl_enabled = true
 
me = peripheral.find("tileinterface")
curr = nil
 
-- List of processable items with item name stored as key, and processable metadatas stored as values
-- Evaluated before the blacklist
whitelist = {
  -- ["RotaryCraft:rotarycraft_item_canola"]={0,2},
  ["RotaryCraft:rotarycraft_item_powders"]={2}
}
 
-- List of processable items with item name stored as key, and NON-processable metadatas stored as values
blacklist = {
  ["ChromatiCraft:chromaticraft_item_coloredmod"]={},
  ["ExtraBees:honeyComb"]={},
  ["Forestry:beeCombs"]={},
  ["MagicBees:comb"]={},
  ["RotaryCraft:rotarycraft_item_modinterface"]={},
  ["computronics:computronics.partsForestry"]={},
  ["gendustry:HoneyComb"]={},
  ["Forestry:propolis"]={0,1,2},
  ["MagicBees:propolis"]={0},
  ["ExtraBees:propolis"]={0}
}
 
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
  ct = 0
  i = 1
  while i < 9 do
    t = me.pullItem(ex_dir,i,128)
    ct = ct + t
    if t then
      i = i + 1
    else
      i = 9
    end
  end
  return ct
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
          print("Processing " .. v.fingerprint.id .. ":" .. v.fingerprint.dmg)
          curr = v
          remaining = v.size < limit_per_type and v.size or limit_per_type
          while remaining > 0 do
            extractFlakes()
            pc, results = pcall(me.exportItem, v.fingerprint, ex_dir, remaining > 64 and 64 or remaining)
            if pc == true then
              remaining = remaining - results.size
              sleep(0.1)
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