return {
	--GUI: General
	GUI_TRUE = "True",
	GUI_FALSE = "False",
	GUI_YES = "Yes",
	GUI_NO = "No",
	GUI_NONE = "None",

	--GUI: Main Controls
	GUI_TITL = "Third-Person Vehicle Camera Tool",
	GUI_TGL_MOD = "Toggle Mod Functionality",
	GUI_TGL_MOD_TIP = "Enables or disables the mod functionality.",
	GUI_RLD_ALL = "Reload All Presets",
	GUI_RLD_ALL_TIP = "Reloads all data from custom preset files - only needed if files have been changed or added, or if you want to reset the last unsaved changes.\n\nKeep in mind that changes only take effect after exiting and re-entering the vehicle",
	GUI_DMODE = "Developer Mode",
	GUI_DMODE_TIP = "Enables a feature that allows you to create, test, and save your own presets.\n\nAlso adjusts the level of debug output:\n 0 = Disabled\n 1 = Print only\n 2 = Print & Alert\n 3 = Print, Alert & Log",
	GUI_APPLY = "Apply Changes",
	GUI_APPLY_TIP = "Applies the configured values without saving them permanently.\n\nThe vehicle must be exited and re-entered for the changes to become active.",
	GUI_SAVE = "Save Changes Permanently",
	GUI_SAVE_TIP = "Applies the configured values and saves them permanently to \"./presets/%s.lua\".\n\nChanges will only take effect after exiting and re-entering the vehicle.",
	GUI_REST_TIP = "Removes the \"./presets/%s.lua\" to revert to the default preset.\n\nYou must exit and re-enter the vehicle for the changes to take effect",
	GUI_OVWR_CONFIRM = "Replace existing file \"./presets/%s.lua\"?",
	GUI_OPEN_FMAN = "Open Preset File Manager",

	--GUI: Table Headers
	GUI_TBL_HEAD_KEY = "Key",
	GUI_TBL_HEAD_VAL = "Value",
	GUI_TBL_HEAD_LVL = "Level",
	GUI_TBL_HEAD_ANG = "Angle",
	GUI_TBL_HEAD_X = "X Offset",
	GUI_TBL_HEAD_Y = "Y Offset",
	GUI_TBL_HEAD_Z = "Z Offset",

	--GUI: Table Labels
	GUI_TBL_LABL_VEH = "Vehicle",
	GUI_TBL_LABL_APP = "Appearance",
	GUI_TBL_LABL_CAMID = "Camera",
	GUI_TBL_LABL_PSET = "Preset",
	GUI_TBL_LABL_ISDEF = "Is Default",

	--GUI: Table Values
	GUI_TBL_VAL_PSET_TIP = "When saving, the name \"%s\" is used. The new name must exactly match the value of Vehicle or Appearance, or be at least a prefix of one of them.\n\nPlease note that you only need to change the name manually if you want to apply a preset to multiple identical vehicles, so you do not need to create a separate preset for each color variation.\n\n\nMatching Priorities (only the first match is loaded):\n\n1. Vehicle: (e.g. \"%s.lua\")\n2. Appearance (e.g. \"%s.lua\")\n3. Prefix of Vehicle: (e.g. \"%s.lua\")\n4. Prefix of Appearance: (e.g. \"%s.lua\")\n\n\nPlease ensure that your new preset name has the correct priority, otherwise, you will need to delete the one that will steal its priority. Take a look at the Preset File Manager to delete presets.",
	GUI_TBL_VAL_ANG_TIP = "Min: %s\nMax: %s",
	GUI_TBL_VAL_X_TIP = "Min: %s\nMax: %s\n\nIncrease: Right\nDecrease: Left",
	GUI_TBL_VAL_Y_TIP = "Min: %s\nMax: %s\n\nIncrease: Closer\nDecrease: Farther",
	GUI_TBL_VAL_Z_TIP = "Min: %s\nMax: %s\n\nIncrease: Up\nDecrease: Down",

	--GUI: Preset File Manager
	GUI_FMAN_TITLE = "Preset File Manager",
	GUI_FMAN_HEAD_NAME = "Filename",
	GUI_FMAN_HEAD_ACTION = "Actions",
	GUI_FMAN_DEL_BTN = "Delete##%s",
	GUI_FMAN_DEL_CONFIRM = "Delete file \"%s\"?",
	GUI_FMAN_NO_PSETS = "No presets have been created yet.",

	--LOG: Info
	LOG_CAM_PSET = "Camera preset: '%s'",
	LOG_CAM_OSET_DONE = "Camera offset '%s' is complete.",
	LOG_FOUND_DEF = "Default preset '%s' found.",
	LOG_LINK_PSET = "Following linked preset (%d): '%s'",
	LOG_LOAD_PSET = "Preset '%s' has been loaded from './%s/%s'.",
	LOG_MOD_OFF = "Mod has been disabled!",
	LOG_MOD_ON = "Mod has been enabled!",
	LOG_PSET_SAVED = "File './presets/%s.lua' was saved successfully.",
	LOG_PSET_UPD = "The preset '%s' has been updated.",
	LOG_PSETS_RLD = "Presets have been reloaded.",
	LOG_REST_ALL = "Restored all default presets.",
	LOG_REST_PSET = "Preset for ID '%s' has been restored.",
	LOG_REST_PSETS = "Restored %d/%d changed preset(s).",
	LOG_DEL_SUCCESS = "Deleted preset '%s'.",

	--LOG: Warnings
	LOG_BLANK_NAME = "The new preset name cannot be blank.",
	LOG_CLEAR_PSETS = "Cleared all loaded camera offset presets.",
	LOG_FILE_EXIST = "File './%s' already exists, and overwrite is disabled.",
	LOG_NO_PSET_FOUND = "No preset found.",
	LOG_NAMES_MISM = "The new preset name must be '%s', '%s', or a prefix of one of them; otherwise, it will not be applied and will be ignored.",
	LOG_NAME_MISM = "The new preset name must be '%s' or a prefix of it; otherwise, it will not be applied and will be ignored.",
	LOG_PSET_NOT_CHANGED = "No changes were made to preset '%s' compared to the default preset '%s'.",
	LOG_PSET_NOT_SAVED = "File './presets/%s.lua' could not be saved.",
	LOG_SKIP_PSET = "Skipping already loaded preset: '%s' ('./%s/%s').",

	--LOG: Errors
	LOG_DIR_NOT_EXIST = "You cannot delete the entire directory under './%s'.",
	LOG_DEFS_INCOMP = "The default presets are incomplete.",
	LOG_NO_CAM_OSET = "Could not retrieve camera offset: '%s'.",
	LOG_FAIL_APPLY = "Failed to apply preset.",
	LOG_FAIL_LOAD = "Failed to load preset './%s/%s': %s",
	LOG_BAD_PSET = "Invalid or failed preset './%s/%s'.",
	LOG_MISS_DEF = "Default preset '%s' could not be found.",
	LOG_NO_DEF_PSET = "Default preset '%s' for '%s' not found.",
	LOG_NO_PSET_FOR_LVL = "No preset provided for level '%s'.",
	LOG_DEL_FAILURE = "Failed to delete preset '%s'."
}