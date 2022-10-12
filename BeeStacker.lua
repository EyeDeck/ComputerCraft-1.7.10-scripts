-- slot 1: queen
-- slot 2: mate
-- slot 3: output middle
-- slot 4: output top-right

b = peripheral.find("tile_for_apiculture_0_name")
while true do
  os.pullEvent("redstone")
  if rs.getInput("front") == true then
    while true do
      mate = b.getStackInSlot(2)
      drone = b.getStackInSlot(3)
      princess = b.getStackInSlot(4)
      if drone == nil or princess == nil or drone.id ~= "Forestry:beeDroneGE" or princess.id ~= "Forestry:beePrincessGE" then
        sleep(0.25)
      else
        drone_count = drone.qty
        drone_count = drone_count + (mate and mate.qty or 0)
        
        if drone_count >= 64 then
          print("Done!")
          break
        end
        
        if mate == nil then
          b.pushItem("west",3,1) -- drone -> mate
          b.pullItem("west",1)
        end
        
        b.pushItem("west",4) -- princess -> queen
        b.pullItem("west",1)
        print("Bred a generation...")
      end
    end
  end
end