dir = "north" -- direction of interface relative to ender chest
c = peripheral.find("ender_chest")

while true do
	local success, item = pcall(c.getStackInSlot, 27)
	if success == false or item ~= nil then
		for i = 1, 27, 1 do
			local success, item = pcall(c.getStackInSlot, i)
			if success == false or item ~= nil then
				c.pushItem(dir, i, 64, i%8)
			end
		end
		print("[" .. textutils.formatTime(os.time(), true) .. "] Inventory dumped")
	end

	sleep(0.25)
end