dofile_once("data/scripts/perks/perk.lua")
dofile_once("mods/fungal-twitch/files/utils.lua")

local Anarchy = dofile_once('mods/fungal-twitch/files/anarchy.lua')
local Democracy = dofile_once('mods/fungal-twitch/files/democracy.lua')
local TI = dofile_once('mods/fungal-twitch/files/ti.lua')

local START_WITH_TELEPORT = ModSettingGet("fungal-twitch.START_WITH_TELEPORT")
local START_WITH_PEACE = ModSettingGet("fungal-twitch.START_WITH_PEACE")
local START_WITH_BREATHLESS = ModSettingGet("fungal-twitch.START_WITH_BREATHLESS")
local VOTE_MODE = ModSettingGet("fungal-twitch.VOTE_MODE")

local gui
local gui_id

local mode

function OnModPostInit()
	gui = GuiCreate()
	gui_id = 3355

	if (VOTE_MODE == "democracy") then
		mode = Democracy
	elseif (VOTE_MODE == "anarchy") then
		mode = Anarchy
	elseif (VOTE_MODE == "ti") then
		mode = TI
	end
end

function OnWorldPreUpdate()
	poll()
	mode:tick()
	drawUI()
end

function OnPlayerSpawned(player_entity)
	mode:init()
	GamePrint("[Fungal Twitch] Connection status: " .. getSocket():status())

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
	local success, data = getSocket():poll()
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
				banMaterial(key)
			end
			return
		end

		if (VOTE_MODE ~= "ti" and mode:isIllegalMaterial(material)) then
			getSocket():send(user .. ", illegal material: " .. material)
			return
		end

		if (method == "ban") then
			banMaterial(material)
			getSocket():send("ban " .. material)
			return
		end
		if (method == "unban") then
			unbanMaterial(material)
			getSocket():send("unban " .. material)
			return
		end

		if (mode:isBannedMaterial(material)) then
			getSocket():send(user .. ", banned material: " .. material)
			return
		end

		mode:handleInput(user, method, material)
	end
end

function drawUI()
	if (mode:hasUI() == false) then
		return
	end

	local player = EntityGetWithTag("player_unit")[1]
	if (player == nil or EntityGetIsAlive(player) == false) then
		return
	end
	SetRandomSeed(EntityGetTransform(player))

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

	local from_table = mode:getOptionsFrom()
	local to_table = mode:getOptionsTo()
	local cooldown = mode:getCooldown()

	GuiText(gui, 10, 290, cooldown > 0 and (string.format("%.0f", cooldown) .. " seconds left") or "Waiting for enough materials to shift")
	GuiText(gui, 10, 300, "Material FROM")
	for i,obj in ipairs(from_table) do
		if (i > 5) then
			break
		end
		GuiText(gui, 10, 300 + i*10, obj.text)
	end

	local tableWidth = mode:getTableWidth() + 10
	GuiText(gui, tableWidth, 300, "Material TO")
	for i,obj in ipairs(to_table) do
		if (i > 5) then
			break
		end
		GuiText(gui, tableWidth, 300 + i*10, obj.text)
	end

	GuiIdPop(gui)
end
