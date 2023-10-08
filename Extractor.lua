--[[
EyeDeck's RoC extractor controller

Recommended setup:
A M M M
E C P P
B V G I

A = AE interface
M = CC Modem/cable
E = Extractor
C = Computer
P = Peripheral Proxy (pointed down)
B = Bevel gears (^<)
G = 16:1 Diamond or Bedrock Gearbox, speed mode
V = CVT, w/lube and 31 belts
I = Industrial Coil w/ external Redstone

Next, attach a 2x2 of advanced monitors,
either to the computer, or via network cable.

Finally, to load, enter:
  openp/github get EyeDeck ComputerCraft-1.7.10-scripts master Extractor.lua startup
  startup
--]]

local ex_dir = "down" -- configurable, but usually not changed

local coil_speed = 4096 -- constant
local stages = {
  {ratio=-2, coil=4096, t=0.4}, -- 16MW: -2x CVT, 4096Nm coil, 0.4s, 32768 @ 512Nm  #1/t
  -- 3/t? only 3rd stage matters here anyway
  {ratio=32, coil=512,  t=0.6},  -- 2MW: 32x CVT, 512Nm coil, 0.6s, = 2097152 @ 1Nm; #2/t  x1.5  12
  {ratio=1,  coil=4096, t=0.7}   -- 16MW, 1x CVT, 4096Nm coil 0.9s, = 65536 @ 256    #2/t  x1.5  14
  -- note that last stage runs at 1 op/t while first stage is active
}

local w_per_cycle = 0
local total_time = 0
for _,stage in pairs(stages) do
  w_per_cycle = w_per_cycle + (coil_speed * stage.coil * stage.t)
  total_time = total_time + stage.t
end

local avg_w = w_per_cycle / total_time
local pwr_remaining_mult = avg_w * 60 * 60

print('Average wattage: ' .. avg_w)

-- Manually curated list of compatible ores
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
  ["BiomesOPlenty:gemOre"]={0,2,4,12,14},
  ["ProjRed|Exploration:projectred.exploration.ore"]={0,1,2,3,4,5,6},
  ["Mimicry:Sparr_Mimichite Ore"]={0,1,2},
  ["ImmersiveEngineering:ore"]={0,1,2,3,4}
}

local f = fs.open("buttonAPI","r")

if f == nil then
  print("Attempting to fetch ButtonAPI...")
  local bapi = http.get("https://raw.githubusercontent.com/EyeDeck/ComputerCraft-1.7.10-scripts/master/ButtonAPI.lua")
  if (bapi) then
    f = fs.open("buttonAPI","w")
    f.write(bapi.readAll())
    print("...complete, ButtonAPI has been downloaded.")
  else
    print("...failed, ButtonAPI could not be downloaded. Re-run this program to retry, or supply ButtonAPI manually.")
    error("ButtonAPI download failed")
  end
  bapi = nil
end
f.close()
f = nil

os.loadAPI("buttonAPI")
local ex, cvt, coil, mon, me = nil, nil, nil, nil, nil
local warning = {}

-- Check for critical peripherals
print("Checking peripherals...")
while ex == nil or cvt == nil or coil == nil or mon == nil do
  ex = peripheral.find("Extractor")
  adv1,adv2 = peripheral.find("AdvancedGear")
  mon = peripheral.find("monitor")
  if adv1.getName() == "CVT Unit" then
    cvt = adv1
    coil = adv2
  else
    cvt = adv2
    coil = adv1
  end
  
  if ex == nil then
    if warning.ex == nil then
      print("Extractor missing!")
      warning.ex = true
    end
     sleep(2)
  elseif cvt == nil then
    if warning.cvt == nil then
      print("CVT missing!")
      warning.cvt = true
    end
    sleep(2)
  elseif coil == nil then
    if warning.coil == nil then
      print("Coil missing!")
      warning.coil = true
    end
    sleep(2)
  elseif mon == nil then
    if warning.mon == nil then
      print("Monitor missing!")
      warning.mon = true
    end
    sleep(2)
  else
    break
  end
end
print("Critical peripherals present.")
peripherals = 0

function tryConnectAE()
  me = peripheral.find("tileinterface")
  can_do_ae = me ~= nil
  if can_do_ae == false then
    do_ae = false
    writeState("do_ae", do_ae)
  end
  return can_do_ae
