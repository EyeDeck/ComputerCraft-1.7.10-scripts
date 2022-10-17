--[[
openp/github get EyeDeck ComputerCraft-1.7.10-scripts master ChestDumper.lua startup

Usage:
Place on an Ender Chest, adjacent to an ME interface.
Set 'dir' to the the location of the interface relative to the Ender Chest.
(north/south/east/west/up/down)

Access using an Ender Pouch.
Place an item in the second-to-last slot to send it to storage.
Place an item in the last slot to dump the entire chest into storage.

Bonus points if you attach a Logistics Pipes Provider to the ME interface,
a Remote Orderer pipe to the Ender Chest, and link a Remote Orderer, which
allows full I/O access to your ME system from almost anywhere.
--]]
dir = "north"
c = peripheral.find("ender_chest")

size = c.getInventorySize()

blacklist = {
  ["LogisticsPipes:item.remoteOrdererItem"]={-1},
  ["ChromatiCraft:chromaticraft_item_aurapouch"]={-1},
  ["ThaumicTinkerer:ichorPouch"]={-1},
  ["EnderStorage:enderPouch"]={-1},
  ["Backpack:backpack"]={-1},
}
 
function isBlacklisted(name,ID)
  if blacklist[name] ~= nil then
    if blacklist[name][1] == -1 then
      return true
    end
    for k,v in ipairs(blacklist[name]) do
      if v == ID then
        return true
      end
    end
  end
  return false
end
 
while true do
  local success, item = pcall(c.getStackInSlot, size-1)
  if success == false or item ~= nil then
    if not isBlacklisted(item.id, item.dmb) then
      c.pushItem(dir, size-1, 64, 0)
    end
  end
  
  success, item = pcall(c.getStackInSlot, size)
  if success == false or item ~= nil then
    for i = 1, size, 1 do
      local success, item = pcall(c.getStackInSlot, i)
      if success == false or item ~= nil and not isBlacklisted(item.id, item.dmg) then
        c.pushItem(dir, i, 64, i%8)
      end
    end
    -- print("[" .. textutils.formatTime(os.time(), true) .. "] Inventory dumped")
  end
 
  sleep(0.1)
end