dofile_once("mods/fungal-twitch/files/utils.lua")

local TI_INTERVAL = ModSettingGet("fungal-twitch.TI_INTERVAL")

local last_tick = GameGetRealWorldTimeSinceStarted()
local votes = {}
local options_from = {}
local options_to = {}

local allValidMaterials = {}

local TI = {}

function TI:init()
	for _,material in ipairs(CellFactory_GetAllLiquids(true, true)) do
		if (not isIllegalMaterial(material) and not isBannedMaterial(material)) then
			table.insert(allValidMaterials, material)
		end
	end
	for _,material in ipairs(CellFactory_GetAllSands(true, true)) do
		if (not isIllegalMaterial(material) and not isBannedMaterial(material)) then
			table.insert(allValidMaterials, material)
		end
	end
	for _,material in ipairs(CellFactory_GetAllGases(true, true)) do
		if (not isIllegalMaterial(material) and not isBannedMaterial(material)) then
			table.insert(allValidMaterials, material)
		end
	end
	for _,material in ipairs(CellFactory_GetAllFires(true, true)) do
		if (not isIllegalMaterial(material) and not isBannedMaterial(material)) then
			table.insert(allValidMaterials, material)
		end
	end
	for _,material in ipairs(CellFactory_GetAllSolids(true, true)) do
		if (not isIllegalMaterial(material) and not isBannedMaterial(material)) then
			table.insert(allValidMaterials, material)
		end
	end
	resetOptions()
end

function TI:tick()
	if (self:getCooldown() <= 0) then
    last_tick = GameGetRealWorldTimeSinceStarted()

		local from_table = self:getOptionsFrom()
		table.sort(from_table, function(a, b)
	    return a.amount > b.amount
		end)

		local to_table = self:getOptionsTo()
		table.sort(to_table, function(a, b)
	    return a.amount > b.amount
		end)

		local same_from = {}
		for i=1, #from_table do
			if (from_table[i].amount == from_table[1].amount) then
				table.insert(same_from, from_table[i])
			end
		end

		local same_to = {}
		for i=1, #to_table do
			if (to_table[i].amount == to_table[1].amount) then
				table.insert(same_to, to_table[i])
			end
		end

		local mat1 = same_from[Random(1, #same_from)].material
		local mat2 = same_to[Random(1, #same_to)].material

		doShift(mat1, mat2)

		votes = {}
		resetOptions()
	end
	drawUI()
end

function TI:handleInput(user, method, material)
  if (method == "ti") then
		if (votes[user] == nil) then
			local obj = {}
			obj.from = nil
			obj.to = nil
			votes[user] = obj
		end
		local fromMaterial = string.match(material, "[1-4]")
		local toMaterial = string.match(material, "[a-d]")
		if (fromMaterial ~= nil) then
			votes[user].from = tonumber(fromMaterial)
		end
		if (toMaterial ~= nil) then
			local choices = {}
			choices['a'] = 1
			choices['b'] = 2
			choices['c'] = 3
			choices['d'] = 4
			votes[user].to = choices[toMaterial]
		end
  end
end

function TI:hasUI()
  return true
end

function TI:getTableWidth()
	return 190
end


function TI:getOptionsFrom()
	local options = {}
	for k,v in ipairs(options_from) do
		options[k] = 0
	end
	for k,v in pairs(votes) do
		local from = v.from
		if (from ~= nil) then
			options[from] = options[from] + 1
		end
	end
  local result = {}
	for k,v in pairs(options) do
		local obj = {}
		obj.amount = v
		obj.material = options_from[k]
		obj.text = k .. ") " .. getReadableName(options_from[k]) .. " (" .. v .. ")"
		table.insert(result, obj)
	end
	return result
end

function TI:getOptionsTo()
	local options = {}
	for k,v in ipairs(options_to) do
		options[k] = 0
	end
	for k,v in pairs(votes) do
		local to = v.to
		if (to ~= nil) then
			options[to] = options[to] + 1
		end
	end
  local result = {}
	for k,v in pairs(options) do
		local obj = {}
		local keys = {'a','b','c','d'}
		obj.amount = v
		obj.material = options_to[k]
		obj.text = keys[k] .. ") " .. getReadableName(options_to[k]) .. " (" .. v .. ")"
		table.insert(result, obj)
	end
	return result
end

function TI:getCooldown()
  return last_tick + TI_INTERVAL - GameGetRealWorldTimeSinceStarted()
end

function TI:isIllegalMaterial(material)
	return false
end

function TI:isBannedMaterial(material)
	return false
end

function resetOptions()
	local materials = getRandomMaterials(8)
	options_from = {}
	options_to = {}
	for i=1,4 do
		table.insert(options_from, materials[i])
		table.insert(options_to, materials[i + 4])
	end
end

function getRandomMaterials(count)
	local pickedMaterials = {}
	for i=1,count do
		local randomMaterial = getRandomMaterial()
		if (randomMaterial == nil) then
			return {}
		end
		while (pickedMaterials[randomMaterial] ~= nil) do
			randomMaterial = getRandomMaterial()
		end
		pickedMaterials[randomMaterial] = 1
	end
	local result = {}
	for k,v in pairs(pickedMaterials) do
		table.insert(result, k)
	end
	return result
end

function getRandomMaterial()
	return allValidMaterials[Random(1, #allValidMaterials)]
end

return TI
