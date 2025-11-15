--[[
==============================================
This file is distributed under the MIT License
==============================================

Third-Person Vehicle Camera Tool

Allows you to adjust third-person perspective
(TPP) camera offsets for any vehicle.

Filename: text.lua
Version: 2025-10-02, 08:14 UTC+01:00 (MEZ)

Copyright (c) 2025, Si13n7 Developments(tm)
All rights reserved.
______________________________________________
--]]


return {
	--GUI: 🧩 General
	GUI_YES = "\u{f0026} Yes",
	GUI_NO = "\u{f073a} No",
	GUI_NONE = "None",
	GUI_RESET = "Reset",

	--GUI: 🚀 Main Controls and Tooltips
	GUI_TITL = "Third-Person Vehicle Camera Tool",
	GUI_OLD_VER = "\u{f0026} This mod requires game version 2.21 or higher and CET version 1.35 or higher. You are using at least one outdated version (game: %s; CET: %s), which may cause issues. Any use is at your own risk. Please do not report any problems unless you meet the minimum requirements.",
	GUI_TGL_MOD = "Toggle Mod Functionality",
	GUI_TGL_MOD_TIP = "Enables or disables the mod functionality.",
	GUI_GSETS = "\u{F1064} Global Settings ",
	GUI_PSETS_RLD = "\u{f054d} Reload Presets ",
	GUI_PSETS_RLD_TIP = "Reloads all preset data. Use this to reset unsaved changes, after enabling or disabling vanilla presets, or when you have changed or added preset files outside of the game.\n\nKeep in mind that changes only take effect after exiting and re-entering the vehicle",
	GUI_DMODE = "Developer Mode",
	GUI_DMODE_TIP = "Enables a feature that allows you to create, test, and save your own presets.\n\nAlso controls debug output and overlay visibility:\n\u{f0b39}\u{f00a0} Disabled - running in performance mode.\n\u{f0b3a}\u{f018d} Logs basic info to the CET console.\n\u{f0b3b}\u{f05b2} Like 1, but keeps the overlay always visible.\n\u{f0b3c}\u{f0369} Like 2, plus in-game pop-up notifications.\n\u{f0b3d}\u{f1272} Like 3, plus extended debug info and log file output.",
	GUI_NO_VEH = "\u{f02fd} Please enter a vehicle first!",
	GUI_PRE_ON = "\u{f1952} Preset loaded and active!",
	GUI_PRE_OFF = "\u{f11be} No preset available!",
	GUI_APPLY = "\u{f044f} Apply ",
	GUI_APPLY_TIP = "Applies the configured values without saving them permanently.\n\nThe vehicle must be exited and re-entered for the changes to become active.",
	GUI_SAVE = "\u{f0193} Save ",
	GUI_SAVE_TIP = "Applies the configured values and saves them permanently to \"presets/%s.lua\".\n\nChanges will only take effect after exiting and re-entering the vehicle.",
	GUI_REST_TIP = "Removes the \"presets/%s.lua\" to revert to the default preset.\n\nYou must exit and re-enter the vehicle for the changes to take effect",
	GUI_OVWR_CONFIRM = "Replace existing file \"%s\"?",
	GUI_FEXP = "\u{f12e3} Preset File Explorer ",

	--GUI: 📋 Table Label Tooltips
	GUI_TBL_LABL_DNAME_TIP = "The vehicle's display name.",
	GUI_TBL_LABL_STATUS_TIP = "The vehicle's player status.",
	GUI_TBL_LABL_VEH_TIP = "The vehicle's name.",
	GUI_TBL_LABL_APP_TIP = "The vehicle's appearance name.",
	GUI_TBL_LABL_CAMID_TIP = "The vehicle's camera identifier.",
	GUI_TBL_LABL_CCAMID_TIP = "The vehicle's custom camera identifier.",
	GUI_TBL_LABL_PSET_TIP = "The vehicle's active camera preset.",
	GUI_TBL_LABL_CLO_TIP = "Camera Distance: Close",
	GUI_TBL_LABL_MID_TIP = "Camera Distance: Medium",
	GUI_TBL_LABL_FAR_TIP = "Camera Distance: Far",

	--GUI: 💶 Table Values and Tooltips
	GUI_TBL_VAL_STATUS_0 = "Vanilla Crowd Vehicle",
	GUI_TBL_VAL_STATUS_1 = "Vanilla Player Vehicle",
	GUI_TBL_VAL_STATUS_2 = "Custom Player Vehicle",
	GUI_TBL_VAL_CCAMID_TIP = "\u{f1980} Camera Access Map| |Distance Level:|Database Access Path:",
	GUI_TBL_VAL_PSET_TIP1 = "When saving, the name \"%s\" is used. The new name must exactly match the value of \u{f010b} or \u{f07ac}, or be at least a prefix of one of them.\n\nPlease note that you only need to change the name manually if you want to apply a preset to multiple identical vehicles, so you do not need to create a separate preset for each variation.\n\nMatching Priorities (first match is used):\n\u{f0b3a}\u{f010b} (e.g. \"%s\")\n\u{f0b3b}\u{f07ac} (e.g. \"%s\")\n\u{f0b3c}Prefix of \u{f010b} (e.g. \"%s\")\n\u{f0b3d}Prefix of \u{f07ac} (e.g. \"%s\")\n\nPlease ensure that your new preset name has the correct priority. It is recommended to make prefixes as long as possible to avoid conflicts in the future. Take a look at the Preset File Explorer to delete presets, if necessary.",
	GUI_TBL_VAL_PSET_TIP2 = "When saving, the name \"%s\" is used. The new name must exactly match the value of \u{f010b}, or at least be its prefix.\n\nPlease note that you only need to change the name manually if you want to apply a preset to multiple identical vehicles, so you do not need to create a separate preset for each variation.\n\nMatching Priorities (first match is used):\n\u{f0b3a}\u{f010b} (e.g. \"%s\")\n\u{f0b3b}Prefix of \u{f010b} (e.g. \"%s\")\n\nPlease ensure that your new preset name has the correct priority. It is recommended to make prefixes as long as possible to avoid conflicts in the future. Take a look at the Preset File Explorer to delete presets, if necessary.",
	GUI_TBL_VAL_ANG_TIP = "\u{f10f3} Angles (°)| |Default:|%d|Min:|%d|Max:|%d|In Use:|%d",
	GUI_TBL_VAL_DIST_TIP = "\u{f054e} Distance| |Default:|%.2f|Min:|%.2f|Max:|%.2f|In Use:|%.2f|Decrease:|Closer|Increase:|Farther",
	GUI_TBL_VAL_X_TIP = "\u{f0d4c} X-Offset| |Default:|%.2f|Min:|%.2f|Max:|%.2f|In Use:|%.2f|Decrease:|Left|Increase:|Right",
	GUI_TBL_VAL_Y_TIP = "\u{f0d51} Y-Offset| |Default:|%.2f|Min:|%.2f|Max:|%.2f|In Use:|%.2f|Decrease:|Farther|Increase:|Closer",
	GUI_TBL_VAL_Z_TIP = "\u{f0d55} Z-Offset| |Default:|%.2f|Min:|%.2f|Max:|%.2f|In Use:|%.2f|Decrease:|Down|Increase:|Up",

	--GUI: ⚙️ Global Options
	GUI_GOPT_FOV = "Field Of View",
	GUI_GOPT_NAC = "No Auto-Centering",
	GUI_GOPT_NVAN = "No Vanilla Presets",
	GUI_GOPT_NVAN_TIP = "Some vanilla vehicles have unusual camera settings that this mod corrects. Enable this option to leave vanilla vehicles untouched.\n\nKeep in mind that changes only take effect after exiting and re-entering the vehicle.",
	GUI_GOPT_TIP = "Keep in mind that changes only take effect after exiting and re-entering the vehicle.\n\nFor certain vehicles, you may also need to disable and re-enable the mod via the checkbox—while not sitting in any vehicle—to apply your changes.",

	--GUI: 🗂️ Preset File Explorer
	GUI_FEXP_DEL_CONFIRM = "Delete file \"%s\"?",
	GUI_FEXP_NO_PSETS = "No presets have been created yet.",
	GUI_FEXP_NAME_TIP = "\u{f08b1} %s",
	GUI_FEXP_SEARCH_TIP = "\u{f0232} Filter Commands| |%s|Shows files of vehicles available in the game|%s|Shows files of available custom vehicles|%s|Shows files of vehicles not available in the game|%s|Shows files of vehicles that have been actively used|%s|Shows files of vehicles that exist but have never been used|%s|Shows files of vanilla vehicles",
	GUI_FEXP_USAGE_TIP = "\u{f0520} Usage History| |First Used:|%s|Last Used:|%s|Total Uses:|%d",

	--LOG: ℹ️ Info
	LOG_CAM_OSET_DONE = "Camera offset '%s' is ready.",
	LOG_CAM_PSET = "Camera preset: '%s' found.",
	LOG_EVNT_MNT = "Event 'VehicleComponent:OnMountingEvent' triggered.",
	LOG_EVNT_UMNT = "Event 'VehicleComponent:OnUnmountingEvent' triggered.",
	LOG_EVNT_UMNT_FAIL = "Event 'VehicleComponent:OnUnmountingEvent' triggered without any valid reason.",
	LOG_MOD_OFF = "Mod has been disabled!",
	LOG_MOD_ON = "Mod has been enabled!",
	LOG_PARAM_BACKUP = "Backup param (key: '%s'; value: '%s').",
	LOG_PARAM_IS_LOW = "Param '%s' is low height.",
	LOG_PARAM_MANIP = "Param manipulation detected (key: '%s'; value: '%s'), reset value to '%s' from key '%s'.",
	LOG_PARAM_REST = "Restore param (key: '%s') to value '%s'.",
	LOG_PARAM_SET = "Set param (key: '%s') to value '%s'.",
	LOG_PSET_DEF_FOUND = "Default preset '%s' found.",
	LOG_PSET_DEF_JOINED = "Default preset '%s' joined.",
	LOG_PSET_DELETED = "Preset '%s' deleted.",
	LOG_PSET_EDIT_DELETED = "Last editor preset removed.",
	LOG_PSET_LOAD = "Preset '%s' loaded from '%s/%s'.",
	LOG_PSET_REST = "Preset for ID '%s' restored.",
	LOG_PSET_SAVED = "File '%s' was saved successfully.",
	LOG_PSET_UPDATED = "Preset '%s' updated.",
	LOG_PSETS_LOAD_CUS = "%d/%d custom presets verified in %.3f seconds.",
	LOG_PSETS_LOAD_DEF = "%d/%d defaults verified in %.3f seconds.",
	LOG_PSETS_LOAD_DONE = "Presets fully initialized in %.3f seconds.",
	LOG_PSETS_LOAD_IGNO = "%d custom presets ignored because the corresponding vehicle mod is not installed.",
	LOG_PSETS_LOAD_VAN = "%d/%d vanilla presets verified in %.3f seconds.",
	LOG_PSETS_REST = "Restored %d/%d changed preset(s).",
	LOG_PSETS_REST_DEF = "Restored all default presets.",
	LOG_VEH_UIDS = "Found %d unique vehicle identifiers.",

	--LOG: ⚠️ Warnings
	LOG_CAM_ID_MISM = "Camera ID mismatch: preset '%s' vs. vehicle '%s'.",
	LOG_CAMS_ALL_CLEARED = "Cleared all loaded camera offset presets.",
	LOG_CAMS_CLEARED = "Cleared %d loaded camera offset presets whose keys started with '%s'.",
	LOG_PLAYER_UNDEFINED = "No player detected.",
	LOG_PSET_BLANK_NAME = "The new preset name cannot be blank.",
	LOG_PSET_DEF_MISS = "Default preset '%s' could not be found.",
	LOG_PSET_EXE_FAIL = "Failed to execute preset '%s/%s'.",
	LOG_PSET_FILE_EXIST = "File '%s' already exists, and overwrite is disabled.",
	LOG_PSET_IGNORED = "Ignoring preset (required mod not installed): '%s' ('%s/%s').",
	LOG_PSET_NAME_MISM = "The new preset name must be '%s' or a prefix of it; otherwise, it will not be applied and will be ignored.",
	LOG_PSET_NAMES_MISM = "The new preset name must be '%s', '%s', or a prefix of one of them; otherwise, it will not be applied and will be ignored.",
	LOG_PSET_NOT_CHANGED = "No changes were made to preset '%s' compared to the default preset '%s'.",
	LOG_PSET_NOT_FOUND = "No preset found for '%s'.",
	LOG_PSET_NOT_SAVED = "File 'presets/%s.lua' could not be saved.",
	LOG_PSET_SKIPPED = "Skipping already loaded preset: '%s' ('%s/%s').",

	--LOG: ❌ Errors
	LOG_APP_NOT_FOUND = "The vehicle's appearance could not be found.",
	LOG_ARG_INVALID = "At least one argument is invalid.",
	LOG_ARG_OUT_OF_RANGE = "At least one argument is out of range.",
	LOG_CAM_ID_MISS = "Vehicle camera ID is missing.",
	LOG_CAM_OSET_MISS = "Could not retrieve camera offset: '%s'.",
	LOG_FORMAT_INVALID = "Format invalid.",
	LOG_PSET_APPLY_FAIL = "Could not apply preset: incomplete parameters ('%s').",
	LOG_PSET_DEL_FAIL = "Failed to delete preset '%s'. %s",
	LOG_PSET_INVALID = "Invalid or failed preset '%s/%s'.",
	LOG_PSET_LOAD_FAIL = "Failed to load preset '%s/%s': '%s'.",
	LOG_PSET_LVL_MISS = "No preset provided for level '%s'.",
	LOG_PSETS_DEF_BROKEN = "The default presets are incomplete.",
	LOG_PSETS_DIR_MISS = "No directory under '%s'.",
	LOG_VEH_NAME_MISS = "Vehicle name not found.",
	LOG_VEH_REC_ID_MISS = "Vehicle record ID is missing.",
	LOG_VEH_REC_NAME_MISS = "Vehicle record name is missing.",

	--THROW: 🆘 Errors
	THROW_CACHE_ID = "Cache ID is missing.",
	THROW_SQL_DELETE = "Invalid arguments in SQLite delete.",
	THROW_SQL_INIT = "nvalid arguments in SQLite init.",
	THROW_SQL_UPSERT = "nvalid arguments in SQLite upserts."
}
