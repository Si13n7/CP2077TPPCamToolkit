--[[
==============================================
This file is distributed under the MIT License
==============================================

Third-Person Vehicle Camera Tool

Allows you to adjust third-person perspective
(TPP) camera offsets for any vehicle.

Filename: init.lua
Version: 2025-09-28, 19:40 UTC+01:00 (MEZ)

Copyright (c) 2025, Si13n7 Developments(tm)
All rights reserved.
______________________________________________

Naming Conventions in this codebase:
 - SCREAMINGCASE:        Constant single-word variables
 - SCREAMING_SNAKE_CASE: Constant multi-word variables
 - PascalCase:           Constant arrays or interface variables
 - camelCase:            Local multi-word variables and functions (non-constants)
 - flatcase:             Local single-word variables, functions, or single-letter interface variables (non-constants)
 - Exceptions:           Game- or Lua-defined names and terms

Examples:
 - presets                   (single-word variable)
 - presets.loadTask          (plus multi-word variable)
 - presets.loadTask.IsActive (plus interface variable)
 - DevLevels                 (constant array)
 - DevLevels.DISABLED        (plus constant variable)
 - vehicleName               (local multi-word variable)
 - i, x, v                   (local single-character variables)

Development Environment:
 - Editor: Visual Studio Code
 - Lua Extension: sumneko.lua
--]]


--#region 🚧 Core Definitions

---Represents available developer debug modes used to control logging and feedback behavior.
---@alias DevLevelType 0|1|2|3|4

---Represents available logging levels for categorizing message severity.
---@alias LogLevelType 0|1|2

---Enumeration of developer debug modes with increasing verbosity.
---@class DevLevelEnum
---@field DISABLED DevLevelType # No debug output (default).
---@field BASIC DevLevelType # Logs output to the CET console only.
---@field OVERLAY DevLevelType # Logs to console and keeps the overlay visible even when CET is hidden.
---@field ALERT DevLevelType # Same as OVERLAY, but also shows pop-up alerts on screen.
---@field FULL DevLevelType # Same as ALERT, but with extended technical output and additional logging to file.

---Enumeration of log message severity levels.
---@class LogLevelEnum
---@field INFO LogLevelType # General informational output.
---@field WARN LogLevelType # Non-critical issues or unexpected behavior.
---@field ERROR LogLevelType # Critical failures or important errors that need attention.

---Enumeration of predefined color constants used for UI theming and styling.
---@class ColorEnum
---@field CARAMEL integer # Caramel is a warm, golden brown with rich amber tones.
---@field FIR integer # Fir is a dark, cool green with subtle blue undertones.
---@field GARNET integer # Garnet is a deep, muted red with a subtle brown undertone.
---@field MULBERRY integer # Mulberry is a deep, muted purple with rich red undertones and a cool, berry-like hue.
---@field OLIVE integer # Olive is a muted yellow-green with an earthy, natural tone.

---Represents folders for different types of camera presets.
---@class PresetLocations
---@field DEFAULTS string # Folder containing base presets representing the standard/default settings.
---@field CUSTOM string # Folder containing presets for modded/custom vehicles.
---@field VANILLA string # Folder containing presets for vanilla vehicles.

---Represents search filter commands.
---@class SearchFilterCommands
---@field INSTALLED string # Presets of vehicles that are available in the game.
---@field MODDED string # Presets of custom vehicles that are available in the game.
---@field UNAVAILABLE string # Presets of vehicles not available in the game.
---@field ACTIVE string # Presets of vehicles that were actively used.
---@field INACTIVE string # Presets of vehicles that exist but have never been used.
---@field VANILLA string # Presets of standard vehicles that come with the base game.

---Represents a parsed version number in structured format.
---@class IVersion
---@field Major number # Major version number (required).
---@field Minor number # Minor version number (optional, defaults to 0 if missing).
---@field Build number # Build number (optional, defaults to 0 if missing).
---@field Revision number # Revision number (optional, defaults to 0 if missing).

---Represents a recurring asynchronous timer.
---@class AsyncTimer
---@field Interval number # The time interval in seconds between each callback execution.
---@field Time number # The next scheduled execution time (typically os.clock() + interval).
---@field Callback fun(id: integer) # The function to be executed when the timer triggers; receives the timer's unique ID.
---@field IsActive boolean # True if the timer is currently active, false if paused or canceled.

---Represents a global options structure.
---@class IOptionData
---@field DisplayName string # The display name.
---@field Value any # The current value.
---@field Default any # The game's default value.
---@field Min number? # The minimum value.
---@field Max number? # The maximum value.
---@field IsDefaultParam boolean? # Determines whether this is treated as TweakDB default parameter of the game.

---Represents the state of a preset loader task.
---@class IPresetLoaderTask
---@field IsActive boolean? # True if the task is currently running.
---@field StartTime number? # Timestamp when the task started.
---@field EndTime number? # Timestamp when the task finished or last finished.
---@field Duration number? # Total elapsed time of the task. For multiple consecutive runs, this is the sum of all individual run durations.
---@field Finalizer function? # Function called when all tasks have finished.

---Represents a camera offset configuration with rotation and positional data.
---@class IOffsetData
---@field a number # The camera's angle in degrees.
---@field x number # The offset on the X-axis.
---@field y number # The offset on the Y-axis.
---@field z number # The offset on the Z-axis.
---@field d number # The offset of the camera distance.

---Represents a vehicle camera preset.
---@class ICameraPreset
---@field ID string? # The camera ID used for the vehicle.
---@field Close IOffsetData? # The offset data for close camera view.
---@field Medium IOffsetData? # The offset data for medium camera view.
---@field Far IOffsetData? # The offset data for far camera view.
---@field IsDefault boolean? # Determines whether this camera preset is a default one.
---@field IsJoined boolean? # Determines whether this camera preset was newly generated as a default.
---@field IsVanilla boolean? # Determines whether this camera preset comes from a vanilla vehicle.

---Represents usage statistics for a camera preset.
---@class IPresetUsage
---@field First number # Timestamp of the first time this preset was applied.
---@field Last number # Timestamp of the most recent time this preset was applied.
---@field Total number # Total number of times this preset has been applied.

---Represents a single camera preset entry used in the editor, including its metadata and file state.
---@class IEditorPreset
---@field Preset ICameraPreset # The actual preset data (angles and offsets).
---@field Key string # Internal identifier for lookups and invalid name detection.
---@field Name string # User-modifiable display name of the preset.
---@field Token number # Adler-53 checksum of `Preset`, used to detect changes.
---@field IsPresent boolean # True if a corresponding preset file exists on disk.

---Represents pending actions for a modified camera preset within the editor workflow.
---@class IEditorTasks
---@field Rename boolean # True if the preset has been renamed but the file itself still needs to be renamed.
---@field Validate boolean # True if angles or offsets have changed, used to highlight buttons.
---@field Apply boolean # True if there are unapplied changes ready to be applied in-game.
---@field Save boolean # True if there are unsaved modifications that need to be written to disk.
---@field Restore boolean # True if saving will revert the preset back to its default configuration.

---Holds multiple versions of a vehicle camera preset within the editor.
---Each version represents a different state in the edit/apply/save workflow.
---@class IEditorBundle
---@field Nexus IEditorPreset # Immutable default preset for the mounted vehicle.
---@field Flux IEditorPreset # Live preset reflecting current UI edits.
---@field Pivot IEditorPreset # Snapshot of Flux at the last apply action.
---@field Finale IEditorPreset # Snapshot of Flux at the last save action.
---@field Tasks IEditorTasks # Flags for pending rename, validate, apply, save, or restore actions.

--Aliases for commonly used standard library functions to simplify code.
local format, rep, concat, insert, remove, sort, unpack, abs, ceil, floor, max, min, band, bor, lshift, rshift =
	string.format,
	string.rep,
	table.concat,
	table.insert,
	table.remove,
	table.sort,
	table.unpack,
	math.abs,
	math.ceil,
	math.floor,
	math.max,
	math.min,
	bit32.band,
	bit32.bor,
	bit32.lshift,
	bit32.rshift

---Loads all static UI and log string constants from `text.lua` into the global `Text` table.
---This is the most efficient way to manage display strings separately from logic and code.
---@type table<string, string>
local Text = dofile(
	"text.lua")

---Developer mode levels used to control the verbosity and behavior of debug output.
---@type DevLevelEnum
local DevLevels = {
	DISABLED = 0,
	BASIC = 1,
	OVERLAY = 2,
	ALERT = 3,
	FULL = 4
}

---Log levels used to classify the severity of log messages.
---@type LogLevelEnum
local LogLevels = {
	INFO = 0,
	WARN = 1,
	ERROR = 2
}

---Contains textual tags, toast icons, and toast types for each log level.
---@type table<LogLevelType, {TAG: string, ICON: string, TOAST: integer}>
local LogMeta = {
	[LogLevels.ERROR] = { TAG = "[Error]", ICON = "\u{f0e1c}", TOAST = ImGui.ToastType.Error },
	[LogLevels.WARN] = { TAG = "[Warn]", ICON = "\u{f0d64}", TOAST = ImGui.ToastType.Warning },
	[LogLevels.INFO] = { TAG = "[Info]", ICON = "\u{f11be}", TOAST = ImGui.ToastType.Info }
}

---Provides predefined hexadecimal color values for theming and UI interaction states.
---@type ColorEnum
local Colors = {
	CARAMEL = 0x8a295c7a,
	FIR = 0x8a6a7a29,
	GARNET = 0x8a29297a,
	MULBERRY = 0x8a68297a,
	OLIVE = 0x8a297a68
}

---Predefined folder paths for storing camera presets.
---@type PresetLocations
local PresetFolders = {
	DEFAULTS = "defaults",
	CUSTOM = "presets",
	VANILLA = "presets-vanilla"
}

---Provides a table of Preset File Explorer search filter commands.
---@type SearchFilterCommands
local ExplorerCommands = {
	INSTALLED = ":installed",
	MODDED = ":installed_mods",
	UNAVAILABLE = ":not_installed",
	ACTIVE = ":active",
	INACTIVE = ":unused",
	VANILLA = ":vanilla"
}

---Default parameters including TweakDB keys and variable names.
---@type table<string, string[]>
local DefaultParams = {
	Keys = {
		"Camera.VehicleTPP_DefaultParams",
		"Camera.VehicleTPP_2w_DefaultParams"
	},
	Vars = {
		"airFlowDistortion",
		"autoCenterMaxSpeedThreshold",
		"autoCenterSpeed",
		"cameraBoomExtensionSpeed",
		"cameraMaxPitch",
		"cameraMinPitch",
		"cameraSphereRadius",
		"collisionDetection",
		"drivingDirectionCompensation",
		"drivingDirectionCompensationAngle",
		"drivingDirectionCompensationAngleSmooth",
		"drivingDirectionCompensationAngularVelocityMin",
		"drivingDirectionCompensationSpeedCoef",
		"drivingDirectionCompensationSpeedMax",
		"drivingDirectionCompensationSpeedMin",
		"elasticBoomAcceleration",
		"elasticBoomAccelerationExpansionLength",
		"elasticBoomForwardAccelerationCoef",
		"elasticBoomSpeedExpansionLength",
		"elasticBoomSpeedExpansionSpeedMax",
		"elasticBoomSpeedExpansionSpeedMin",
		"elasticBoomVelocity",
		"fov",
		"headLookAtCenterYawThreshold",
		"headLookAtMaxPitchDown",
		"headLookAtMaxPitchUp",
		"headLookAtMaxYaw",
		"headLookAtRotationSpeed",
		"inverseCameraInputBreakThreshold",
		"lockedCamera",
		"slopeAdjustement",
		"slopeCorrectionInAirDampFactor",
		"slopeCorrectionInAirFallCoef",
		"slopeCorrectionInAirPitchMax",
		"slopeCorrectionInAirPitchMin",
		"slopeCorrectionInAirRaiseCoef",
		"slopeCorrectionInAirSpeedMax",
		"slopeCorrectionInAirStrength",
		"slopeCorrectionOnGroundPitchMax",
		"slopeCorrectionOnGroundPitchMin",
		"slopeCorrectionOnGroundStrength"
	}
}

---Camera-related metadata including levels and variable names.
---@type table<string, string[]>
local CameraData = {
	Levels = {
		"High_Close",
		"High_Medium",
		"High_Far",
		"High_DriverCombatClose",
		"High_DriverCombatMedium",
		"High_DriverCombatFar",
		"Low_Close",
		"Low_Medium",
		"Low_Far",
		"Low_DriverCombatClose",
		"Low_DriverCombatMedium",
		"Low_DriverCombatFar"
	},
	Vars = {
		"airFlowDistortionSizeHorizontal",
		"airFlowDistortionSizeVertical",
		"airFlowDistortionSpeedMax",
		"airFlowDistortionSpeedMin",
		"baseBoomLength",
		"boomLengthOffset",
		"defaultRotationPitch",
		"distance",
		"height",
		"lookAtOffset"
	}
}

---Maps vehicle preset IDs to camera paths that are considered invalid.
---If a camera ID exists in the map and a corresponding camera level is
---found, the next operation should be aborted.
---@type table<string, table<string, boolean>>
local CameraDataInvalidLevelMap = {
	["4w_Medium_Preset"] = {
		High_DriverCombatClose = true,
		High_DriverCombatMedium = true,
		High_DriverCombatFar = true,
		Low_Close = true,
		Low_Medium = true,
		Low_Far = true,
		Low_DriverCombatClose = true,
		Low_DriverCombatMedium = true,
		Low_DriverCombatFar = true
	},
	["4w_SubCompact_Preset"] = {
		High_DriverCombatClose = true,
		High_DriverCombatMedium = true,
		High_DriverCombatFar = true,
		Low_Close = true,
		Low_Medium = true,
		Low_Far = true,
		Low_DriverCombatClose = true,
		Low_DriverCombatMedium = true,
		Low_DriverCombatFar = true
	},
	["Default_Preset"] = {
		High_DriverCombatClose = true,
		High_DriverCombatMedium = true,
		High_DriverCombatFar = true,
		Low_DriverCombatClose = true,
		Low_DriverCombatMedium = true,
		Low_DriverCombatFar = true
	},
	["v_utility4_kaukaz_bratsk_Preset"] = {
		Low_Medium = true,
		Low_Far = true,
		Low_DriverCombatClose = true,
		Low_DriverCombatMedium = true,
		Low_DriverCombatFar = true
	},
	["v_utility4_militech_behemoth_Preset"] = {
		Low_Medium = true,
		Low_Far = true,
		Low_DriverCombatClose = true,
		Low_DriverCombatMedium = true,
		Low_DriverCombatFar = true
	}
}

---Contains base camera levels and corresponding offset keys for presets.
---@type table<string, string[]>
local PresetInfo = {
	---Constant array of base camera levels.
	Levels = { "Close", "Medium", "Far" },

	---Constant array of `IOffsetData` keys.
	Offsets = { "a", "x", "y", "z", "d" }
}

---Holds global mod state and runtime flags.
local state = {
	---Current developer mode level controlling debug output and behavior.
	devMode = DevLevels.DISABLED,

	---Determines whether the mod is enabled.
	isModEnabled = true,

	---Indicates whether the running game version meets the minimum required version.
	isGameMinVersion = false,

	---Indicates whether the running CET version meets the minimum required version.
	isRuntimeMinVersion = false,

	---Indicates whether the running CET version supports all required features.
	isRuntimeFullVersion = false,

	---If true, temporarily suppresses all logging output regardless of `state.devMode`.
	---Useful to avoid log spam during mass operations or invalid intermediate states.
	isLogSuspend = false
}

---Manages recurring asynchronous timers and their status.
local async = {
	---Stores all active recurring async timers, indexed by their unique ID.
	---@type table<integer, AsyncTimer>
	timers = {},

	---Auto-incrementing ID used to assign unique keys to each timer.
	idCounter = 0,

	---Indicates whether at least one recurring timer is active.
	---Used to skip unnecessary processing in `onUpdate` event when no timers exist.
	isActive = false
}

---Stores persistent and transient caches for various data.
---@type table<string, table<number, any>>
local caches = {
	---Persistent cache for storing reusable or computed values across sessions.
	---Unlike `transient`, it retains data throughout the CET runtime.
	persistent = {},

	---Temporary cache mostly used to store vehicle-related data during an active session.
	---This cache is cleared or rebuilt when the vehicle context changes.
	transient = {}
}

---Holds mod options and some default parameters.
local config = {
	---Global option data.
	---@type table<string, IOptionData>
	options = {
		noVanilla = {
			DisplayName = Text.GUI_GOPT_NVAN,
			Tooltip = Text.GUI_GOPT_NVAN_TIP,
			Default = false
		},

		---`DefaultParams` that can be customized by the user.
		fov = {
			DisplayName = Text.GUI_GOPT_FOV,
			Default = 69,
			Min = 10,
			Max = 150,
			IsDefaultParam = true
		},
		lockedCamera = {
			DisplayName = Text.GUI_GOPT_NAC,
			Default = false,
			IsDefaultParam = true
		}
	},

	---Determines whether the Global Parameters window is open.
	isOpen = false,

	---Determines whether global parameters have been modified.
	isUnsaved = false
}

---Manages camera presets including loading, active state, and usage statistics.
local presets = {
	---Holds the state of the asynchronous preset loading task.
	---@type IPresetLoaderTask
	loaderTask = {},

	---Container for all camera presets.
	---@type table<string, ICameraPreset>
	collection = {},

	---Determines whether a preset is currently loaded and active.
	isAnyActive = false,

	---List of camera preset IDs that were modified at runtime to enable selective restoration.
	---@type string[]
	restoreStack = {},

	---Stores original custom parameter values before resetting them to global defaults.
	---Keys are TweakDB paths (string), and values are the original values.
	---Allows potential restoration of vehicle-specific parameters on shutdown.
	---@type table<string, any>
	restoreParams = {},

	---A mapping of preset names to their usage statistics.
	---@type table<string, IPresetUsage>
	usage = {},

	---Determines whether preset usage state has been modified.
	isUsageUnsaved = false
}

---Holds GUI-related flags and temporary UI states.
local gui = {
	---Indicates whether the CET overlay UI should be temporarily disabled.
	---Used to trigger `ImGui.BeginDisabled(true)` in frames where no user interaction
	---is allowed, e.g., during loading sequences or pending asynchronous operations.
	isOverlayLocked = false,

	---Determines whether the CET overlay is open.
	isOverlayOpen = false,

	---Forces a one–frame skip in `onDraw` after certain events (e.g. onUnmount).
	---Used to ensure `getMetrics()` is executed once, then discarded,
	---so the next frame can rebuild the window with a clean width.
	doMetricsReset = true,

	---When set to true, disables dynamic window padding
	---adjustments and uses the fixed `gui.paddingWidth` value.
	isPaddingLocked = false,

	---Current horizontal padding value used for centering UI elements.
	---Dynamically adjusted based on available window width.
	paddingWidth = 0,

	---Indicates whether there are active toast notifications pending.
	areToastsPending = false,

	---Maps `ImGui.ToastType` to their combined message strings.
	---@type table<ImGui.ToastType, string>
	toasterBumps = {}
}

---Stores per-vehicle editor state and recently used bundles.
local editor = {
	---Holds per-vehicle editor state for all mounted and recently edited vehicles.
	---The key is always the vehicle name and appearance name, separated by an asterisk (*).
	---Each entry tracks editor data and preset version states for the given vehicle.
	---@type table<string, IEditorBundle>
	bundles = {},

	---Stores the most recently accessed editor bundle.
	---@type IEditorBundle
	lastBundle = nil,

	---Determines whether overwriting the preset file is allowed.
	isOverwriteConfirmed = false
}

---Tracks state of the Preset File Explorer UI.
local explorer = {
	---Determines whether the Preset File Explorer is open.
	isOpen = false,

	---Search query entered in the Preset File Explorer.
	searchText = ExplorerCommands.INSTALLED,

	---Number of files currently displayed in the file browser.
	totalVisible = 0
}

--#endregion

--#region 🔧 Utility Functions

---Checks whether the provided argument is of the specified type.
---@param t string # The expected type name.
---@param v any # The value to check against the specified type.
---@return boolean # True if the argument match the specified type, false otherwise.
local function isType(t, v)
	return type(v) == t
end

---Checks whether all provided arguments is of type `function`.
---@param n any # Value to check.
---@return boolean # True if the argument is a function, false otherwise.
local function isFunction(n)
	return isType("function", n)
end

---Checks whether the provided argument is of type `boolean`.
---@param b any # Value to check.
---@return boolean # True if the argument is a voolean, false otherwise.
local function isBoolean(b)
	return isType("boolean", b)
