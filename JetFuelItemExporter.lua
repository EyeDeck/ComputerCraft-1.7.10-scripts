--[[
openp/github get EyeDeck ComputerCraft-1.7.10-scripts master JetFuelItemExporter.lua startup

Connect to an ME interface, and an Ender Chest
(which will need to be peripheral proxied),
and the controller will attempt to keep a stack
of each component in the Ender Chest.
(Protip: do your Rotarycraft Jet Fuel
 fabrication in the Nether, as close to bedrock
 as possible, for much higher efficiency!)
--]]

-- set this to the dir of the chest relative to the interface
chest_dir = "up"

items = {
	['Coal Dust']       = {['RotaryCraft:rotarycraft_item_powders'] = 10},
	['Netherrack Dust'] = {['RotaryCraft:rotarycraft_item_powders'] = 0},
	['Tar Sand']        = {['RotaryCraft:rotarycraft_item_powders'] = 1},
	['Blaze Powder']    = {['minecraft:blaze_powder'] = 0},
	['Pink Dye']        = {['minecraft:dye'] = 9},
	['Magma Cream']     = {['minecraft:magma_cream'] = 0},
}

function dump(o)
	if type(o) == 'table' then
		local s = '{ '
		for k,v in pairs(o) do
				if type(k) ~= 'number' then k = '"'..k..'"' end
				s = s .. '['..k..'] = ' .. dump(v) .. ','
		end
		return s .. '} '
	else
		return tostring(o)
	end
end

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

-- print(dump(items))

me = peripheral.find("tileinterface")
chest = peripheral.find("ender_chest")

padlen = 0
for k, v in pairs(items) do
	padlen = math.max(padlen, string.len(k))
end

function tryToExport(item_list, craft)
	craft = craft or false
	ct = 0
	for name, id in pairs(item_list) do
		name_id = name.. ':' .. id
		item = storage[name_id]
		if item ~= nil then
			ct = ct + item.size
			if in_chest == nil or (in_chest.id .. ':' .. in_chest.dmg) == name_id then
				if craft then me.requestCrafting(item.fingerprint, 64) end
				me.exportItem(item.fingerprint, chest_dir, 64, i)
			end
		end
	end
	if ct == 0 and craft == false then
		ct = tryToExport(item_list, true)
	end
	return ct
end

function fetchLoop()
	while true do
		storage = keyAvailableItems(me.getAvailableItems())
		
		term.setCursorPos(1,1)
		i = 0
		for k, v in pairs(items) do
			i = i + 1
			in_chest = chest.getStackInSlot(i)
			tryToExport(v)
			print(k .. string.rep(' ', padlen - string.len(k)) .. ': ' .. ct .. '	 ')
		end
		
		sleep(5)
	end
end

fetchLoop()

parallel.waitForAll(mainLoop,offsetLoop,uiLoop)
