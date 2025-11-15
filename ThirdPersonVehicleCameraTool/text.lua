--[[
==============================================
This file is distributed under the MIT License
==============================================

Third-Person Vehicle Camera Tool

Allows you to adjust third-person perspective
(TPP) camera offsets for any vehicle.

Filename: text.lua
Version: 2025-04-22, 10:38 UTC+01:00 (MEZ)

Copyright (c) 2025, Si13n7 Developments(tm)
All rights reserved.
______________________________________________
--]]


return {
	--GUI: General
	GUI_YES = "\u{f0026} Yes",
	GUI_NO = "\u{f073a} No",
	GUI_NONE = "None",

	--GUI: Main Controls and Tooltips
	GUI_TITL = "Third-Person Vehicle Camera Tool",
	GUI_TGL_MOD = "Toggle Mod Functionality",
	GUI_TGL_MOD_TIP = "Enables or disables the mod functionality.",
	GUI_RLD_ALL = "\u{f054d} Reload All Presets ",
	GUI_RLD_ALL_TIP = "Reloads all data from custom preset files - only needed if files have been changed or added, or if you want to reset the last unsaved changes.\n\nKeep in mind that changes only take effect after exiting and re-entering the vehicle",
	GUI_DMODE = "Developer Mode",
	GUI_DMODE_TIP = "Enables a feature that allows you to create, test, and save your own presets.\n\nAlso adjusts the level of debug output:\n 0. Disabled\n 1. Print only\n 2. Print & Alert\n 3. Print, Alert & Log",
	GUI_APPLY = "\u{f044f} Apply ",
	GUI_APPLY_TIP = "Applies the configured values without saving them permanently.\n\nThe vehicle must be exited and re-entered for the changes to become active.",
	GUI_SAVE = "\u{f0193} Save ",
	GUI_SAVE_TIP = "Applies the configured values and saves them permanently to \"presets/%s.lua\".\n\nChanges will only take effect after exiting and re-entering the vehicle.",
	GUI_REST_TIP = "Removes the \"presets/%s.lua\" to revert to the default preset.\n\nYou must exit and re-enter the vehicle for the changes to take effect",
	GUI_OVWR_CONFIRM = "Replace existing file \"presets/%s.lua\"?",
	GUI_OPEN_FMAN = "\u{f12e3} Preset File Manager ",

	--GUI: Table Label Tooltips
	GUI_TBL_LABL_VEH_TIP = "The name of the vehicle.",
	GUI_TBL_LABL_APP_TIP = "The appearance name of the vehicle.",
	GUI_TBL_LABL_CAMID_TIP = "The camera settings identifier used by this vehicle.",
	GUI_TBL_LABL_OKEY_TIP = "The key used to access the camera settings in TweakDB.",
	GUI_TBL_LABL_OLVLS_TIP = "The camera levels combined with the key to access camera settings in TweakDB.",
	GUI_TBL_LABL_PSET_TIP = "The active camera preset applied to this vehicle.",
	GUI_TBL_LABL_CLO_TIP = "Camera Distance: Close",
	GUI_TBL_LABL_MID_TIP = "Camera Distance: Medium",
	GUI_TBL_LABL_FAR_TIP = "Camera Distance: Far",

	--GUI: Table Value Tooltips
	GUI_TBL_VAL_OKEY_TIP = "This key appears in the vehicle's Tweak YAML file if it overrides 'Camera.VehicleTPP', and you must use the full name without the camera level, for example, \"Low_Close\".",
	GUI_TBL_VAL_OLVLS_TIP = "These levels appear in the vehicle's Tweak YAML file if it overrides 'Camera.VehicleTPP'. You need to enter all available levels here, separated by commas. The order must always follow the pattern: Close, Medium, Far, repeated in that exact sequence. The total number of entries must be divisible by 3. If any levels are missing, you must add dummy entries to keep the correct sequence.",
	GUI_TBL_VAL_PSET_TIP = "When saving, the name \"%s\" is used. The new name must exactly match the value of Vehicle or Appearance, or be at least a prefix of one of them.\n\nPlease note that you only need to change the name manually if you want to apply a preset to multiple identical vehicles, so you do not need to create a separate preset for each color variation.\n\nMatching Priorities (first match is used):\n\u{f0b3a}\u{f010b} Vehicle: (e.g. \"%s\")\n\u{f0b3b}\u{f07ac} Appearance: (e.g. \"%s\")\n\u{f0b3c}\u{f010b} Prefix of Vehicle: (e.g. \"%s\")\n\u{f0b3d}\u{f07ac} Prefix of Appearance: (e.g. \"%s\")\n\nPlease ensure that your new preset name has the correct priority, otherwise, you will need to delete the one that will steal its priority. Take a look at the Preset File Manager to delete presets.",
	GUI_TBL_VAL_ANG_TIP = "Default:|%d|Min:|%d|Max:|%d|In Use:|%d",
	GUI_TBL_VAL_X_TIP = "Default:|%.3f|Min:|%.3f|Max:|%.3f|In Use:|%.3f|Decrease:|Left|Increase:|Right",
	GUI_TBL_VAL_Y_TIP = "Default:|%.3f|Min:|%.3f|Max:|%.3f|In Use:|%.3f|Decrease:|Farther|Increase:|Closer",
	GUI_TBL_VAL_Z_TIP = "Default:|%.3f|Min:|%.3f|Max:|%.3f|In Use:|%.3f|Decrease:|Down|Increase:|Up",

	--GUI: Preset File Manager
	GUI_FMAN_TITLE = "Preset File Manager",
	GUI_FMAN_DEL_CONFIRM = "Delete file \"%s\"?",
	GUI_FMAN_NO_PSETS = "No presets have been created yet.",

	--LOG: Info
	LOG_CAM_PSET = "Camera preset: '%s'",
	LOG_CAM_OSET_DONE = "Camera offset '%s' is complete.",
	LOG_FOUND_DEF = "Default preset '%s' found.",
	LOG_LINK_PSET = "Following linked preset (%d): '%s'",
	LOG_LOAD_PSET = "Preset '%s' has been loaded from '%s/%s'.",
	LOG_MOD_OFF = "Mod has been disabled!",
	LOG_MOD_ON = "Mod has been enabled!",
	LOG_PSET_SAVED = "File 'presets/%s.lua' was saved successfully.",
	LOG_PSET_UPD = "The preset '%s' has been updated.",
	LOG_PSETS_RLD = "Presets have been reloaded.",
	LOG_REST_ALL = "Restored all default presets.",
	LOG_REST_PSET = "Preset for ID '%s' has been restored.",
	LOG_REST_PSETS = "Restored %d/%d changed preset(s).",
	LOG_DEL_SUCCESS = "Deleted preset '%s'.",

	--LOG: Warnings
	LOG_BLANK_NAME = "The new preset name cannot be blank.",
	LOG_CLEAR_PSETS = "Cleared all loaded camera offset presets.",
	LOG_CLEAR_NPSETS = "Cleared %d loaded camera offset presets whose keys started with '%s'.",
	LOG_FILE_EXIST = "File '%s' already exists, and overwrite is disabled.",
	LOG_NO_PSET_FOUND = "No preset found.",
	LOG_NAMES_MISM = "The new preset name must be '%s', '%s', or a prefix of one of them; otherwise, it will not be applied and will be ignored.",
	LOG_NAME_MISM = "The new preset name must be '%s' or a prefix of it; otherwise, it will not be applied and will be ignored.",
	LOG_PSET_NOT_CHANGED = "No changes were made to preset '%s' compared to the default preset '%s'.",
	LOG_PSET_NOT_SAVED = "File 'presets/%s.lua' could not be saved.",
	LOG_SKIP_PSET = "Skipping already loaded preset: '%s' ('%s/%s').",

	--LOG: Errors
	LOG_DIR_NOT_EXIST = "You cannot delete the entire directory under '%s'.",
	LOG_DEFS_INCOMP = "The default presets are incomplete.",
	LOG_NO_CAM_OSET = "Could not retrieve camera offset: '%s'.",
	LOG_FAIL_APPLY = "Failed to apply preset.",
	LOG_FAIL_LOAD = "Failed to load preset '%s/%s': %s",
	LOG_BAD_PSET = "Invalid or failed preset '%s/%s'.",
	LOG_MISS_DEF = "Default preset '%s' could not be found.",
	LOG_NO_PSET_FOR_LVL = "No preset provided for level '%s'.",
	LOG_DEL_FAILURE = "Failed to delete preset '%s'. %s",
	LOG_MOVE_FAILURE = "Failed to rename preset '%s' to '%s'. %s"
}