end

---Checks whether all provided arguments is of type `number`.
---@param n any # Value to check.
---@return boolean # True if the argument is a number, false otherwise.
local function isNumber(n)
	return isType("number", n)
end

---Checks whether the provided argument is of type `string`.
---@param s any # Value to check.
---@return boolean # True if the argument is a string, false otherwise.
local function isString(s)
	return isType("string", s)
end

---Checks whether the provided argument is a non-empty string.
---Returns false if the argument is not a string or is an empty string.
---@param s any # Value to check.
---@return boolean # True if the argument is a non-empty string, false otherwise.
local function isStringValid(s)
	return isString(s) and #s > 0
end

---Checks whether the provided argument is of type `table`.
---@param t any # Value to check.
---@return boolean # True if the argument is a table, false otherwise.
local function isTable(t)
	return isType("table", t)
end

---Checks whether the provided argument is a non-empty table.
---Returns false if the argument is not a table or is an empty table.
---@param t any # Value to check.
---@return boolean # True if the argument is a non-empty table, false otherwise.
local function isTableValid(t)
	return isTable(t) and next(t) ~= nil
end

---Checks whether the provided argument is of type 'userdata'.
---@param u any Value to check.
---@return boolean # True if the argument is an userdata, false otherwise.
local function isUserdata(u)
	return isType("userdata", u)
end

---Attempts to determine a human-readable type name of a userdata value.
---@param v any # The value to check. Must be userdata to return a result.
---@return string? # A type name string if available, otherwise `nil`.
local function getUserdataType(v)
	if not isUserdata(v) then return nil end
	local mt = getmetatable(v)
	if isTable(mt) then
		local x = mt.__name or mt.__type or mt.__tag
		if isStringValid(x) then
			return x
		end
	end
	local s = tostring(v)
	return s:sub(1, 3) ~= "0x" and s or nil
end

---Checks whether the provided argument is of the specified custom type.
---@param t string # The expected type name.
---@param v any # The value to check against the specified type.
---@return boolean # True if the argument match the specified type, false otherwise.
local function isUserdataType(t, v)
	if t == nil then return false end
	return t == getUserdataType(v)
end

---Checks whether the provided argument is of type `Vector3`.
---@param v any # Value to check.
---@return boolean # True only if the argument is Vector3.
local function isVector3(v)
	return isUserdataType("sol.Vector3", v)
end

---Checks whether a value is nil or considered empty (string or table).
---@param v any # The value to check.
---@return boolean # True if the value is nil, an empty string, or an empty table.
local function nilOrEmpty(v)
	if v == nil then return true end
	local t = type(v)
	if t == "string" then return #v == 0 end
	if t == "table" then return next(v) == nil end
	return false
end

---Checks whether all provided arguments are of the specified type.
---@param t string # The expected type name.
---@param ... any # A variable number of values to check against the specified type.
---@return boolean # True if all arguments match the specified type, false otherwise.
local function areType(t, ...)
	for i = 1, select("#", ...) do
		local v = select(i, ...)
		if not isType(t, v) then
			return false
		end
	end
	return true
end

---Checks whether all provided arguments are of type `number`.
---@param ... any # Values to check.
---@return boolean # True if all arguments are numbers, false otherwise.
local function areNumber(...)
	return areType("number", ...)
end

---Checks whether all provided arguments are of type `string`.
---@param ... any # Values to check.
---@return boolean # True if all arguments are strings, false otherwise.
local function areString(...)
	return areType("string", ...)
end

---Checks whether all provided arguments are a non-empty strings.
---Returns false if any argument is not a string or is an empty string.
---@param ... any # Values to check.
---@return boolean # True if all arguments are non-empty strings, false otherwise.
local function areStringValid(...)
	for i = 1, select("#", ...) do
		local s = select(i, ...)
		if not isStringValid(s) then
			return false
		end
	end
	return true
end

---Checks whether all provided arguments are of type `table`.
---@param ... any # Values to check.
---@return boolean # True if all arguments are tables, false otherwise.
local function areTable(...)
	return areType("table", ...)
end

---Checks whether all provided arguments are non-empty tables.
---Returns false if any argument is not a table or is an empty table.
---@param ... any # Values to check.
---@return boolean # True if all arguments are non-empty tables, false otherwise.
local function areTableValid(...)
	for i = 1, select("#", ...) do
		local t = select(i, ...)
		if not isTableValid(t) then
			return false
		end
	end
	return true
end

---Checks whether all provided arguments are of the specified custom type.
---@param t string # The expected type name (a custom `__name` string).
---@param ... any # A variable number of values to check against the specified type.
---@return boolean # True if all arguments match the specified type, false otherwise.
local function areUserdataType(t, ...)
	for i = 1, select("#", ...) do
		local v = select(i, ...)
		if not isUserdataType(t, v) then
			return false
		end
	end
	return true
end

---Checks whether all provided arguments are of type `Vector3`.
---@param ... any # Values to check.
---@return boolean # True if all arguments are `Vector3`, false otherwise.
local function areVector3(...)
	return areUserdataType("sol.Vector3", ...)
end

---Determines whether a table is a pure sequence (array) with contiguous integer keys 1..#t.
---Returns false if any key is non-numeric or if there are gaps in the numeric index.
---@param t table # The table to test (nil or non-table will be treated as not an array).
---@return boolean # True if `t` is an array of length `#t` with no non-numeric keys.
local function isArray(t)
	if not isTable(t) then return false end
	local n = #t
	local c = 0
	for i in pairs(t) do
		if not isNumber(i) then
			return false
		end
		c = c + 1
	end
	return c == n
end

---Checks whether the given value represents a valid number (integer or float).
---@param x number|string The value to check.
---@return boolean # True if the value can be converted to a number, false otherwise.
local function isNumeric(x)
	return tonumber(x) ~= nil
end

---Checks whether all provided values represent valid numbers (integers or floats).
---@param ... number|string The values to check.
---@return boolean # True if all values can be converted to numbers, false otherwise.
local function areNumeric(...)
	for i = 1, select("#", ...) do
		local v = select(i, ...)
		if not isNumeric(v) then
			return false
		end
	end
	return true
end

---Compares two values for equality, including support for numbers with tolerance and nested tables.
---Performs deep comparison for tables and numeric tolerance (1e-4) for numbers or number-like strings.
---Also supports booleans, nil, functions, userdata, and threads using standard equality (`==`).
---Handles recursive tables safely using a visited map to prevent infinite loops.
---@param a any The first value to compare.
---@param b any The second value to compare.
---@param visited? table<any, any> Internal cache to handle cyclic table references (do not provide manually).
---@return boolean # True if values are considered equal, false otherwise.
local function equals(a, b, visited)
	if a == b then return true end
	if type(a) ~= type(b) then return false end

	if isNumber(a) then
		return abs(a - b) < 1e-4
	elseif isString(a) and areNumeric(a, b) then
		local na, nb = tonumber(a), tonumber(b)
		return abs(na - nb) < 1e-4
	elseif isTable(a) then
		visited = visited or {}
		if visited[a] and visited[a] == b then
			return true
		end
		visited[a] = b

		for k, va in pairs(a) do
			if not equals(va, b[k], visited) then
				return false
			end
		end
		for k, vb in pairs(b) do
			if not equals(vb, a[k], visited) then
				return false
			end
		end
		return true
	elseif areVector3(a, b) then
		return equals(a.x, b.x) and equals(a.y, b.y) and equals(a.z, b.z)
	end

	return false
end

---Checks whether a given value is contained within another value.
---For strings and numbers, it checks containment (prefix match for numbers, substring for strings).
---For tables, it distinguishes between arrays and key-value tables:
--- - Arrays: checks if any value equals the target.
--- - Key-value tables: checks if the key equals the target, or the value contains the target.
---@param x any The container value (string, number, or table).
---@param v any The value to search for.
---@return boolean # True if the value is found, false otherwise.
local function contains(x, v)
	if x == nil or v == nil then return false end
	if x == v then return true end

	if isUserdata(x) then
		local s = tostring(x)
		return contains(s, v)
	end

	if areNumeric(x, v) then
		local xs, vs = tostring(x), tostring(v)
		return #xs >= #vs and xs:sub(1, #vs) == vs
	end

	if isString(x) then
		local vs = tostring(v)
		return #x >= #vs and x:find(vs, 1, true) ~= nil
	end

	if not isTable(x) then return false end

	if isArray(x) then
		for _, e in ipairs(x) do
			if equals(e, v) then
				return true
			end
		end
		return false
	end

	for k, e in pairs(x) do
		if equals(k, v) or contains(e, v) then
			return true
		end
	end

	return false
end

---Checks if a string starts or ends with a given affix.
---@param s string # The string to check.
---@param v string # The prefix or suffix to match.
---@param atEnd boolean # If true, checks suffix (ends with); if false, checks prefix (starts with).
---@param caseInsensitive boolean? # If true, ignores case when comparing.
---@return boolean # True if the condition is met, false otherwise.
local function hasAffix(s, v, atEnd, caseInsensitive)
	if not s or not v then return false end
	s, v = tostring(s), tostring(v)
	if caseInsensitive then
		s = s:lower()
		v = v:lower()
	end
	local len = #v
	if #s == len then return s == v end
	if #s < len then return false end
	return (atEnd and s:sub(-len) or s:sub(1, len)) == v
end

---Checks if a string starts with a given prefix.
---@param s string # The string to check.
---@param v string # The prefix to match.
---@param caseInsensitive boolean? # True if string comparisons ignore letter case.
---@return boolean # True if `s` starts with `v`, false otherwise.
local function startsWith(s, v, caseInsensitive)
	return hasAffix(s, v, false, caseInsensitive)
end

---Checks if a string ends with a specified suffix.
---@param s string # The string to check.
---@param v string # The suffix to look for.
---@param caseInsensitive boolean? # True if string comparisons ignore letter case.
---@return boolean Returns # True if the `s` ends with the specified `v`, otherwise false.
local function endsWith(s, v, caseInsensitive)
	return hasAffix(s, v, true, caseInsensitive)
end

---Checks if a given filename string ends with `.lua`.
---@param s string # The value to check, typically a string representing a filename.
---@return boolean # True if the filename ends with `.lua`, otherwise false.
local function hasLuaExt(s)
	if not s then return false end
	return endsWith(s, ".lua", true)
end

---Returns the file name with a `.lua` extension. If the input already ends with `.lua`, it is returned unchanged.
---@param s string # The input value to be converted to a Lua file name.
---@return string # The file name with `.lua` extension, or an empty string if the input is `nil`.
local function ensureLuaExt(s)
	if not s then return "" end
	s = tostring(s)
	return hasLuaExt(s) and s or s .. ".lua"
end

---Removes the `.lua` extension from a filename if present.
---@param s string? # The filename to process.
---@return string # The filename without `.lua` extension, or the original string if no `.lua` extension is found.
local function trimLuaExt(s)
	if not s then return "" end
	s = tostring(s)
	return hasLuaExt(s) and s:sub(1, -5) or s
end

---Splits a string into a list of substrings using a specified separator.
---@param s string? # The input string to split. If nil, returns an empty table.
---@param sep string? # The separator to split by (default: ",").
---@param trim boolean? # If true, trims whitespace from each resulting entry.
---@return string[] # A list of substrings resulting from the split.
local function split(s, sep, trim)
	if not s then return {} end
	s = tostring(s)
	sep = sep or ","
	local t = {}
	for v in s:gmatch("([^" .. sep .. "]+)") do
		insert(t, trim and v:match("^%s*(.-)%s*$") or v)
	end
	return t
end

