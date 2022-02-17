local gui = dofile_once('mods/fungal-twitch/files/gui.lua')

local VOTE_MODE = ModSettingGet("fungal-twitch.VOTE_MODE")
local SHOW_ILLEGAL_MATERIALS = ModSettingGet("fungal-twitch.SHOW_ILLEGAL_MATERIALS")
local SHOW_COOLDOWNS = ModSettingGet("fungal-twitch.SHOW_COOLDOWNS")

local vote_mode = {
	messages = {},
	illegal_materials = {},
	mode = nil
}

function vote_mode:init()
	if (VOTE_MODE == "democracy") then
		self.mode = dofile_once('mods/fungal-twitch/files/democracy.lua')
	elseif (VOTE_MODE == "anarchy") then
		self.mode = dofile_once('mods/fungal-twitch/files/anarchy.lua')
	elseif (VOTE_MODE == "ti") then
		self.mode = dofile_once('mods/fungal-twitch/files/ti.lua')
	end
	gui:init()
end

function vote_mode:initMode()
  self.mode:init()
end

function vote_mode:tick()
	local message = self:getFirstMessage()
	if (message ~= nil) then
		local material = message.message
		if (self.mode:isIllegal(material)) then
			table.insert(self.illegal_materials, material)
		else
			self.mode:handleInput(message.user, material, message.rewardId)
		end
	end
  self.mode:tick()
end

function vote_mode:messageReceived(user, message, rewardId)
	table.insert(self.messages, {
		user = user,
		message = message,
		rewardId = rewardId
	})
end

function vote_mode:getFirstMessage()
	if (self.messages[1] ~= nil) then
		return table.remove(self.messages, 1)
	end
	return nil
end

function vote_mode:handleInput(user, message, rewardId)
  self.mode:handleInput(user, message, rewardId)
end

function vote_mode:drawUI()
  local player = EntityGetWithTag("player_unit")[1]
	if (player == nil or EntityGetIsAlive(player) == false) then
		return
	end

  gui:start()
  local guiObj = gui:getObject()

	local platform_shooter_player = EntityGetFirstComponentIncludingDisabled(player, "PlatformShooterPlayerComponent")
	if (platform_shooter_player) then
		local is_gamepad = ComponentGetValue2(platform_shooter_player, "mHasGamepadControlsPrev")
		if (is_gamepad) then
			GuiOptionsAdd(guiObj, GUI_OPTION.NonInteractive)
			GuiOptionsAdd(guiObj, GUI_OPTION.AlwaysClickable)
		end
	end

	local cooldown_users = self.mode:getUsersOnCooldown()
	local y = 1
	if (SHOW_ILLEGAL_MATERIALS and #self.illegal_materials > 0) then
		local str = "Illegal materials: "
		for _,mat in ipairs(self.illegal_materials) do
			str = str .. mat .. " "
		end
		GuiText(guiObj, 20, y, str)
		y = y + 10
	end
	if (SHOW_COOLDOWNS and #cooldown_users > 0) then
		local str = "Cooldowns: "
		for _,user in ipairs(cooldown_users) do
			str = str .. user .. " "
		end
		GuiText(guiObj, 20, y, str)
	end

	if (self.mode:hasUI() == true) then
		local from_table = self.mode:getOptionsFrom()
		local to_table = self.mode:getOptionsTo()
		local cooldown = self.mode:getCooldown()

		GuiText(guiObj, 10, 290, cooldown > 0 and (string.format("%.0f", cooldown) .. " seconds left") or "Waiting for enough materials to shift")
		GuiText(guiObj, 10, 300, "Material FROM")
		for i,obj in ipairs(from_table) do
			if (i > 5) then
				break
			end
			GuiText(guiObj, 10, 300 + i*10, obj.text)
		end

		GuiText(guiObj, 310, 300, "Material TO")
		for i,obj in ipairs(to_table) do
			if (i > 5) then
				break
			end
			GuiText(guiObj, 310, 300 + i*10, obj.text)
		end
	end

	gui:finish()
end

return vote_mode
