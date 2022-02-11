dofile_once("mods/fungal-twitch/files/utils.lua")

local DEMOCRACY_INTERVAL = ModSettingGet("fungal-twitch.DEMOCRACY_INTERVAL")

local last_tick
local votes_from = {}
local votes_to = {}

local Democracy = {}

function Democracy:init()
	last_tick = GameGetRealWorldTimeSinceStarted()
end

function Democracy:tick()
	if (tableSize(votes_from) > 0 and
			tableSize(votes_to) > 0 and
			self:getCooldown() <= 0) then
    last_tick = GameGetRealWorldTimeSinceStarted()

		local from_table = namesToVotes(votes_from)
		local to_table = namesToVotes(votes_to)

		doShift(from_table[1].material, to_table[1].material)

		votes_from = {}
		votes_to = {}
	end
	drawUI()
end

function Democracy:handleInput(user, method, material)
  if (method == "from") then
    votes_from[user] = material
  end
  if (method == "to") then
    votes_to[user] = material
  end
end

function Democracy:hasUI()
  return true
end

function Democracy:getTableWidth()
	return 290
end

function Democracy:getOptionsFrom()
  return namesToVotes(votes_from)
end

function Democracy:getOptionsTo()
  return namesToVotes(votes_to)
end

function Democracy:getCooldown()
  return last_tick + DEMOCRACY_INTERVAL - GameGetRealWorldTimeSinceStarted()
end

function Democracy:isIllegalMaterial(material)
	return isIllegalMaterial(material)
end

function Democracy:isBannedMaterial(material)
	return isBannedMaterial(material)
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
    obj.text = v .. ") " .. k .. " (" .. getReadableName(k) .. ")"
		table.insert(items, obj)
	end

	table.sort(items, function(a, b)
    return a.amount > b.amount
	end)

	return items
end

return Democracy