---Removes a substring from a string either globally, only at the start, or only at the end.
---@param s string The input string to process.
---@param sub string The substring to remove.
---@param mode number? # 1 = start only, -1 = end only, or anything else = remove all.
---@param caseInsensitive boolean? # If true, ignores case when matching the substring. Has no effect if mode is nil (removal anywhere).
---@return string The modified string with the specified removal.
local function strip(s, sub, mode, caseInsensitive)
	if not areString(s, sub) or #sub == 0 or #s < #sub then return s end

	if mode == 1 then
		if startsWith(s, sub, caseInsensitive) then
			return s:sub(#sub + 1)
		end
	elseif mode == -1 then
		if endsWith(s, sub, caseInsensitive) then
			return s:sub(1, - #sub - 1)
		end
	else
		local seek = sub:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
		return (s:gsub(seek, ""))
	end

	return s
end

---Returns a shortened version of the input string by removing a number of trailing underscore-separated parts.
---The number of parts removed depends on how many underscores are in the string.
---@param s string # The input string (e.g., "v_sport2_porsche_911turbo_player").
---@return string # The shortened string (e.g., "v_sport2_porsche").
local function chopUnderscoreParts(s)
	local t = {}
	s = tostring(s or "")
	for p in s:gmatch("[^_]+") do
		insert(t, p)
	end
	local n = #t / 2
	if n <= 1 then
		n = n + 1
	end
	return concat(t, "_", 1, n)
end

---Concatenates multiple path segments into a single path using '/' as separator.
---@vararg string # The path segments to combine.
---@return string # The combined path. Returns an empty string if no arguments are given.
local function combine(...)
	local len = select("#", ...)
	if len < 1 then return "" end
	if len == 1 then return select(1, ...) end
	return concat({ ... }, "/")
end

---Iterates over a table's keys in sorted order.
---Useful for producing stable output or consistent serialization.
---@param t table # The table to iterate over.
---@return fun(): any, any # An iterator that yields key-value pairs in sorted key order.
local function opairs(t)
	t = isTable(t) and t or {}
	local ks = {}
	for k in pairs(t) do
		insert(ks, k)
	end
	sort(ks, function(a, b)
		return tostring(a) < tostring(b)
	end)
	local i = 0
	return function()
		i = i + 1
		local k = ks[i]
		if k ~= nil then
			return k, t[k]
		end
	end
end

---Creates a deep copy of a given table, including nested subtables.
---@param t table # The table to copy.
---@param seen table? # Internal table to track already-copied references (prevents cycles).
---@return table # A new table with the same structure and values as the original.
local function clone(t, seen)
	if not isTable(t) then return t end
	if seen and seen[t] then return seen[t] end

	local result = {}
	seen = seen or {}
	seen[t] = result

	for k, v in pairs(t) do
		result[k] = clone(v, seen)
	end

	return result
end

---Ensures a nested table path exists and returns the deepest subtable if `t` is a valid table.
---@param t table # The table to access.
---@param ... any # Keys leading to the nested table
---@return any # The final nested subtable if `t` is a table; otherwise `nil`.
local function deep(t, ...)
	if not isTable(t) then return nil end
	for i = 1, select("#", ...) do
		local k = select(i, ...)
		t[k] = t[k] or {}
		t = t[k]
	end
	return t
end

---Safely retrieves a nested value from a table (e.g., table[one][two][three]).
---Returns a default value if any level is missing or invalid.
---@param t table # The root table to access.
---@param fallback any # The fallback value if the lookup fails.
---@param ... any # One or more keys representing the path.
---@return any # The nested value if it exists, or the default value.
local function get(t, fallback, ...)
	if not isTable(t) then return fallback end
	local v = t
	for i = 1, select("#", ...) do
		local k = select(i, ...)
		if not isTable(v) or k == nil then
			return fallback
		end
		v = rawget(v, k)
	end
	return v == nil and fallback or v
end

---Returns the value at the specified index from a variable list of arguments.
---If the index is beyond the number of available arguments, the last value is returned instead.
---@param i number # The index of the value to retrieve (1-based).
---@param ... any # A variable number of values to select from.
---@return any # The value at index `i`, or the last value if `i` is too large.
local function pick(i, ...)
	local len = select("#", ...)
	return select(i < len and i or len, ...)
end

---Converts any value to a readable string representation.
---For numbers, a trimmed 3-digit float format is used (e.g., 1.000 → "1", 3.140 → "3.14").
---For tables, the output is compact, recursively formatted, and uses sorted keys.
---Numeric keys in non-array tables are automatically converted to hexadecimal.
---@param x any # The value to convert to string.
---@param hexNums boolean? # Optional. If true, numeric values are output as hexadecimal (e.g., 255 → "0xFF").
---@return string # A string representation of the value.
local function serialize(x, hexNums)
	if not isTable(x) then
		if isString(x) then
			return format("%q", x)
		elseif isNumeric(x) then
			local str = format("%.2f", x):gsub("0+$", ""):gsub("%.$", "")
			return hexNums and format("0x%02X", str) or str
		elseif isVector3(x) then
			local t = {}
			for _, a in ipairs({ "x", "y", "z" }) do
				insert(t, serialize(x[a], hexNums))
			end
			return format("Vector3{x=%s,y=%s,z=%s}", unpack(t))
		else
			return tostring(x)
		end
	end

	if isArray(x) then
		local parts = {}
		for i = 1, #x do
			parts[i] = serialize(x[i], hexNums)
		end
		return format("{%s}", concat(parts, ","))
	end

	if not isTable(x) then return tostring(x) end

	if areNumber(x.Major, x.Minor, x.Build, x.Revision) then
		if x.Build > 0 and x.Revision > 0 then
			return format("%d.%d.%d.%d", x.Major, x.Minor, x.Build, x.Revision)
		elseif x.Build > 0 then
			return format("%d.%d.%d", x.Major, x.Minor, x.Build)
		else
			return format("%d.%d", x.Major, x.Minor)
		end
	end

	local parts = {}
	for k, v in opairs(x) do
		local key
		if isString(k) and k:match("^[%a_][%w_]*$") ~= nil then
			key = k
		else
			key = format("[%s]", serialize(k, isNumeric(k)))
		end
		parts[#parts + 1] = format("%s=%s", key, serialize(v, hexNums))
	end
	return format("{%s}", concat(parts, ","))
end

---Computes an Adler-53 checksum over one or more values without allocating a new table.
---
---This function implements a custom 53-bit variant of the Adler checksum algorithm,
---designed by me (Si13n7) through minimal mathematical adjustments to the original.
---
---It improves upon Adler-32 by using a much larger prime modulus and a wider final hash space,
---which significantly reduces the chance of hash collisions, even with shorter inputs.
---
---The result fits within Lua's numeric precision limit for integers (53 bits), making it safe
---to use as a numeric key or identifier without loss of accuracy.
---
---Compared to Adler-32, Adler-53 offers:
--- - A larger prime modulus (2^26-5) for better distribution
--- - Full use of Lua's 53-bit integer precision
--- - Improved robustness against uniform or repeating byte patterns
---
---This makes it suitable for identifying or caching structured values, serialized content,
---or any use case where a compact and deterministic hash is required.
---@param ... any # One or more values to include in the checksum calculation.
---@return integer # 53-bit checksum combining all arguments.
local function checksum(...)
	local prime = 0x3fffffb
	local a, b = 1, 0
	local len = select('#', ...)
	for i = 1, len do
		local v = select(i, ...)
		local s = serialize(v)
		for j = 1, #s do
			local x = s:byte(j)
			a = (a + x) % prime
			b = (b + a) % prime
		end
	end
	return floor(b * 2 ^ 26 + a)
end

---Checks whether a file with the given name exists and is readable.
---@param path string # The full or relative path to the file.
---@return boolean # True if the file exists and is readable, false otherwise.
local function fileExists(path)
	if not isString(path) then return false end
	local handle = io.open(path, "r")
	if handle then
		handle:close()
		return true
	end
	return false
end

---Parses a version string or returns an existing `IVersion` table.
---Accepts version formats like "[v]Major[.Minor[.Build[.Revision]]]".
---@param x table|string # A version input as a string, or IVersion table.
---@return IVersion # A table with Major, Minor, Build, and Revision fields as numbers.
local function parseVersion(x)
	if isTable(x) and isNumber(x.Major) then ---@cast x IVersion
		return x
	end
	if not isString(x) then
		x = tostring(x) ---@cast x string
	end
	local v1, v2, v3, v4 = x:match("^v?(%d+)%.?(%d*)%.?(%d*)%.?(%d*)$")
	return {
		Major = tonumber(v1) or 0,
		Minor = tonumber(v2) or 0,
		Build = tonumber(v3) or 0,
		Revision = tonumber(v4) or 0
	}
end

---Compares two version strings in "[v]Major[.Minor[.Build[.Revision]]]" format.
---Returns 1 if a > b, -1 if a < b, or 0 if equal.
---@param a IVersion|string # First version.
---@param b IVersion|string # Second version.
---@return integer # 1 if `a > b`, -1 if `a < b`, 0 if equal.
local function compareVersion(a, b)
	local v1 = parseVersion(a)
	local v2 = parseVersion(b)
	for _, k in ipairs({
		"Major",
		"Minor",
		"Build",
		"Revision"
	}) do
		local n1 = v1[k] or 0
		local n2 = v2[k] or 0
		if n1 > n2 then
			return 1
		elseif n1 < n2 then
			return -1
		end
	end
	return 0
end

---Checks if the current game version is less than or equal to the specified version.
---@param current IVersion|string # The version string to compare.
---@param require IVersion|string # Maxmium required version in "[v]major[.minor[.build[.revision]]]" format.
---@return boolean # True if the runtime version is <= the specified version, false otherwise.
local function isVersionAtMost(current, require)
	return compareVersion(current, require) <= 0
end

---Checks if the runtime version is greater than or equal to a specified minimum version.
---@param current IVersion|string # The version string to compare.
---@param require IVersion|string # Minimum required version in "[v]major[.minor[.build[.revision]]]" format.
---@return boolean # True if the runtime version is >= the specified version, false otherwise.
local function isVersionAtLeast(current, require)
	return compareVersion(current, require) >= 0
end

---Retrieves the current game version `string` or a parsed `IVersion` table.
---@return IVersion # Parsed version object if `asString` is false/nil, otherwise the version string.
local function getGameVersion()
	local raw = Game.GetSystemRequestsHandler():GetGameVersion()
	local ver = parseVersion(raw)
	if ver.Minor < 10 then ver.Minor = ver.Minor * 10 end
	return ver
end

---Retrieves the current CET (runtime) version `string` or a parsed `IVersion` table.
---@return IVersion # Parsed version object if `asString` is false/nil, otherwise the version string.
local function getRuntimeVersion()
	return parseVersion(GetVersion())
end

---Extracts the record name from a TweakDBID string representation.
---@param data TDBID # The TweakDBID to be parsed.
---@return string? # The extracted record name, or nil if not found.
local function getRecordName(data)
	if not data then return nil end
	if not contains(data, "--[[") or not contains(data, "--]]") then
		return TDBID.ToStringDEBUG(data)
	end
	return tostring(data):match("%-%-%[%[(.-)%-%-%]%]"):match("^%s*(.-)%s*$")
end

---Checks whether a cache (persistent or transient) contains any non-empty value.
---@param persistent boolean? # If true, check the persistent cache; otherwise check the transient cache.
---@return boolean # True if at least one entry exists and is not nil or empty, false otherwise.
local function isCachePopulated(persistent)
	for _, value in pairs(persistent and caches.persistent or caches.transient) do
		if not nilOrEmpty(value) then
			return true
		end
	end
	return false
end

---Retrieves a sub-cache from `caches.persistent` or `caches.transient`, initializing it with a default if it does not exist.
---@param id number # Unique ID of the sub-cache to retrieve.
---@param persistent boolean? # Optional. If true, use persistent cache; defaults to transient.
---@return any # The existing or initialized value of the sub-cache.
local function getCache(id, persistent)
	if not id then return nil end
	return persistent and caches.persistent[id] or caches.transient[id]
end

---Sets a sub-cache in `caches.persistent` or `caches.transient`, creating it if needed.
---@param id number # Unique ID of the sub-cache to set.
---@param value any # The table to store in the cache.
---@param persistent boolean? # Optional. If true, use persistent cache; defaults to transient.
local function setCache(id, value, persistent)
	value = value or nil
	if not id then return value end
	if persistent then
		caches.persistent[id] = value
	else
		caches.transient[id] = value
	end
	return value
end

---Resets either the `caches.persistent` or `caches.transient` by replacing it with a new empty table.
---@param persistent boolean? # If true, reset the persistent cache; otherwise reset the transient cache.
local function resetCache(persistent)
	if persistent then
		caches.persistent = {}
	else
		caches.transient = {}
	end
end

---Logs and displays messages based on the current `state.devMode` level.
---Messages can be written to the log file, printed to the console, or shown as in-game alerts.
---@param lvl LogLevelType # Logging level (0 = Info, 1 = Warning, 2 = Error).
---@param id integer # The ID used for location tracing.
---@param fmt string # A format string for the message.
---@vararg any # Additional arguments for formatting the message. Tables and userdata will be serialized automatically.
local function log(lvl, id, fmt, ...)
	if state.isLogSuspend or state.devMode < DevLevels.BASIC then return end

	lvl = max(LogLevels.INFO, min(lvl, LogLevels.ERROR))

	if nilOrEmpty(fmt) then
		lvl = LogLevels.ERROR
		fmt = "Format string in log() is empty!"
	end

	local cache = getCache(0x8069, true) or {}
	local hash = checksum(lvl, id, fmt, ...)
	local now = os.time()
	if cache[hash] and cache[hash] >= now then return end

	local cutoff = now - 60
	for k, v in pairs(cache) do
		if v < cutoff then
			cache[k] = nil
		end
	end

	cache[hash] = now + 5
	setCache(0x8069, cache, true)

	local len = select("#", ...)
	local tag = LogMeta[lvl].TAG
	local str
	if len < 1 then
		str = fmt
	else
		local args = {}
		for i = 1, len do
			local v = select(i, ...)
			args[i] = (isTable(v) or isUserdata(v)) and serialize(v) or v
		end
		local ok, result = pcall(format, fmt, unpack(args))
		str = ok and result or Text.LOG_FORMAT_INVALID
	end
	local msg = format("[TPVCamTool]  [%04X]  %s  %s", id or 0, tag, str)

	if state.devMode >= DevLevels.FULL then
		(lvl == LogLevels.ERROR and spdlog.error or spdlog.info)(msg)
	end

	if state.devMode >= DevLevels.ALERT then
		if state.isRuntimeFullVersion then
			local toast = format("%s %s", LogMeta[lvl].ICON, str)
			local kind = LogMeta[lvl].TOAST
			gui.toasterBumps[kind] = gui.toasterBumps[kind] and (gui.toasterBumps[kind] .. "\n\n" .. toast) or toast
			gui.areToastsPending = true
		else
			local player = Game.GetPlayer()
			if player then
				player:SetWarningMessage(msg, 5)
			end
		end
	end

	print(msg)
end

---Forces a log message to be emitted using a temporary `state.devMode` override.
---Useful for outputting messages regardless of the current developer mode setting.
---Internally calls `log()` with the given parameters, then restores the previous `state.devMode`.
---@param mode DevLevelType # Temporary development mode to use.
---@param lvl LogLevelType # Log level passed to `log()`.
---@param id integer # The ID used for location tracing.
---@param fmt string # Format string for the message.
---@vararg any # Optional arguments for formatting the message. Tables and userdata will be serialized automatically.
local function logF(mode, lvl, id, fmt, ...)
	if mode < DevLevels.BASIC or state.isLogSuspend and mode < DevLevels.OVERLAY then return end
	local prev = state.devMode
	state.devMode = prev < mode and mode or prev
	state.isLogSuspend = false
	log(lvl, id, fmt, ...)
	state.devMode = prev
end

---Logs a formatted message if the current `state.devMode` meets or exceeds the specified threshold.
---Internally calls `log()` with the given parameters.
---@param mode DevLevelType # Minimum development mode required to output the log.
---@param lvl LogLevelType # Log level passed to `log()`.
---@param id integer # The ID used for location tracing.
---@param fmt string # Format string for the message.
---@vararg any # Optional arguments for formatting the message. Tables and userdata will be serialized automatically.
local function logIf(mode, lvl, id, fmt, ...)
	if state.devMode == DevLevels.DISABLED or state.devMode < mode then return end
	state.isLogSuspend = false
	log(lvl, id, fmt, ...)
end

---Stops and removes an active async timer with the given ID.
---Has no effect if the ID is invalid or already cleared.
---@param id integer Timer ID to stop.
local function asyncStop(id)
	async.timers[id] = nil
	async.isActive = isTableValid(async.timers)
end

---Creates a recurring async timer that executes a callback every `interval` seconds.
---The first execution happens only after the initial interval has passed, not immediately at creation time.
---The callback receives the timer ID as its only argument.
---@param interval number Time in seconds between executions (absolute value is used).
---@param callback fun(id: integer) Function to execute each cycle.
---@return integer timerID Unique ID of the created timer, or -1 if invalid parameters were passed.
local function asyncRepeat(interval, callback)
	if not isFunction(callback) then
		return -1
	end

	async.idCounter = async.idCounter + 1

	local id = async.idCounter
	local time = abs(isNumber(interval) and interval or 0)
	async.timers[id] = {
		Interval = time,
		Callback = callback,
		Time = time,
		IsActive = true
	}

	async.isActive = true

	return id
end

---Executes the callback immediately once, then creates a recurring async timer that executes the callback every `interval` seconds.
---@param interval number Time in seconds between executions (absolute value is used).
---@param callback fun(id: integer) Function to execute each cycle.
---@return integer timerID Unique ID of the created timer, or -1 if invalid parameters were passed.
local function asyncRepeatBurst(interval, callback)
	if not isFunction(callback) then
		return -1
	end
	local id = asyncRepeat(interval, callback)
	callback(id)
	return id
end

---Creates a one-shot async timer that executes a callback once after `delay` seconds.
---@param delay number Time in seconds before execution (absolute value is used).
---@param callback fun(id: integer?) Function to execute once after the delay.
---@return integer timerID Unique ID of the created timer, or -1 if invalid parameters were passed.
local function asyncOnce(delay, callback)
	if not isFunction(callback) then
		return -1
	end
	return asyncRepeat(delay, function(id)
		asyncStop(id)
		callback(id)
	end)
end

--#endregion

--#region 🚗 Vehicle Metadata

---Returns a list of all player vehicles from the game database.
---@return TDBID[] # An array of all vehicle records.
local function getPlayerVehicles()
	local cache = getCache(0x4003, true)
	if cache then return cache end
	return setCache(0x4003, TweakDB:GetFlat("Vehicle.vehicle_list.list") or {}, true)
end

---Returns the number of vanilla vehicles in the game, depending on the game version.
---@return number # The total count of vanilla vehicles.
local function getVanillaVehicleCount()
	local cache = getCache(0x0a00, true)
	if cache then return cache end
	return setCache(0x0a00, isVersionAtMost(getGameVersion(), "2.20") and 85 or 105, true)
end

---Finds the name of a vehicle based on its TweakDB ID.
---@param tid TDBID # The TweakDB ID of the vehicle to look up.
---@return string? # The vehicle name if found and valid, otherwise nil.
local function findVehicleName(tid)
	if not tid or not isNumber(tid.hash) then return nil end

	local vehicles = getPlayerVehicles()
	for _, v in ipairs(vehicles) do
		if v.hash == tid.hash then
			local name = getRecordName(v)
			if isStringValid(name) then
				return name
			end
			break
		end
	end

	return getRecordName(tid)
end

---Retrieves all appearance entries for a given vehicle name.
---@param name string # The name of the vehicle.
---@return VehicleAppearance[]? # A table of appearance entries if found, or `nil` if the name is invalid or the resource cannot be loaded.
local function getVehicleApperances(name)
	if not isStringValid(name) then
		logIf(DevLevels.FULL, LogLevels.ERROR, 0x8d0c, Text.LOG_ARG_INVALID)
		return nil
	end

	local path = TweakDB:GetFlat(format("Vehicle.%s.entityTemplatePath", name))
	if not path then return nil end

	local depot = Game.GetResourceDepot()
	if not depot then return nil end

	local loader = depot:LoadResource(path)
	if not loader then return nil end

	local resource = loader:GetResource()
	return resource and resource.appearances or nil
end

---Searches for a vehicle appearance matching a given key within a vehicle's appearances.
---@param name string # The name of the vehicle.
---@param key string # The key or prefix to match against appearance names.
---@return string? # Returns the matching appearance name if found, otherwise `nil`.
local function findVehicleApperance(name, key)
	local apps = getVehicleApperances(name)
	if not isTableValid(apps) then
		logIf(DevLevels.FULL, LogLevels.ERROR, 0x57a1, Text.LOG_ARG_OUT_OF_RANGE)
		return nil
	end ---@cast apps VehicleAppearance[]

	for _, app in ipairs(apps) do
		local cname = app and app.name
		if cname then
			local str = Game.NameToString(cname)
			if cname and startsWith(str, key) then
				return str
			end
		end
	end

	return nil
end

---Builds a map of all unique player vehicle and appearance names. Optionally skips vanilla vehicles.
---@param customOnly boolean # If true, only custom vehicles will be included.
---@return table? # A table where keys are vehicle or appearance identifiers and values are `true`. Returns nil if no vehicles are found.
---@return number # Number of entries in the returned table, or -1 if no vehicles are found.
local function getAllUniqueVehicleIdentifiers(customOnly)
	local vehicles = getPlayerVehicles()
	if nilOrEmpty(vehicles) then
		logIf(DevLevels.FULL, LogLevels.ERROR, 0x7a6e, Text.LOG_ARG_INVALID)
		return nil, -1
	end

	local start = customOnly and getVanillaVehicleCount() + 1 or 1
	local length = #vehicles
	if start > length then
		logIf(DevLevels.FULL, LogLevels.ERROR, 0x7a6e, Text.LOG_ARG_OUT_OF_RANGE)
		return nil, -1
	end

	local result = {}
	local amount = 0
	for i = start, length do
		local name = TDBID.ToStringDEBUG(vehicles[i])
		if nilOrEmpty(name) then goto continue end ---@cast name string

		name = name:gsub("^Vehicle%.", "")
		if nilOrEmpty(name) or result[name] then goto continue end

		result[name] = true
		amount = amount + 1

		local apps = getVehicleApperances(name)
		if nilOrEmpty(apps) then goto continue end ---@cast apps table

		for x = 1, #apps, 1 do
			local raw = apps[x]
			local cname = raw and raw.name or nil
			if cname then
				local appName = Game.NameToString(cname)
				if not result[appName] then
					result[appName] = true
					amount = amount + 1
				end
			end
		end

		::continue::
	end

	return result, amount
end

---Checks if the player is currently inside a vehicle.
---@return boolean # True if the player exists and is mounted in a vehicle, otherwise false.
local function isVehicleMounted()
	local player = Game.GetPlayer()
	return player ~= nil and Game.GetMountedVehicle(player) ~= nil
end

---Retrieves the vehicle the player is currently mounted in, if any.
---Internally retrieves the player instance and checks for an active vehicle.
---@return Vehicle? # The currently mounted vehicle instance, or nil if the player is not mounted.
local function getMountedVehicle()
	local cache = getCache(0xecd7)
	if isUserdata(cache) then return cache end

	local player = Game.GetPlayer()
	if not player then
		logIf(DevLevels.ALERT, LogLevels.WARN, 0xecd7, Text.LOG_PLAYER_UNDEFINED)
		return nil
	end

	return setCache(0xecd7, Game.GetMountedVehicle(player))
end

---Determines the status of a mounted vehicle.
---@return integer # Vehicle status code:
--- - -1: No valid vehicle found (missing TDBID or lookup failed)
--- - 0: Crowd vehicle (vanilla, but not part of the player vehicle list)
--- - 1: Player vanilla vehicle (index <= 105, or <= 85 on game version <= 2.20)
--- - 2: Custom/modded vehicle (index above threshold)
local function getVehicleStatus()
	local cache = getCache(0xddf2)
	if cache then return cache end

	local result = -1
	local vehicle = getMountedVehicle()
	if vehicle then
		local tid = vehicle:GetTDBID()
		if tid then
			for i, v in ipairs(getPlayerVehicles()) do
				if v.hash == tid.hash then
					result = i <= getVanillaVehicleCount() and 1 or 2
					break
				end
			end
			result = result > 0 and result or 0
		end
	end

	return setCache(0xddf2, result)
end

---Retrieves the list of third-person camera preset keys for the mounted vehicle.
---Each key is in the form "Camera.VehicleTPP_<CameraID>_<Level>".
---@return string[]? # Array of camera preset keys, or `nil` if not found.
local function getVehicleCameraKeys()
	local cache = getCache(0xe98c)
	if isTableValid(cache) then return cache end

	local vehicle = getMountedVehicle()
	if not vehicle then return nil end

	local vid = vehicle:GetRecordID()
	if not vid then
		logIf(DevLevels.ALERT, LogLevels.ERROR, 0xe98c, Text.LOG_VEH_REC_ID_MISS)
		return nil
	end

	local vname = findVehicleName(vid)
	if not vname then
		logIf(DevLevels.ALERT, LogLevels.ERROR, 0xe98c, Text.LOG_VEH_REC_NAME_MISS)
		return nil
	end

	local record = TweakDB:GetFlat(vname .. ".tppCameraPresets")
	if not isTable(record) then return nil end ---@cast record table

	local list = {}
	for _, v in ipairs(record) do
		local name = getRecordName(v)
		if not name then goto continue end

		insert(list, name)

		::continue::
	end

	if isTableValid(list) then
		return setCache(0xe98c, list)
	end

	return nil
end

---Attempts to retrieve the custom camera ID associated with the mounted vehicle.
---@return string? # The extracted custom camera ID (e.g., "lotus_camera") or nil if not found.
local function getCustomVehicleCameraID()
	local cache = getCache(0x4509)
	if isString(cache) then return isStringValid(cache) and cache or nil end

	local keys = getVehicleCameraKeys()
	if not isTable(keys) then return nil end ---@cast keys string[]

	local ids = {}
	local seen = {}

	for _, v in ipairs(keys) do
		--Strip known suffix.
		local id = v:gsub("%.tppCameraPresets%$[%x]+$", "")

		--Iteratively remove known prefixes.
		repeat
			local prev = id
			id = strip(id, ".", 1)
			id = strip(id, "_", 1)
			id = strip(id, "VehicleTPP", 1, true)
			id = strip(id, "Camera", 1, true)
			id = strip(id, "Vehicle", 1, true)
		until id == prev

		--Remove known suffixes.
		for _, s in ipairs(CameraData.Levels) do
			id = strip(id, s, -1, true)
			id = strip(id, ".", -1)
			id = strip(id, "_", -1)
		end

		--Only insert non-empty ID.
		if #id > 0 and not seen[id] then
			insert(ids, id)
			seen[id] = true
		end
	end

	--Filter vanilla defaults.
	for _, p in pairs(presets.collection) do
		if not p.IsDefault or p.IsJoined or not isString(p.ID) then
			goto continue
		end

		for i = #ids, 1, -1 do
			if startsWith(p.ID, ids[i]) then
				remove(ids, i)
				break
			end
		end

		::continue::
	end

	if isTableValid(ids) then
		return setCache(0x4509, tostring(ids[1]))
	end

	--Caches negative results to avoid repeated lookups when nothing is found.
	setCache(0x4509, "")
	return nil
end

---Attempts to retrieve the camera ID associated with the mounted vehicle.
---@return string? # The extracted camera ID (e.g., "4w_911") or nil if not found.
local function getVehicleCameraID()
	local cache = getCache(0xe9aa)
	if isString(cache) then return cache end

	local keys = getVehicleCameraKeys()
	if not isTable(keys) then return nil end ---@cast keys string[]

	--Works in 99.9 percent of cases.
	for _, v in pairs(keys) do
		local match = v:match("^[%a]+%.VehicleTPP_([%w_]+)_[%w_]+_[%w_]+")
		if match then
			return setCache(0xe9aa, match)
		end
	end

	--Rock-solid solution for obfuscated TweakDB key overrides.
	local result = getCustomVehicleCameraID()
	return result and setCache(0xe9aa, result) or nil
end

---Builds a robust and reliable map for vehicle camera TweakDB keys based on their internal data.
---This method is especially useful when keys are obfuscated (e.g., modded content with hashed or unreadable key names).
---@return table<string, string>? # A map from camera preset names (e.g., "High_Close") to raw TweakDB key strings.
local function getVehicleCameraMap()
	local cache = getCache(0xca33)
	if isTableValid(cache) then return cache end

	local keys = getVehicleCameraKeys()
	if not isTable(keys) then return nil end ---@cast keys string[]

	--Rock-solid solution for obfuscated TweakDB key overrides.
	local map = {}
	for _, v in pairs(keys) do
		local height = TweakDB:GetFlat(v .. ".height")
		if not height then goto continue end

		local heightName = getRecordName(height)
		if not heightName then goto continue end

		local distance = TweakDB:GetFlat(v .. ".distance")
		if not distance then goto continue end

		local distanceName = getRecordName(distance)
		if not distanceName then goto continue end

		--Workaround for mislabeled Low/High YAML tweaks.
		local search = ({ Low = "_high", High = "_low" })[heightName]
		if search and contains(v:lower(), search) then
			heightName = heightName == "Low" and "High" or "Low"
			TweakDB:SetFlat(v .. ".height", heightName)
		end

		map[format("%s_%s", heightName, distanceName)] = v

		::continue::
	end

	return isTableValid(map) and setCache(0xca33, map) or nil
end

---Attempts to retrieve the name of the mounted vehicle.
---@return string? # The resolved vehicle name as a string, or `nil` if it could not be determined.
local function getVehicleName()
	local cache = getCache(0x3ae2)
	if isString(cache) then return cache end

	local vehicle = getMountedVehicle()
	if not vehicle then return nil end

	local tid = vehicle:GetTDBID()
	if not tid then return nil end

	local str = findVehicleName(tid)
	return str and setCache(0x3ae2, str:gsub("^Vehicle%.", "")) or nil
end

---Attempts to retrieve the appearance name of the mounted vehicle.
---@return string? # The resolved vehicle name as a string, or `nil` if it could not be determined.
local function getVehicleAppearanceName()
	local vehicle = getMountedVehicle()
	if not vehicle then return nil end

	local cname = vehicle:GetCurrentAppearanceName()
	if cname then
		return Game.NameToString(cname)
	end
end

---Retrieves the display name of the currently mounted vehicle.
---@return string? # The display name of the mounted vehicle, or `nil` if no name available.
local function getVehicleDisplayName()
	local cache = getCache(0x05b4)
	if isStringValid(cache) then return cache end

	local vehicle = getMountedVehicle()
	if not vehicle then return nil end

	local name = vehicle:GetDisplayName()
	if not name then return nil end

	return setCache(0x05b4, name:gsub("„", '"'):gsub("“", '"'))
end

--#endregion

--#region 🧬 Tweak Accessors

---Update the global default parameter values in TweakDB.
---Iterates over all entries in `config.options` and applies clamping,
---default assignment, type coercion and optional restoring.
---@param restore boolean? # If true, values are reset to their default.
local function updateDefaultParams(restore)
	if not areTableValid(DefaultParams.Keys, config.options) then return end

	for varName, data in pairs(config.options) do
		if not data.IsDefaultParam then
			data.Value = data.Value or data.Default
			goto continue
		end

		for _, baseKey in ipairs(DefaultParams.Keys) do
			local key = format("%s.%s", baseKey, varName)
			local current = TweakDB:GetFlat(key)
			if current == nil then goto continue end

			local isNum = isNumber(current)
			local hasMinMax = areNumber(data.Min, data.Max)
			if isNum and hasMinMax then
				current = min(max(current, data.Min), data.Max)
			end
			if data.Default == nil then
				data.Default = current
			end
			if data.Value == nil then
				data.Value = current
			end
			if type(current) ~= type(data.Value) then
				data.Value = isNum and (data.Value and 1 or 0) or ((data.Value or 0) > 0)
			end

			if restore then
				if current ~= data.Default then
					TweakDB:SetFlat(key, data.Default)
					logIf(DevLevels.ALERT, LogLevels.INFO, 0x602e, Text.LOG_PARAM_REST, key, data.Default)
				end
				goto continue
			end

			if current == data.Value then goto continue end
			local value = isNum and hasMinMax and min(max(data.Value, data.Min), data.Max) or data.Value
			TweakDB:SetFlat(key, value)
			logIf(DevLevels.ALERT, LogLevels.INFO, 0x602e, Text.LOG_PARAM_SET, key, value)

			::continue::
		end

		::continue::
	end
end

---Returns a formatted TweakDB record key for accessing vehicle camera data.
---@param preset ICameraPreset # The camera preset.
---@param path string # The camera level path (e.g. "High_Close").
---@param var string # The variable name.
---@param skipCustom boolean? # True, skips checking for a custom key; otherwise, custom keys will be evaluated.
---@return string? # The formatted TweakDB record key (may be a custom key).
---@return string? # The original key, only returned if the formatted key is a custom entry.
local function getCameraTweakKey(preset, path, var, skipCustom)
	if not isTable(preset) then return nil, nil end

	local id = preset.ID
	if not areString(id, path, var) or get(CameraDataInvalidLevelMap, false, id, path) then
		return nil, nil
	end

	if not skipCustom and isString(getCustomVehicleCameraID()) then
		local map = getVehicleCameraMap()
		if isTableValid(map) then ---@cast map table
			local key = map[path]
			if isString(key) then
				return format("%s.%s", key, var), getCameraTweakKey(preset, path, var, true)
			end
		end
	end

	local isBasilisk = id == "v_militech_basilisk_CameraPreset"
	if isBasilisk and (startsWith(path, "Low") or contains(path, "DriverCombat")) then
		return nil, nil
	end

	local section = isBasilisk and "Vehicle" or "Camera"
	return format("%s.VehicleTPP_%s_%s.%s", section, id, path, var), nil
end

---Gets the default rotation pitch value for a given camera preset and path.
---@param preset ICameraPreset # The camera preset.
---@param path string # The camera path for the vehicle.
---@return number # The default rotation pitch for the given camera path.
local function getCameraDefaultRotationPitch(preset, path)
	local key = getCameraTweakKey(preset, path, "defaultRotationPitch")

	local isLow = startsWith(path, "Low_")
	local defaults = {
		["4w_aerondight"]                   = { low = 04, high = 12 },
		["4w_Preset"]                       = { low = 04, high = 15 },
		["4w_SubCompact_Preset"]            = { low = 12, high = 12 },
		v_militech_basilisk_CameraPreset    = { low = 05, high = 05 },
		v_utility4_militech_behemoth_Preset = { low = 05, high = 12 },
		default                             = { low = 04, high = 11 }
	}

	local def = defaults[preset.ID] or defaults.default
	local defVal = isLow and def.low or def.high

	if not key then return defVal end

	local value = tonumber(TweakDB:GetFlat(key))
	if isLow and value ~= nil then
		local lowValue = value - 7
		if lowValue == abs(lowValue) then
			value = lowValue
		end
	end

	return value or defVal
end

---Sets the default rotation pitch for a given camera preset and path.
---@param preset ICameraPreset # The camera preset.
---@param path string # The camera path for the vehicle.
---@param value number # The value to set for the default rotation pitch.
local function setCameraDefaultRotationPitch(preset, path, value)
	if not isNumber(value) then return end

	local key, isCustom = getCameraTweakKey(preset, path, "defaultRotationPitch")
	if not key then return end

	local fallback = getCameraDefaultRotationPitch(preset, path)
	if not fallback then return end

	--Adjust low camera.
	if startsWith(path, "Low_") then
		value = value - 7
		logIf(DevLevels.FULL, LogLevels.INFO, 0x5c19, Text.LOG_PARAM_IS_LOW, key)
	end

	if equals(value, fallback) then return end

	--Backup default value for shutdown.
	if isCustom and not presets.restoreParams[key] then
		presets.restoreParams[key] = fallback
		logIf(DevLevels.ALERT, LogLevels.INFO, 0x5c19, Text.LOG_PARAM_BACKUP, key, fallback)
	end

	--Finally, set the new value.
	TweakDB:SetFlat(key, value)
	logIf(DevLevels.FULL, LogLevels.INFO, 0x5c19, Text.LOG_PARAM_SET, key, value)
end

---Gets the look-at offset value for a given camera preset and path.
---@param preset ICameraPreset # The camera preset.
---@param path string # The camera path to retrieve the offset for.
---@return Vector3? # The camera offset as a Vector3.
local function getCameraLookAtOffset(preset, path)
	local key = getCameraTweakKey(preset, path, "lookAtOffset")
	return key and TweakDB:GetFlat(key) or nil
end

---Sets the look-at offset for a given camera preset and path.
---@param preset ICameraPreset # The camera preset.
---@param path string # The camera path to set the offset for.
---@param x number # The X-coordinate of the camera position.
---@param y number # The Y-coordinate of the camera position.
---@param z number # The Z-coordinate of the camera position.
local function setCameraLookAtOffset(preset, path, x, y, z)
	if not areNumber(x, y, z) then return end

	local key, isCustom = getCameraTweakKey(preset, path, "lookAtOffset")
	if not key then return end

	local fallback = getCameraLookAtOffset(preset, path)
	if not fallback then return end

	--Adjust combat camera.
	if contains(path, "DriverCombat") then
		z = z + 0.5
	end

	local value = Vector3.new(x or fallback.x, y or fallback.y, z or fallback.z)
	if equals(value, fallback) then return end

	--Backup default value for shutdown.
	if isCustom and not presets.restoreParams[key] then
		presets.restoreParams[key] = fallback
		logIf(DevLevels.ALERT, LogLevels.INFO, 0xb786, Text.LOG_PARAM_BACKUP, key, fallback)
	end

	--Finally, set the new value.
	TweakDB:SetFlat(key, value)
	logIf(DevLevels.FULL, LogLevels.INFO, 0xb786, Text.LOG_PARAM_SET, key, value)
end

---Gets the boom length offset value for a given camera preset and path.
---@param preset ICameraPreset # The camera preset.
---@param path string # The camera path for the vehicle.
---@return number # The boom length offset for the given camera path.
local function getCameraBoomLengthOffset(preset, path)
	local key = getCameraTweakKey(preset, path, "boomLengthOffset")
	return key and (tonumber(TweakDB:GetFlat(key)) or 0) or 0
end

---Sets the boom length offset for a given camera preset and path.
---@param preset ICameraPreset # The camera preset.
---@param path string # The camera path for the vehicle.
---@param value number # The value to set for the boom length offset.
local function setCameraBoomLengthOffset(preset, path, value)
	if not isNumber(value) then return end

	local key, isCustom = getCameraTweakKey(preset, path, "boomLengthOffset")
	if not key then return end

	--Adjust combat camera.
	if contains(path, "DriverCombat") then
		value = value + 0.5
	end

	local fallback = getCameraBoomLengthOffset(preset, path)
	if not fallback or equals(value, fallback) then return end

	--Backup default value for shutdown.
	if isCustom and not presets.restoreParams[key] then
		presets.restoreParams[key] = fallback
		logIf(DevLevels.ALERT, LogLevels.INFO, 0x25a4, Text.LOG_PARAM_BACKUP, key, fallback)
	end

	--Finally, set the new value.
	TweakDB:SetFlat(key, value)
	logIf(DevLevels.FULL, LogLevels.INFO, 0x25a4, Text.LOG_PARAM_SET, key, value)
end

---Resets custom camera behavior values for the mounted vehicle to their global defaults.
---Ensures modded vehicles do not override global TweakDB values such as FOV or camera locking.
---This operation can be undone using `restoreAllCustomCameraData`.
---@param key string # The vehicle's preset key. Used for cache.
local function resetCustomDefaultParams(key)
	if not key then return end

	local cache = getCache(0xf5d6, true) or {}
	if cache[key] then return end

	cache[key] = true
	setCache(0xf5d6, cache, true)

	local vehicle = getMountedVehicle()
	if not vehicle then return end

	local vtid = vehicle:GetTDBID()
	if not vtid then return end

	local vname = TDBID.ToStringDEBUG(vtid)
	if not vname then return end

	local cptid = TweakDB:GetFlat(vname .. ".tppCameraParams")
	if not cptid then return end

	local cparam = TDBID.ToStringDEBUG(cptid)
	if not cparam or contains(DefaultParams.Keys, cparam) then return end

	local baseKey = DefaultParams.Keys[contains(cparam:lower(), "_2w_") and 2 or 1]
	for _, varName in ipairs(DefaultParams.Vars) do
		local cKey = cparam .. "." .. varName
		local val = TweakDB:GetFlat(cKey)
		if not val then goto continue end

		local rKey = baseKey .. "." .. varName
		local ref = TweakDB:GetFlat(baseKey .. "." .. varName)
		if not ref then
			if not isBoolean(val) then goto continue end
			ref = false
		end

		if not equals(val, ref) then
			if not presets.restoreParams[cKey] then
				presets.restoreParams[cKey] = val
			end

			TweakDB:SetFlat(cKey, ref)
			logF(DevLevels.BASIC, LogLevels.INFO, 0x460a, Text.LOG_PARAM_MANIP, cKey, val, ref, rKey)
		end

		::continue::
	end
end

---Resets custom camera behavior values for the mounted vehicle to their defaults.
---This operation can be undone using `restoreAllCustomCameraData`.
---@param key string # The vehicle's preset key. Used for cache.
local function resetCustomCameraVars(key, preset)
	if not key then return end

	local cache = getCache(0x810b, true) or {}
	if cache[key] then return end

	cache[key] = true
	setCache(0x810b, cache, true)

	for _, path in ipairs(CameraData.Levels) do
		for _, var in ipairs(CameraData.Vars) do
			local ckey, dkey = getCameraTweakKey(preset, path, var)
			if not ckey or not dkey or presets.restoreParams[ckey] then goto continue end

			local def = TweakDB:GetFlat(dkey)
			if def == nil then goto continue end

			local val = TweakDB:GetFlat(ckey)
			if equals(val, def) then goto continue end

			presets.restoreParams[ckey] = val
			TweakDB:SetFlat(ckey, def)
			logF(DevLevels.BASIC, LogLevels.INFO, 0x810b, Text.LOG_PARAM_MANIP, ckey, val, def, dkey)

			::continue::
		end
	end
end

---Restores all previously overridden custom camera behavior values.
---Only re-applies values if they differ from the current ones in TweakDB.
---Requires `presets.restoreParams` to contain valid entries; otherwise, nothing happens.
local function restoreAllCustomCameraData()
	if not isTableValid(presets.restoreParams) then return end

	for k, v in pairs(presets.restoreParams) do
		local value = TweakDB:GetFlat(k)
		if not equals(value, v) then
			TweakDB:SetFlat(k, v)
			logF(DevLevels.BASIC, LogLevels.INFO, 0x09ea, Text.LOG_PARAM_REST, k, v)
		end
	end

	presets.restoreParams = {}
	setCache(0xf5d6, nil, true) --resetCustomDefaultParams
	setCache(0x810b, nil, true) --resetCustomCameraVars
end

--#endregion

--#region ⚖️ Preset Management

---Checks whether a preset with the given key exists and matches the specified camera ID.
---Returns true only if the preset is present in `presets.collection ` and its `ID` matches `id`.
---@param key string # The key under which the preset is stored in the `presets.collection ` table.
---@param id string # The camera ID of the mounted vehicle.
---@return boolean # True if the preset exists and has a matching ID, false otherwise.
local function presetExists(key, id)
	local preset = get(presets.collection, nil, key)
	return preset and preset.ID == id
end

---Attempts to find the best matching key in the `presets.collection ` table using one or more candidate values.
---It first checks for exact matches, and then for prefix-based partial matches.
---@param ... string # One or more strings to match against known preset keys (e.g., vehicle name, appearance name).
---@return string? # The matching key from `presets.collection `, or `nil` if no match was found.
local function findPresetKey(...)
	local id = getVehicleCameraID()
	local length, result
	for pass = 1, 2 do
		if pass == 2 then
			length = 0
		end
		for i = 1, select("#", ...) do
			local search = select(i, ...)
			for key, preset in pairs(presets.collection) do
				if preset.ID ~= id then goto continue end

				if pass == 1 and search == key then
					return key
				elseif pass == 2 and startsWith(search, key) then
					local len = #key
					if len > length then
						length = len
						result = key
					end
				end

				::continue::
			end
		end
	end
	return result
end

---Validates a new preset key based on the given vehicle and appearance names.
---Ensures the key is non-empty, meets the minimum length, and matches expected name prefixes.
---@param vehicleName string # The base vehicle name used for validation.
---@param appearanceName string # The appearance variant of the vehicle. May be the same as `vehicleName`.
---@param currentKey string # The currently active or fallback preset key. Used as return value on failure.
---@param newKey string? # The newly entered preset key that should be validated.
---@return string # Returns the validated preset key (without `.lua` extension), or `currentKey` if validation fails.
local function validatePresetKey(vehicleName, appearanceName, currentKey, newKey)
	if not areString(vehicleName, appearanceName) then return currentKey end
	if not isString(currentKey) then return vehicleName end
	if not isString(newKey) then return currentKey end

	local name = trimLuaExt(newKey)
	if #name < 1 then
		logIf(DevLevels.ALERT, LogLevels.WARN, 0x19fd, Text.LOG_PSET_BLANK_NAME)
		return currentKey
	end

	if startsWith(vehicleName, name) or
		startsWith(appearanceName, name) then
		return name
	end

	if vehicleName ~= appearanceName then
		logIf(DevLevels.ALERT, LogLevels.WARN, 0x19fd, Text.LOG_PSET_NAMES_MISM, vehicleName, appearanceName)
	else
		logIf(DevLevels.ALERT, LogLevels.WARN, 0x19fd, Text.LOG_PSET_NAME_MISM, vehicleName)
	end

	return currentKey
end

---Retrieves the current camera offset data for the specified camera ID from TweakDB and returns it as a `ICameraPreset` table.
---@param id string # The camera ID to query.
---@return ICameraPreset? # The retrieved camera offset data, or nil if not found.
local function getPreset(id)
	if not id then return nil end

	local preset = { ID = id } ---@cast preset ICameraPreset
	for i, path in ipairs(CameraData.Levels) do
		local vec3 = getCameraLookAtOffset(preset, path)
		if not vec3 or (not vec3.x and not vec3.y and not vec3.z) then goto continue end

		local level = PresetInfo.Levels[(i - 1) % 3 + 1]
		local angle = getCameraDefaultRotationPitch(preset, path)
		local dist = getCameraBoomLengthOffset(preset, path)

		preset[level] = {
			a = tonumber(angle),
			x = tonumber(vec3.x),
			y = tonumber(vec3.y),
			z = tonumber(vec3.z),
			d = tonumber(dist),
		}

		if preset.Far and preset.Medium and preset.Close then
			logIf(DevLevels.ALERT, LogLevels.INFO, 0x198c, Text.LOG_CAM_OSET_DONE, id)
			return preset
		end

		::continue::
	end

	log(LogLevels.ERROR, 0x198c, Text.LOG_CAM_OSET_MISS, id)
	return nil
end

---Retrieves the default preset that matches the given preset's camera ID.
---@param preset ICameraPreset # The preset to search for a default version.
---@return ICameraPreset? # Returns the default preset if found, otherwise nil.
local function getDefaultPreset(preset)
	if not preset then return nil end

	local id = preset.ID
	if not id then return nil end

	for _, item in pairs(presets.collection) do
		if item.IsDefault and item.ID == id then
			logIf(DevLevels.ALERT, LogLevels.INFO, 0xaced, Text.LOG_PSET_DEF_FOUND, id)
			return item
		end
	end

	log(LogLevels.WARN, 0xaced, Text.LOG_PSET_DEF_MISS, id)

	local fallback = getPreset(id)
	if not fallback then return nil end

	--Ensures unique key to prevent conflicts.
	local key = format("%x_%s", checksum(id), id)

	fallback.IsDefault = true
	fallback.IsJoined = true
	presets.collection[key] = fallback

	log(LogLevels.INFO, 0xaced, Text.LOG_PSET_DEF_JOINED, key)

	return fallback
end

---Returns the Y and Z offset values from a preset or its fallback.
---@param preset ICameraPreset? # The main preset table containing `Close`, `Medium`, or `Far` levels.
---@param fallback ICameraPreset? # The fallback preset table used if values are missing in the main preset.
---@param level "Close"|"Medium"|"Far" # The level to fetch ("Close", "Medium", or "Far").
---@return number a # The angle value. Falls back to 11 if not found.
---@return number x # The X offset value. Falls back to 0 if not found.
---@return number y # The Y offset value. Falls back to 0 if not found.
---@return number z # The Z offset value. Falls back to a default per level (Close = 1.115, Medium = 1.65, Far = 2.25).
---@return number d # The distance value. Falls back to a default per level (Close = 0, Medium = 1.5, Far = 4).
local function getOffsetData(preset, fallback, level)
	if not isTable(preset) or not contains(PresetInfo.Levels, level) then
		logF(DevLevels.FULL, LogLevels.ERROR, 0x21d6, Text.LOG_PSET_LVL_MISS, level)
		return 0, 0, 0, 0, 0 --Should never be returned with the current code.
	end ---@cast preset ICameraPreset

	local p = preset[level]
	local f = (fallback and fallback[level]) or {}

	local a = tonumber(p and p.a or f.a) or 11
	local x = tonumber(p and p.x or f.x) or 0
	local y = tonumber(p and p.y or f.y) or 0
	local z = tonumber(p and p.z or f.z) or ({ Close = 1.115, Medium = 1.65, Far = 2.25 })[level]
	local d = tonumber(p and p.d or f.d) or ({ Close = 0, Medium = 1.5, Far = 4 })[level]

	return a, x, y, z, d
end

---Applies a camera offset preset to the vehicle by updating values in TweakDB.
---If no `preset` is provided, the preset is looked up automatically based on the mounted vehicle.
---Missing values in the preset are replaced with fallback values from the default preset, if available.
---Each successfully applied preset ID is recorded in `presets.restoreStack`.
---@param preset ICameraPreset? # The preset to apply. May be `nil` to auto-resolve via the current vehicle.
---@param id string? # The camera ID of the mounted vehicle.
local function applyPreset(preset, id)
	if not preset then
		local name = getVehicleName()
		if not name then return end

		local appName = getVehicleAppearanceName()
		if not appName then return end

		local key = name == appName and findPresetKey(name) or findPresetKey(name, appName)
		if not key then return end

		local cid = getVehicleCameraID()
		if not cid then return end

		logIf(DevLevels.ALERT, LogLevels.INFO, 0x9583, Text.LOG_CAM_PSET, key)

		local pset = presets.collection[key]
		if not isTableValid(pset) then return end

		if pset.IsVanilla and get(config.options, false, "noVanilla", "Value") then
			return
		end

		resetCustomDefaultParams(key)
		resetCustomCameraVars(key, pset)
		applyPreset(pset, cid)

		--Tracks usage statistics.
		local usage = presets.usage[key] or {}
		usage.Last = os.time()
		usage.First = usage.First or usage.Last
		usage.Total = usage.Total and (usage.Total + 1) or 1
		presets.usage[key] = usage
		presets.isUsageUnsaved = true
		return
	end

	if not isStringValid(preset.ID) then
		logF(DevLevels.BASIC, LogLevels.ERROR, 0x9583, Text.LOG_PSET_APPLY_FAIL)
		return
	end

	if isString(id) and id ~= preset.ID then
		logIf(DevLevels.ALERT, LogLevels.WARN, 0x9583, Text.LOG_CAM_ID_MISM, preset.ID, id)
		return
	end

	local isDefault = preset.IsDefault
	local fallback = isDefault and preset or getDefaultPreset(preset) or {}
	for i, path in ipairs(CameraData.Levels) do
		local level = PresetInfo.Levels[(i - 1) % 3 + 1]
		local a, x, y, z, d = getOffsetData(preset, fallback, level)

		setCameraDefaultRotationPitch(preset, path, a)
		setCameraLookAtOffset(preset, path, x, y, z)
		setCameraBoomLengthOffset(preset, path, d)
	end
	if not isDefault then
		presets.isAnyActive = true
	end

	insert(presets.restoreStack, preset.ID)
end

---Restores all camera offset presets to their default values.
local function restoreAllPresets()
	for _, preset in pairs(presets.collection) do
		if preset.IsDefault then
			applyPreset(preset)
		end
	end
	presets.restoreStack = {}

	log(LogLevels.INFO, 0x8438, Text.LOG_PSETS_REST_DEF)
end

---Restores modified camera offset presets to their default values.
local function restoreModifiedPresets()
	local changed = presets.restoreStack
	if not isTableValid(changed) then return end

	local amount = #changed
	local restored = 0
	for _, preset in pairs(presets.collection) do
		if preset.IsDefault and contains(changed, preset.ID) then
			applyPreset(preset)
			restored = restored + 1
			log(LogLevels.INFO, 0xe126, Text.LOG_PSET_REST, preset.ID)
		end
		if restored >= amount then break end
	end
	presets.restoreStack = {}

	log(LogLevels.INFO, 0xe126, Text.LOG_PSETS_REST, restored, amount)
end

---Validates whether the given camera offset preset is structurally valid.
---A preset is valid if it has a string ID and at least one of Close, Medium,
---or Far contains a numeric `y` or `z` value.
---@param preset ICameraPreset # The preset to validate.
---@return boolean # True if the preset is valid, false otherwise.
local function isPresetValid(preset)
	if not isTable(preset) or not isStringValid(preset.ID) then return false end

	for _, e in ipairs(PresetInfo.Levels) do
		local offset = preset[e]
		if not isTable(offset) then
			goto continue
		end
		for _, k in ipairs(PresetInfo.Offsets) do
			if isNumber(offset[k]) then
				return true
			end
		end
		::continue::
	end

	return false
end

---Adds, updates, or removes a preset entry in the `presets.collection ` table.
---@param key string # The key under which the preset is stored (usually the preset name without ".lua").
---@param preset ICameraPreset? # The preset to store. If `nil`, the existing entry will be removed.
---@return boolean # True if the operation was successful (added, updated or removed), false if the key is invalid or the preset is not valid.
local function setPresetEntry(key, preset)
	if not isString(key) then return false end

	if preset == nil then
		if presets.collection[key] ~= nil then
			presets.isUsageUnsaved = true
			presets.collection[key] = nil
		end
		return true
	end

	if not isPresetValid(preset) then return false end

	presets.collection[key] = preset
	return true
end

--#endregion

--#region 💾 Preset File Control

---Builds the absolute path to a preset file based on its name and vehicle status.
---@param name string # The base name of the preset file (with or without `.lua` extension).
---@param status integer # Vehicle status code. Matches getVehicleStatus(), with one exception:
--- - -1 = defaults (special case, not equal by getVehicleStatus)
--- -  0 = crowd vanilla vehicle
--- -  1 = player vanilla vehicle
--- -  2 = custom/modded vehicle
--- - any other value is treated as custom
---@return string # The full path to the preset file, or an empty string if name is invalid.
local function getPresetFilePath(name, status)
	if not isString(name) then return "" end

	local path
	if status == -1 then
		path = PresetFolders.DEFAULTS
	elseif status == 0 or status == 1 then
		path = PresetFolders.VANILLA
	else
		path = PresetFolders.CUSTOM
	end

	return combine(path, ensureLuaExt(name))
end

---Checks whether a preset file with the given name exists in the appropriate folder.
---Automatically adds the ".lua" extension if missing.
---@param name string # The name of the preset file (with or without ".lua" extension).
---@param isDefault boolean? # If true, checks the "defaults" directory instead of "presets".
---@return boolean # True if the file exists, false otherwise.
local function presetFileExists(name, isDefault)
	if not isStringValid(name) then return false end

	if isDefault then
		local path = getPresetFilePath(name, -1)
		return fileExists(path)
	end

	name = ensureLuaExt(name)
	for key, value in pairs(PresetFolders) do
		if key ~= "DEFAULTS" then
			local path = combine(value, name)
			if fileExists(path) then
				return true
			end
		end
	end

	return false
end

---Removes camera presets from the global `presets.collection ` table.
---If no key is provided, clears all presets
---If a key is provided, removes only entries whose keys start with the given prefix.
---@param key string? # Optional key prefix used to filter which presets to remove.
local function purgePresets(key)
	if not isString(key) then
		presets.collection = {}
		log(LogLevels.WARN, 0x176b, Text.LOG_CAMS_ALL_CLEARED)
		return
	end ---@cast key string

	local c = 0
	for k in pairs(presets.collection) do
		if startsWith(k, key) then
			presets.collection[k] = nil
			c = c + 1
		end
	end

	log(LogLevels.WARN, 0x176b, Text.LOG_CAMS_CLEARED, c, key)
end

---Loads a single camera preset file, validates it, and registers it if applicable.
---Checks if the preset is relevant for custom/modded vehicles.
---@param file string # The preset filename (with `.lua` extension).
---@param folder string # Directory where the preset file is located.
---@param count integer # Current number of successfully loaded presets.
---@param vehicleNames table<string, boolean>? # Optional map of vehicle names and their apperance names to validate the preset against.
---@return integer # Updated count of successfully loaded presets.
local function loadPresetFile(file, folder, count, vehicleNames)
	if not state.isModEnabled or not file or not hasLuaExt(file) then return count end

	local key = trimLuaExt(file)
	if presets.collection[key] then
		count = count + 1
		logF(DevLevels.BASIC, LogLevels.WARN, 0x0305, Text.LOG_PSET_SKIPPED, key, folder, file)
		return count
	end

	--Ensures that presets are only loaded for vehicles that are actually installed.
	if vehicleNames then ---@cast vehicleNames table<string, boolean>
		local isValid = vehicleNames[key] ~= nil

		if not isValid then
			for name in pairs(vehicleNames) do
				if startsWith(name, key) then
					isValid = true
					break
				end
				if isValid then break end
			end
		end

		if not isValid then
			logIf(DevLevels.ALERT, LogLevels.INFO, 0x0305, Text.LOG_PSET_IGNORED, key, folder, file)
			return count
		end
	end

	local path = combine(folder, file)
	local chunk, err = loadfile(path)
	if not chunk then
		logF(DevLevels.BASIC, LogLevels.ERROR, 0x0305, Text.LOG_PSET_LOAD_FAIL, folder, file, err)
		return count
	end

	local ok, result = pcall(chunk)
	if not ok or not result then
		logF(DevLevels.BASIC, LogLevels.WARN, 0x0305, Text.LOG_PSET_EXE_FAIL, folder, file)

		local success, error = pcall(os.remove, path)
		if success then
			logF(DevLevels.BASIC, LogLevels.INFO, 0x0305, Text.LOG_PSET_DELETED, path)
		else
			logF(DevLevels.BASIC, LogLevels.WARN, 0x0305, Text.LOG_PSET_DEL_FAIL, path, error)
		end

		return count
	end

	if not setPresetEntry(key, result) then
		logF(DevLevels.BASIC, LogLevels.ERROR, 0x0305, Text.LOG_PSET_INVALID, folder, file)
		return count
	end

	count = count + 1
	logIf(DevLevels.FULL, LogLevels.INFO, 0x0305, Text.LOG_PSET_LOAD, key, folder, file)
	return count
end

---Loads all valid preset files from the specified folder.
---Automatically handles all different location folders differently.
---For custom folders, files are loaded asynchronously in small batches to avoid blocking,
---due to the verification process that checks if each preset matches an installed vehicle.
---@param path string # One of the paths from `PresetFolders` (DEFAULTS, VANILLA, CUSTOM) indicating which folder to load presets from.
local function loadPresetsFrom(path)
	if not state.isModEnabled then return end

	local isVan = path == PresetFolders.VANILLA
	local noVan = get(config.options, false, "noVanilla", "Value")
	if isVan and noVan then return end

	local isDef = path == PresetFolders.DEFAULTS
	local files = dir(path)
	if files then
		local task = presets.loaderTask
		local count = 0

		if isDef or isVan then
			task.StartTime = os.clock()
			for _, v in ipairs(files) do
				count = loadPresetFile(v.name, path, count)
			end
			task.EndTime = os.clock()

			local duration = task.EndTime - task.StartTime
			task.Duration = (task.Duration or 0) + duration

			if isDef and count < 39 then
				state.isModEnabled = false
				logF(DevLevels.FULL, LogLevels.ERROR, 0x98e0, Text.LOG_PSETS_DEF_BROKEN)
			end

			local text = isDef and Text.LOG_PSETS_LOAD_DEF or Text.LOG_PSETS_LOAD_VAN
			state.isLogSuspend = false
			logF(DevLevels.BASIC, LogLevels.INFO, 0x98e0, text, count, #files - 1, duration)
			return
		end

		task.IsActive = true
		task.StartTime = os.clock()
		task.EndTime = task.StartTime
		task.Duration = task.Duration or 0

		local isBusy = false
		local length = #files - 1
		local iterations = ceil(length / 5)
		local index, file

		--Workaround to query all custom vehicle appearances. I'm not sure
		--if this is a CET bug or intended behavior, but it doesn't seem to
		--matter when I call it. On the very first time, only about half of
		--the appearances that should be available are returned. The query
		--must be forced at least one frame before the actual action. The
		--result is discarded, only to ensure that the next queries returns
		--all appearances.
		local names, amount
		local interval = 0
		asyncRepeatBurst(interval, function(id)
			local map, quantity = getAllUniqueVehicleIdentifiers(true)
			logIf(DevLevels.BASIC, LogLevels.INFO, 0x98e0, Text.LOG_VEH_UIDS, quantity)
			if quantity == amount or interval >= 1 then
				asyncStop(id)
				names = map
				return
			end
			amount = quantity
			interval = interval + .1
		end)

		asyncRepeat(0.1, function(id)
			if isBusy or not names then return end
			isBusy = true
			for _ = 1, iterations do
				index, file = next(files, index)
				if not file then
					asyncStop(id)
					task.EndTime = os.clock()
					task.IsActive = false
					return
				end
				count = loadPresetFile(file.name, path, count, names)
			end
			isBusy = false
		end)

		asyncRepeat(1, function(id)
			if task.IsActive then return end
			asyncStop(id)

			local duration = task.EndTime - task.StartTime
			task.Duration = task.Duration + duration

			state.isLogSuspend = false

			logF(DevLevels.BASIC, LogLevels.INFO, 0x98e0, Text.LOG_PSETS_LOAD_CUS, count, length, duration)
			logF(DevLevels.BASIC, LogLevels.INFO, 0x98e0, Text.LOG_PSETS_LOAD_IGNO, length - count)
			logF(DevLevels.ALERT, LogLevels.INFO, 0x98e0, Text.LOG_PSETS_LOAD_DONE, task.Duration)

			task.Duration = 0

			if isFunction(task.Finalizer) then
				task.Finalizer()
			end
		end)

		return
	end

	state.isModEnabled = false
	logF(DevLevels.FULL, LogLevels.ERROR, 0x98e0, Text.LOG_PSETS_DIR_MISS, path)
end

---Loads all camera presets from the defaults, vanilla, and custom folders.
---@param refresh boolean? # Whether to clear existing presets before loading.
---@param delay number? # Optional delay before execution.
local function loadPresets(refresh, delay)
	if refresh then purgePresets() end

	delay = abs(isNumber(delay) and delay or 0)
	asyncOnce(delay, function()
		loadPresetsFrom(PresetFolders.DEFAULTS)
		loadPresetsFrom(PresetFolders.VANILLA)
		loadPresetsFrom(PresetFolders.CUSTOM)
	end)
end

---Saves a camera preset to file, either as a regular preset or as a default.
---It serializes only values that differ from the default (unless saving as default).
---@param name string # The name of the preset file (with or without `.lua` extension).
---@param preset table # The preset data to save (must include an `ID` and valid offset data).
---@param allowOverwrite boolean? # Whether existing files may be overwritten.
---@param forceDefault boolean? # If true, saves the preset to the `defaults` directory instead of `presets`.
---@return boolean # True on success, or false if writing failed or nothing needed to be saved.
local function savePreset(name, preset, allowOverwrite, forceDefault)
	if not isStringValid(name) or not isTableValid(preset) then return false end

	local status = getVehicleStatus()
	local isVanilla = status == 0 or status == 1
	local path = combine(
		forceDefault and PresetFolders.DEFAULTS or
		isVanilla and PresetFolders.VANILLA or
		PresetFolders.CUSTOM, ensureLuaExt(name))
	if not isStringValid(path) then return false end

	--To always save all values, as the currently retrieved defaults may change in future.
	local isCustom = preset.ID == getCustomVehicleCameraID()

	if not allowOverwrite and not isCustom then
		local check = io.open(path, "r")
		if check then
			check:close()
			log(LogLevels.WARN, 0x8515, Text.LOG_PSET_FILE_EXIST, path)
			return false
		end
	end

	local default = getDefaultPreset(preset) or {}
	local save = false
	local parts = { "return{" }
	insert(parts, format("ID=%q,", preset.ID))
	for _, mode in ipairs(PresetInfo.Levels) do
		local p = preset[mode]
		local d = default[mode]
		local sub = {}

		if isTable(p) then
			d = isTable(d) and d or {}
			for _, k in ipairs(PresetInfo.Offsets) do
				if isCustom or forceDefault or not equals(p[k], d[k]) then
					save = true
					insert(sub, format("%s=%s", k, serialize(p[k])))
				end
			end
		end

		if #sub > 0 then
			insert(parts, format("%s={%s},", mode, concat(sub, ",")))
		end
	end

	if not save then
		log(LogLevels.WARN, 0x8515, Text.LOG_PSET_NOT_CHANGED, path, default.ID)

		if not forceDefault then
			local ok, err = os.remove(path)
			if ok then
				logF(DevLevels.ALERT, LogLevels.WARN, 0x8515, Text.LOG_PSET_DELETED, path)
			else
				logF(DevLevels.FULL, LogLevels.ERROR, 0x8515, Text.LOG_PSET_DEL_FAIL, path, err)
			end
			return ok and setPresetEntry(name)
		end

		return false
	end

	if forceDefault then
		insert(parts, "IsDefault=true")
	elseif isVanilla then
		insert(parts, "IsVanilla=true")
	end

	local last = parts[#parts]
	if last and last:sub(-1) == "," then
		parts[#parts] = last:sub(1, -2)
	end

	insert(parts, "}")

	local file = io.open(path, "w")
	if not file then
		return false
	end
	file:write(concat(parts))
	file:close()

	logF(DevLevels.ALERT, LogLevels.INFO, 0x8515, Text.LOG_PSET_SAVED, path)

	return true
end

---Loads preset usage statistics from `.usage.lua`.
local function loadPresetUsage()
	local path = ".usage.lua"
	if not fileExists(path) then
		--Rename outdated file.
		local outdated = trimLuaExt(path)
		if fileExists(outdated) then
			local ok, _ = os.rename(outdated, path)
			if not ok then path = outdated end
		end
	end

	local chunk = loadfile(path)
	if not chunk then return end

	local ok, data = pcall(chunk)
	if ok and isTable(data) then
		presets.usage = data
		return
	end
end

---Saves the `presets.usage` table to `.usage.lua` on disk.
local function savePresetUsage()
	if not presets.isUsageUnsaved then return end
	presets.isUsageUnsaved = false

	if not isTableValid(presets.usage) then return end

	--Removes outdated backup file.
	local backup = ".usage.bak"
	if fileExists(backup) then
		pcall(os.remove, backup)
	end

	local cleaned = {}
	for name, usage in pairs(presets.usage) do
		if presets.collection[name] then
			cleaned[name] = usage
		end
	end
	presets.usage = cleaned

	local path = ".usage.lua"
	if nilOrEmpty(cleaned) then
		if fileExists(path) then
			pcall(os.remove, path)
		end
		return
	end

	local file = io.open(path, "w")
	if file then
		file:write("return" .. serialize(cleaned))
		file:close()
	end
end

---Loads settings from a JSON file and applies them.
---@param path string? Optional file path.
local function loadGlobalOptions(path)
	path = isStringValid(path) and path or ".globals.json"

	local file = io.open(path, "r")
	if not file then return end

	local content = file:read("*a")
	file:close()
	if nilOrEmpty(content) then return end

	local ok, result = pcall(json.decode, content)
	if not ok or not isTableValid(result) then return end

	for varName, data in pairs(config.options) do
		local item = result[varName]
		if item and item.Value then
			data.Value = item.Value
		end
	end
end

---Saves the `config.options` table to `.globals.lua` on disk.
local function saveGlobalOptions()
	if not config.isUnsaved then return end
	config.isUnsaved = false

	if not isTable(config.options) then return end

	local path = ".globals.json"
	if not isTableValid(config.options) then
		if fileExists(path) then
			pcall(os.remove, path)
		end
		return
	end

	--Removes outdated backup file.
	local backup = path .. ".bak"
	if fileExists(backup) then
		pcall(os.remove, backup)
	end

	local relevantData = {}
	for varName, data in pairs(config.options) do
		if not equals(data.Value, data.Default) then
			relevantData[varName] = {
				Value = data.Value
			}
		end
	end

	--No need to save a file if everything is set to default.
	if nilOrEmpty(relevantData) then
		if fileExists(path) then
			pcall(os.remove, path)
		end
		return
	end

	--Save changes to file.
	local file = io.open(path, "w")
	if file then
		file:write(json.encode(relevantData))
		file:close()
	end
end

--#endregion

--#region 🧪 Preset Editor

---Generates a checksum token for a camera preset by combining its ID and offset tables.
---@param preset ICameraPreset # The camera preset containing fields `ID`, `Close`, `Medium`, and `Far`.
---@return integer # Adler-53 checksum of `preset.ID`, `preset.Close`, `preset.Medium`, `preset.Far`, or -1 if invalid.
local function getEditorPresetToken(preset)
	if not isTable(preset) then return -1 end
	return checksum(preset.ID, preset.Close, preset.Medium, preset.Far)
end

---Creates a new editor preset entry from a camera preset.
---@param preset ICameraPreset # The source camera preset.
---@param key string # Identifier/name for this preset entry.
---@param snapshot boolean? # If true, deep-copies `preset` and clears its `IsDefault` flag.
---@param verify boolean? # If true, sets `IsPresent` by checking the file system.
---@return IEditorPreset # A table with fields: Preset, Key, Name, Token, IsPresent.
local function getEditorPreset(preset, key, snapshot, verify)
	local object = preset

	if snapshot then
		object = clone(object)
	end

	return {
		Preset = object,
		Key = key,
		Name = key,
		Token = getEditorPresetToken(object),
		IsPresent = verify and presetFileExists(key) or false
	}
end

---Retrieves (and if necessary initializes) the four editor‐preset entries for a given arguments.
---If the entries already exist in `editor.bundles`, it simply returns them.
---@param name string # Vehicle name (e.g. "v_sport2_porsche_911turbo_player").
---@param appName string # Appearance name (e.g. "porsche_911turbo__basic_johnny").
---@param id string # Camera-preset ID for TweakDB lookup.
---@param key string # Preset key/alias used for storage and display.
---@return IEditorBundle? # Returns the editor bundle containing Flux, Pivot, Finale, Nexus, and Tasks entries, or `nil` if initialization failed.
local function getEditorBundle(name, appName, id, key)
	local bundle = deep(editor.bundles, format("%s*%s", name, appName)) ---@cast bundle IEditorBundle

	if not areTable(bundle.Flux, bundle.Pivot, bundle.Finale, bundle.Nexus, bundle.Tasks) then
		local flux = getPreset(id)
		if not flux then
			log(LogLevels.WARN, 0xf0b7, Text.LOG_PSET_NOT_FOUND, id)
			return
		end

		bundle.Flux = getEditorPreset(flux, key)
		bundle.Pivot = getEditorPreset(flux, key, true)
		bundle.Finale = getEditorPreset(flux, key, true, true)

		local nexus = getDefaultPreset(flux) ---@cast nexus ICameraPreset
		bundle.Nexus = getEditorPreset(nexus, key, true, true)

		bundle.Tasks = {
			Rename = false,
			Validate = false,
			Apply = false,
			Save = false,
			Restore = false
		}
	end

	return bundle
end

---Clears the last editor bundle if no pending tasks are active.
local function clearLastEditorBundle()
	local bundle = editor.lastBundle
	if not isTable(bundle) then return end

	if bundle.Tasks.Apply or
		bundle.Tasks.Save or
		bundle.Tasks.Restore then
		return
	end

	local flux = get(bundle, {}, "Flux")
	local key = flux.Key
	local hash = flux.Token
	if key and hash and not presetFileExists(key) and hash == get(bundle, {}, "Nexus").Token then
		presets.collection[key] = nil

		log(LogLevels.INFO, 0xbc48, Text.LOG_PSET_DELETED, key)
	end

	bundle.Flux = nil
	bundle.Pivot = nil
	bundle.Finale = nil
	bundle.Nexus = nil

	editor.lastBundle = nil

	log(LogLevels.INFO, 0xbc48, Text.LOG_PSET_EDIT_DELETED)
end
function ClearLastEditorBundle() clearLastEditorBundle() end

---Replaces an existing editor preset entry with values from another and updating its checksum.
---@param src IEditorPreset # The source preset entry whose data will be copied.
---@param dest IEditorPreset # The preset entry to overwrite (modified in place).
---@param verify boolean? # If true, recomputes `IsPresent` by checking the file system for `src.Key`.
local function replaceEditorPreset(src, dest, verify)
	if not areTable(src, dest) then return end

	local preset = clone(src.Preset)
	dest.Preset = preset
	dest.Key = src.Key
	dest.Name = src.Name
	dest.Token = getEditorPresetToken(preset)
	dest.IsPresent = verify and presetFileExists(src.Key) or false

	local cache = getCache(0xcb3d) --onDraw
	if cache then
		cache.key = nil
	end
end

---Applies the current UI-edited camera preset to the internal preset registry.
---Updates the pivot state, clears the old entry, and assigns any preserved overrides.
---@param key string # The key under which the current preset will be stored.
---@param flux IEditorPreset # The edited preset containing user modifications.
---@param pivot IEditorPreset # The previously applied preset; will be overwritten with `flux`.
---@param tasks IEditorTasks # Tracks pending editor actions; `Apply` will be cleared here.
local function applyEditorPreset(key, flux, pivot, tasks)
	if not isString(key) or not areTable(flux, pivot, tasks) then return end

	tasks.Apply = false

	local isVanilla = false
	if presets.collection[pivot.Key] then
		isVanilla = presets.collection[pivot.Key].IsVanilla
	end

	presets.collection[pivot.Key] = nil
	if not tasks.Restore then
		if isVanilla then
			flux.Preset.IsVanilla = true
		end
		presets.collection[key] = flux.Preset
	end

	replaceEditorPreset(flux, pivot)

	logF(DevLevels.ALERT, LogLevels.INFO, 0x1e64, Text.LOG_PSET_UPDATED, key)
end

---Saves the current camera preset to disk and updates the saved (finale) state.
---Performs overwrite, cleanup of old files on rename, and syncs the checksum.
---@param key string # The key used as filename for saving the preset (without `.lua` extension).
---@param flux IEditorPreset # The currently edited preset with unsaved modifications.
---@param finale IEditorPreset # The last saved version of the preset; will be updated to match `flux`.
---@param tasks IEditorTasks # Tracks pending editor actions; will reset `Save`, `Restore`, and optionally `Rename`.
---@param status integer # Vehicle status used to determine the folder path:
--- - 0 = crowd vanilla vehicle
--- - 1 = player vanilla vehicle
--- - 2 = custom/modded vehicle
local function saveEditorPreset(key, flux, finale, tasks, status)
	if not isString(key) or not areTable(flux, finale, tasks) or not isNumber(status) or status == -1 then
		logIf(DevLevels.FULL, LogLevels.ERROR, 0xebb8, Text.LOG_ARG_INVALID)
		return
	end

	if not savePreset(key, flux.Preset, true) then
		logF(DevLevels.ALERT, LogLevels.WARN, 0xebb8, Text.LOG_PSET_NOT_SAVED, key)
		return
	end

	tasks.Restore = false
	tasks.Save = false

	if tasks.Rename then
		tasks.Rename = false
		local path = getPresetFilePath(finale.Name, status)
		local ok, err = isStringValid(path) and os.remove(path) or false, nil
		if not ok then
			logF(DevLevels.FULL, LogLevels.ERROR, 0xebb8, Text.LOG_PSET_DEL_FAIL, finale.Name, flux.Name, err)
		end

		presets.collection[finale.Key] = nil
	end

	replaceEditorPreset(flux, finale, true)
end

--#endregion

--#region 🎨 UI Layout Helpers

---Calculates UI layout metrics based on the current content region and font size.
---Uses a baseline font height of 18px to derive a scale factor.
---If `gui.isPaddingLocked` is true and `gui.paddingWidth` is already set, returns the locked value.
---@return number width # Available width of the content region in pixels.
---@return number half # Half of `width` minus half the item spacing.
---@return number spacing # Item spacing width.
---@return number scale # UI scale factor (fontSize / 18).
---@return number padding # Computed horizontal padding (pixels), at least 10 * scale when unlocked.
local function getMetrics()
	local w = ImGui.GetContentRegionAvail()

	local st = ImGui.GetStyle()
	local sp = st.ItemSpacing.x

	local h = ImGui.GetFontSize()
	local s = h / 18

	if gui.doMetricsReset then
		w = 240 * s
	end

	local hf = w * 0.5
	hf = min(hf, ceil(abs(hf - (sp * 0.5))))

	if gui.isPaddingLocked then
		return w, hf, sp, s, gui.paddingWidth
	end

	local bw = 240 * s
	local bo = 22 * s
	local rp = (w - bw) * 0.5 + bo - sp
	gui.paddingWidth = ceil(max(16 * s, rp))

	return w, hf, sp, s, gui.paddingWidth
end

---Aligns the next ImGui item horizontally, vertically, or both.
---If `x` is a number, only vertical alignment is applied using it as cell height.
---If `x` is a string, both horizontal (right-aligned) and vertical centering are enabled by default.
---@param x string|number # Text to align (string) or cell height to vertically center (number).
---@param hAlign boolean? # If true, right-aligns the next item. Defaults to true if `x` is a string.
---@param vAlign boolean? # If true, vertically centers the next item. Defaults to true.
---@param cellHeight number? # Optional height of the cell for vertical centering. Ignored if `x` is a number.
local function alignNext(x, hAlign, vAlign, cellHeight)
	if isNumber(x) then ---@cast x number
		if hAlign then
			hAlign = false
		end
		cellHeight = x
	elseif isString(x) then
		if not isBoolean(hAlign) then
			hAlign = true
		end
	else
		return
	end

	if vAlign == nil then
		vAlign = true
	end

	local style = ImGui.GetStyle()
	local fh = ImGui.GetFontSize()

	if hAlign then ---@cast x string
		local cw = ImGui.GetColumnWidth()
		local tw = ImGui.CalcTextSize(x)
		local cx = ImGui.GetCursorPosX()
		ImGui.SetCursorPosX(cx + cw - tw)
	end

	if vAlign then
		local cy = ImGui.GetCursorPosY()
		local oy = cellHeight or (fh + style.FramePadding.y * 2)
		ImGui.SetCursorPosY(cy + (oy - fh) * 0.5)
	end
end

---Adjusts an ABGR color by modifying its alpha, blue, green, and red (weird order in LUA) components.
---@param c integer # The input color in 0xAARRGGBB format.
---@param aa integer? # Amount to add to the alpha channel.
---@param bb integer? # Amount to add to the blue channel.
---@param gg integer? # Amount to add to the green channel.
---@param rr integer? # Amount to add to the red channel.
---@return integer # The resulting adjusted color in 0xAARRGGBB format.
local function adjustColor(c, aa, bb, gg, rr)
	if not isNumber(c) then return 0 end

	local a = band(rshift(c, 24), 0xff)
	local b = band(rshift(c, 16), 0xff)
	local g = band(rshift(c, 8), 0xff)
	local r = band(c, 0xff)

	a = isNumber(aa) and min(0xff, a + aa) or a
	b = isNumber(bb) and min(0xff, b + bb) or b
	g = isNumber(gg) and min(0xff, g + gg) or g
	r = isNumber(rr) and min(0xff, r + rr) or r

	return bor(lshift(a, 24), lshift(b, 16), lshift(g, 8), r)
end

---Generates three color variants from a base color for use in UI styling (e.g., normal, hovered, active).
---Each subsequent variant increases brightness slightly on BGR channels.
---@param base integer # The base color in 0xAAGGBBRR format.
---@return integer, integer, integer # Returns three color variants: base, hover, and active.
local function getThreeColorsFrom(idx, base)
	if not isNumber(base) then return 0, 0, 0 end

	local alpha = idx == ImGuiCol.Button and 0xff or 0
	local hover = adjustColor(base, alpha, 32, 32, 32)
	local active = adjustColor(base, alpha, 64, 64, 64)

	return base, hover, active
end

---Pushes a set of up to three related style colors to ImGui's style stack: base, hovered, and active.
---Calculated automatically from a single base color by brightening B, G, and R (weird order in LUA) channels.
---Returns the number of pushed styles so they can be popped accordingly.
---@param idx integer # The ImGuiCol index for the base color (e.g. ImGuiCol.FrameBg or ImGuiCol.Button).
---@param color integer # The base color in 0xAAGGBBRR format.
---@return integer # The number of style colors pushed. Returns 0 if arguments are invalid.
local function pushColors(idx, color)
	if not areNumber(idx, color) then return 0 end

	if idx ~= ImGuiCol.Button and idx ~= ImGuiCol.FrameBg then
		ImGui.PushStyleColor(idx, adjustColor(color, 0xff, 32, 32, 32))

		return 1
	end

	local hoveredIdx, activeIdx = idx + 1, idx + 2
	local base, hover, active = getThreeColorsFrom(idx, color)

	ImGui.PushStyleColor(idx, base)
	ImGui.PushStyleColor(hoveredIdx, hover)
	ImGui.PushStyleColor(activeIdx, active)

	return 3
end

---Safely pops a number of ImGui style colors from the stack.
---Calls `ImGui.PopStyleColor(num)` only if `num` is a positive integer.
---@param num integer # The number of style colors to pop from the ImGui stack.
local function popColors(num)
	if not isNumber(num) or num <= 0 then return end
	ImGui.PopStyleColor(num)
end

---Displays a single line of text with optional horizontal centering, vertical spacing, and custom color.
---@param text string # The text to display.
---@param color? number # Optional 32-bit ABGR color (e.g. 0xffc0c0c0). If provided, temporarily overrides the current text color.
---@param heightPadding? number # Optional vertical space (in pixels) added below the text. Defaults to 0 if omitted.
---@param contentWidth? number # Optional content width, used to center the text horizontally.
---@param itemSpacing? number # Optional horizontal spacing between UI elements. Used with centering logic.
local function addText(text, color, heightPadding, contentWidth, itemSpacing)
	if not isStringValid(text) then return end

	if areNumber(contentWidth, itemSpacing) then
		local halfSize = ImGui.CalcTextSize(text) * 0.5
		local padding = max(0, (contentWidth - ImGui.GetScrollMaxY() - itemSpacing * 3) * 0.5 - halfSize)
		if padding > 0 then
			ImGui.Dummy(padding, 0)
			ImGui.SameLine()
		end
	end

	local isColor = isNumber(color)
	if isColor then ---@cast color number
		ImGui.PushStyleColor(ImGuiCol.Text, adjustColor(color, 0xff))
	end

	ImGui.Text(text)

	if isColor then
		ImGui.PopStyleColor()
	end

	if not isNumber(heightPadding) then return end ---@cast heightPadding number
	ImGui.Dummy(0, heightPadding)
end

---Adds centered text with custom word wrapping.
---@param text string # The text to display.
---@param wrap number # The maximum width before wrapping.
local function addTextCenterWrap(text, wrap)
	if not isStringValid(text) or not isNumber(wrap) or wrap < 10 then return end

	local ln, w = "", ImGui.GetWindowSize()
	for s in text:gmatch("%S+") do
		local t = (nilOrEmpty(ln)) and s or (ln .. " " .. s)
		if ImGui.CalcTextSize(t) > wrap and ln ~= "" then
			ImGui.SetCursorPosX((w - ImGui.CalcTextSize(ln)) * 0.5)
			ImGui.Text(ln)
			ln = s
		else
			ln = t
		end
	end
	if isStringValid(ln) then
		ImGui.SetCursorPosX((w - ImGui.CalcTextSize(ln)) * 0.5)
		ImGui.Text(ln)
	end
end

---Displays a tooltip when the current UI item is hovered.
---If a single string is passed, displays it as wrapped text.
---If multiple arguments are passed, they are interpreted as alternating key-value pairs for a tooltip table.
---If a table is passed, it will be unpacked as key-value pairs.
---@param scale number? # The resolution scale for wrapping text.
---@param ... string|table # Either a single string, a table of pairs, or a sequence of key-value pairs.
local function addTooltip(scale, ...)
	if not ImGui.IsItemHovered() then return end

	local count = select("#", ...)
	if count >= 2 then
		ImGui.BeginTooltip()
		if not ImGui.BeginTable("TooltipTable", 2) then return end
		for i = 1, count, 2 do
			local key = tostring(select(i, ...))
			local val = tostring(select(i + 1, ...) or "")
			ImGui.TableNextRow()
			ImGui.TableSetColumnIndex(0)
			ImGui.Text(key)
			ImGui.TableSetColumnIndex(1)
			ImGui.Text(val)
		end
		ImGui.EndTable()
		ImGui.EndTooltip()
		return
	end

	local item = select(1, ...)
	if item == nil then return end

	if isString(item) then
		ImGui.BeginTooltip()

		local wrap = scale and ceil(420 * scale) or nil
		if wrap then
			ImGui.PushTextWrapPos(wrap)
		end

		ImGui.Text(item)

		if wrap then
			ImGui.PopTextWrapPos()
		end

		ImGui.EndTooltip()
	elseif isTable(item) then
		addTooltip(nil, unpack(item))
	end
end

---Displays a modal popup with a text prompt and two buttons: Yes and No.
---Returns true if the Yes button is clicked, false if No is clicked, and nil if the popup was not active.
---@param id string # The unique popup ID.
---@param text string # The message to display in the popup.
---@param yesBtnColor? number # Optional color index for the Yes button (ImGuiCol style constant).
---@param noBtnColor? number # Optional color index for the No button (ImGuiCol style constant).
---@return boolean? # True if Yes clicked, false if No clicked, nil if popup not active.
local function addPopupYesNo(id, text, scale, yesBtnColor, noBtnColor)
	if not areStringValid(id, text) or not ImGui.BeginPopup(id) then return nil end

	local result = nil

	ImGui.Text(text)
	ImGui.Dummy(0, 2)
	ImGui.Separator()
	ImGui.Dummy(0, 2)

	local width, height = ceil(80 * scale), floor(30 * scale)

	---@cast yesBtnColor number
	local pushed = isNumber(yesBtnColor) and pushColors(ImGuiCol.Button, yesBtnColor) or 0
	if ImGui.Button(Text.GUI_YES, width, height) then
		result = true
		ImGui.CloseCurrentPopup()
	end
	popColors(pushed)

	ImGui.SameLine()

	---@cast noBtnColor number
	pushed = isNumber(noBtnColor) and pushColors(ImGuiCol.Button, noBtnColor) or 0
	if ImGui.Button(Text.GUI_NO, width, height) then
		result = false
		ImGui.CloseCurrentPopup()
	end
	popColors(pushed)

	ImGui.EndPopup()

	return result
end

---Adds a button to open the Global Parameters window and returns the current window geometry if clicked.
---@param controlPadding number # Left padding used to center content within the window.
---@param halfHeightPadding number # Padding below the button.
---@param buttonWidth number # Width of the button.
---@param buttonHeight number # Height of the button.
---@return number? x # The window X position when the button was clicked.
---@return number? y # The window Y position when the button was clicked.
---@return number? w # The window width when the button was clicked.
---@return number? h # The window height (clamped to at least 400) when the button was clicked.
local function addGlobalOptionsButton(controlPadding, halfHeightPadding, buttonWidth, buttonHeight)
	if not areNumber(controlPadding, halfHeightPadding, buttonWidth, buttonHeight) then return end

	local x, y, w, h

	ImGui.Dummy(controlPadding, 0)
	ImGui.SameLine()
	if ImGui.Button(Text.GUI_GSETS, buttonWidth, buttonHeight) then
		x, y = ImGui.GetWindowPos()
		w, h = ImGui.GetWindowSize()
		h = max(h, 186)
		config.isOpen = not config.isOpen
	end
	ImGui.Dummy(0, halfHeightPadding)

	return x, y, w, h
end

---Draws and manages the Global Parameters window.
---@param scale number # UI scale factor based on current DPI and font size.
---@param controlPadding number # Left padding used to center content within the window.
---@param heightPadding number # Height padding used to center content within the window.
---@param x number? # Optional X position to place the window.
---@param y number? # Optional Y position to place the window.
---@param w number? # Optional width for the window.
---@param h number? # Optional height for the window.
local function openGlobalOptionsWindow(scale, contentWidth, controlPadding, heightPadding, buttonHeight, x, y, w, h)
	if not config.isOpen or not areNumber(scale, controlPadding, heightPadding) then return end

	if areNumber(x, y, w, h) then
		---@cast x number
		---@cast y number
		---@cast w number
		---@cast h number
		ImGui.SetNextWindowPos(x, y)
		ImGui.SetNextWindowSize(w, h)
	end

	local flags = bor(ImGuiWindowFlags.NoCollapse, ImGuiWindowFlags.NoResize, ImGuiWindowFlags.NoMove)
	config.isOpen = ImGui.Begin(Text.GUI_GSETS, config.isOpen, flags)
	if not config.isOpen then return end

	ImGui.Dummy(0, floor(4 * heightPadding))
	if not isTableValid(config.options) or not ImGui.BeginTable("GlobalOptions", 2, ImGuiTableFlags.Borders) then
		ImGui.End()
		return
	end

	ImGui.TableSetupColumn(" \u{f09a8}", ImGuiTableColumnFlags.WidthStretch)
	ImGui.TableSetupColumn(" \u{f1b91}", ImGuiTableColumnFlags.WidthFixed)
	ImGui.TableHeadersRow()

	for key, data in opairs(config.options) do
		---@cast key string
		---@cast data IOptionData
		ImGui.TableNextRow()

		ImGui.TableSetColumnIndex(0)
		ImGui.Text(tostring(data.DisplayName or key))

		ImGui.TableSetColumnIndex(1)
		if isBoolean(data.Value) then
			local value = ImGui.Checkbox("##" .. key, data.Value)
			if value ~= data.Value then
				config.isUnsaved = true
				data.Value = value
			end
		elseif isNumber(data.Value) then
			local label = "##" .. key
			if areNumber(data.Min, data.Max) then
				ImGui.PushItemWidth(floor(24 * scale) * #tostring(data.Max) / 2)
				local value = ImGui.DragFloat(label, data.Value, 0.1, data.Min, data.Max, "%.0f")
				if value ~= data.Value then
					config.isUnsaved = true
					data.Value = value
				end
			else
				--Fallback.
				local before = tostring(data.Value)
				local after = ImGui.InputText(label, before)
				if before ~= after and isNumeric(after) then
					config.isUnsaved = true
					data.Value = tonumber(after)
				end
			end
		else
			--Unsuported type.
			ImGui.Text(tostring(data.Value))
		end

		---@diagnostic disable-next-line
		local tip = data.Tooltip ---@cast tip string
		if isStringValid(tip) then
			addTooltip(scale, tip)
		else
			addTooltip(scale, Text.GUI_GOPT_TIP)
		end
	end

	ImGui.EndTable()

	ImGui.Dummy(0, heightPadding)

	if ImGui.Button(Text.GUI_RESET, contentWidth - ImGui.GetScrollMaxY(), buttonHeight) then
		for _, data in pairs(config.options) do
			if not equals(data.Value, data.Default) then
				config.isUnsaved = true
			end
			data.Value = data.Default
		end
	end

	addTooltip(scale, Text.GUI_GOPT_TIP)

	ImGui.End()
end

---Adds a button to open the Preset File Explorer and returns the current window geometry if clicked.
---@param contentWidth number # The width of the content region to size the button.
---@param heightPadding number # Padding above the button.
---@param halfHeightPadding number # Padding below the button.
---@param buttonHeight number # Height of the button.
---@return number? x # The window X position when the button was clicked.
---@return number? y # The window Y position when the button was clicked.
---@return number? w # The window width when the button was clicked.
---@return number? h # The window height (clamped to at least 400) when the button was clicked.
local function addFileExplorerButton(contentWidth, heightPadding, halfHeightPadding, buttonHeight)
	if not areNumber(contentWidth, heightPadding, halfHeightPadding, buttonHeight) then return end

	local x, y, w, h

	ImGui.Separator()
	ImGui.Dummy(0, heightPadding)
	if ImGui.Button(Text.GUI_FEXP, contentWidth, buttonHeight) then
		x, y = ImGui.GetWindowPos()
		w, h = ImGui.GetWindowSize()
		h = max(h, 400)
		explorer.isOpen = not explorer.isOpen
	end
	ImGui.Dummy(0, halfHeightPadding)

	return x, y, w, h
end

---Draws and manages the Preset File Explorer window.
---Displays all available preset files, allows file deletion, shows usage stats, and supports live search filtering.
---@param scale number # UI scale factor based on current DPI and font size.
---@param controlPadding number # Left padding used to center content within the window.
---@param halfHeightPadding number # Vertical padding between UI elements.
---@param buttonHeight number # Height of the file action buttons.
---@param x number? # Optional X position to place the window.
---@param y number? # Optional Y position to place the window.
---@param w number? # Optional width for the window.
---@param h number? # Optional height for the window.
local function openFileExplorerWindow(scale, controlPadding, halfHeightPadding, buttonHeight, x, y, w, h)
	if not explorer.isOpen or not areNumber(scale, controlPadding, halfHeightPadding, buttonHeight) then return end

	local cache = getCache(0x970b, true) or {}
	local dirs = cache.dirs or {
		[1] = PresetFolders.VANILLA,
		[2] = PresetFolders.CUSTOM
	}
	local files = cache.files or {}
	local total = cache.total or 0
	if not isTableValid(files) then
		for i, location in ipairs(dirs) do
			local entries = dir(location)
			if entries then
				total = total + 1
				for _, entry in ipairs(entries) do
					local name = entry.name
					if name and hasLuaExt(name) then
						files[name] = i
					end
				end
			end
		end
		setCache(0x970b, cache, true)
	end

	if total ~= #dirs then
		explorer.isOpen = false
		logF(DevLevels.FULL, LogLevels.ERROR, 0x970b, Text.LOG_PSETS_DIR_MISS)
		return
	end

	if areNumber(x, y, w, h) then
		---@cast x number
		---@cast y number
		---@cast w number
		---@cast h number
		ImGui.SetNextWindowPos(x, y)
		ImGui.SetNextWindowSize(w, h)
	end

	local flags = bor(ImGuiWindowFlags.NoCollapse, ImGuiWindowFlags.NoResize, ImGuiWindowFlags.NoMove)
	explorer.isOpen = ImGui.Begin(Text.GUI_FEXP, explorer.isOpen, flags)
	if not explorer.isOpen then return end

	local barFlags = bor(ImGuiTableFlags.SizingFixedFit, ImGuiTableFlags.NoBordersInBody)
	local barHeight = floor(32 * scale)
	if ImGui.BeginTable("SearchBar", 3, barFlags) then
		ImGui.TableSetupColumn("##Label", ImGuiTableColumnFlags.WidthFixed, barHeight)
		ImGui.TableSetupColumn("##Input", ImGuiTableColumnFlags.WidthStretch)
		ImGui.TableSetupColumn("##PadRight", ImGuiTableColumnFlags.WidthFixed, barHeight)

		ImGui.TableNextRow()

		ImGui.TableSetColumnIndex(0)
		local label = "\u{f1a7e}"
		alignNext(label)
		ImGui.Text(label)

		ImGui.TableSetColumnIndex(1)
		ImGui.PushItemWidth(-1)
		local newVal, changed = ImGui.InputText("##Search", explorer.searchText or "", 96)
		if changed and newVal then
			explorer.searchText = newVal
		end
		ImGui.PopItemWidth()

		addTooltip(nil,
			split(format(Text.GUI_FEXP_SEARCH_TIP,
				ExplorerCommands.INSTALLED,
				ExplorerCommands.MODDED,
				ExplorerCommands.UNAVAILABLE,
				ExplorerCommands.ACTIVE,
				ExplorerCommands.INACTIVE,
				ExplorerCommands.VANILLA), "|"))

		ImGui.EndTable()
	end
	ImGui.Dummy(0, halfHeightPadding)

	local command = nil
	local search = (explorer.searchText or ""):lower()
	for _, value in pairs(ExplorerCommands) do
		if search == value then
			command = value
			search = ""
			break
		end
	end

	if ImGui.BeginTable("PresetFiles", 2, ImGuiTableFlags.Borders) then
		ImGui.TableSetupColumn(" \u{f09a8}" .. explorer.totalVisible, ImGuiTableColumnFlags.WidthStretch)
		ImGui.TableSetupColumn(" \u{f05e9}", ImGuiTableColumnFlags.WidthFixed)
		ImGui.TableHeadersRow()

		explorer.totalVisible = 0
		for f, i in opairs(files) do
			if #search > 0 and not f:lower():find(search, 1, true) then
				goto continue
			end

			local k = trimLuaExt(f)
			local p = presets.collection[k]
			if (p and command == ExplorerCommands.MODDED and p.IsVanilla) or (command == ExplorerCommands.VANILLA and i > 1) then
				goto continue
			end

			local c
			if not p then
				if isStringValid(command) and command ~= ExplorerCommands.UNAVAILABLE and command ~= ExplorerCommands.VANILLA then
					goto continue
				end

				c = Colors.GARNET
			end
			if command == ExplorerCommands.UNAVAILABLE and not c then
				goto continue
			end

			local usage = presets.usage[k]
			if isTableValid(usage) then
				if command == ExplorerCommands.INACTIVE then goto continue end
				c = Colors.FIR
			end
			if command == ExplorerCommands.ACTIVE and c ~= Colors.FIR then goto continue end

			explorer.totalVisible = explorer.totalVisible + 1
			ImGui.TableNextRow()
			ImGui.TableSetColumnIndex(0)

			alignNext(buttonHeight)

			if c then c = pushColors(ImGuiCol.Text, c) end

			local columnWidth = (ImGui.GetColumnWidth(0) - 4) * scale
			local textWidth = ImGui.CalcTextSize(f) * scale
			local nameTooLong = columnWidth < textWidth
			if nameTooLong then
				local short = f
				local dots = "..."
				local cutoff = columnWidth - ImGui.CalcTextSize(dots) * scale
				while #short > 0 and ImGui.CalcTextSize(short) * scale > cutoff do
					short = short:sub(1, -2)
				end
				ImGui.Text(short .. dots)
				addTooltip(scale, format(Text.GUI_FEXP_NAME_TIP, f))
			else
				ImGui.Text(f)
			end

			if c then popColors(c) end

			if usage then
				if nameTooLong then
					addTooltip(scale, "\n")
				end
				local fmt = "%Y-%m-%d %H:%M:%S %p"
				addTooltip(nil,
					split(format(Text.GUI_FEXP_USAGE_TIP,
						os.date(fmt, usage.First),
						os.date(fmt, usage.Last),
						usage.Total), "|"))
			end

			ImGui.TableSetColumnIndex(1)
			if ImGui.Button("\u{f05e8}##" .. f, 0, buttonHeight) then
				ImGui.OpenPopup(f)
			end

			local folder = dirs[i]
			local path = combine(folder, f)
			if addPopupYesNo(f, format(Text.GUI_FEXP_DEL_CONFIRM, path), scale, Colors.GARNET) then
				if not folder then goto continue end

				local ok, err = os.remove(path)
				if ok then
					for n in pairs(editor.bundles) do
						local parts = split(n, "*")
						if #parts < 2 then goto continue end

						local vName, aName = parts[1], parts[2]
						if startsWith(vName, k) or startsWith(aName, k) then
							editor.bundles[n] = nil
						end

						::continue::
					end

					setPresetEntry(k)

					if get(editor.lastBundle, {}, "Flux").Key == k then
						restoreModifiedPresets()
						clearLastEditorBundle()
					end

					savePresetUsage()

					logF(DevLevels.ALERT, LogLevels.INFO, 0x970b, Text.LOG_PSET_DELETED, f)

					setCache(0x970b, nil, true)
				else
					logF(DevLevels.FULL, LogLevels.WARN, 0x970b, Text.LOG_PSET_DEL_FAIL, f, err)
				end
			end

			::continue::
		end

		ImGui.EndTable()
	end

	if nilOrEmpty(files) then
		local hPad = ceil(180 * scale)
		local wPad = floor(controlPadding - 4 * scale)
		ImGui.Dummy(0, hPad)
		ImGui.Dummy(wPad, 0)
		ImGui.SameLine()
		ImGui.PushStyleColor(ImGuiCol.Text, adjustColor(Colors.GARNET, 0xff))
		ImGui.Text(Text.GUI_FEXP_NO_PSETS)
		ImGui.PopStyleColor()
	end

	ImGui.End()
end

--#endregion

--#region 🎬 Runtime Behavior

---Initializes the mod when CET is loaded.
---This function is triggered once at the beginning of a session.
---It loads all preset files, usage data, and applies the current camera preset.
local function onInit()
	loadGlobalOptions()
	updateDefaultParams()
	loadPresetUsage()

	local task = presets.loaderTask
	if not isFunction(task.Finalizer) then
		task.Finalizer = function()
			clearLastEditorBundle()
			resetCache()
			applyPreset()
		end
	end

	loadPresets(true, 3)
end

---Handles logic when a vehicle is unmounted.
---If forced or the mod is enabled, resets padding and cache, restores default presets,
---and clears the last active editor session state.
---@param force boolean? # If true, unmount logic will execute even if the mod is disabled.
local function onUnmount(force)
	if not force and not state.isModEnabled then return end

	state.isLogSuspend = false
	if not force and state.devMode >= DevLevels.ALERT then
		log(LogLevels.INFO, 0x9dee, Text.LOG_EVNT_UMNT)
	end

	gui.doMetricsReset = true
	savePresetUsage()

	restoreModifiedPresets()
	updateDefaultParams(true)

	clearLastEditorBundle()

	resetCache()
	presets.isAnyActive = false
end

---Handles logic when the game or CET shuts down.
---Restores all camera presets and parameters to default and saves usage stats.
local function onShutdown()
	restoreAllPresets()
	restoreAllCustomCameraData()
	updateDefaultParams(true)
end

--[[
---This event gets triggered even before `onInit`.
registerForEvent("onTweak", function()
	--Save default presets.
	local defaults = {
		"2w_Preset",
		"4w_911",
		"4w_aerondight",
		"4w_Alvarado_Preset",
		"4w_Archer_Hella",
		"4w_Archer_Quarz",
		"4w_BMF",
		"4w_caliburn",
		"4w_Columbus",
		"4w_Cortes_Preset",
		"4w_Galena",
		"4w_Galena_Nomad",
		"4w_herrera_outlaw",
		"4w_herrera_riptide",
		"4w_Hozuki",
		"4w_Limo_Thrax",
		"4w_Mahir_Supron_Kurtz",
		"4w_Makigai",
		"4w_Medium_Preset",
		"4w_Preset",
		"4w_Quadra",
		"4w_Quadra66",
		"4w_Quadra66_Nomad",
		"4w_Shion",
		"4w_Shion_Nomad",
		"4w_SubCompact_Preset",
		"4w_Tanishi",
		"4w_Thorton_Colby",
		"4w_Thorton_Colby_Pickup",
		"4w_Thorton_Colby_Pickup_Kurtz",
		"4w_Truck_Preset",
		"Brennan_Preset",
		"Default_Preset",
		"v_militech_basilisk_CameraPreset",
		"v_standard25_mahir_supron_CameraPreset",
		"v_utility4_centurion",
		"v_utility4_kaukaz_bratsk_Preset",
		"v_utility4_kaukaz_zeya_Preset",
		"v_utility4_militech_behemoth_Preset"
	}
	for _, value in ipairs(defaults) do
		local preset = getPreset(value)
		if preset then
			savePreset(preset.ID, preset, true, true)
		end
	end
end)
--]]

--This event is triggered when the CET initializes this mod.
registerForEvent("onInit", function()
	local backupDevMode

	--Game version check.
	state.isGameMinVersion = isVersionAtLeast(getGameVersion(), "2.21")

	--CET version check.
	local runVer = getRuntimeVersion()
	state.isRuntimeMinVersion = isVersionAtLeast(runVer, "1.35")
	state.isRuntimeFullVersion = isVersionAtLeast(runVer, "1.35.1")

	--Ensures the log file is fresh when the mod initializes.
	pcall(function()
		local name = "ThirdPersonVehicleCameraTool"
		for i = 1, 9, 1 do
			local path = format("%s.%d.log", name, i)
			if not fileExists(path) then
				break
			end
			pcall(os.remove, path)
		end
		local file = io.open(format("%s.log", name), "w")
		if file then file:close() end
	end)

	--Load all saved data from disk; apply preset only if the player is in a vehicle.
	onInit()

	--When the player enters a vehicle. This event also fires
	--every few seconds for no apparent reason, so it's essential
	--to ensure the code runs only once when entering a vehicle.
	Observe("VehicleComponent", "OnMountingEvent", function(_)
		if not state.isModEnabled or not isVehicleMounted() or isCachePopulated() then
			return
		end
		logIf(DevLevels.ALERT, LogLevels.INFO, 0x0f9b, Text.LOG_EVNT_MNT)
		updateDefaultParams()
		applyPreset()
	end)

	--When the player unmounts from a vehicle, reset to default camera offsets.
	Observe("VehicleComponent", "OnUnmountingEvent", function(_)
		if isVehicleMounted() then
			logIf(DevLevels.ALERT, LogLevels.INFO, 0x0f9b, Text.LOG_EVNT_UMNT_FAIL)
			return
		end
		onUnmount(false)
	end)

	--When the game returns to the main menu, ensure any active vehicle camera presets are reset.
	Observe("QuestTrackerGameController", "OnUninitialize", function() onUnmount(false) end)

	--While the loading screen is active, but also triggers
	--once when the user confirms it at the end with a key press.
	Observe("LoadingScreenProgressBarController", "SetProgress", function(_, progress)
		gui.isOverlayLocked = progress < 1.0 --1.0 only on keyboard-confirmation.
		if not state.isModEnabled then return end
		if gui.isOverlayLocked then
			backupDevMode = backupDevMode or state.devMode
			state.devMode = DevLevels.DISABLED
			config.isOpen = false
			explorer.isOpen = false
			return
		end
		if backupDevMode ~= nil then
			state.devMode = backupDevMode
			backupDevMode = nil
		end
	end)

	--When a non-keyboard-confirmed loading screen finishes.
	Observe("FastTravelSystem", "OnLoadingScreenFinished", function(_, finished)
		if not finished then return end
		gui.isOverlayLocked = false
		if backupDevMode ~= nil then
			state.devMode = backupDevMode
			backupDevMode = nil
		end
	end)

	--When control over the player character is gained (e.g. after loading a save).
	Observe("PlayerPuppet", "OnTakeControl", function(self)
		if not state.isModEnabled or gui.isOverlayLocked or self:GetEntityID().hash ~= 1 then return end

		onUnmount(true)

		local deadline = 20
		asyncRepeat(0.3, function(id)
			if not state.isModEnabled then
				asyncStop(id)
				return
			end

			asyncStop(id)

			if not Game.GetPlayer() then return end
			if deadline > 0 and not isVehicleMounted() then
				deadline = deadline - 1
				return
			end

			applyPreset()
		end)
	end)

	--When Photo Mode is activated.
	Observe("gameuiPhotoModeMenuController", "OnShow", function() gui.isOverlayLocked = true end)

	--When Photo Mode is closed.
	Observe("gameuiPhotoModeMenuController", "OnHide", function() gui.isOverlayLocked = false end)
end)

--Detects when the CET overlay is opened.
registerForEvent("onOverlayOpen", function()
	gui.isOverlayOpen = true
end)

--Detects when the CET overlay is closed.
registerForEvent("onOverlayClose", function()
	gui.isOverlayOpen = false
	config.isOpen = false
	explorer.isOpen = false
	explorer.searchText = ExplorerCommands.INSTALLED
	setCache(0x970b, nil, true) --openFileExplorerWindow
	saveGlobalOptions()
end)

--Display a simple GUI with some options.
registerForEvent("onDraw", function()
	--Notification system (requires at least CET 'v1.35.1').
	if state.isRuntimeFullVersion and gui.areToastsPending then
		gui.areToastsPending = false
		if isTableValid(gui.toasterBumps) then
			for k, v in pairs(gui.toasterBumps) do
				local toast = ImGui.Toast.new(k, v)
				ImGui.ShowToast(toast)
			end
		end
		gui.toasterBumps = {}
	end

	--Stop when CET overlay is hidden.
	if not gui.isOverlayOpen and state.devMode < DevLevels.OVERLAY then return end

	--Main window begins.
	local flags = ImGuiWindowFlags.AlwaysAutoResize
	if not gui.isOverlayOpen then
		flags = bor(flags, ImGuiWindowFlags.NoCollapse, ImGuiWindowFlags.NoNavInputs)
	end
	if not ImGui.Begin(Text.GUI_TITL, flags) then return end

	local locked = gui.isOverlayLocked
	if locked or presets.loaderTask.IsActive then
		ImGui.BeginDisabled(true)
	end

	--Computes scaled layout values (content width, control sizes, and paddings) based on the UI scale factor.
	local contentWidth, halfContentWidth, itemSpacing, scale, controlPadding = getMetrics()
	local baseContentWidth = floor(240 * scale)
	local buttonHeight = floor(24 * scale)
	local rowHeight = floor(28 * scale)
	local heightPadding = floor(4 * scale)
	local halfHeightPadding = floor(2 * scale)
	local doubleHeightPadding = floor(8 * scale)

	--Forces ImGui to rebuild the window on the next frame with fresh metrics.
	if gui.doMetricsReset then
		gui.doMetricsReset = false
		ImGui.End()
		return
	end

	--Minimum window width and height padding.
	ImGui.Dummy(baseContentWidth, heightPadding)

	--Warning for outdated versions.
	if (not state.isGameMinVersion or not state.isRuntimeMinVersion) and state.devMode <= DevLevels.DISABLED then
		local gameVer, cetVer = serialize(getGameVersion()), serialize(getRuntimeVersion())
		ImGui.Dummy(0, 0)
		ImGui.SameLine()
		ImGui.PushStyleColor(ImGuiCol.Text, adjustColor(Colors.GARNET, 0xff))
		addTextCenterWrap(format(Text.GUI_OLD_VER, gameVer, cetVer), contentWidth)
		ImGui.PopStyleColor()
		ImGui.Dummy(0, doubleHeightPadding)
	end

	--Checkbox to toggle mod functionality and handle enable/disable logic.
	ImGui.Dummy(controlPadding, 0)
	ImGui.SameLine()
	local isEnabled = ImGui.Checkbox(Text.GUI_TGL_MOD, state.isModEnabled)
	addTooltip(scale, Text.GUI_TGL_MOD_TIP)
	if isEnabled ~= state.isModEnabled then
		state.isModEnabled = isEnabled
		if isEnabled then
			onInit()
			logF(DevLevels.ALERT, LogLevels.INFO, 0xcb3d, Text.LOG_MOD_ON)
		else
			onUnmount(true)
			onShutdown()
			purgePresets()
			resetCache()
			editor.bundles = {}
			presets.usage = {}
			state.devMode = DevLevels.DISABLED
			logF(DevLevels.ALERT, LogLevels.INFO, 0xcb3d, Text.LOG_MOD_OFF)
		end
	end
	ImGui.Dummy(0, halfHeightPadding)
	if not state.isModEnabled then
		--Mod is disabled — nothing left to add.
		ImGui.End()
		return
	end

	--Button to open the global Default Parameters window.
	local globalBtnWidth = floor(192 * scale)
	local dpx, dpy, dpw, dph = addGlobalOptionsButton(controlPadding, halfHeightPadding, globalBtnWidth, buttonHeight)
	openGlobalOptionsWindow(scale, contentWidth, controlPadding, heightPadding, buttonHeight, dpx, dpy, dpw, dph)

	--The button that reloads all presets.
	ImGui.Dummy(controlPadding, 0)
	ImGui.SameLine()
	if ImGui.Button(Text.GUI_PSETS_RLD, globalBtnWidth, buttonHeight) then
		state.isLogSuspend = false
		editor.bundles = {}
		resetCache()
		restoreAllPresets()
		loadPresets(true)
		applyPreset()
	end
	addTooltip(scale, Text.GUI_PSETS_RLD_TIP)
	ImGui.Dummy(0, halfHeightPadding)

	--Slider to set the developer mode level.
	local sliderWidth = floor(77 * scale)
	ImGui.Dummy(controlPadding, 0)
	ImGui.SameLine()
	ImGui.PushItemWidth(sliderWidth)
	local devMode = ImGui.SliderInt(Text.GUI_DMODE, state.devMode, DevLevels.DISABLED, DevLevels.FULL)
	if devMode ~= state.devMode then
		state.devMode = min(max(devMode, DevLevels.DISABLED), DevLevels.FULL)
	end
	gui.isPaddingLocked = ImGui.IsItemActive()
	addTooltip(scale, Text.GUI_DMODE_TIP)
	ImGui.PopItemWidth()
	ImGui.Dummy(0, doubleHeightPadding)

	--Table showing vehicle name, camera ID and more — if certain conditions are met.
	local cache = getCache(0xcb3d) or {}
	local vehicle, name, appName, id, key, displayName, status, statusText
	local steps = {
		function()
			return not locked and state.devMode > DevLevels.DISABLED
		end,
		function()
			vehicle = getMountedVehicle()
			return vehicle
		end,
		function()
			name = getVehicleName()
			if not name then
				log(LogLevels.ERROR, 0xcb3d, Text.LOG_VEH_NAME_MISS)
			end
			return name
		end,
		function()
			appName = getVehicleAppearanceName()
			if not appName then
				log(LogLevels.ERROR, 0xcb3d, Text.LOG_APP_NOT_FOUND)
			end
			return appName
		end,
		function()
			id = getVehicleCameraID()
			if not id then
				log(LogLevels.ERROR, 0xcb3d, Text.LOG_CAM_ID_MISS)
				addText(Text.LOG_CAM_ID_MISS, Colors.GARNET, halfHeightPadding, contentWidth, itemSpacing)
			end
			return id
		end,
		function()
			key = cache.key
			if isString(key) then return key end

			key = name ~= appName and findPresetKey(name, appName) or findPresetKey(name) or name
			cache.key = key

			if not key then
				log(LogLevels.ERROR, 0xcb3d, Text.LOG_CAM_ID_MISS)
			end

			return key
		end,
		function()
			displayName = cache.displayName
			if isString(displayName) then return displayName end

			displayName = getVehicleDisplayName() or Text.GUI_NONE
			cache.displayName = displayName

			return displayName
		end,
		function()
			status = cache.status
			if isString(status) then return status end

			status = getVehicleStatus()
			cache.status = status

			return status
		end,
		function()
			statusText = cache.statusText
			if isString(status) then return status end

			statusText = ({
				[0] = Text.GUI_TBL_VAL_STATUS_0,
				[1] = Text.GUI_TBL_VAL_STATUS_1,
				[2] = Text.GUI_TBL_VAL_STATUS_2
			})[status] or Text.GUI_NONE

			cache.statusText = statusText

			return statusText
		end
	}

	local failed = false
	for _, fn in ipairs(steps) do
		if not fn() then
			failed = true
			break
		end
	end

	setCache(0xcb3d, cache)

	if failed then
		state.isLogSuspend = true
		if state.devMode > DevLevels.DISABLED then
			if not locked and not vehicle then
				addText(Text.GUI_NO_VEH, Colors.CARAMEL, halfHeightPadding, contentWidth, itemSpacing)
			end
		elseif not locked and isVehicleMounted() then
			local text, color
			if presets.isAnyActive then
				text = Text.GUI_PRE_ON
				color = Colors.FIR
			else
				text = Text.GUI_PRE_OFF
				color = Colors.CARAMEL
			end
			addText(text, color, halfHeightPadding, contentWidth, itemSpacing)
		end

		--Button to open the Preset File Explorer.
		local x, y, w, h = addFileExplorerButton(contentWidth, heightPadding, halfHeightPadding, buttonHeight)

		if locked then
			ImGui.EndDisabled()
		end

		--Main window is done.
		ImGui.End()

		--Opens the Preset File Explorer window when button triggered.
		openFileExplorerWindow(scale, controlPadding, halfHeightPadding, buttonHeight, x, y, w, h)
		return
	end

	local bundle = getEditorBundle(name, appName, id, key) ---@cast bundle IEditorBundle
	if not isTableValid(bundle) then
		--Nothing else to display.
		ImGui.End()
	end
	editor.lastBundle = bundle

	local flux = bundle.Flux ---@cast flux IEditorPreset
	local pivot = bundle.Pivot ---@cast pivot IEditorPreset
	local finale = bundle.Finale ---@cast finale IEditorPreset
	local nexus = bundle.Nexus ---@cast nexus IEditorPreset
	local tasks = bundle.Tasks ---@cast tasks IEditorTasks
	if not areTableValid(flux, pivot, finale, nexus, tasks) then
		--No further controls required.
		ImGui.End()
	end

	local presetName = (flux.Name ~= key or presetExists(key, id)) and flux.Name or id
	if ImGui.BeginTable("PresetInfo", 2, ImGuiTableFlags.Borders) then
		ImGui.TableSetupColumn("\u{f11be}", ImGuiTableColumnFlags.WidthFixed, -1)
		ImGui.TableSetupColumn("\u{f09a8}", ImGuiTableColumnFlags.WidthStretch)
		ImGui.TableHeadersRow()

		local customID = getCustomVehicleCameraID()
		local rows = {
			{ label = "\u{f0208}", tip = Text.GUI_TBL_LABL_DNAME_TIP,  value = displayName },
			{ label = "\u{f1975}", tip = Text.GUI_TBL_LABL_STATUS_TIP, value = statusText },
			{ label = "\u{f010b}", tip = Text.GUI_TBL_LABL_VEH_TIP,    value = name },
			{ label = "\u{f07ac}", tip = Text.GUI_TBL_LABL_APP_TIP,    value = appName },
			{ label = "\u{f0567}", tip = Text.GUI_TBL_LABL_CAMID_TIP,  value = id },
			{
				label  = "\u{f0569}",
				tip    = Text.GUI_TBL_LABL_CCAMID_TIP,
				value  = customID,
				valTip = Text.GUI_TBL_VAL_CCAMID_TIP,
				custom = isStringValid(customID)
			},
			{
				label    = "\u{f1952}",
				tip      = Text.GUI_TBL_LABL_PSET_TIP,
				value    = presetName,
				valTip   = Text.GUI_TBL_VAL_PSET_TIP,
				editable = true
			}
		}

		local maxInputWidth = floor(max(16, (contentWidth - 38)) * scale)
		for _, row in ipairs(rows) do
			if not areString(row.label, row.value) then goto continue end

			ImGui.TableNextRow(0, rowHeight)
			ImGui.TableSetColumnIndex(0)

			alignNext(rowHeight)
			ImGui.Text(row.label)
			addTooltip(scale, row.tip)

			ImGui.TableSetColumnIndex(1)

			if row.custom then
				alignNext(rowHeight)
				ImGui.Text(row.value)

				local camMap = getVehicleCameraMap()
				if isTableValid(camMap) then ---@cast camMap table<string, string>
					local list = split(row.valTip, "|") or {}
					for _, v in ipairs(CameraData.Levels) do
						local cam = camMap[v]
						insert(list, v .. ":")
						insert(list, cam and cam or "\u{f0026} " .. Text.GUI_NONE)
					end
					addTooltip(nil, list)
				end
			elseif row.editable then
				local namWidth = min(ImGui.CalcTextSize(name), 302)
				local appWidth = min(ImGui.CalcTextSize(appName), 302)
				local maxWidth = max(namWidth, appWidth)
				local width = min(maxWidth, maxInputWidth) + doubleHeightPadding
				ImGui.PushItemWidth(width)

				local color
				if flux.Name ~= flux.Key then
					color = Colors.GARNET
				elseif flux.Name == finale.Name then
					color = Colors.FIR
				else
					color = Colors.CARAMEL
				end
				local pushd = row.value ~= id and pushColors(ImGuiCol.FrameBg, color) or 0

				local maxLen = max(#name, #appName) + 1
				local newVal, changed = ImGui.InputText("##FileName", row.value, maxLen)
				if changed and newVal then
					local trimVal = trimLuaExt(newVal)
					if trimVal == id then
						trimVal = ""
					end
					if flux.Name ~= trimVal then
						if #trimVal > 0 then
							flux.Name = trimVal
							tasks.Rename = true
						else
							flux.Key = key
							flux.Name = key
						end
					end
				end

				popColors(pushd)
				ImGui.PopItemWidth()

				addTooltip(scale, format(
					row.valTip,
					color == Colors.CARAMEL and flux.Name or key,
					name,
					appName,
					chopUnderscoreParts(name),
					chopUnderscoreParts(appName)
				))
			else
				alignNext(rowHeight)

				local rawValue = tostring(row.value or Text.GUI_NONE)
				local value = rawValue
				local maxWidth = 290 * scale

				if ImGui.CalcTextSize(value) > maxWidth then
					repeat
						value = value:sub(1, -2)
					until ImGui.CalcTextSize(value) <= maxWidth
					value = value .. "..."
				end

				ImGui.Text(value)
				if rawValue ~= value then
					addTooltip(scale, rawValue)
				end
				addTooltip(scale, row.valTip)
			end

			::continue::
		end

		ImGui.EndTable()
	end

	if tasks.Rename then
		tasks.Rename = finale.IsPresent and flux.Name ~= finale.Name
		flux.Key = flux.Name
	end

	--Camera preset editor allowing adjustments to Angle, X, Y, Z
	--coordinates, and Distance — if certain conditions are met.
	if ImGui.BeginTable("PresetEditor", 6, ImGuiTableFlags.Borders) then
		local headers = {
			"\u{f066a}", --Levels
			"\u{f10f3}\u{f0aee}", --Angles
			"\u{f0d4c}\u{f0b05}", --X-axis
			"\u{f0d51}\u{f0b06}", --Y-axis
			"\u{f0d55}\u{f0b07}", --Z-axis
			"\u{f054e}\u{f0af1}" --Distance
		}

		for i, header in ipairs(headers) do
			local flag = i < 3 and ImGuiTableColumnFlags.WidthFixed or ImGuiTableColumnFlags.WidthStretch
			local head = header
			if i > 2 and #head < 12 then
				local pad = 12 - #head
				local left = floor(pad / 2)
				local right = pad - left
				head = rep(" ", left) .. head .. rep(" ", right)
			end
			ImGui.TableSetupColumn(head, flag, -1)
		end

		ImGui.TableHeadersRow()

		local rows = {
			{ label = "\u{f0623}", tip = Text.GUI_TBL_LABL_CLO_TIP },
			{ label = "\u{f0622}", tip = Text.GUI_TBL_LABL_MID_TIP },
			{ label = "\u{f0621}", tip = Text.GUI_TBL_LABL_FAR_TIP }
		}

		local tips = {
			Text.GUI_TBL_VAL_ANG_TIP,
			Text.GUI_TBL_VAL_X_TIP,
			Text.GUI_TBL_VAL_Y_TIP,
			Text.GUI_TBL_VAL_Z_TIP,
			Text.GUI_TBL_VAL_DIST_TIP
		}

		for i, row in ipairs(rows) do
			local level = PresetInfo.Levels[i]

			ImGui.TableNextRow(0, rowHeight)
			ImGui.TableSetColumnIndex(0)

			alignNext(rowHeight)
			ImGui.Text(row.label)
			addTooltip(scale, row.tip)

			for j, field in ipairs(PresetInfo.Offsets) do
				local defVal = get(nexus.Preset, 0, level, field)
				local curVal = get(flux.Preset, defVal, level, field)
				local speed = pick(j, 1, 1e-2)
				local minVal = pick(j, -45, -5, -10, 0, -3.8)
				local maxVal = pick(j, 90, 5, 10, 32, 24)
				local fmt = pick(j, "%.0f", "%.2f")

				ImGui.TableSetColumnIndex(j)
				ImGui.PushItemWidth(-1)

				local pushd = not equals(curVal, defVal) and
					pushColors(ImGuiCol.FrameBg, (id ~= presetName and Colors.FIR or Colors.GARNET)) or 0
				local newVal = ImGui.DragFloat(format("##%s_%s", level, field), curVal, speed, minVal, maxVal, fmt)
				if not equals(newVal, curVal) then
					newVal = min(max(newVal, minVal), maxVal)
					deep(flux.Preset, level)[field] = newVal
					tasks.Validate = true
				end
				popColors(pushd)

				local tip = tips[j]
				if tip then
					local origVal = get(pivot.Preset, defVal, level, field)
					addTooltip(nil, split(format(tip, defVal, minVal, maxVal, origVal), "|"))
				end

				ImGui.PopItemWidth()
			end
		end

		ImGui.EndTable()
		ImGui.Dummy(0, halfHeightPadding)
	end

	if tasks.Validate then
		tasks.Validate = false
		flux.Token = getEditorPresetToken(flux.Preset)
		tasks.Apply = flux.Token ~= pivot.Token
		tasks.Save = flux.Token ~= finale.Token
		tasks.Restore = tasks.Save and flux.Token == nexus.Token
	end

	key = validatePresetKey(name, appName, key or name, flux.Name)
	if key ~= flux.Name then
		--No longer identical to `flux.Key`; triggers red highlight in UI.
		flux.Name = key
	end

	--Button to apply previously configured values in-game.
	local color = tasks.Restore and Colors.OLIVE or Colors.CARAMEL
	local pushed = tasks.Apply and pushColors(ImGuiCol.Button, color) or 0
	if ImGui.Button(Text.GUI_APPLY, halfContentWidth, buttonHeight) then
		--Always applies on user action — even if unnecessary.
		applyEditorPreset(key, flux, pivot, tasks)
	end
	popColors(pushed)
	addTooltip(scale, Text.GUI_APPLY_TIP)
	ImGui.SameLine()

	--Button in same line to save configured values to a file for future automatic use.
	local saveConfirmed = false
	pushed = (tasks.Save or tasks.Rename) and pushColors(ImGuiCol.Button, color) or 0
	if ImGui.Button(Text.GUI_SAVE, halfContentWidth, buttonHeight) then
		if presetFileExists(finale.Name) then
			editor.isOverwriteConfirmed = true
			ImGui.OpenPopup(key)
		else
			saveConfirmed = true
		end
	end
	popColors(pushed)
	addTooltip(scale, format(tasks.Restore and Text.GUI_REST_TIP or Text.GUI_SAVE_TIP, key))

	if editor.isOverwriteConfirmed then
		local path = getPresetFilePath(key, status)
		local confirmed = addPopupYesNo(key, format(Text.GUI_OVWR_CONFIRM, path), scale, Colors.CARAMEL)
		if confirmed ~= nil then
			editor.isOverwriteConfirmed = false
			saveConfirmed = confirmed
		end
	end
	if saveConfirmed then
		saveConfirmed = false

		--Apply is always performed on user request, even if redundant.
		applyEditorPreset(key, flux, pivot, tasks)

		--Saving is always performed, even if no changes were made in the editor. The
		--user could theoretically delete preset files manually outside the game, and
		--the mod wouldn't detect that at runtime. It would be problematic if saving
		--were blocked just because the mod assumes there are no changes.
		saveEditorPreset(key, flux, finale, tasks, status)
	end

	ImGui.Dummy(0, heightPadding)

	--Button to open the Preset File Explorer.
	local x, y, w, h = addFileExplorerButton(contentWidth, heightPadding, halfHeightPadding, buttonHeight)

	--Well done.
	ImGui.End()

	--Opens the Preset File Explorer window when toggled.
	openFileExplorerWindow(scale, controlPadding, halfHeightPadding, buttonHeight, x, y, w, h)
end)

--Restores default camera offsets for vehicles upon mod shutdown.
registerForEvent("onShutdown", onShutdown)

---Called every frame to update active timers.
---Processes all running async timers and executes their callbacks when their interval elapses.
registerForEvent("onUpdate", function(deltaTime)
	if not async.isActive then return end

	for id, timer in pairs(async.timers) do
		if not timer.IsActive then goto continue end

		timer.Time = timer.Time - deltaTime
		if timer.Time > 0 then goto continue end

		timer.Callback(id)
		timer.Time = timer.Interval

		::continue::
	end
end)

--#endregion

--#region 📟 Console Commands

---Moves vanilla preset files to the correct folder and updates their metadata.
---This command is intended for users who only create their own presets.
---With the new version, vanilla presets are stored in a different folder.
---If you downloaded a version of the mod without built-in presets, vanilla
---presets might not load correctly.
---This task scans the custom presets folder, identifies vanilla files, moves
---them to the proper folder, and validates them.
local function repairVanillaPresetFilesAsyncTask()
	if getCache(0x997f, true) then return end
	setCache(0x997f, true, true)

	local files = {}
	local entries = dir(PresetFolders.CUSTOM)
	if entries then
		for i, entry in ipairs(entries) do
			local name = entry.name
			if name and hasLuaExt(name) then
				files[i] = name
			end
		end
	end

	local index, file
	local vehicles = getPlayerVehicles()
	local length = getVanillaVehicleCount()
	length = length < #vehicles and length or #vehicles
	asyncRepeat(0, function(id)
		index, file = next(files, index)
		if not file then
			asyncStop(id)

			editor.bundles = {}
			resetCache()
			restoreAllPresets()
			loadPresets(true)
			applyPreset()

			setCache(0x997f, false, true)
			return
		end

		local key = trimLuaExt(file)
		for i = 1, length do
			local name = findVehicleName(vehicles[i])
			if isStringValid(name) then ---@cast name string
				local search = "Vehicle." .. key
				if startsWith(name, search) or findVehicleApperance(name, key) ~= nil then
					local path = getPresetFilePath(key, 2)
					local chunk, _ = loadfile(path)
					if not chunk then break end

					local ok, result = pcall(chunk)
					if not ok or not result or not isStringValid(result.ID) then break end

					setCache(0xddf2, 1) --fakes vanilla vehicle status via cache
					savePreset(key, result, true)
					setCache(0xddf2, nil) --remove fake

					pcall(os.remove, path)
					break
				end
			end
		end
	end)
end

return {
	---Command: GetMod("ThirdPersonVehicleCameraTool").RepairVanillaPresets()
	RepairVanillaPresets = repairVanillaPresetFilesAsyncTask
}

--#endregion
