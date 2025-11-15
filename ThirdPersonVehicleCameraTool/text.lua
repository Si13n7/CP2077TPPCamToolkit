return {
	--GUI: General
	GUI_YES = "Yes",
	GUI_NO = "No",

	--GUI: Main Controls
	GUI_TITLE = "Third-Person Vehicle Camera Tool",
	GUI_MOD_TOGGLE = "Toggle Mod Functionality",
	GUI_MOD_TOGGLE_TOOLTIP = "Enables or disables the mod functionality.",
	GUI_PRESETS_RELOAD = "Reload All Presets",
	GUI_PRESETS_RELOAD_TOOLTIP = "Reloads all data from custom preset files - only needed if files have been changed or added, or if you want to reset the last unsaved changes.\n\nPlease note that you need to exit and re-enter the vehicle for the changes to take effect.",
	GUI_DEVMODE = "Developer Mode",
	GUI_DEVMODE_TOOLTIP = "Enables a feature that allows you to create, test, and save your own presets.\n\nAlso adjusts the level of debug output:\n 0 = Disabled\n 1 = Print only\n 2 = Print & Alert\n 3 = Print, Alert & Log",
	GUI_PRESET_APPLY = "Apply Changes",
	GUI_PRESET_APPLY_TOOLTIP = "Applies the configured values without saving them permanently.\n\nPlease note that you need to exit and re-enter the vehicle for the changes to take effect.",
	GUI_PRESET_SAVE = "Save Changes to File",
	GUI_PRESET_SAVE_TOOLTIP = "Saves the modified preset permanently under \"./presets/%s.lua\".\n\nPlease note that overwriting existing presets is not allowed by default to prevent accidental loss of data.",
	GUI_ALLOW_OVERWRITE = "Allow Overwriting of Files",
	GUI_ALLOW_OVERWRITE_TOOLTIP = "Enables or disables the ability to overwrite existing preset files.",
	GUI_PRESET_MANAGER = "Open Preset File Manager",
	GUI_FMAN_NO_PRESETS = "No presets have been created yet.",

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
	GUI_TABLE_LABEL_CAMERA_ID = "Camera ID",
	GUI_TABLE_LABEL_PRESET = "Preset",
	GUI_TABLE_LABEL_PRESET_TOOLTIP = "When saving, the name \"%s\" is automatically used. The new name must be at least a prefix of it.\n\nPlease note that you only need to change the name manually if you want to apply a preset to multiple identical vehicles, so you do not need to create a separate preset for each color variation.",
	GUI_TABLE_LABEL_IS_DEFAULT = "Is Default",

	--GUI: Preset File Manager
	GUI_FMAN_TITLE = "Preset File Manager",
	GUI_FMAN_HEADER_NAME = "Filename",
	GUI_FMAN_HEADER_ACTIONS = "Actions",
	GUI_FMAN_DELETE_BUTTON = "Delete##%s",
	GUI_FMAN_DELETE_CONFIRM = "Delete file \"%s\"?",

	--LOG: Info
	LOG_CAMERA_ID = "Camera preset ID: '%s'",
	LOG_CAMERA_OFFSET_COMPLETE = "Camera offset '%s' is complete.",
	LOG_FOUND_DEFAULT = "Default preset '%s' found.",
	LOG_LINKED_PRESET = "Following linked preset (%d): '%s'",
	LOG_LOADED_PRESET = "Loaded preset '%s' from './%s/%s'.",
	LOG_MOD_DISABLED = "Mod has been disabled!",
	LOG_MOD_ENABLED = "Mod has been enabled!",
	LOG_PRESET_SAVED = "File './presets/%s.lua' was saved successfully.",
	LOG_PRESET_UPDATED = "The preset '%s' has been updated.",
	LOG_PRESETS_RELOADED = "Presets have been reloaded!",
	LOG_RESTORED_ALL_DEFAULTS = "Restored all default presets.",
	LOG_RESTORED_PRESET = "Preset for ID '%s' has been restored.",
	LOG_RESTORED_SOME_PRESETS = "Restored %d/%d changed preset(s).",
	LOG_VEHICLE = "Mounted vehicle: '%s'",
	LOG_DELETE_SUCCESS = "Deleted preset '%s'.",

	--LOG: Warnings
	LOG_BLANK_NAME = "The new preset name cannot be blank.",
	LOG_CLEARED_PRESETS = "Cleared all loaded camera offset presets.",
	LOG_FILE_EXISTS = "File './%s' already exists, and overwrite is disabled.",
	LOG_NO_PRESET_FOUND = "No preset found.",
	LOG_PREFIX_MISMATCH = "The new preset name must be '%s' or a prefix of it; otherwise, it will not be applied and will be ignored.",
	LOG_PRESET_NOT_CHANGED = "No changes were made to preset '%s' compared to the default preset '%s'.",
	LOG_PRESET_NOT_SAVED = "File './presets/%s.lua' could not be saved.",
	LOG_SHORT_NAME = "The new preset name must be at least 2 characters long.",
	LOG_SHADOWED = "A preset with the shorter name ('%s') already exists. The shortest name is always preferred when applying presets. Therefore, you must either delete this preset to use the name '%s', or choose an even shorter name for your new preset to be loaded.",
	LOG_SKIPPED_PRESET = "Skipping already loaded preset: '%s' ('./%s/%s').",

	--LOG: Errors
	LOG_DIR_NOT_EXISTS = "You cannot delete the entire directory under './%s'.",
	LOG_DEFAULTS_INCOMPLETE = "The default presets are incomplete.",
	LOG_COULD_NOT_RETRIEVE = "Could not retrieve camera offset: '%s'.",
	LOG_FAILED_APPLY = "Failed to apply preset.",
	LOG_FAILED_TO_LOAD_PRESET = "Failed to load preset './%s/%s': %s",
	LOG_INVALID_PRESET = "Invalid or failed preset './%s/%s'.",
	LOG_MISSING_DEFAULT = "Default preset '%s' could not be found.",
	LOG_NO_ORIGINAL_PRESET = "Original preset '%s' for '%s' not found.",
	LOG_NO_PRESET_FOR_LEVEL = "No preset provided for level '%s'.",
	LOG_DELETE_FAILURE = "Failed to delete preset '%s'."
}