dofile_once("data/scripts/perks/perk.lua")
local pollnet = dofile_once('mods/fungal-twitch/lib/pollnet.lua')
local socket = pollnet.open_ws('ws://localhost:9444')
local LOG_SHIFT_RESULT_IN_GAME = ModSettingGet("fungal-twitch.LOG_SHIFT_RESULT_IN_GAME")
local LOG_SHIFT_RESULT_IN_TWITCH = ModSettingGet("fungal-twitch.LOG_SHIFT_RESULT_IN_TWITCH")
local START_WITH_PEACE = ModSettingGet("fungal-twitch.START_WITH_PEACE")
local START_WITH_BREATHLESS = ModSettingGet("fungal-twitch.START_WITH_BREATHLESS")

function OnWorldPreUpdate()
	local success, data = socket:poll()
	if (success and data and string.len(data) > 0) then
		local mats = {}
		for mat in string.gmatch(data, '[^%s]+') do
			table.insert(mats, mat)
		end
		local mat1 = CellFactory_GetType(mats[1])
		local mat2 = CellFactory_GetType(mats[2])
		if (mat1 > -1 and mat2 > -1) then
			local msg = "Shifting from " ..
				GameTextGetTranslatedOrNot(CellFactory_GetUIName(mat1)) ..
				" to " ..
				GameTextGetTranslatedOrNot(CellFactory_GetUIName(mat2))
			if (LOG_SHIFT_RESULT_IN_GAME) then
				GamePrintImportant(msg)
			end
			if (LOG_SHIFT_RESULT_IN_TWITCH) then
				socket:send(msg)
			end
			ConvertMaterialEverywhere(mat1, mat2)
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
