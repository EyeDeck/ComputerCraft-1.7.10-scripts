-- set this to the dir of the inventory relative to the interface
inv_dir = "north"
scan_wait = 1.2

--[[
openp/github get EyeDeck ComputerCraft-1.7.10-scripts master ThaumcraftAutoScanner.lua startup

Usage:
- load into a computer attached to an ME interface
- Place a SFM Rapid Item Valve adjacent to the interface
- Configure inv_dir

Before you use the learner routine, first combine Aqua+Terra,
and Aer+Aqua in a research table. The learner routine will
attempt to teach you every aspect using items already
likely to be in your ME system.

The scanner routine will instead go through every single
item in your ME system. This may take quite a bit of time
if there are thousands of unique items, around 10 minutes
per full ME drive (640 types).

Get your Thaumcraft scanner ready. Then, open the computer,
and press 'l' or 's' to start a scan routine. Quickly exit,
and then hold your scanner in front of the item valve output.

In the computer, space/enter/pause will pause the program.
Up/Down will skip forward or backwards in the item list.
PgUp/PgDn will skip 64 forward or backwards.
End will halt the program.
--]]

learners = {
  {['aspect']='lux', ['minecraft:torch']={0}},
  {['aspect']='potentia', ['minecraft:coal']={0},['minecraft:coal_ore']={0}},
  {['aspect']='herba', ['minecraft:grass']={0}},
  {['aspect']='motus & arbor', ['minecraft:trapdoor']={0}},
  {['aspect']='vacuos', ['minecraft:bowl']={0}},
  {['aspect']='vitreus', ['minecraft:glass']={0}},
  {['aspect']='mortuus & praecantatio', ['minecraft:potion']={8200,8232,8264}},
  {['aspect']='volatus', ['minecraft:feather']={0}},
  {['aspect']='bestia', ['minecraft:egg']={0}},
  {['aspect']='spiritus & vinculum', ['minecraft:soul_sand']={0},['minecraft:skull']={-1}},
  {['aspect']='cognitio', ['minecraft:book']={0}},
  {['aspect']='humanus&corpus', ['minecraft:rotten_flesh']={0}},
  {['aspect']='fames & messis', ['minecraft:wheat']={0},['minecraft:bread']={0},['minecraft:apple']={0},['minecraft:carrot']={0},['minecraft:potato']={0}},
  {['aspect']='instrumentum', ['minecraft:flint']={0}},
  {['aspect']='tenebrae', ['minecraft:obsidian']={0}},
  {['aspect']='sensus', ['minecraft:red_flower']={-1},['minecraft:dye']={-1}},
  {['aspect']='fabrico & pannus', ['minecraft:wool']={0}},
  {['aspect']='venenum', ['minecraft:spider_eye']={0}},
  {['aspect']='gelum', ['minecraft:snowball']={0},['minecraft:snow_layer']={0},['minecraft:ice']={0},['minecraft:packed_ice']={0}},
  {['aspect']='sano', ['minecraft:milk_bucket']={0}},
  {['aspect']='meto', ['minecraft:wooden_hoe']={-1},['minecraft:stone_hoe']={-1},['minecraft:iron_hoe']={-1},['minecraft:diamond_hoe']={-1},['minecraft:iron_hoe']={-1},['minecraft:shears']={-1},['ThermalFoundation:tool.shearsWood']={-1},['ThermalFoundation:tool.shearsStone']={-1}},
  {['aspect']='perfodio', ['minecraft:iron_pickaxe']={-1},['minecraft:stone_pickaxe']={-1},['minecraft:iron_pickaxe']={-1},['minecraft:diamond_pickaxe']={-1}},
  {['aspect']='telum', ['minecraft:arrow']={0}},
  {['aspect']='tutamen', ['minecraft:leather']={0},['minecraft:iron_helmet']={-1},['minecraft:iron_chestplate']={-1},['minecraft:iron_leggings']={-1},['minecraft:iron_boots']={-1}},
  {['aspect']='permutatio', ['minecraft:hopper']={0},['minecraft:wheat_seeds']={0},['Thaumcraft:blockCustomOre']={0}},
  {['aspect']='machina & iter', ['minecraft:fence_gate']={0}},
  {['aspect']='metallum', ['minecraft:iron_ore']={0},['minecraft:iron_ingot']={0},['minecraft:iron_block']={0}},
  {['aspect']='lucrum', ['minecraft:gold_ore']={0},['minecraft:gold_ingot']={0},['minecraft:gold_block']={0}},
  {['aspect']='exanimis', ['Thaumcraft:ItemZombieBrain']={0}},
  {['aspect']='alienis', ['minecraft:ender_pearl']={0},['ThaumCraft:blockCosmeticSolid']={0}},
  {['aspect']='limus', ['minecraft:slime_ball']={0}},
  {['aspect']='vitium', ['Thaumcraft:ItemResource']={11,12}},
  {['aspect']='auram', ['Thaumcraft:ItemWispEssence']={0}}
}

