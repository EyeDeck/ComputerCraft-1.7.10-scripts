-- Note: Superceded by extractor.lua, which now handles this too

-- Transfers compatible ores from ME system, to
-- extractor, and returns flakes to ME system.
 
-- Usage: Place on ME interface on extractor,
-- configure the two vars below, and start.
 
-- Direction of extractor relative to interface
ex_dir = "down"
-- limit of ores per type to do in a row
limit_per_type = 256
 
me = peripheral.find("tileinterface")
curr = nil
 
-- List of ores with block name stored as key, and extractable metadatas as values
o = {
  ["minecraft:iron_ore"]={0},
  ["minecraft:gold_ore"]={0},
  ["minecraft:coal_ore"]={0},
  ["minecraft:redstone_ore"]={0},
  ["minecraft:lapis_ore"]={0},
  ["minecraft:diamond_ore"]={0},
  ["minecraft:emerald_ore"]={0},
  ["minecraft:quartz_ore"]={0},
  ["IC2:blockOreTin"]={0},
  ["IC2:blockOreCopper"]={0},
  ["IC2:blockOreLead"]={0},
  ["IC2:blockOreUran"]={0},
  ["DraconicEvolution:draconiumOre"]={0},
  ["Railcraft:ore"]={0,1,2,3,4,5},
  ["ThermalFoundation:Ore"]={0,1,2,3,4,5,6},
  ["TConstruct:GravelOre"]={0,1,2,3,4,5},
  ["TConstruct:SearedBrick"]={1,2,3,4,5},
  ["Forestry:resources"]={0,1,2},
  ["Metallurgy:base.ore"]={0,1,2},
  ["Metallurgy:precious.ore"]={0,1,2},
  ["Metallurgy:utility.ore"]={0,2},
  ["ReactorCraft:reactorcraft_block_ore"]={1,2,3,4,5,6,7,8,9},
  ["ReactorCraft:reactorcraft_block_fluoriteore"]={0,1,2,3,4,5,6,7},
  ["ElectriCraft:electricraft_block_ore"]={0,1,2,3,4,5},
  ["Thaumcraft:blockCustomOre"]={0,1,2,3,4,5,6,7},
  ["appliedenergistics2:tile.OreQuartz"]={0},
  ["libVulpes:libVulpesore0"]={0,4,5,8,9},
  ["Mekanism:OreBlock"]={0,1,2},
  ["BiomesOPlenty:gemOre"]={2,4,12,14},
  ["ProjRed|Exploration:projectred.exploration.ore"]={0,1,2,3,4,5,6},
  ["Mimicry:Sparr_Mimichite Ore"]={0,1,2},
  ["ImmersiveEngineering:ore"]={0,1,2,3,4}
}
 
function isOre(name,ID)
  if o[name] ~= nil then
    for k,v in ipairs(o[name]) do
      if v == ID then
        return true
      end
    end
  end
  return false
end
 
function extractFlakes()
  ct = me.pullItem(ex_dir,8,64)
  ct = ct + me.pullItem(ex_dir,9,64)
  return ct
end
 
function mainLoop()
  no_ore = 0
  while true do
    no_ore = no_ore + 1
    inv = me.getAvailableItems()
    if inv[1] ~= nil then
      for k,v in ipairs(inv) do
        if isOre(v.fingerprint.id, v.fingerprint.dmg) then
          no_ore = 0
          print("Extracting ore " .. v.fingerprint.id .. ":" .. v.fingerprint.dmg)
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
    sleep(no_ore > 0 and math.min(math.pow(2,no_ore),32) or 0)
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
      end
   end
end
 
extractFlakes()
parallel.waitForAll(mainLoop,skipLoop)