end

--Returns right-most item in extractor, else if empty returns false
function notEmpty()
  local item = {}
  for i = 4,1,-1 do
    item = getStackInSlot(ex,i)
    if item ~= nil then
      return item
    end
  end
 
  return false
end

function getItemNameList(p)
  local items = {}
  for i = 1,4,1 do
    item = getStackInSlot(p,i)
    if item == nil then
      items[i] = " "
    else
      items[i] = string.format("%02d", item.qty) .. " x " .. item.display_name
    end
  end
  return items
end

function getStackInSlot(p,slot)
  sanityCheck()
  local item = {}
  item.raw_name, item.dmg, item.qty, item.display_name = p.getSlot(slot-1)
  
  -- make sure that nil is returned instead of a useless object if there is no item or the script will break in 12 different places
  if item.qty ~= nil then
    return item
  else
    return nil
  end
end

-- A huge hack to prevent a crash when a peripheral is disconnected
function sanityCheck()
  if peripherals < 0 then
    print("A peripheral has been detached!\nWaiting for reattachment...")
    while peripherals < 0 do
      sleep(2)
    end
    print("Resuming.")
  end
end

function writeState(state,val)
  if val == true then val = "1" else val = "0" end
  
  local file = fs.open("state_"..state,"w")
  file.write(val)
  file.close()
end

function readState(state)
  local file = fs.open("state_"..state,"r")
  local val
  
  if file == nil then
    val = false
  else
    val = file.readAll()
    if val == "1" then val = true else val = false end
    file.close()
  end
  
  return val
end
 
function updateDisplay()
  sanityCheck()
  local old_disp = term.redirect(mon)
  local power_in_hours = math.floor(coil.getEnergy() / pwr_remaining_mult * 100)*.01
  local cx, cy = 2, 10
  
  -- term.setCursorPos(cx,cy)
  if display_state == "ex" then
    term.setTextColor(colors.lime)
    writeCentered(term, cy, "-- Extracting --")
  elseif display_state == "jam" then
    term.setTextColor(colors.red)
    writeCentered(term, cy, "-- Jammed! Check machine -- ")
  elseif display_state == "idle" then
    term.setTextColor(colors.yellow)
    writeCentered(term, cy, "-- Idle --")
  end
  
  term.setTextColor(colors.white)
  cx = cx + 2
  local items = getItemNameList(ex)
  for k,v in ipairs(items) do
    cy = cy + 1
    term.setCursorPos(cx,cy)
    term.clearLine()
    term.write(k .. ": " .. v)
  end
  
  cx = 2
  cy = 23
  term.setCursorPos(cx,cy - 2)
  term.clearLine()
  term.write("AE: " .. tostring(ae_remaining) .. "/" .. tostring(limit_per_type) .. " " .. ae_name)
  
  -- term.setCursorPos(cx,cy - 2)
  ---term.write("Current jam ct: ".. jam_count .."  ")
  
  term.setCursorPos(cx,cy)
  term.clearLine()
  term.write("Power remaining: ".. power_in_hours .."h")
  
  term.redirect(old_disp)
end

