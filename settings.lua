dofile("data/scripts/lib/mod_settings.lua")

local lastMode = ModSettingGet("fungal-twitch.VOTE_MODE")

function isMode(mode)
	if (lastMode == nil) then
		return mode == "anarchy"
	end
	return lastMode == mode
end

function mod_setting_bool_custom( mod_id, gui, in_main_menu, im_id, setting )
	local value = ModSettingGetNextValue( mod_setting_get_id(mod_id,setting) )
	local text = setting.ui_name .. " - " .. GameTextGet( value and "$option_on" or "$option_off" )

	if GuiButton( gui, im_id, mod_setting_group_x_offset, 0, text ) then
		ModSettingSetNextValue( mod_setting_get_id(mod_id,setting), not value, false )
	end

	mod_setting_tooltip( mod_id, gui, in_main_menu, setting )
end

function mod_setting_change_callback( mod_id, gui, in_main_menu, setting, old_value, new_value  )
	lastMode = new_value
	GamePrint( tostring(old_value) .. " - " .. tostring(new_value) )
end

local mod_id = "fungal-twitch"
mod_settings_version = 1

function getModSettings()
return
{
	{
		category_id = "mod_settings",
		ui_name = "Fungal Twitch Settings",
		ui_description = "Settings for the Fungal Twitch mod",
		settings = {
			{
				id = "LOG_SHIFT_RESULT_IN_GAME",
				ui_name = "Log a shift result ingame",
				ui_description = "Toggle to show a message with the shift details when it happens or not.",
				value_default = true,
				scope = MOD_SETTING_SCOPE_NEW_GAME,
			},
			{
				id = "LOG_SHIFT_RESULT_IN_TWITCH",
				ui_name = "Log a shift result in Twitch",
				ui_description = "Toggle to send a message to Twitch with the shift details when it happens or not.",
				value_default = true,
				scope = MOD_SETTING_SCOPE_NEW_GAME,
			},
			{
				id = "START_WITH_TELEPORT",
				ui_name = "Start with a small teleport bolt",
				ui_description = "",
				value_default = false,
				scope = MOD_SETTING_SCOPE_NEW_GAME,
			},
			{
				id = "START_WITH_PEACE",
				ui_name = "Start with the perk Peace with the gods",
				ui_description = "",
				value_default = false,
				scope = MOD_SETTING_SCOPE_NEW_GAME,
			},
			{
				id = "START_WITH_BREATHLESS",
				ui_name = "Start with the perk Breathless",
				ui_description = "",
				value_default = false,
				scope = MOD_SETTING_SCOPE_NEW_GAME,
			},
			{
				ui_fn = mod_setting_vertical_spacing,
				not_setting = true,
			},
			{
				id = "VOTE_MODE",
				ui_name = "Vote mode",
				ui_description = "Toggle me",
				value_default = "anarchy",
				values = { {"anarchy","[Anarchy]"}, {"democracy","[Democracy]"}, {"ti","[TI]"} },
				scope = MOD_SETTING_SCOPE_RUNTIME,
				change_fn = mod_setting_change_callback,
			},
			{
				ui_fn = mod_setting_vertical_spacing,
				not_setting = true,
			},
			{
				id = "txt1",
				ui_name = "- Anarchy mode shifts as soon as the from and to materials are set",
				not_setting = true,
				hidden = not isMode("anarchy")
			},
			{
				id = "txt2",
				ui_name = "- Democracy mode collects votes and shifts at a set interval",
				not_setting = true,
				hidden = not isMode("democracy")
			},
			{
				id = "txt3",
				ui_name = "- TI mode uses random materials and lets chat vote like Twitch Integration",
				not_setting = true,
				hidden = not isMode("ti")
			},
			{
				ui_fn = mod_setting_vertical_spacing,
				not_setting = true,
			},
			{
				id = "UNBALANCED_MODE",
				ui_name = "Unbalanced mode",
				ui_description = "Everyone can fully control a shift, both from and to",
				value_default = false,
				scope = MOD_SETTING_SCOPE_NEW_GAME,
				hidden = not isMode("anarchy")
			},
			{
        id = "ANARCHY_COOLDOWN",
        ui_name = "Anarchy cooldown per user",
        ui_description = "",
				value_default = 60,
				value_min = 0,
				value_max = 300,
				value_display_multiplier = 1,
				value_display_formatting = " $0 seconds",
				scope = MOD_SETTING_SCOPE_NEW_GAME,
				hidden = not isMode("anarchy")
      },
			{
        id = "DEMOCRACY_INTERVAL",
        ui_name = "Democracy interval",
        ui_description = "At what interval will shifts happen",
				value_default = 30,
				value_min = 10,
				value_max = 150,
				value_display_multiplier = 1,
				value_display_formatting = " $0 seconds",
				scope = MOD_SETTING_SCOPE_NEW_GAME,
				hidden = not isMode("democracy")
      },
			{
        id = "TI_INTERVAL",
        ui_name = "TI interval",
        ui_description = "At what interval will shifts happen",
				value_default = 45,
				value_min = 10,
				value_max = 150,
				value_display_multiplier = 1,
				value_display_formatting = " $0 seconds",
				scope = MOD_SETTING_SCOPE_NEW_GAME,
				hidden = not isMode("ti")
      },
		}
	},

}

end

function ModSettingsUpdate( init_scope )
	local old_version = mod_settings_get_version( mod_id )
	mod_settings_update( mod_id, getModSettings(), init_scope )
end

function ModSettingsGuiCount()
	return mod_settings_gui_count( mod_id, getModSettings() )
end

function ModSettingsGui( gui, in_main_menu )
	mod_settings_gui( mod_id, getModSettings(), gui, in_main_menu )
end
