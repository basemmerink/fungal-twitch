dofile_once("mods/fungal-twitch/files/utils.lua")

local TI_INTERVAL = ModSettingGet("fungal-twitch.TI_INTERVAL")

local allValidMaterials = {}

local TI = {
	last_tick = nil,
	votes = {},
	options_from = {},
	options_to = {}
}

function TI:init()
	self.last_tick = GameGetRealWorldTimeSinceStarted()
	if (#allValidMaterials == 0) then
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
	end
	self:resetOptions()
end

function TI:tick()
	if (self:getCooldown() <= 0) then
    self.last_tick = GameGetRealWorldTimeSinceStarted()

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

		SetRandomSeed(GameGetFrameNum(), -GameGetFrameNum())
		local mat1 = same_from[Random(1, #same_from)].material
		local mat2 = same_to[Random(1, #same_to)].material

		doShift(mat1, mat2)

		self:resetOptions()
	end
end

function TI:handleInput(user, message, rewardId)
	if (self.votes[user] == nil) then
		self.votes[user] = {from = nil, to = nil}
	end

	local first, second = message:find('^[1-4a-d]? ?[1-4a-d]$?')

	if (first == nil) then
		return
	end
	
	local mat1 = message:sub(first, first)
	local mat2 = message:sub(second, second)

	local toChoices = {}
	toChoices['a'] = 1
	toChoices['b'] = 2
	toChoices['c'] = 3
	toChoices['d'] = 4

	if (mat1:match("[1-4]") ~= nil) then
		self.votes[user].from = tonumber(mat1)
	else
		self.votes[user].to = toChoices[mat1]
	end

	if (mat1 == mat2) then
		return
	end

	if (mat2:match("[1-4]") ~= nil) then
		self.votes[user].from = tonumber(mat2)
	else
		self.votes[user].to = toChoices[mat2]
	end
end

function TI:hasUI()
  return true
end

function TI:getOptionsFrom()
	local options = {}
	for k,v in ipairs(self.options_from) do
		options[k] = 0
	end
	for k,v in pairs(self.votes) do
		local from = v.from
		if (from ~= nil) then
			options[from] = options[from] + 1
		end
	end
  local result = {}
	for k,v in pairs(options) do
		table.insert(result, {
			amount = v,
			material = self.options_from[k],
			text = k .. ") " .. self.options_from[k] .. " (".. getReadableName(self.options_from[k]) .. ") [" .. v .. "]"
		})
	end
	return result
end

function TI:getOptionsTo()
	local options = {}
	for k,v in ipairs(self.options_to) do
		options[k] = 0
	end
	for k,v in pairs(self.votes) do
		local to = v.to
		if (to ~= nil) then
			options[to] = options[to] + 1
		end
	end
  local result = {}
	for k,v in pairs(options) do
		local keys = {'a','b','c','d'}
		table.insert(result, {
			amount = v,
			material = self.options_to[k],
			text = keys[k] .. ") " .. self.options_to[k] .. " (" .. getReadableName(self.options_to[k]) .. ") [" .. v .. "]"
		})
	end
	return result
end

function TI:isIllegal(material)
	return false
end

function TI:getCooldown()
  return self.last_tick + TI_INTERVAL - GameGetRealWorldTimeSinceStarted()
end

function TI:getUsersOnCooldown()
	return {}
end

function TI:resetOptions()
	local materials = getRandomMaterials(8)
	self.votes = {}
	self.options_from = {}
	self.options_to = {}
	for i=1,4 do
		table.insert(self.options_from, materials[i])
		table.insert(self.options_to, materials[i + 4])
	end
end

function getRandomMaterials(count)
	SetRandomSeed(GameGetFrameNum(), -GameGetFrameNum())
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
