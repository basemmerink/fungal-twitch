dofile_once("data/scripts/perks/perk.lua")
local pollnet = dofile_once('mods/fungal-twitch/lib/pollnet.lua')
local socket = pollnet.open_ws('ws://localhost:9444')
local LOG_SHIFT_RESULT_IN_GAME = ModSettingGet("fungal-twitch.LOG_SHIFT_RESULT_IN_GAME")
local LOG_SHIFT_RESULT_IN_TWITCH = ModSettingGet("fungal-twitch.LOG_SHIFT_RESULT_IN_TWITCH")
local INDIVIDUAL_USER_COOLDOWN_IN_SECONDS = ModSettingGet("fungal-twitch.INDIVIDUAL_USER_COOLDOWN_IN_SECONDS")
local START_WITH_PEACE = ModSettingGet("fungal-twitch.START_WITH_PEACE")
local START_WITH_BREATHLESS = ModSettingGet("fungal-twitch.START_WITH_BREATHLESS")

local fromUser = ""
local toUser = ""
local fromMaterial = ""
local toMaterial = ""

local cooldowns = {}

function OnWorldPreUpdate()
	local success, data = socket:poll()
	if (success and data and string.len(data) > 0) then
		local command = {}
		for key in string.gmatch(data, '[^%s]+') do
			table.insert(command, key)
		end

		if (#command < 3) then
			return
		end

		local user = command[1]
		local method = command[2]
		local material = command[3]

		local cooldown = getCooldown(user)
		if (cooldown > 0) then
			socket:send(user .. ", your cooldown is " .. string.format("%.0f", cooldown)  .. " seconds")
			return
		end

		if (method == "from") then
			fromUser = user
			fromMaterial = material
		end
		if (method == "to") then
			toUser = user
			toMaterial = material
		end

		if (fromMaterial ~= "" and toMaterial ~= "") then
			local time = GameGetRealWorldTimeSinceStarted()
			local mat1 = CellFactory_GetType(fromMaterial)
			local mat2 = CellFactory_GetType(toMaterial)
			cooldowns[fromUser] = time
			cooldowns[toUser] = time
			fromMaterial = ""
			toMaterial = ""
			if (mat1 > -1 and mat2 > -1) then
				local mat1String = GameTextGetTranslatedOrNot(CellFactory_GetUIName(mat1))
				local mat2String = GameTextGetTranslatedOrNot(CellFactory_GetUIName(mat2))
				ConvertMaterialEverywhere(mat1, mat2)
				if (LOG_SHIFT_RESULT_IN_GAME) then
					GamePrintImportant("Shifting from " .. mat1String .. " to " .. mat2String)
				end
				if (LOG_SHIFT_RESULT_IN_TWITCH) then
					socket:send("(" .. fromUser .. ") " .. mat1String .. " -> " .. mat2String .. " (" .. toUser .. ")")
				end
			end
		end
	end
end

function OnPlayerSpawned(player_entity)
	GamePrintImportant("Connection status: " .. socket:status())

	if (START_WITH_PEACE) then
		givePerk(player_entity, "PEACE_WITH_GODS")
	end
	if (START_WITH_BREATHLESS) then
		givePerk(player_entity, "BREATH_UNDERWATER")
	end
end

function givePerk(player_entity, perk_id)
	local x, y = EntityGetTransform(player_entity)

	local perk_entity = perk_spawn(x, y, perk_id)
	perk_pickup(perk_entity, player_entity, nil, false, false)
end

function getCooldown(username)
	if (cooldowns[username] == nil) then
		return 0
	end
	local time = GameGetRealWorldTimeSinceStarted()
	return cooldowns[username] + INDIVIDUAL_USER_COOLDOWN_IN_SECONDS - time
end
