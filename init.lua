ModLuaFileAppend("data/scripts/streaming_integration/event_utilities.lua", "mods/fungal-twitch/files/event_utilities.lua")

dofile("data/scripts/lib/utilities.lua")
dofile_once("data/scripts/perks/perk.lua")

local gui = dofile_once('mods/fungal-twitch/files/gui.lua')
local vote_mode = dofile_once('mods/fungal-twitch/files/vote_mode.lua')

local START_WITH_TELEPORT = ModSettingGet("fungal-twitch.START_WITH_TELEPORT")
local START_WITH_FIRESTONE = ModSettingGet("fungal-twitch.START_WITH_FIRESTONE")
local START_WITH_PEACE = ModSettingGet("fungal-twitch.START_WITH_PEACE")
local START_WITH_BREATHLESS = ModSettingGet("fungal-twitch.START_WITH_BREATHLESS")

local REWARD_FROM_ID = ModSettingGet("fungal-twitch.REWARD_FROM_ID") or ""
local REWARD_TO_ID = ModSettingGet("fungal-twitch.REWARD_TO_ID") or ""

local lastMessage = nil

function OnModPostInit()
	vote_mode:init()
	gui:init()
end

function OnWorldPreUpdate()
	if (GlobalsGetValue("fungal-twitch.hasNewMessage") == "true") then
		vote_mode:messageReceived(
			GlobalsGetValue("fungal-twitch.lastUser"),
			GlobalsGetValue("fungal-twitch.lastMessage"),
			GlobalsGetValue("fungal-twitch.lastRewardId"))
		GlobalsSetValue("fungal-twitch.hasNewMessage", "false")
	end

	if (StreamingGetIsConnected() and REWARD_FROM_ID ~= "" and REWARD_TO_ID ~= "") then
		vote_mode:tick()
		vote_mode:drawUI()
	else
		drawUI()
	end
end

function drawUI()
	local player = EntityGetWithTag("player_unit")[1]
	if (player == nil or EntityGetIsAlive(player) == false) then
		return
	end

	gui:start()
	local guiObj = gui:getObject()
	local guiId = gui:getId()

	if (player) then
		local platform_shooter_player = EntityGetFirstComponentIncludingDisabled(player, "PlatformShooterPlayerComponent")
		if (platform_shooter_player) then
			local is_gamepad = ComponentGetValue2(platform_shooter_player, "mHasGamepadControlsPrev")
			if (is_gamepad) then
				GuiOptionsAdd(guiObj, GUI_OPTION.NonInteractive)
				GuiOptionsAdd(guiObj, GUI_OPTION.AlwaysClickable)
			end
		end
	end

	local screenWidth, screenHeight = GuiGetScreenDimensions(guiObj)
	local centerX, centerY = screenWidth / 2, screenHeight / 2
	local width, height = 300, 100
	local method = REWARD_FROM_ID == "" and "FROM" or "TO"

	--GuiImageNinePiece(guiObj, guiId, centerX - width / 2, centerY - height / 2, width, height, 1)
	GuiOptionsAdd(guiObj, GUI_OPTION.Align_HorizontalCenter)
	GuiBeginAutoBox(guiObj)

	GuiZSet(guiObj, 1)
	if (not StreamingGetIsConnected()) then
		GuiText(guiObj, centerX, centerY, "Please go to Options > Streaming and connect to twitch")
	else
		if (lastMessage == nil) then
			lastMessage = vote_mode:getFirstMessage()
		end
		if (lastMessage == nil) then
			GuiText(guiObj, centerX, centerY - 20, "Please navigate to your twitch dashboard and create a channel point redemption for the " .. method .. " material")
			GuiText(guiObj, centerX, centerY - 10, "! Make sure that viewers are required to enter a message !")
			GuiText(guiObj, centerX, centerY, "It is adviced to make it really cheap and put no cooldown")
			GuiText(guiObj, centerX, centerY + 20, "After you have done this, redeem the " .. method .. " redemption")
		elseif (lastMessage.rewardId ~= "") then
			GuiText(guiObj, centerX, centerY - 40, lastMessage.user .. ": " .. lastMessage.message)
			GuiText(guiObj, centerX, centerY - 20, "Did " .. lastMessage.user .. " just redeem the " .. method .. "?")
			if (GuiButton(guiObj, guiId + 1, centerX + 30, centerY + 35, "[Yes]")) then
				ModSettingSet("fungal-twitch.REWARD_" .. method .. "_ID", lastMessage.rewardId)
				if (method == "FROM") then
					REWARD_FROM_ID = lastMessage.rewardId
				else
					REWARD_TO_ID = lastMessage.rewardId
				end
				vote_mode:initMode()
				lastMessage = nil
			end
			if (GuiButton(guiObj, guiId + 2, centerX - 30, centerY + 35, "[No]")) then
				lastMessage = nil
			end
		else
			lastMessage = nil
		end

	end

	GuiZSetForNextWidget(guiObj, 2)
	GuiEndAutoBoxNinePiece(guiObj)

	gui:finish()
end

function OnPlayerSpawned(player_entity)
	vote_mode:initMode()
	StreamingSetVotingEnabled(false)
	if (StreamingGetIsConnected()) then
		GamePrint("Connected to Twitch")
	end

	if (START_WITH_TELEPORT) then
		pickupItem(player_entity, "data/entities/misc/custom_cards/teleport_projectile_short.xml")
	end
	if (START_WITH_FIRESTONE) then
		pickupItem(player_entity, "data/entities/items/pickup/brimstone.xml")
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

function pickupItem(player_entity, item)
	local x, y = EntityGetTransform(player_entity)
	GamePickUpInventoryItem(player_entity, EntityLoad(item, x, y), true)
end
