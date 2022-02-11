dofile_once("data/scripts/perks/perk.lua")
local pollnet = dofile_once('mods/fungal-twitch/lib/pollnet.lua')
local socket = pollnet.open_ws('ws://localhost:9444')

local LOG_SHIFT_RESULT_IN_GAME = ModSettingGet("fungal-twitch.LOG_SHIFT_RESULT_IN_GAME")
local LOG_SHIFT_RESULT_IN_TWITCH = ModSettingGet("fungal-twitch.LOG_SHIFT_RESULT_IN_TWITCH")
local START_WITH_TELEPORT = ModSettingGet("fungal-twitch.START_WITH_TELEPORT")
local START_WITH_PEACE = ModSettingGet("fungal-twitch.START_WITH_PEACE")
local START_WITH_BREATHLESS = ModSettingGet("fungal-twitch.START_WITH_BREATHLESS")
local VOTE_MODE = ModSettingGet("fungal-twitch.VOTE_MODE")
local UNBALANCED_MODE = ModSettingGet("fungal-twitch.UNBALANCED_MODE")
local ANARCHY_COOLDOWN = ModSettingGet("fungal-twitch.ANARCHY_COOLDOWN")
local DEMOCRACY_INTERVAL = ModSettingGet("fungal-twitch.DEMOCRACY_INTERVAL")

local banned_materials = {}

local fromUser = ""
local toUser = ""
local anarchy_cooldowns = {}
local anarchy_users_from = {}
local anarchy_users_to = {}

local last_democracy_tick = 0
local democracy_votes_from = {}
local democracy_votes_to = {}

local gui
local gui_id

function OnModPostInit()
	gui = GuiCreate()
	gui_id = 3355
end

function OnWorldPreUpdate()
	poll()
	if (VOTE_MODE == "democracy") then
		democracyTick()
	end
end

function OnPlayerSpawned(player_entity)
	GamePrintImportant("Connection status: " .. socket:status())

	if (START_WITH_TELEPORT) then
		local x, y = EntityGetTransform(player_entity)
		GamePickUpInventoryItem(player_entity, EntityLoad('data/entities/misc/custom_cards/teleport_projectile_short.xml', x, y), true)
	end

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

function poll()
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

		if (method == "init_banned_materials") then
			for key in string.gmatch(material, '[^,]+') do
				table.insert(banned_materials, key)
			end
			return
		end

		if (isIllegalMaterial(material)) then
			socket:send(user .. ", illegal material: " .. material)
			return
		end
		if (isBannedMaterial(material)) then
			socket:send(user .. ", banned material: " .. material)
			return
		end

		if (method == "ban") then
			table.insert(banned_materials, material)
			socket:send("ban " .. material)
			return
		end
		if (method == "unban") then
			for index,value in ipairs(banned_materials) do
					if (value == material) then
						table.remove(banned_materials, index)
						break
					end
			end
			socket:send("unban " .. material)
			return
		end

		if (VOTE_MODE == "anarchy") then
			doAnarchy(user, method, material)
		end
		if (VOTE_MODE == "democracy") then
			doDemocracy(user, method, material)
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

function democracyTick()
	local time = GameGetRealWorldTimeSinceStarted()
	if (tableSize(democracy_votes_from) > 0 and
			tableSize(democracy_votes_to) > 0 and
			(last_democracy_tick + DEMOCRACY_INTERVAL) < time) then

		local from_table = namesToVotes(democracy_votes_from)
		local to_table = namesToVotes(democracy_votes_to)

		doShift(from_table[1].mat, to_table[1].mat)

		last_democracy_tick = time
		democracy_votes_from = {}
		democracy_votes_to = {}
	end
	drawUI()
end

function tableSize(tab)
	local n = 0
	for key in pairs(tab) do
		n = n + 1
	end
	return n
end

function namesToVotes(originalTable)
	local new_table = {}
	for k, v in pairs(originalTable) do
		new_table[v] = (new_table[v] or 0) + 1
	end

	local items = {}
	for k,v in pairs(new_table) do
		local obj = {}
		obj.mat = k
		obj.amount = v
		table.insert(items, obj)
	end

	table.sort(items, function(a, b)
		return a.amount > b.amount
	end)

	return items
end

function drawUI()
	local player = EntityGetWithTag("player_unit")[1]
	if (player == nil or EntityGetIsAlive(player) == false) then
		return
	end

	gui_id = 3355
	GuiStartFrame(gui)
	GuiIdPushString(gui, "fungal-twitch")

	local platform_shooter_player = EntityGetFirstComponentIncludingDisabled(player, "PlatformShooterPlayerComponent")
	if (platform_shooter_player) then
		local is_gamepad = ComponentGetValue2(platform_shooter_player, "mHasGamepadControlsPrev")
		if (is_gamepad) then
			GuiOptionsAdd(gui, GUI_OPTION.NonInteractive)
			GuiOptionsAdd(gui, GUI_OPTION.AlwaysClickable)
		end
	end

	local from_table = namesToVotes(democracy_votes_from)
	local to_table = namesToVotes(democracy_votes_to)

	local time = last_democracy_tick + DEMOCRACY_INTERVAL - GameGetRealWorldTimeSinceStarted()
	GuiText(gui, 10, 290, time > 0 and (string.format("%.0f", time) .. " seconds left") or "Waiting for enough materials to shift")
	GuiText(gui, 10, 300, "Material FROM")
	for i,obj in ipairs(from_table) do
		if (i > 5) then
			break
		end
		GuiText(gui, 10, 300 + i*10, obj.amount .. ") " .. obj.mat .. " (" .. getReadableName(obj.mat) .. ")")
	end

	GuiText(gui, 300, 300, "Material TO")
	for i,obj in ipairs(to_table) do
		if (i > 5) then
			break
		end
		GuiText(gui, 300, 300 + i*10, obj.amount .. ") " .. obj.mat .. " (" .. getReadableName(obj.mat) .. ")")
	end

	GuiIdPop(gui)
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
				socket:send((#fromUser > 0 and "(" .. fromUser .. ") " or "") .. mat1String .. " -> " .. mat2String .. (#toUser > 0 and " (" .. toUser .. ")" or ""))
			end
			return true
		end
	end
	return false
end

function getReadableName(material)
	return GameTextGetTranslatedOrNot(CellFactory_GetUIName(CellFactory_GetType(material)))
end

function doAnarchy(user, method, material)
	local time = GameGetRealWorldTimeSinceStarted()
	if (anarchy_cooldowns[user] ~= nil) then
		local cooldown = anarchy_cooldowns[user] + ANARCHY_COOLDOWN - time
		if (cooldown > 0) then
			socket:send(user .. ", your cooldown is " .. string.format("%.0f", cooldown)  .. " seconds")
			return
		end
	end

	if (method == "from") then
		fromUser = user
		anarchy_users_from[user] = material
	end
	if (method == "to") then
		toUser = user
		anarchy_users_to[user] = material
	end

	local success = false
	if (UNBALANCED_MODE) then
		success = doShift(anarchy_users_from[user], anarchy_users_to[user])
	else
		success = doShift(anarchy_users_from[fromUser], anarchy_users_to[toUser])
	end

	if (success) then
		anarchy_users_from[fromUser] = nil
		anarchy_users_to[toUser] = nil
		anarchy_cooldowns[fromUser] = time
		anarchy_cooldowns[toUser] = time
	end
end

function doDemocracy(user, method, material)
	if (method == "from") then
		democracy_votes_from[user] = material
	end
	if (method == "to") then
		democracy_votes_to[user] = material
	end
end