function writeCentered(p,y,txt)
  p.setCursorPos(math.floor(mon_w / 2) - math.floor(#txt / 2), y)
  p.clearLine()
  p.write(txt)
end

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
  if can_do_ae then
    return me.pullItem(ex_dir,8,64) + me.pullItem(ex_dir,9,64)
  else
    return false
  end
end

function redrawAEButton()
  if can_do_ae then
    if do_ae then
      buttonAPI.redrawButton(nil,nil,nil,nil,nil,nil,colors.pink,{"AE","Active"},"aetoggle")
    else
      buttonAPI.redrawButton(nil,nil,nil,nil,nil,nil,colors.purple,{"AE","Inactive"},"aetoggle")
    end
  else
    buttonAPI.redrawButton(nil,nil,nil,nil,nil,nil,colors.white,{"AE","Missing"},"aetoggle")
  end
end

function exLoop()
  while true do
    if is_on then
      print("Beginning extraction...")
      os.queueEvent("wake_ae")
      
      checkForJam()
      while is_on do
        if do_ae then
          extractFlakes()
        end
        
        local current_item = notEmpty()
        
        items = getItemNameList(ex)
        if current_item ~= false and jammed == false then
          display_state = "ex"
          updateDisplay()
          
          for _,stage in pairs(stages) do
            sanityCheck()
            checkForJam()
            cvt.setRatio(stage.ratio)
            coil.setTorque(stage.coil)
            sleep(stage.t)
          end
        else
          if jammed == true then
            display_state = "jam"
            updateDisplay()
            checkForJam()
          else
            display_state = "idle"
            updateDisplay()
          end
         
          if auto_on then
            sanityCheck()
            coil.setTorque(0)
            sleep(8)
          else
            is_on = false
            buttonAPI.drawButton(mon,2,2,16,7,colors.black,colors.lime,"Start")
          end
        end
      end
      sanityCheck()
      coil.setTorque(0)
      print("Ceasing extraction.")
 
    else -- is_on == false
      os.pullEvent("main_start")
    end
  end
end

function uiLoop()
  while true do
    sanityCheck()
    local event, _, x, y = os.pullEvent("monitor_touch")
    --[[
    old_termx = term.redirect(mon)
    paintutils.drawPixel(x,y,colors.red)
    term.redirect(old_termx)
    sleep(0.33) --]]
    local button_name = buttonAPI.getButton(x,y)
    --print(button_name .. " pressed at " .. x .. "," .. y)
   
    if button_name == "startstop" then
      if is_on == false then
        --buttonAPI.drawButton(mon,2,2,16,7,colors.black,colors.red,"Stop")
        buttonAPI.redrawButton(nil,nil,nil,nil,nil,nil,colors.red,"Stop","startstop")
        is_on = true
        os.queueEvent("main_start")
      else
        --buttonAPI.drawButton(mon,2,2,16,7,colors.black,colors.lime,"Start")
        buttonAPI.redrawButton(nil,nil,nil,nil,nil,nil,colors.lime,"Start","startstop")
        is_on = false
        display_state = "idle"
      end
      resetJams()
      writeState("is_on",is_on)
    elseif button_name == "manualauto" then
      if auto_on == false then
        -- buttonAPI.drawButton(mon,20,2,16,7,colors.black,colors.yellow,"Automatic")
        buttonAPI.redrawButton(nil,nil,nil,nil,nil,nil,colors.yellow,"Automatic","manualauto")
        auto_on = true
      else
        buttonAPI.redrawButton(nil,nil,nil,nil,nil,nil,colors.blue,"Manual","manualauto")
        auto_on = false
      end
      writeState("auto_on", auto_on)
    elseif button_name == "aetoggle" then
      if can_do_ae then
        do_ae = not do_ae
      else
        do_ae = false
      end
      writeState("do_ae", do_ae)
      redrawAEButton()
      if do_ae then
        print("Starting AE")
        os.queueEvent("start_ae")
      end
    elseif button_name == "aeskip" then
      if curr ~= nil then
        print("Skipping " .. curr.fingerprint.id .. ":" .. curr.fingerprint.dmg)
        os.queueEvent("wake_ae")
        ae_remaining = 0
      else
        print("Nothing to skip")
      end
    end
    updateDisplay()
  end  
end

function checkForJam()
  jam_latest = ex.getAllStacks()
  if jamInner() then
    jam_count = jam_count + 1
    if jam_count >= jam_max_consecutive then
      jammed = true
    end
  else
    jam_count = 0
    jammed = false
  end
  jam_last = jam_latest
  return jammed
end

function jamInner()
  if #jam_latest ~= #jam_last then
    --print('ct diff')
    return false
  end
  
  -- same number of keys, start testing by value
  for i=9,1,-1 do
    local latest = jam_latest[i]
    if latest then
      local last = jam_last[i]
      if last then
        if latest.qty ~= last.qty or latest.dmg ~= last.dmg or latest.id ~= last.id then
          --print('val diff at index ' .. tostring(i))
          return false
        end
      else
        --print('index diff at ' .. tostring(i))
        return false
      end
    end
  end
  return true
end

function resetJams()
  jam_count = 0
  jam_last = {}
  jammed = false
end

function peripheralLoop()
  while true do
    local event = os.pullEvent("peripheral")
    if can_do_ae == false and tryConnectAE() then
      redrawAEButton()
      print("AE connected.")
    else
      peripherals = peripherals + 1
      print("A critical peripheral has been reattached! Missing: " .. -peripherals)
      if coil ~= nil then
        coil.setSpeed(coil_speed)
      end
    end
  end
end

function peripheralDetachLoop()
  while true do
    local event = os.pullEvent("peripheral_detach")
    
    if can_do_ae and tryConnectAE() == false then
      redrawAEButton()
      print("AE disconnected.")
    else
      peripherals = peripherals - 1
      print("A critical peripheral has been detached! Missing: " .. -peripherals)
    end
    --print(me)
  end
end

function aeInterfaceLoop()
  curr = nil
  while true do
    if can_do_ae and do_ae then
      ae_no_ore = ae_no_ore + 1
      local inv = me.getAvailableItems()
      if inv[1] ~= nil then
        for k,v in ipairs(inv) do
          local get_name = true
          if isOre(v.fingerprint.id, v.fingerprint.dmg) then
            ae_no_ore = 0
            print("Extracting ore " .. v.fingerprint.id .. ":" .. v.fingerprint.dmg)
            ae_name = v.fingerprint.id .. ":" .. v.fingerprint.dmg
            curr = v
            ae_remaining = v.size < limit_per_type and v.size or limit_per_type
            while ae_remaining > 0 do
              if do_ae == false then
                os.pullEvent("start_ae")
              end
              extractFlakes()
              
              pc, results = pcall(me.exportItem, v.fingerprint, ex_dir, ae_remaining > 64 and 64 or ae_remaining)
              if pc == true then
                -- print("exported " .. tostring(results.size))
                if get_name and results.size > 0 then
                  ae_name = getStackInSlot(ex,1).display_name
                  get_name = false
                end
                ae_remaining = ae_remaining - results.size
                pullEventOrTimeout("wake_ae", 1)
              else
                ae_remaining = 0
              end
              
            end
            v = nil
          end -- if isOre()
        end --  for k,v in ipairs(inv) do
      else
        print("AE returned empty item list.")
      end --  if inv[1] ~= nil then
      
      pullEventOrTimeout("wake_ae", math.min(math.pow(2,ae_no_ore),32) or 0)
    else
      os.pullEvent("start_ae")
    end
  end -- while true do
end

function pullEventOrTimeout(event, timeout)
  local timer_id = os.startTimer(timeout)
  while true do
    local e = {os.pullEvent()}
    if e[1] == "timer" then
      if e[2] == timer_id then
        return nil
      end
    elseif e[1] == event then
      return table.unpack(e,2)
    end
  end
end

print("Checking for AE...")
if tryConnectAE() then
  print("AE connected.")
else
  print("AE not available.")
end

limit_per_type = 256
ae_no_ore = 0
ae_remaining = 0
ae_name = "n/a"

mon.setTextScale(0.5)
mon.setBackgroundColor(colors.black)
mon.setTextColor(colors.white)
mon.clear()
mon_w, mon_h = mon.getSize()
 
coil.setSpeed(coil_speed)
coil.setTorque(0)

is_on = readState("is_on")
auto_on = readState("auto_on")
do_ae = readState("do_ae")

buttonAPI.drawButton(mon,2,2,16,7,colors.black,is_on and colors.red or colors.lime,is_on and "Stop" or "Start","startstop")
buttonAPI.drawButton(mon,20,2,16,7,colors.black,auto_on and colors.yellow or colors.blue,auto_on and "Automatic" or "Manual","manualauto")

buttonAPI.drawButton(mon,13,16,6,4,colors.black,colors.green,{"Skip","next"},"aeskip")
buttonAPI.drawButton(mon,2,16,12,4,colors.black,colors.white,"n/a","aetoggle")
redrawAEButton()

jam_count = 0
jam_max_consecutive = 9
jam_latest = {}
jam_last = {}
jammed = false

display_state = nil
if notEmpty() ~= false then
  display_state = "ex"
else
  display_state = "idle"
end
updateDisplay()

parallel.waitForAll(uiLoop, peripheralLoop, peripheralDetachLoop, aeInterfaceLoop, exLoop)
