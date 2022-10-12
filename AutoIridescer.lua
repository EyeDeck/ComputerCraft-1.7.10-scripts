-- direction of "right click" item inserter relative to chest
iR = "east"
-- direction of "entity" item inserter relative to chest
iE = "west"

no_item = 0
LOL_REIKA = "pcall: Reika.ChromatiCraft.Base.ItemChromaBasic.obfuscate(Lnet/minecraft/item/ItemStack;)Z"
c = peripheral.find("tile_extrautils_chestmini_name")

function pushItemCount(p, dir, from_slot, count, to_slot)
  remaining = count
  while true do
    remaining = remaining - p.pushItem(dir, from_slot, math.min(remaining,64), to_slot)
    if remaining <= 0 then
      break
    else
      sleep(0.25)
    end
  end
end

sleep(55) -- delay in case crafting is already going
while true do
  no_item = 0
  f, item = pcall(c.getStackInSlot, 1)
  
  if f == false and item == LOL_REIKA then
    print("[" .. textutils.formatTime(os.time(), true) .. "] Found item stack, crafting a stack of iridescent shards...")
    pushItemCount(c, iR, 1, 1, 1)
    pushItemCount(c, iE, 1, 63, 1)
    sleep(55)
  else
    no_item = math.min(no_item + 1, 10)
  end
  
  sleep(no_item > 0 and math.min(math.pow(2,no_item),64) or 0)
end