r = peripheral.wrap("right")

function suckNextItem()
  pcall(r.pushItem,"down",1)
  
  for i=1, 256, 1 do
    succ, amt = pcall(r.pullItem,"up",i)
    if succ == true and amt ~= 0 then
      item = r.getStackInSlot(1)
      if item.dmg == 0 then
        return suckNextItem()
      else
        return true
      end
    elseif succ == false then
      return false
    end
  end
end

function doRepairs()
  repair = 0
  if suckNextItem() == false then return repair else repair = repair + 1 end
  
  while true do
    item = r.getStackInSlot(1)
    if item ~= nil then
      --print(item.name .. ":" .. item.dmg)
      if item.dmg == 0 then
          if suckNextItem() == false then return repair else repair = repair + 1 end
      end
    else
      print("Item missing, or removed? Continuing...")
      if suckNextItem() == false then return repair else repair = repair + 1 end
    end
    sleep(1)
  end
end

while true do
  waitForRs = os.pullEvent("redstone")
  
  print("Beginning repairs...")
  repCount = doRepairs()
  print("Finished. Repaired " .. repCount .. " items.")
end