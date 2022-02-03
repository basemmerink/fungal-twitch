dofile("data/scripts/lib/mod_settings.lua")

function mod_setting_bool_custom( mod_id, gui, in_main_menu, im_id, setting )
	local value = ModSettingGetNextValue( mod_setting_get_id(mod_id,setting) )
	local text = setting.ui_name .. " - " .. GameTextGet( value and "$option_on" or "$option_off" )

	if GuiButton( gui, im_id, mod_setting_group_x_offset, 0, text ) then
		ModSettingSetNextValue( mod_setting_get_id(mod_id,setting), not value, false )
	end

	mod_setting_tooltip( mod_id, gui, in_main_menu, setting )
end

function mod_setting_change_callback( mod_id, gui, in_main_menu, setting, old_value, new_value  )
	print( tostring(new_value) )
end

local mod_id = "fungal-twitch"
mod_settings_version = 1
mod_settings =
{
	{
		category_id = "mod_settings",
		ui_name = "Fungal Twitch Settings",
		ui_description = "Settings for the Fungal Twitch mod",
		settings = {
      {
        id = "LOG_SHIFT_RESULT_IN_GAME",
        ui_name = "Log a shift result",
        ui_description = "Toggle to show a message with the shift details when it happens or not.",
        value_default = true,
        scope = MOD_SETTING_SCOPE_NEW_GAME,
      },
			{
				id = "START_WITH_PEACE",
				ui_name = "Start with Peace with the gods",
				ui_description = "Toggle to start the run with the perk Peace with the gods or not.",
				value_default = false,
				scope = MOD_SETTING_SCOPE_NEW_GAME,
			},
			{
				id = "START_WITH_BREATHLESS",
				ui_name = "Start with Breathless",
				ui_description = "Toggle to start the run with the perk Breathless or not.",
				value_default = false,
				scope = MOD_SETTING_SCOPE_NEW_GAME,
			},
		}
	},

}

function ModSettingsUpdate( init_scope )
	local old_version = mod_settings_get_version( mod_id )
	mod_settings_update( mod_id, mod_settings, init_scope )
end

function ModSettingsGuiCount()
	return mod_settings_gui_count( mod_id, mod_settings )
end

function ModSettingsGui( gui, in_main_menu )
	mod_settings_gui( mod_id, mod_settings, gui, in_main_menu )
end
