local pollnet = dofile_once('mods/fungal-twitch/lib/pollnet.lua')
local socket = pollnet.open_ws('ws://localhost:9444')
local LOG_SHIFT_RESULT_IN_GAME = ModSettingGet("fungal-twitch.LOG_SHIFT_RESULT_IN_GAME")
local LOG_FAULTY_MATERIAL = ModSettingGet("fungal-twitch.LOG_FAULTY_MATERIAL")

function OnWorldPreUpdate()
	local success, data = socket:poll()
	if (success and data and string.len(data) > 0) then
		local mats = {}
		for mat in string.gmatch(data, '[^%s]+') do
			table.insert(mats, mat)
		end
		local mat1 = CellFactory_GetType(mats[1])
		local mat2 = CellFactory_GetType(mats[2])
		if (mat1 > -1) then
			if (mat2 > -1) then
				if (LOG_SHIFT_RESULT_IN_GAME) then
					GamePrintImportant("Shifting from " .. mats[1] .. " to " .. mats[2])
				end
				ConvertMaterialEverywhere(mat1, mat2)
			elseif (LOG_FAULTY_MATERIAL) then
				GamePrintImportant("Material " .. mats[2] .. " does not exist")
			end
		elseif (LOG_FAULTY_MATERIAL) then
			GamePrintImportant("Material " .. mats[1] .. " does not exist")
		end
	end
end

function OnPlayerSpawned( player_entity )
	GamePrintImportant("Connection status: " .. socket:status())
end
