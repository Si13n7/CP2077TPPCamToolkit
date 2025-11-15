return {
	--GUI: General
	GUI_TRUE = "True",
	GUI_FALSE = "False",
	GUI_YES = "Yes",
	GUI_NO = "No",
	GUI_NONE = "None",

	--GUI: Main Controls
	GUI_TITLE = "Third-Person Vehicle Camera Tool",
	GUI_MOD_TOGGLE = "Toggle Mod Functionality",
	GUI_MOD_TOGGLE_TOOLTIP = "Enables or disables the mod functionality.",
	GUI_PRESETS_RELOAD = "Reload All Presets",
	GUI_PRESETS_RELOAD_TOOLTIP = "Reloads all data from custom preset files - only needed if files have been changed or added, or if you want to reset the last unsaved changes.\n\nKeep in mind that changes only take effect after exiting and re-entering the vehicle",
	GUI_DEVMODE = "Developer Mode",
	GUI_DEVMODE_TOOLTIP = "Enables a feature that allows you to create, test, and save your own presets.\n\nAlso adjusts the level of debug output:\n 0 = Disabled\n 1 = Print only\n 2 = Print & Alert\n 3 = Print, Alert & Log",
	GUI_PRESET_APPLY = "Apply Changes",
	GUI_PRESET_APPLY_TOOLTIP = "Applies the configured values without saving them permanently.\n\nThe vehicle must be exited and re-entered for the changes to become active.",
	GUI_PRESET_SAVE = "Apply & Save Changes",
	GUI_PRESET_SAVE_TOOLTIP = "Applies the configured values and saves them permanently to \"./presets/%s.lua\".\n\nChanges will only take effect after exiting and re-entering the vehicle.",
	GUI_PRESET_RESTORE_TOOLTIP = "Removes the \"./presets/%s.lua\" to revert to the default preset.\n\nYou must exit and re-enter the vehicle for the changes to take effect",
	GUI_OVERWRITE_CONFIRM = "Replace existing file \"./presets/%s.lua\"?",
	GUI_PRESET_MANAGER = "Open Preset File Manager",

	--GUI: Table Headers
	GUI_TABLE_HEADER_KEY = "Key",
	GUI_TABLE_HEADER_VALUE = "Value",
	GUI_TABLE_HEADER_LEVEL = "Level",
	GUI_TABLE_HEADER_ANGLE = "Angle",
	GUI_TABLE_HEADER_X = "X Offset",
	GUI_TABLE_HEADER_Y = "Y Offset",
	GUI_TABLE_HEADER_Z = "Z Offset",

	--GUI: Table Labels
	GUI_TABLE_LABEL_VEHICLE = "Vehicle",
	GUI_TABLE_LABEL_APPEARANCE = "Appearance",
	GUI_TABLE_LABEL_CAMERAID = "Camera",
	GUI_TABLE_LABEL_PRESET = "Preset",
	GUI_TABLE_LABEL_IS_DEFAULT = "Is Default",

	--GUI: Table Values
	GUI_TABLE_VALUE_PRESET_TOOLTIP = "When saving, the name \"%s\" is used. The new name must exactly match the value of Vehicle or Appearance, or be at least a prefix of one of them.\n\nPlease note that you only need to change the name manually if you want to apply a preset to multiple identical vehicles, so you do not need to create a separate preset for each color variation.\n\n\nMatching Priorities (only the first match is loaded):\n\n1. Vehicle: (e.g. \"%s.lua\")\n2. Appearance (e.g. \"%s.lua\")\n3. Prefix of Vehicle: (e.g. \"%s.lua\")\n4. Prefix of Appearance: (e.g. \"%s.lua\")\n\n\nPlease ensure that your new preset name has the correct priority, otherwise, you will need to delete the one that will steal its priority. Take a look at the Preset File Manager to delete presets.",
	GUI_TABLE_VALUE_ANGLE_TOOLTIP = "Min: %s\nMax: %s",
	GUI_TABLE_VALUE_X_TOOLTIP = "Min: %s\nMax: %s\n\nIncrease: Right\nDecrease: Left",
	GUI_TABLE_VALUE_Y_TOOLTIP = "Min: %s\nMax: %s\n\nIncrease: Closer\nDecrease: Farther",
	GUI_TABLE_VALUE_Z_TOOLTIP = "Min: %s\nMax: %s\n\nIncrease: Up\nDecrease: Down",

	--GUI: Preset File Manager
	GUI_FMAN_TITLE = "Preset File Manager",
	GUI_FMAN_HEADER_NAME = "Filename",
	GUI_FMAN_HEADER_ACTIONS = "Actions",
	GUI_FMAN_DELETE_BUTTON = "Delete##%s",
	GUI_FMAN_DELETE_CONFIRM = "Delete file \"%s\"?",
	GUI_FMAN_NO_PRESETS = "No presets have been created yet.",

	--LOG: Info
	LOG_CAMERA_PRESET = "Camera preset: '%s'",
	LOG_CAMERA_OFFSET_COMPLETE = "Camera offset '%s' is complete.",
	LOG_FOUND_DEFAULT = "Default preset '%s' found.",
	LOG_LINKED_PRESET = "Following linked preset (%d): '%s'",
	LOG_LOADED_PRESET = "Preset '%s' has been loaded from './%s/%s'.",
	LOG_MOD_DISABLED = "Mod has been disabled!",
	LOG_MOD_ENABLED = "Mod has been enabled!",
	LOG_PRESET_SAVED = "File './presets/%s.lua' was saved successfully.",
	LOG_PRESET_UPDATED = "The preset '%s' has been updated.",
	LOG_PRESETS_RELOADED = "Presets have been reloaded.",
	LOG_RESTORED_ALL_DEFAULTS = "Restored all default presets.",
	LOG_RESTORED_PRESET = "Preset for ID '%s' has been restored.",
	LOG_RESTORED_SOME_PRESETS = "Restored %d/%d changed preset(s).",
	LOG_DELETE_SUCCESS = "Deleted preset '%s'.",

	--LOG: Warnings
	LOG_BLANK_NAME = "The new preset name cannot be blank.",
	LOG_CLEARED_PRESETS = "Cleared all loaded camera offset presets.",
	LOG_FILE_EXISTS = "File './%s' already exists, and overwrite is disabled.",
	LOG_NO_PRESET_FOUND = "No preset found.",
	LOG_NAMES_MISMATCH = "The new preset name must be '%s', '%s', or a prefix of one of them; otherwise, it will not be applied and will be ignored.",
	LOG_NAME_MISMATCH = "The new preset name must be '%s' or a prefix of it; otherwise, it will not be applied and will be ignored.",
	LOG_PRESET_NOT_CHANGED = "No changes were made to preset '%s' compared to the default preset '%s'.",
	LOG_PRESET_NOT_SAVED = "File './presets/%s.lua' could not be saved.",
	LOG_SKIPPED_PRESET = "Skipping already loaded preset: '%s' ('./%s/%s').",

	--LOG: Errors
	LOG_DIR_NOT_EXISTS = "You cannot delete the entire directory under './%s'.",
	LOG_DEFAULTS_INCOMPLETE = "The default presets are incomplete.",
	LOG_COULD_NOT_RETRIEVE = "Could not retrieve camera offset: '%s'.",
	LOG_FAILED_APPLY = "Failed to apply preset.",
	LOG_FAILED_TO_LOAD_PRESET = "Failed to load preset './%s/%s': %s",
	LOG_INVALID_PRESET = "Invalid or failed preset './%s/%s'.",
	LOG_MISSING_DEFAULT = "Default preset '%s' could not be found.",
	LOG_NO_DEFAULT_PRESET = "Default preset '%s' for '%s' not found.",
	LOG_NO_PRESET_FOR_LEVEL = "No preset provided for level '%s'.",
	LOG_DELETE_FAILURE = "Failed to delete preset '%s'."
}