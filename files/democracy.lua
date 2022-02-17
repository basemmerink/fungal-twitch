dofile_once("mods/fungal-twitch/files/utils.lua")

local DEMOCRACY_INTERVAL = ModSettingGet("fungal-twitch.DEMOCRACY_INTERVAL")

local REWARD_FROM_ID = ModSettingGet("fungal-twitch.REWARD_FROM_ID")
local REWARD_TO_ID = ModSettingGet("fungal-twitch.REWARD_TO_ID")

local Democracy = {
	last_tick = nil,
	votes_from = {},
	votes_to = {}
}

function Democracy:init()
	self.last_tick = GameGetRealWorldTimeSinceStarted()
	REWARD_TO_ID = ModSettingGet("fungal-twitch.REWARD_TO_ID")
	REWARD_FROM_ID = ModSettingGet("fungal-twitch.REWARD_FROM_ID")
end

function Democracy:tick()
	if (tableSize(self.votes_from) > 0 and
			tableSize(self.votes_to) > 0 and
			self:getCooldown() <= 0) then
    self.last_tick = GameGetRealWorldTimeSinceStarted()

		local from_table = namesToVotes(self.votes_from)
		local to_table = namesToVotes(self.votes_to)

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

		self.votes_from = {}
		self.votes_to = {}
	end
end

function Democracy:handleInput(user, message, rewardId)
	if (rewardId == nil) then
    return
  elseif (rewardId == REWARD_FROM_ID) then
    self.votes_from[user] = message
  elseif (rewardId == REWARD_TO_ID) then
    self.votes_to[user] = message
  else
    return
  end
end

function Democracy:hasUI()
  return true
end

function Democracy:getOptionsFrom()
  return namesToVotes(self.votes_from)
end

function Democracy:getOptionsTo()
  return namesToVotes(self.votes_to)
end

function Democracy:isIllegal(material)
	return isIllegalMaterial(material) or isBannedMaterial(material)
end

function Democracy:getCooldown()
  return self.last_tick + DEMOCRACY_INTERVAL - GameGetRealWorldTimeSinceStarted()
end

function Democracy:getUsersOnCooldown()
	return {}
end

function namesToVotes(originalTable)
	local new_table = {}
	for k, v in pairs(originalTable) do
		new_table[v] = (new_table[v] or 0) + 1
	end

	local items = {}
	for k,v in pairs(new_table) do
		local obj = {}
		obj.material = k
    obj.amount = v
    obj.text = k .. " (" .. getReadableName(k) .. ") [" .. v .. "]"
		table.insert(items, obj)
	end

	table.sort(items, function(a, b)
    return a.amount > b.amount
	end)

	return items
end

return Democracy