-- reformats AE item table to 'name:meta'=v,
-- and 'name'.size=(total size for all metas),
-- and 'name'.fingerprints={all fingerprints}
function keyAvailableItems(inv)
  local out = {}
  for k,v in ipairs(inv) do
    local id = v.fingerprint.id
    local meta = v.fingerprint.dmg
    if out[id] ~= nil then
      out[id].size = out[id].size + v.size
    else
      out[id] = {['size'] = v.size}
      out[id].fingerprints = {}
    end
    out[id].fingerprints[#out[id].fingerprints+1] = v.fingerprint
    out[id..':'..meta] = v
  end
  return out
end

function moveForScanning(fingerprint)
  pcall(me.exportItem, fingerprint, inv_dir, 1)
  sleep(scan_wait)
  retrieveItems()
end

function retrieveItems()
  for i=1,4 do
    pcall(me.pullItem, inv_dir, i, i)
  end
end

function startRoutine(event_id)
  curr_mode = event_id
  os.queueEvent('start', event_id)
  os.pullEvent('finish') --wait for whatever function that caught this to finish
end

function learnerRoutine()
  retrieveItems()

  local inv = me.getAvailableItems()
  local inv_keyed = keyAvailableItems(inv)

  local available = {}

  local missing = {}
  local missing_ct = 0

  for k,v in ipairs(learners) do
    local fingerprint

    for k2,v2 in pairs(v) do
      if k2 == 'aspect' then
        --pass
      elseif v2[1] == -1 then
        if inv_keyed[k2] ~= nil then
          fingerprint = inv_keyed[k2].fingerprints[1]
        end
      else
        for _,v3 in ipairs(v2) do
          if inv_keyed[k2..':'..v3] ~= nil then
            fingerprint = inv_keyed[k2..':'..v3].fingerprint
          end
        end
      end
    end

    if fingerprint ~= nil then
      available[k] = fingerprint
    else
      missing_ct = missing_ct + 1
      local aspect = v.aspect
      missing[aspect] = ''
      for k2,v2 in pairs(v) do
        if k2 ~= 'aspect' then
          local s = k2 .. ':'
          for _,v3 in ipairs(v2) do
            s = s .. v3 .. ','
          end

          missing[aspect] = missing[aspect] .. s .. '; '
        end
      end
    end
  end

  if missing_ct > 0 then
    print('Missing:')
    for k,v in pairs(missing) do
      print('  ' .. k .. '=' .. v)
    end
    print('Continue anyway? [y/n]')
    local keyloop = true
    while keyloop do
      local event, key = os.pullEvent('key')
      if key == keys.n then
        return
      elseif key == keys.y then
        keyloop = false
      end
    end
  else
    print('All items accounted for. Continuing.')
  end

  print('Delaying 3s to get scanner ready.')
  sleep(3)

  for k,v in pairs(available) do
    print('  scanning ' .. v.id)
    moveForScanning(v)
  end
end

function scannerRoutine()
  local inv = me.getAvailableItems()

  print('Delaying 3s to get scanner ready.')
  sleep(3)
  local inv_size = #inv
  local last_id = 0
  local last_meta = 0

  while offset <= inv_size do
    local f = inv[offset].fingerprint
    local id = f.id
    local meta = f.dmg

    if last_id ~= id or last_meta ~= meta then
      print('  scanning #'..offset..'='..f.id)
      moveForScanning(f)
      while paused do
        sleep(1)
      end

      if stop then
        return
      end
    end

    last_id = id
    last_meta = meta
    offset = offset + 1
  end
end

function mainLoop()
  while true do
    local event, id = os.pullEvent('start')
    retrieveItems()
    if id == 0 then
      scannerRoutine()
      os.queueEvent('finish')
    elseif id == 1 then
      learnerRoutine()
      print('learnerRoutine() returned')
      os.queueEvent('finish')
    end
  end
end

function offsetLoop()
  while true do
    local event, key = os.pullEvent('key')
    if key == keys.enter or key == keys.pause or keys.space then
      paused = paused == false
      print(paused and 'Paused' or 'Unpaused')
      retrieveItems()
    elseif key == keys.end then
      print('Halting')
      retrieveItems()
      stop = true
    else
      local last_offset = offset
      if key == keys.up then
        offset = offset+1
      elseif key == keys.down then
        offset = offset-1
      elseif key == keys.pageUp or key == keys.right then
        offset = offset+64
      elseif key == keys.pageDown or key == keys.left then
        offset = offset-64
      end
      offset = math.max(1,offset)
      if offset ~= last_offset then
        print('New offset: ' .. offset)
      end
    end
  end
end

function uiLoop()
  while true do
    term.setCursorPos(1,1)
    term.clear()
    stop = false
    print('Waiting for command...\n  "l" to start learner routine\n  "s" to start scanner routine')
    local event, key = os.pullEvent('key')
    if key == keys.s then
      startRoutine(0)
    elseif key == keys.l then
      startRoutine(1)
    end
  end
end

offset = 0
curr_mode = 0

me = peripheral.find("tileinterface")

parallel.waitForAll(mainLoop,offsetLoop,uiLoop)