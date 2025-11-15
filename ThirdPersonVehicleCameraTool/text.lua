--[[
==============================================
This file is distributed under the MIT License
==============================================

Third-Person Vehicle Camera Tool

Allows you to adjust third-person perspective
(TPP) camera offsets for any vehicle.

Filename: text.lua
Version: 2025-10-14, 00:11 UTC+01:00 (MEZ)

Copyright (c) 2025, Si13n7 Developments(tm)
All rights reserved.
______________________________________________
--]]


return {
	--GUI: 🧩 General
	GUI_YES = "\u{f0026} Yes",
	GUI_NO = "\u{f073a} No",
	GUI_NONE = "None",
	GUI_UNKNOWN = "Unknown",

	--GUI: 🚀 Main Controls
	GUI_TITLE = "TPP Vehicle Cam Toolkit",
	GUI_TITLE_SHORT = "TPPVCamTool",
	GUI_VERSION_WARN = "\u{f0026} This mod requires game version 2.21 or higher and CET version 1.35 or higher. You are using at least one outdated version (game: %s; CET: %s), which may cause issues. Any use is at your own risk. Please do not report any problems unless you meet the minimum requirements.",
	GUI_MOD_TOGGLE = " Toggle Mod Functionality",
	GUI_MOD_TOGGLE_TIP = "Enables or disables the mod functionality",
	GUI_SETTINGS = "\u{F1064} Global Settings ",
	GUI_SETTINGS_TIP = "Applies settings that affect all vehicles.\n\nDue to a game limitation affecting third-person behavior, some changes made while seated in a vehicle only take effect after exiting and re-entering.",
	GUI_CREAT_MODE = " Creator Mode",
	GUI_CREAT_MODE_TIP = "Enables a feature that allows you to create, test, and save your own presets.\n\nAlso controls debug output and overlay visibility:\n\u{f0b39}\u{f00a0} Disabled - runs in performance mode\n\u{f0b3a}\u{f018d} Logs basic info to the CET console\n\u{f0b3b}\u{f05b2} Keeps the overlay always visible\n\u{f0b3c}\u{f046d} Adds a ruler at the bottom of the screen\n\u{f0b3d}\u{f0369} Adds in-game pop-up notifications\n\u{f0b3e}\u{f1272} Adds extended debug info and log file output",
	GUI_PSETS_RLD = "\u{f054d} Reload Presets ",
	GUI_PSETS_RLD_TIP = "Reloads all preset data. Use this to reset unsaved changes, after enabling or disabling vanilla presets, or when you have changed or added preset files outside of the game.\n\nKeep in mind that changes only take effect after exiting and re-entering the vehicle",
	GUI_STATE_NO_VEH = "\u{f02fd} Please enter a vehicle first",
	GUI_STATE_PSET_ON = "\u{f1668} Preset loaded and active",
	GUI_STATE_PSET_OFF = "\u{f11be} No preset available",
	GUI_PSET_EXPL = "\u{f069d} Preset Explorer ",
	GUI_PSET_EXPL_TIP = "Browse all preset files, view usage data, or delete the ones you no longer need.",
	GUI_EDIT_APPLY = "\u{f044f} Apply ",
	GUI_EDIT_APPLY_TIP = "Applies the configured values without saving them permanently.\n\nThe vehicle must be exited and re-entered for the changes to become active.",
	GUI_EDIT_SAVE = "\u{f0193} Save ",
	GUI_EDIT_SAVE_TIP = "Applies the configured values and saves them permanently to \"presets/%s.lua\".\n\nChanges will only take effect after exiting and re-entering the vehicle.",
	GUI_EDIT_REST_TIP = "Removes the \"presets/%s.lua\" to revert to the default preset.\n\nYou must exit and re-enter the vehicle for the changes to take effect.",
	GUI_EDIT_OWR_POP = "Replace existing file \"%s\"?",

	--GUI: ⚒️ Global Settings
	GUI_GSET_CLOSER_BIKES = "Closer Bike Camera",
	GUI_GSET_CLOSER_BIKES_TIP = "Moves the camera closer to motorcycles for a tighter, more immersive view.\n\nOnly works for motorcycles that have a preset.\n\nMotorcycle presets cannot be edited while this option is enabled.",
	GUI_GSET_AUTO_CENTER = "Disable Auto-Centering",
	GUI_GSET_AUTO_CENTER_TIP = "Disables automatic camera centering.\n\nTakes effect only after exiting and re-entering the vehicle.",
	GUI_GSET_VAN_PSETS = "Disable Vanilla Presets",
	GUI_GSET_VAN_PSETS_TIP = "Prevents changes to vanilla vehicles.\n\nSome vanilla vehicles have unusual camera settings that this mod corrects by default.",
	GUI_GSET_FOV = "Field Of View",
	GUI_GSET_FOV_DESC = "Determines the vertical field of view, measured in degrees.\n\nMight only work after you exit and enter the vehicle again.",
	GUI_GSET_FOV_TIP = "Default:|%d|Min:|%d|Max:|%d",
	GUI_GSET_ZOOM = "Zoom",
	GUI_GSET_ZOOM_DESC = "Controls the camera zoom level, allowing you to get closer to the subject.",
	GUI_GSET_ZOOM_TIP = "Default:|%.2f|Min:|%.2f|Max:|%.2f",
	GUI_GSET_RESET = "\u{f054d} Reset",
	GUI_GSET_RESET_TIP = "You may need to reload the presets for changes to fully take effect, and some changes only apply after exiting and re-entering the vehicle.",
	GUI_GSET_ADVANCED = "\u{f0169} Advanced",
	GUI_GSET_ADVANCED_TIP = "Direct access to all raw global parameters. No automatic calibration or value limits applied.\n\nChanges take effect once you exit and get back into the vehicle.",
	GUI_ASET_TITLE = "\u{f0169} Advanced Settings",
	GUI_ASET_HEAD1 = "\u{f0bd8} Cars, SUVs, Vans, Trucks, Tanks, etc.",
	GUI_ASET_HEAD2 = "\u{f037c} Motorcycles",

	--GUI: 🗂️ Preset Explorer
	GUI_PSET_EXPL_SEARCH_TIP = "\u{f0232} Search Options| |%s|Shows files of vehicles available in the game|%s|Shows files of available custom vehicles|%s|Shows files of vehicles not available in the game|%s|Shows files of vehicles that have been actively used|%s|Shows files of vehicles that exist but have never been used|%s|Shows files of vanilla vehicles|anything|Normal text search",
	GUI_PSET_EXPL_NAME_TIP = "\u{f103a} %s",
	GUI_PSET_EXPL_USAGE_TIP = "\u{f0520} Usage History| |First Used:|%s|Last Used:|%s|Total Uses:|%d",
	GUI_PSET_EXPL_EMPTY = "No presets have been created yet.",
	GUI_PSET_EXPL_UNMATCH = "No presets match your search.",
	GUI_PSET_EXPL_DEL_TIP = "Delete this preset",
	GUI_PSET_EXPL_DEL_POP = "Delete file \"%s\"?",

	--GUI: 📝 Preset Editor
	GUI_TBL_LABL_DNAME_TIP = "\u{f0208} Vehicle's display name",
	GUI_TBL_LABL_STATUS_TIP = "\u{f1975} Vehicle's player status",
	GUI_TBL_LABL_VEH_TIP = "\u{f1b8d} Vehicle's name",
	GUI_TBL_LABL_APP_TIP = "\u{f0301} Vehicle's appearance name",
	GUI_TBL_LABL_CAMID_TIP = "\u{f0567} Vehicle's camera identifier",
	GUI_TBL_LABL_CCAMID_TIP = "\u{f0569} Vehicle's custom camera identifier",
	GUI_TBL_LABL_PSET_TIP = "\u{f1668} Vehicle's active camera preset",
	GUI_TBL_LABL_CLO_TIP = "\u{f0623} Close camera distance",
	GUI_TBL_LABL_MID_TIP = "\u{f0622} Medium camera distance",
	GUI_TBL_LABL_FAR_TIP = "\u{f0621} Far camera distance",
	GUI_TBL_VAL_STATUS_0 = "Vanilla Crowd Vehicle",
	GUI_TBL_VAL_STATUS_1 = "Vanilla Player Vehicle",
	GUI_TBL_VAL_STATUS_2 = "Custom Player Vehicle",
	GUI_TBL_VAL_CCAMID_TIP = "\u{f1980} Camera Access Map| |Distance Level:|Database Access Path:",
	GUI_TBL_VAL_PSET_TIP1 = "\u{f1668} Active Camera Preset\n\nWhen saving, the name \"%s\" is used. The new name must exactly match the value of \u{f1b8d} or \u{f0301}, or be at least a prefix of one of them.\n\nPlease note that you only need to change the name manually if you want to apply a preset to multiple identical vehicles, so you do not need to create a separate preset for each variation.\n\nMatching Priorities (first match is used):\n\u{f0b3a}\u{f1b8d} (e.g. \"%s\")\n\u{f0b3b}\u{f0301} (e.g. \"%s\")\n\u{f0b3c}Prefix of \u{f1b8d} (e.g. \"%s\")\n\u{f0b3d}Prefix of \u{f0301} (e.g. \"%s\")\n\nPlease ensure that your new preset name has the correct priority. It is recommended to make prefixes as long as possible to avoid conflicts in the future. Take a look at the Preset File Explorer to delete presets, if necessary.",
	GUI_TBL_VAL_PSET_TIP2 = "\u{f1668} Active Camera Preset\n\nWhen saving, the name \"%s\" is used. The new name must exactly match the value of \u{f1b8d}, or at least be its prefix.\n\nPlease note that you only need to change the name manually if you want to apply a preset to multiple identical vehicles, so you do not need to create a separate preset for each variation.\n\nMatching Priorities (first match is used):\n\u{f0b3a}\u{f1b8d} (e.g. \"%s\")\n\u{f0b3b}Prefix of \u{f1b8d} (e.g. \"%s\")\n\nPlease ensure that your new preset name has the correct priority. It is recommended to make prefixes as long as possible to avoid conflicts in the future. Take a look at the Preset File Explorer to delete presets, if necessary.",
	GUI_TBL_VAL_ANG_TIP = "\u{f10f3} Angles (°)| |Default:|%d|Min:|%d|Max:|%d|In Use:|%d",
	GUI_TBL_VAL_DIST_TIP = "\u{f054e} Distance| |Default:|%.2f|Min:|%.2f|Max:|%.2f|In Use:|%.2f|Decrease:|Closer|Increase:|Farther",
	GUI_TBL_VAL_X_TIP = "\u{f0d4c} X-Offset| |Default:|%.2f|Min:|%.2f|Max:|%.2f|In Use:|%.2f|Decrease:|Left|Increase:|Right",
	GUI_TBL_VAL_Y_TIP = "\u{f0d51} Y-Offset| |Default:|%.2f|Min:|%.2f|Max:|%.2f|In Use:|%.2f|Decrease:|Farther|Increase:|Closer",
	GUI_TBL_VAL_Z_TIP = "\u{f0d55} Z-Offset| |Default:|%.2f|Min:|%.2f|Max:|%.2f|In Use:|%.2f|Decrease:|Down|Increase:|Up",

	--NUI: ⚔️ Native Settings UI
	NUI_CAT_GSET = "Global Settings",
	NUI_CAT_ASET1 = "Advanced (Cars, SUVs, Vans, Trucks, Tanks, etc.)",
	NUI_CAT_ASET2 = "Advanced (Motorcycles)",

	--LOG: ℹ️ Info
	LOG_CAM_OSET_DONE = "Camera offset '%s' is ready.",
	LOG_CAM_PSET = "Camera preset: '%s' found.",
	LOG_EVNT_MNT = "Event 'VehicleComponent:OnMountingEvent' triggered.",
	LOG_EVNT_UMNT = "Event 'VehicleComponent:OnUnmountingEvent' triggered.",
	LOG_EVNT_UMNT_FAIL = "Event 'VehicleComponent:OnUnmountingEvent' triggered without any valid reason.",
	LOG_MENU_RELEASE = "Menu scenario triggered to release the overlay.",
	LOG_MENU_RESET = "Menu scenario triggered to reset GUI metrics.",
	LOG_MENU_SUPPRESS = "Menu scenario triggered to suppress the overlay.",
	LOG_MENU_TOGGLE = "Menu scenario triggered overlay state toggle.",
	LOG_MOD_OFF = "Mod has been disabled!",
	LOG_MOD_ON = "Mod has been enabled!",
	LOG_NUI_INIT = "Native Settings UI initialized.",
	LOG_PARAM_BACKUP = "Backup param (key: '%s'; value: '%s').",
	LOG_PARAM_IS_LOW = "Param '%s' is low height.",
	LOG_PARAM_MANIP = "Param manipulation detected (key: '%s'; value: '%s'), reset value to '%s'.",
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
