local pollnet = dofile_once('mods/fungal-twitch/lib/pollnet.lua')
local socket = pollnet.open_ws('ws://localhost:9444')

local LOG_SHIFT_RESULT_IN_GAME = ModSettingGet("fungal-twitch.LOG_SHIFT_RESULT_IN_GAME")
local LOG_SHIFT_RESULT_IN_TWITCH = ModSettingGet("fungal-twitch.LOG_SHIFT_RESULT_IN_TWITCH")

local banned_materials = {}

function getSocket()
  return socket
end

function doShift(from, to)
	if (from ~= nil and from ~= "" and to ~= nil and to ~= "") then
		local mat1 = CellFactory_GetType(from)
		local mat2 = CellFactory_GetType(to)
		if (mat1 > -1 and mat2 > -1) then
			local mat1String = getReadableName(from)
			local mat2String = getReadableName(to)
			ConvertMaterialEverywhere(mat1, mat2)
			if (LOG_SHIFT_RESULT_IN_GAME) then
				GamePrintImportant("Shifting from " .. mat1String .. " to " .. mat2String)
			end
			if (LOG_SHIFT_RESULT_IN_TWITCH) then
				socket:send(mat1String .. " -> " .. mat2String)
			end
			return true
		end
	end
	return false
end

function getReadableName(material)
	return GameTextGetTranslatedOrNot(CellFactory_GetUIName(CellFactory_GetType(material)))
end

function tableSize(tab)
	local n = 0
	for key in pairs(tab) do
		n = n + 1
	end
	return n
end

function banMaterial(material)
  table.insert(banned_materials, material)
end

function unbanMaterial(material)
  for index,value in ipairs(banned_materials) do
      if (value == material) then
        table.remove(banned_materials, index)
        break
      end
  end
end

function isIllegalMaterial(material_name)
	local type = CellFactory_GetType(material_name)
	if (type == -1) then
		return true
	end
	for _,k in ipairs(CellFactory_GetTags(type)) do
		if (k == "[box2d]") then
			return true
		end
	end
	return false
end

function isBannedMaterial(material_name)
	for _,k in ipairs(banned_materials) do
		if (k == material_name) then
			return true
		end
	end
	return false
end
