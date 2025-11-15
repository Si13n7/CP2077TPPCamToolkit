--[[
==============================================
This file is distributed under the MIT License
==============================================

Third-Person Vehicle Camera Tool

Allows you to adjust third-person perspective
(TPP) camera offsets for any vehicle.

Filename: init.lua
Version: 2025-04-16, 10:00 UTC+01:00 (MEZ)

Copyright (c) 2025, Si13n7 Developments(tm)
All rights reserved.
______________________________________________
--]]


--Aliases for commonly used standard library functions to simplify code.
local format, concat, insert, unpack, max, min, band, bor, lshift, rshift =
	string.format,
	table.concat,
	table.insert,
	table.unpack,
	math.max,
	math.min,
	bit32.band,
	bit32.bor,
	bit32.lshift,
	bit32.rshift

---Loads all static UI and log string constants from `text.lua` into the global `Text` table.
---This is the most efficient way to manage display strings separately from logic and code.
---@type table<string, string>
local Text = dofile("text.lua")

---Developer mode levels used to control the verbosity and behavior of debug output.
---@alias DevLevelType 0|1|2|3
---@class DevLevelEnum
---@field DISABLED DevLevelType # No debug output.
---@field BASIC DevLevelType # Print only.
---@field ALERT DevLevelType # Print + alert.
---@field FULL DevLevelType # Print + alert + log.
---@type DevLevelEnum
local DevLevels = {
	DISABLED = 0,
	BASIC = 1,
	ALERT = 2,
	FULL = 3
}

---Log levels used to classify the severity of log messages.
---@alias LogLevelType 0|1|2
---@class LogLevelEnum
---@field INFO LogLevelType # General informational output.
---@field WARN LogLevelType # Non-critical issues or unexpected behavior.
---@field ERROR LogLevelType # Critical failures or important errors that need attention.
---@type LogLevelEnum
local LogLevels = {
	INFO = 0,
	WARN = 1,
	ERROR = 2
}

---Defines color constants used for theming and UI interaction states.
---@class ColorEnum
---@field CUSTOM integer # Verdigris Teal – indicates custom or user-adjusted presets.
---@field RESTORE integer # Moss Jade – represents actions that revert values to defaults.
---@field CONFIRM integer # Antique Bronze – used for confirming user-driven changes.
---@field DELETE integer # Burnt Cranberry – signals destructive operations such as deletions.
---@type ColorEnum
local Colors = {
	CUSTOM = 0x8a6a7a29,
	RESTORE = 0x8a297a68,
	CONFIRM = 0x8a295c7a,
	DELETE = 0x8a29297a
}

---Constant array of possible camera levels.
---@type string[]
local CameraLevels = {
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
}

---Constant array of preset camera levels.
---@type string[]
local PresetLevels = { "Close", "Medium", "Far" }

---Constant array of `IOffsetData` keys.
---@type string[]
local PresetOffsets = { "a", "x", "y", "z" }

---The current debug mode level controlling logging and alerts:
---0 = Disabled
---1 = Print
---2 = Print + Alert
---3 = Print + Alert + Log
---@type DevLevelType
local dev_mode = DevLevels.DISABLED

---Determines whether the mod is enabled.
---@type boolean
local mod_enabled = true

---Determines whether a vehicle is currently mounted.
---@type boolean
local vehicle_mounted = false

---List of camera preset IDs that were modified at runtime to enable selective restoration.
---@type string[]
local used_presets = {}

---Represents a camera offset configuration with rotation and positional data.
---@class IOffsetData
---@field a number # The camera's angle in degrees.
---@field x number # The offset on the X-axis.
---@field y number # The offset on the Y-axis.
---@field z number # The offset on the Z-axis.

---Represents a vehicle camera preset or links to another one.
---@class ICameraPreset
---@field ID string? # The camera ID used for the vehicle.
---@field Close IOffsetData? # The offset data for close camera view.
---@field Medium IOffsetData? # The offset data for medium camera view.
---@field Far IOffsetData? # The offset data for far camera view.
---@field Link string? # The name of another vehicle appearance to link to (if applicable).
---@field IsDefault boolean? # Whether to reset to default camera offsets.

---Contains all camera presets and linked vehicles.
---@type table<string, ICameraPreset>
local camera_presets = {}

---Determines whether the CET overlay is open.
---@type boolean
local overlay_open

---Current horizontal padding value used for centering UI elements.
---Dynamically adjusted based on available window width.
---@type number
local padding_width

---When set to true, disables dynamic window padding adjustments and uses the fixed `padding_width` value.
---@type boolean
local padding_locked

---Represents the state of an editable vehicle camera preset in the UI editor.
---Tracks different versions of the preset to properly trace changes.
---@class IEditorPresetData
---@field Current ICameraPreset? # The currently edited preset (may be modified by the UI).
---@field CurrentName string? # Editable working name for the current preset.
---@field CurrentToken number? # Checksum of the Current data, used for change tracking.
---@field File ICameraPreset? # The preset as loaded from file, before any user changes.
---@field FileName string? # The file name associated with the loaded preset.
---@field FileToken number? # Checksum of the File preset.
---@field Origin ICameraPreset? # A previous version of Current that has not been applied yet.
---@field OriginToken number? # Checksum of the Origin preset.
---@field Default ICameraPreset? # The game's default preset for this vehicle.
---@field DefaultToken number? # Checksum of the Default preset.
---@field RenamePending boolean? # True if the preset was renamed but the file rename hasn't been completed yet.
---@field RefreshPending boolean? # Indicates the editor UI should refresh its internal state.
---@field ApplyPending boolean? # Indicates changes that can be applied to take effect in-game.
---@field SavePending boolean? # Indicates that there are unsaved changes that can be saved.
---@field SaveIsRestore boolean? # If true, saving the preset will act as a revert-to-default action.

---Holds per-vehicle editor state for all mounted and recently edited vehicles.
---The key is always the vehicle name and appearance name, separated by an asterisk (*).
---Each entry tracks editor data and preset version states for the given vehicle.
---@type table<string, IEditorPresetData|nil>
local editor_data = {}

---Determines whether overwriting the preset file is allowed.
---@type boolean
local overwrite_confirm

---Determines whether the Preset File Manager is open.
---@type boolean
local file_man_open = false

---Logs and displays messages based on the current `dev_mode` level.
---Messages can be written to the log file, printed to the console, or shown as in-game alerts.
---@param lvl LogLevelType # Logging level (0 = Info, 1 = Warning, 2 = Error).
---@param fmt string # A format string for the message.
---@vararg any # Additional arguments for formatting the message.
local function log(lvl, fmt, ...)
	if dev_mode == DevLevels.DISABLED then return end

	local msg = "[TPVCamTool]  "
	if lvl >= LogLevels.ERROR then
		msg = msg .. "[Error]  "
	elseif lvl == LogLevels.WARN then
		msg = msg .. "[Warn]  "
	else
		msg = msg .. "[Info]  "
	end
	msg = msg .. fmt

	local args = { ... }
	local ok, fmted = pcall(format, msg, unpack(args))
	if ok then
		msg = fmted
	end

	if dev_mode >= DevLevels.FULL then
		if lvl == LogLevels.ERROR then
			spdlog.error(msg)
		else
			spdlog.info(msg)
		end
	end
	if dev_mode >= DevLevels.ALERT then
		local player = Game.GetPlayer()
		if player then
			player:SetWarningMessage(msg, 5)
		end
	end
	if dev_mode >= DevLevels.BASIC then
		print(msg)
	end
end

---Enforces a log message to be emitted using a temporary `dev_mode` override.
---Useful for outputting messages regardless of the current developer mode setting.
---Internally calls `log()` with the given parameters, then restores the previous `dev_mode`.
---@param mode DevLevelType # Temporary debug mode to use.
---@param lvl LogLevelType # Log level passed to `log()`.
---@param fmt string # Format string for the message.
---@vararg any # Optional arguments for formatting the message.
local function logE(mode, lvl, fmt, ...)
	if mode <= DevLevels.DISABLED then return end
	local prev = dev_mode
	dev_mode = mode
	log(lvl, fmt, ...)
	dev_mode = prev
end

---Checks whether all provided arguments are of a specified Lua type.
---@param t string # The expected Lua type name (e.g., "number", "string", "table", etc.).
---@param ... any # A variable number of values to check.
---@return boolean # Returns true if all arguments match the specified type, false otherwise.
local function isType(t, ...)
	for i = 1, select("#", ...) do
		if type(select(i, ...)) ~= t then
			return false
		end
	end
	return true
end

---Checks whether all provided arguments are of type `number`.
---@param ... any # A variable number of values to check.
---@return boolean # Returns true only if all arguments are numbers.
local function isNumber(...)
	return isType("number", ...)
end

---Checks whether all provided arguments are of type `string`.
---@param ... any # A variable string of values to check.
---@return boolean # Returns true only if all arguments are strings.
local function isString(...)
	return isType("string", ...)
end

---Checks whether all provided arguments are of type `table`.
---@param ... any # A variable table of values to check.
---@return boolean # Returns true only if all arguments are tables.
local function isTable(...)
	return isType("table", ...)
end

---Checks whether a given string represents a valid number (integer or float).
---@param s string # The input string to check.
---@return boolean # True if the string is a valid number, false otherwise.
local function hasNumber(s)
	return tonumber(s) ~= nil
end

---Compares two values for equality with special handling for numbers and tables.
---Number values are compared with a small tolerance to account for floating-point imprecision.
---Tables are compared recursively, including all nested keys and values.
---Other types (string, boolean, etc.) use strict equality.
---@param a any # The first value to compare.
---@param b any # The second value to compare.
---@return boolean # True if the values are considered equal, false otherwise.
local function equals(a, b)
	if a == b then return true end

	if type(a) ~= type(b) then return false end

	if isNumber(a) then
		return math.abs(a - b) < 1e-4
	elseif isTable(a) then
		for k, va in pairs(a) do
			if not equals(va, b[k]) then return false end
		end
		for k, vb in pairs(b) do
			if not equals(vb, a[k]) then return false end
		end
		return true
	end

	return false
end

---Checks whether a value exists in a table (list or map) or as a substring in a string.
---@param x table|string # The table or string to search.
---@param v any # The value or substring to search for.
---@return boolean # True if found, false otherwise.
local function contains(x, v)
	if x == nil or v == nil then return false end

	if isString(x, v) then
		---@cast x string
		---@cast v string
		if #x == #v then return x == v end
		return #x > #v and x:find(v, 1, true) ~= nil
	elseif isTable(x) then
		---@cast x table
		for k, e in pairs(x) do
			if k == v or e == v then
				return true
			end
		end
	end

	return false
end

---Checks if a string starts with a given prefix.
---@param s string # The string to check.
---@param v string # The prefix to match.
---@return boolean # True if `s` starts with `v`, false otherwise.
local function startsWith(s, v)
	if not s or not v then return false end
	s, v = tostring(s), tostring(v)
	if #s == #v then return s == v end
	return #s > #v and s:sub(1, #v) == v
end

---Checks if a string ends with a specified suffix.
---@param s string # The string to check.
---@param v string # The suffix to look for.
---@return boolean Returns # True if the `s` ends with the specified `v`, otherwise false.
local function endsWith(s, v)
	if not s or not v then return false end
	s, v = tostring(s), tostring(v)
	if #s == #v then return s == v end
	return #s > #v and s:sub(- #v) == v
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

---Checks if a given filename string ends with `.lua`.
---@param s string # The value to check, typically a string representing a filename.
---@return boolean # Returns `true` if the filename ends with `.lua`, otherwise `false`.
local function hasLuaExt(s)
	if not s then return false end
	return endsWith(s, ".lua")
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
	return hasLuaExt(s) and s:gsub("%.lua$", "") or s
end

---Iterates over a table's keys in sorted order.
---Useful for producing stable output or consistent serialization.
---@param t table # The table to iterate over.
---@return fun(): any, any # An iterator that yields key-value pairs in sorted key order.
local function kpairs(t)
	t = isTable(t) and t or {}
	local ks = {}
	for k in pairs(t) do
		insert(ks, k)
	end
	table.sort(ks, function(a, b)
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
---@param seen table|nil # Internal table to track already-copied references (prevents cycles).
---@return table # A new table with the same structure and values as the original.
local function clone(t, seen)
	if not isTable(t) then
		---@cast t any
		return t
	end

	if seen and seen[t] then return seen[t] end

	local result = {}
	seen = seen or {}
	seen[t] = result

	for k, v in pairs(t) do
		result[k] = clone(v, seen)
	end

	return result
end

---Ensures a nested table path exists and returns the deepest subtable.
---@param t table # The table to access.
---@param ... any # Keys leading to the nested table
---@return table? # The final nested subtable if `t` is a table; otherwise `nil`.
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
---@param t table? # The root table to access.
---@param fallback any # The fallback value if the lookup fails.
---@param ... any # One or more keys representing the path.
---@return any # The nested value if it exists, or the default value.
local function get(t, fallback, ...)
	if not isTable(t) then return fallback end
	local v = t ---@cast v table
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
	if i <= len then
		return select(i, ...)
	else
		return select(len, ...)
	end
end

---Splits a string into a list of substrings using a specified separator.
---@param s string? # The input string to split. If nil, returns an empty table.
---@param sep string? # The separator to split by (default: ",").
---@return string[] # A list of substrings resulting from the split.
local function split(s, sep)
	if not s then return {} end
	sep = sep or ","
	local t = {}
	for v in s:gmatch("([^" .. sep .. "]+)") do
		insert(t, v)
	end
	return t
end

---Converts any value to a readable string representation.
---For numbers, a trimmed 3-digit float format is used (e.g., 1.000 → "1", 3.140 → "3.14").
---For tables, the output is compact, recursively formatted, and uses sorted keys.
---@param x any # The value to convert to string.
---@return string # A string representation of the value.
local function serialize(x)
	if not isTable(x) then
		if hasNumber(x) then
			local str = format("%.3f", x):gsub("0+$", ""):gsub("%.$", "")
			return str
		end
		return tostring(x)
	end
	local s = "{"
	for k, v in kpairs(x) do
		s = s .. "[" .. serialize(k) .. "]=" .. serialize(v) .. ","
	end
	return s:sub(1, -2) .. "}"
end

---Calculates a non-cryptographic checksum of any value using Adler-32.
---Used to detect changes in structured data like tables.
---@param x any # The value to calculate the checksum for.
---@return integer # A 32-bit checksum value.
local function checksum(x)
	local s = serialize(x)
	local a, b = 1, 0
	for i = 1, #s do
		a = (a + s:byte(i)) % 65521
		b = (b + a) % 65521
	end
	return bor(lshift(b, 16), a)
end

---Checks whether a file with the given name exists and is readable.
---@param path string # The full or relative path to the file.
---@return boolean # True if the file exists and is readable, false otherwise.
local function fileExists(path)
	if not isString(path) then return false end
	local file = io.open(path, "r")
	if file then
		file:close()
		return true
	end
	return false
end

---Returns a formatted TweakDB record key for accessing vehicle camera data.
---@param id string # The vehicle camera preset ID.
---@param path string # The camera level path (e.g. "High_Close").
---@return string? # The formatted TweakDB record key.
local function getCameraTweakKey(id, path, var)
	if not isString(id, path, var) then return nil end

	local isVehicle = id == "v_militech_basilisk_CameraPreset"
	if isVehicle and (startsWith(path, "Low") or contains(path, "DriverCombat")) then
		return nil
	end

	local section = isVehicle and "Vehicle" or "Camera"
	return format("%s.VehicleTPP_%s_%s.%s", section, id, path, var)
end

---Fetches the default rotation pitch value for a vehicle camera.
---@param id string # The preset ID of the vehicle.
---@param path string # The camera path for the vehicle.
---@return number # The default rotation pitch for the given camera path.
local function getCameraDefaultRotationPitch(id, path)
	local key = getCameraTweakKey(id, path, "defaultRotationPitch")

	local defaults = {
		v_militech_basilisk_CameraPreset = 5,
		v_utility4_militech_behemoth_Preset = 12
	}
	local defVal = defaults[id] or 11
	if not key then return defVal end

	return tonumber(TweakDB:GetFlat(key)) or defVal
end

---Sets the default rotation pitch value for a vehicle camera.
---@param id string # The preset ID of the vehicle.
---@param path string # The camera path for the vehicle.
---@param value number # The value to set for the default rotation pitch.
local function setCameraDefaultRotationPitch(id, path, value)
	local key = getCameraTweakKey(id, path, "defaultRotationPitch")
	if not key then return end

	local fallback = getCameraDefaultRotationPitch(id, path)
	if not isNumber(value) or equals(value, fallback) then return end

	TweakDB:SetFlat(key, value or fallback)
end

---Fetches the current camera offset from TweakDB based on the specified ID and path.
---@param id string # The camera ID.
---@param path string # The camera path to retrieve the offset for.
---@return Vector3? # The camera offset as a Vector3.
local function getCameraLookAtOffset(id, path)
	local key = getCameraTweakKey(id, path, "lookAtOffset")
	if not key then return nil end

	return TweakDB:GetFlat(key)
end

---Sets a camera offset in TweakDB to the specified position values.
---@param id string # The camera ID.
---@param path string # The camera path to set the offset for.
---@param x number # The X-coordinate of the camera position.
---@param y number # The Y-coordinate of the camera position.
---@param z number # The Z-coordinate of the camera position.
local function setCameraLookAtOffset(id, path, x, y, z)
	local key = getCameraTweakKey(id, path, "lookAtOffset")
	if not key then return end

	local fallback = getCameraLookAtOffset(id, path)
	if not fallback or (equals(x, fallback.x) and equals(y, fallback.y) and equals(z, fallback.z)) then return end

	local value = Vector3.new(x or fallback.x, y or fallback.y, z or fallback.z)
	TweakDB:SetFlat(key, value)
end

---Extracts the record name from a TweakDBID string representation.
---@param data any # The TweakDBID to be parsed.
---@return string? # The extracted record name, or nil if not found.
local function getRecordName(data)
	if not data then return nil end
	return tostring(data):match("%-%-%[%[(.-)%-%-%]%]"):match("^%s*(.-)%s*$")
end

---Returns the vehicle the player is currently mounted in, if any.
---Internally retrieves the player instance and checks for an active vehicle.
---@return Vehicle? # The currently mounted vehicle instance, or nil if the player is not mounted.
local function getMountedVehicle()
	local player = Game.GetPlayer()
	if not player then
		vehicle_mounted = false
		return nil
	end
	local vehicle = Game.GetMountedVehicle(player)
	vehicle_mounted = vehicle ~= nil
	return vehicle
end

---Attempts to retrieve the camera ID associated with a given vehicle.
---@param vehicle Vehicle? # The vehicle from which to extract the camera ID.
---@return string? # The extracted camera ID (e.g., "4w_911") or nil if not found.
local function getVehicleCameraID(vehicle)
	if not vehicle then return nil end

	local record = vehicle:GetRecordID()
	if not record then return nil end

	local name = getRecordName(record)
	if not name then return nil end

	local data = TweakDB:GetFlat(name .. ".tppCameraPresets")
	if not data then return nil end

	for _, v in pairs(data) do
		local item = getRecordName(v)
		if item then
			return item:match("^[%a]+%.VehicleTPP_([%w_]+)_[%w_]+_[%w_]+")
		end
	end

	return nil
end

---Attempts to retrieve the name of the specified vehicle.
---@param vehicle Vehicle? # The vehicle object to retrieve the name from.
---@return string? # The resolved vehicle name as a string, or `nil` if it could not be determined.
local function getVehicleName(vehicle)
	if not vehicle then return nil end

	local tid = vehicle:GetTDBID()
	if not tid then return nil end

	local str = TDBID.ToStringDEBUG(tid)
	if not str then return nil end

	local result = str:gsub("^Vehicle%.", "")
	return result
end

---Attempts to retrieve the appearance name of the specified vehicle.
---@param vehicle Vehicle? # The vehicle object to retrieve the appearance name from.
---@return string? # The resolved vehicle name as a string, or `nil` if it could not be determined.
local function getVehicleAppearanceName(vehicle)
	if not vehicle then return nil end

	local name = vehicle:GetCurrentAppearanceName()
	if not name then return nil end

	local result = Game.NameToString(name)
	return result
end

---Attempts to find the best matching key in the `camera_presets` table using one or more candidate values.
---It first checks for exact matches, and then for prefix-based partial matches.
---@param ... string # One or more strings to match against known preset keys (e.g., vehicle name, appearance name).
---@return string? # The matching key from `camera_presets`, or `nil` if no match was found.
local function findPresetKey(...)
	for pass = 1, 2 do
		for i = 1, select("#", ...) do
			local search = select(i, ...)
			for key in pairs(camera_presets) do
				local exact = pass == 1 and search == key
				local partial = pass == 2 and startsWith(search, key)
				if exact or partial then return key end
			end
		end
	end
	return nil
end

---Validates a new preset key based on the given vehicle and appearance names.
---Ensures the key is non-empty, meets the minimum length, and matches expected name prefixes.
---@param vehicleName string # The base vehicle name used for validation.
---@param appearanceName string # The appearance variant of the vehicle. May be the same as `vehicleName`.
---@param currentKey string # The currently active or fallback preset key. Used as return value on failure.
---@param newKey string? # The newly entered preset key that should be validated.
---@return string # Returns the validated preset key (without `.lua` extension), or `currentKey` if validation fails.
local function validatePresetKey(vehicleName, appearanceName, currentKey, newKey)
	if not isString(vehicleName, appearanceName) then return currentKey end
	if not isString(currentKey) then return vehicleName end
	if not isString(newKey) then return currentKey end

	local name = trimLuaExt(newKey)

	local len = #name
	if len < 1 then
		if dev_mode >= DevLevels.ALERT then
			log(LogLevels.WARN, Text.LOG_BLANK_NAME)
		end
		return currentKey
	end

	if startsWith(vehicleName, name) or
		startsWith(appearanceName, name) then
		return name
	end

	if dev_mode >= DevLevels.ALERT then
		if vehicleName ~= appearanceName then
			log(LogLevels.WARN, Text.LOG_NAMES_MISM, vehicleName, appearanceName)
		else
			log(LogLevels.WARN, Text.LOG_NAME_MISM, vehicleName)
		end
	end

	return currentKey
end

---Retrieves the current camera offset data for the specified camera ID from TweakDB and returns it as a `ICameraPreset` table.
---@param id string # The camera ID to query.
---@return ICameraPreset? # The retrieved camera offset data, or nil if not found.
local function getPreset(id)
	if not id then return nil end

	local preset = { ID = id } ---@cast preset ICameraPreset
	for i, path in ipairs(CameraLevels) do
		local vec3 = getCameraLookAtOffset(id, path)
		if not vec3 or (not vec3.x and not vec3.y and not vec3.z) then goto continue end

		local level = PresetLevels[(i - 1) % 3 + 1]
		local angle = getCameraDefaultRotationPitch(id, path)

		preset[level] = {
			a = tonumber(angle),
			x = tonumber(vec3.x),
			y = tonumber(vec3.y),
			z = tonumber(vec3.z)
		}

		if preset.Far and preset.Medium and preset.Close then
			if dev_mode >= DevLevels.FULL then
				log(LogLevels.INFO, Text.LOG_CAM_OSET_DONE, id)
			end
			return preset
		end

		::continue::
	end

	log(LogLevels.ERROR, Text.LOG_NO_CAM_OSET, id)
	return nil
end

---Retrieves the default preset that matches the given preset's camera ID.
---@param preset ICameraPreset # The preset to search for a default version.
---@return ICameraPreset? # Returns the default preset if found, otherwise nil.
local function getDefaultPreset(preset)
	if not preset then return nil end

	local id = preset.ID
	if not id then return nil end

	for _, item in pairs(camera_presets) do
		if item.IsDefault and item.ID == id then
			if dev_mode >= DevLevels.FULL then
				log(LogLevels.INFO, Text.LOG_FOUND_DEF, id)
			end
			return item
		end
	end

	log(LogLevels.ERROR, Text.LOG_MISS_DEF, id)

	local fallback = getPreset(id)
	if not fallback then return nil end

	fallback.IsDefault = true
	camera_presets[id] = fallback
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
local function getOffsetData(preset, fallback, level)
	if not isTable(preset) or not contains(PresetLevels, level) then
		logE(DevLevels.FULL, LogLevels.ERROR, Text.LOG_NO_PSET_FOR_LVL, level)
		return 0, 0, 0, 0 --Should never be returned with the current code.
	end

	---@cast preset ICameraPreset
	local p = preset[level]
	local f = (fallback and fallback[level]) or {}

	local a = tonumber(p and p.a or f.a) or 11
	local x = tonumber(p and p.x or f.x) or 0
	local y = tonumber(p and p.y or f.y) or 0
	local z = tonumber(p and p.z or f.z) or ({ Close = 1.115, Medium = 1.65, Far = 2.25 })[level]

	return a, x, y, z
end

---Applies a camera offset preset to the vehicle by updating values in TweakDB.
---If no `preset` is provided, the preset is looked up automatically based on the mounted vehicle.
---If the preset includes a `Link` field, the function follows the link recursively
---until a final preset is found or the recursion depth limit (8) is reached.
---Missing values in the preset are replaced with fallback values from the default preset, if available.
---Each successfully applied preset ID is recorded in `used_presets`.
---@param preset ICameraPreset? # The preset to apply. May be `nil` to auto-resolve via the current vehicle.
---@param count number? # Internal recursion counter to prevent infinite loops via `Link`. Do not set manually.
local function applyPreset(preset, count)
	if not preset and not count then
		local vehicle = getMountedVehicle()
		if not vehicle then return end

		local name = getVehicleName(vehicle)
		if not name then return end

		local appName = getVehicleAppearanceName(vehicle)
		if not appName then return end

		local key = name == appName and findPresetKey(name) or findPresetKey(name, appName)
		if not key then return end

		if dev_mode >= DevLevels.ALERT then
			log(LogLevels.INFO, Text.LOG_CAM_PSET, key)
		end

		applyPreset(camera_presets[key], 0)
		return
	end

	if preset and preset.Link then
		count = (count or 0) + 1
		if dev_mode >= DevLevels.FULL then
			log(LogLevels.INFO, Text.LOG_LINK_PSET, count, preset.Link)
		end
		preset = camera_presets[preset.Link]
		if preset and preset.Link and count < 8 then
			applyPreset(preset, count)
			return
		end
	end

	if not preset or not preset.ID then
		log(LogLevels.ERROR, Text.LOG_FAIL_APPLY)
		return
	end

	local fallback = getDefaultPreset(preset) or {}
	for i, path in ipairs(CameraLevels) do
		local level = PresetLevels[(i - 1) % 3 + 1]
		local a, x, y, z = getOffsetData(preset, fallback, level)

		setCameraLookAtOffset(preset.ID, path, x, y, z)
		setCameraDefaultRotationPitch(preset.ID, path, a)
	end

	insert(used_presets, preset.ID)
end

---Restores all camera offset presets to their default values.
local function restoreAllPresets()
	for _, preset in pairs(camera_presets) do
		if preset.IsDefault then
			applyPreset(preset)
		end
	end
	used_presets = {}

	log(LogLevels.INFO, Text.LOG_REST_ALL)
end

---Restores modified camera offset presets to their default values.
local function restoreModifiedPresets()
	local changed = used_presets
	if #changed == 0 then return end

	local amount = #changed
	local restored = 0
	for _, preset in pairs(camera_presets) do
		if preset.IsDefault and contains(changed, preset.ID) then
			applyPreset(preset)
			log(LogLevels.INFO, Text.LOG_REST_PSET, preset.ID)
			restored = restored + 1
		end
		if restored >= amount then break end
	end
	used_presets = {}

	log(LogLevels.INFO, Text.LOG_REST_PSETS, restored, amount)
end

---Validates whether the given camera offset preset is structurally valid.
---A preset is valid if it either:
---1. Has a string ID and at least one of Close, Medium, or Far contains a numeric `y` or `z` value.
---2. Or: has only a string `Link` and no other keys.
---@param preset ICameraPreset # The preset to validate.
---@return boolean # Returns true if the preset is valid, false otherwise.
local function isPresetValid(preset)
	if not isTable(preset) then return false end

	if isString(preset.ID) then
		for _, e in ipairs(PresetLevels) do
			local offset = preset[e]
			if not isTable(offset) then
				goto continue
			end
			for _, k in ipairs(PresetOffsets) do
				if isNumber(offset[k]) then
					return true
				end
			end
			::continue::
		end
	end

	if isString(preset.Link) then
		for k, _ in pairs(preset) do
			if k ~= "Link" then
				return false
			end
		end
		return true
	end

	return false
end

---Adds, updates, or removes a preset entry in the `camera_presets` table.
---@param key string # The key under which the preset is stored (usually the preset name without ".lua").
---@param preset ICameraPreset? # The preset to store. If `nil`, the existing entry will be removed.
---@return boolean # True if the operation was successful (added, updated or removed), false if the key is invalid or the preset is not valid.
local function setPresetEntry(key, preset)
	if not isString(key) then return false end

	if preset == nil then
		if camera_presets[key] ~= nil then
			camera_presets[key] = nil
		end
		return true
	end

	if not isPresetValid(preset) then return false end

	camera_presets[key] = preset
	return true
end

---Generates the full file path to a preset file, optionally pointing to the default directory.
---Automatically appends the `.lua` extension if not already present.
---@param name string # The base name of the preset file (with or without `.lua` extension).
---@param isDefault boolean? # If true, returns the path in the `defaults` directory; otherwise in `presets`.
---@return string? # The full file path to the preset, or `nil` if the name is invalid.
local function getPresetFilePath(name, isDefault)
	if not isString(name) then return nil end
	local path = (isDefault and "defaults/" or "presets/") .. ensureLuaExt(name)
	return path
end

---Checks whether a preset file with the given name exists in the appropriate folder.
---Automatically adds the ".lua" extension if missing.
---@param name string # The name of the preset file (with or without ".lua" extension).
---@param isDefault boolean? # If true, checks the "defaults" directory instead of "presets".
---@return boolean # True if the file exists, false otherwise.
local function presetFileExists(name, isDefault)
	local path = getPresetFilePath(name, isDefault)
	if not path then return false end
	return fileExists(path)
end

---Clears all currently loaded camera offset presets.
local function purgePresets()
	camera_presets = {}
	log(LogLevels.WARN, Text.LOG_CLEAR_PSETS)
end

---Loads camera offset presets from `defaults` (first) and `presets` (second).
---Each `.lua` file must return a `ICameraPreset` table with at least an `ID` field.
---Skips already loaded presets unless `refresh` is true (then clears and reloads all).
---@param refresh boolean? — If true, clears existing presets before loading (default: false).
local function loadPresets(refresh)
	local function loadFrom(path)
		local files = dir(path)
		if not files then
			logE(DevLevels.FULL, LogLevels.ERROR, Text.LOG_DIR_NOT_EXIST, path)
			return -1
		end

		local isDef = path == "defaults"
		local count = 0
		for _, file in ipairs(files) do
			local name = file.name
			if not name or not hasLuaExt(name) then goto continue end

			local key = trimLuaExt(name)
			if camera_presets[key] then
				count = count + 1
				logE(DevLevels.BASIC, LogLevels.WARN, Text.LOG_SKIP_PSET, key, path, name)
				goto continue
			end

			local chunk, err = loadfile(path .. "/" .. name)
			if not chunk then
				logE(DevLevels.BASIC, LogLevels.ERROR, Text.LOG_FAIL_LOAD, path, name, err)
				goto continue
			end

			local ok, result = pcall(chunk)
			if not ok or (isDef and not result.IsDefault) or not setPresetEntry(key, result) then
				logE(DevLevels.BASIC, LogLevels.ERROR, Text.LOG_BAD_PSET, path, name)
				goto continue
			end

			count = count + 1
			if dev_mode >= DevLevels.FULL then
				log(LogLevels.INFO, Text.LOG_LOAD_PSET, key, path, name)
			end

			::continue::
		end

		return count
	end

	if refresh then
		purgePresets()
	end

	if loadFrom("defaults") < 39 then
		mod_enabled = false
		logE(DevLevels.FULL, LogLevels.ERROR, Text.LOG_DEFS_INCOMP)
		return
	end

	mod_enabled = loadFrom("presets") >= 0
end

---Saves a camera preset to file, either as a regular preset or as a default.
---It serializes only values that differ from the default (unless saving as default).
---@param name string # The name of the preset file (with or without `.lua` extension).
---@param preset table # The preset data to save (must include an `ID` and valid offset data).
---@param allowOverwrite boolean? # Whether existing files may be overwritten.
---@param saveAsDefault boolean? # If true, saves the preset to the `defaults` directory instead of `presets`.
---@return boolean # Returns `true` on success, or `false` if writing failed or nothing needed to be saved.
local function savePreset(name, preset, allowOverwrite, saveAsDefault)
	local path = getPresetFilePath(name, saveAsDefault)
	if not path or not isTable(preset) then return false end

	if not allowOverwrite then
		local check = io.open(path, "r")
		if check then
			check:close()
			log(LogLevels.WARN, Text.LOG_FILE_EXIST, path)
			return false
		end
	end

	local default = getDefaultPreset(preset) or {}
	local save = false
	local parts = { "return{" }
	insert(parts, format("ID=%q,", preset.ID))
	for _, mode in ipairs(PresetLevels) do
		local p = preset[mode]
		local d = default[mode]
		local sub = {}

		if isTable(p) then
			d = isTable(d) and d or {}
			for _, k in ipairs(PresetOffsets) do
				if saveAsDefault or not equals(p[k], d[k]) then
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
		log(LogLevels.WARN, Text.LOG_PSET_NOT_CHANGED, name, default.ID)

		if not saveAsDefault then
			local ok = os.remove(path)
			if ok then
				logE(DevLevels.ALERT, LogLevels.WARN, Text.LOG_DEL_SUCCESS, path)
			end
			return ok and setPresetEntry(name)
		end

		return false
	end

	if saveAsDefault then
		insert(parts, "IsDefault=true")
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

	logE(DevLevels.ALERT, LogLevels.INFO, Text.LOG_PSET_SAVED, name)

	return true
end

---Retrieves the available content width and calculates dynamic padding for UI alignment.
---If padding changes are locked, returns the last used padding.
---@return number width # The available content width inside the current window.
---@return number padding # The calculated horizontal padding for centering elements.
local function getMetrics()
	local width = ImGui.GetContentRegionAvail()
	if padding_locked then return width, padding_width end
	local style = ImGui.GetStyle()
	padding_width = max(10, math.floor((width - 230) * 0.5 + 18) - style.ItemSpacing.x)
	return width, padding_width
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

---Pushes a set of three related style colors to ImGui's style stack: base, hovered, and active.
---Calculated automatically from a single base color by brightening B, G, and R (weird order in LUA) channels.
---Returns the number of pushed styles so they can be popped accordingly.
---@param idx integer # The ImGuiCol index for the base color (e.g. ImGuiCol.FrameBg or ImGuiCol.Button).
---@param color integer # The base color in 0xAAGGBBRR format.
---@return integer # The number of style colors pushed. Returns 0 if arguments are invalid.
local function pushColors(idx, color)
	if not isNumber(idx, color) then return 0 end

	local hoveredIdx = idx + 1
	local activeIdx = idx + 2
	local base, hover, active = getThreeColorsFrom(idx, color)

	ImGui.PushStyleColor(idx, base)
	ImGui.PushStyleColor(hoveredIdx, hover)
	ImGui.PushStyleColor(activeIdx, active)

	--Currently always 3; may become dynamic if more GUI elements are added someday.
	return 3
end

---Safely pops a number of ImGui style colors from the stack.
---Calls `ImGui.PopStyleColor(num)` only if `num` is a positive integer.
---@param num integer # The number of style colors to pop from the ImGui stack.
local function popColors(num)
	if num <= 0 then return end
	ImGui.PopStyleColor(num)
end

---Displays a tooltip when the current UI item is hovered.
---If a single string is passed, displays it as wrapped text.
---If multiple arguments are passed, they are interpreted as alternating key-value pairs for a tooltip table.
---If a table is passed, it will be unpacked as key-value pairs.
---@param ... string|table # Either a single string, a table of pairs, or a sequence of key-value pairs.
local function addTooltip(...)
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
	if isString(item) then
		ImGui.BeginTooltip()
		ImGui.PushTextWrapPos(420)
		ImGui.Text(item)
		ImGui.PopTextWrapPos()
		ImGui.EndTooltip()
	elseif isTable(item) then
		addTooltip(unpack(item))
	end
end

---Displays a modal popup with a text prompt and two buttons: Yes and No.
---Returns true if the Yes button is clicked, false if No is clicked, and nil if the popup was not active.
---@param id string # The unique popup ID.
---@param text string # The message to display in the popup.
---@param yesBtnColor? number # Optional color index for the Yes button (ImGuiCol style constant).
---@param noBtnColor? number # Optional color index for the No button (ImGuiCol style constant).
---@return boolean? # true if Yes clicked, false if No clicked, nil if popup not active.
local function addPopupYesNo(id, text, yesBtnColor, noBtnColor)
	if not id or not ImGui.BeginPopup(id) then return nil end

	local result = nil

	ImGui.Text(text)
	ImGui.Dummy(0, 2)
	ImGui.Separator()
	ImGui.Dummy(0, 2)

	---@cast yesBtnColor number
	local pushed = isNumber(yesBtnColor) and pushColors(ImGuiCol.Button, yesBtnColor) or 0
	if ImGui.Button(Text.GUI_YES, 80, 30) then
		result = true
		ImGui.CloseCurrentPopup()
	end
	popColors(pushed)

	ImGui.SameLine()

	---@cast noBtnColor number
	pushed = isNumber(noBtnColor) and pushColors(ImGuiCol.Button, noBtnColor) or 0
	if ImGui.Button(Text.GUI_NO, 80, 30) then
		result = false
		ImGui.CloseCurrentPopup()
	end
	popColors(pushed)

	ImGui.EndPopup()
	return result
end

--This event is triggered when the CET environment initializes for a particular game session.
registerForEvent("onInit", function()
	--Save default presets.
	--[[
	local defaults = {
		"v_militech_basilisk_CameraPreset"
	}
	for _, value in ipairs(defaults) do
		local preset = getPreset(value)
		if preset then
			savePreset(preset.ID, preset, true, true)
		end
	end
	]]

	--Load all saved presets from disk.
	loadPresets(true)

	--This step is mainly necessary here in case all mods are reloaded while the player is already inside a vehicle.
	applyPreset()

	--When the player mounts a vehicle, automatically apply the matching camera preset if available.
	--This event can fire even if the player is already mounted, so we guard with `vehicle_mounted`.
	Observe("VehicleComponent", "OnMountingEvent", function()
		if not mod_enabled or vehicle_mounted then return end
		vehicle_mounted = true
		applyPreset()
	end)

	--When the player unmounts from a vehicle, reset to default camera offsets.
	Observe("VehicleComponent", "OnUnmountingEvent", function()
		if not mod_enabled then return end
		vehicle_mounted = false
		restoreModifiedPresets()
	end)

	--Reset the current editor state when the player takes control of their character
	--(usually after loading a save game). This ensures UI does not persist stale data.
	Observe("PlayerPuppet", "OnTakeControl", function(self)
		if not mod_enabled or self:GetEntityID().hash ~= 1 then return end
		vehicle_mounted = false
		applyPreset()
	end)
end)

--Detects when the CET overlay is opened.
registerForEvent("onOverlayOpen", function()
	overlay_open = true
end)

--Detects when the CET overlay is closed.
registerForEvent("onOverlayClose", function()
	overlay_open = false
end)

--Display a simple GUI with some options.
registerForEvent("onDraw", function()
	--Main window begins
	if not overlay_open or not ImGui.Begin(Text.GUI_TITL, ImGuiWindowFlags.AlwaysAutoResize) then return end

	--Minimum window width and height padding.
	ImGui.Dummy(230, 4)

	--Retrieves the available content width and the dynamically calculated control padding for UI element alignment.
	local contentWidth, controlPadding = getMetrics()

	--Checkbox to toggle mod functionality and handle enable/disable logic.
	ImGui.Dummy(controlPadding, 0)
	ImGui.SameLine()
	local isEnabled = ImGui.Checkbox(Text.GUI_TGL_MOD, mod_enabled)
	addTooltip(Text.GUI_TGL_MOD_TIP)
	if isEnabled ~= mod_enabled then
		mod_enabled = isEnabled
		if isEnabled then
			loadPresets()
			applyPreset()
			logE(DevLevels.ALERT, LogLevels.INFO, Text.LOG_MOD_ON)
		else
			dev_mode = DevLevels.DISABLED
			editor_data = {}
			restoreAllPresets()
			purgePresets()
			logE(DevLevels.ALERT, LogLevels.INFO, Text.LOG_MOD_OFF)
		end
	end
	ImGui.Dummy(0, 2)
	if not mod_enabled then
		--Mod is disabled — nothing left to add.
		ImGui.End()
		return
	end

	--The button that reloads all presets.
	ImGui.Dummy(controlPadding, 0)
	ImGui.SameLine()
	if ImGui.Button(Text.GUI_RLD_ALL, 192, 24) then
		editor_data = {}
		loadPresets(true)
		restoreAllPresets()
		applyPreset()
		logE(DevLevels.ALERT, LogLevels.INFO, Text.LOG_PSETS_RLD)
	end
	addTooltip(Text.GUI_RLD_ALL_TIP)
	ImGui.Dummy(0, 2)

	--Slider to set the developer mode level.
	ImGui.Dummy(controlPadding, 0)
	ImGui.SameLine()
	ImGui.PushItemWidth(77)
	dev_mode = ImGui.SliderInt(Text.GUI_DMODE, dev_mode, DevLevels.DISABLED, DevLevels.FULL)
	padding_locked = ImGui.IsItemActive()
	addTooltip(Text.GUI_DMODE_TIP)
	ImGui.PopItemWidth()
	ImGui.Dummy(0, 8)

	--Table showing vehicle name, camera ID and more — if certain conditions are met.
	local vehicle, name, appName, id, key
	for _, fn in ipairs({
		function()
			return dev_mode > DevLevels.DISABLED and vehicle_mounted
		end,
		function()
			vehicle = getMountedVehicle()
			return vehicle
		end,
		function()
			name = getVehicleName(vehicle)
			return name
		end,
		function()
			appName = getVehicleAppearanceName(vehicle)
			return appName
		end,
		function()
			id = getVehicleCameraID(vehicle)
			return id
		end,
		function()
			key = name ~= appName and findPresetKey(name, appName) or findPresetKey(name) or name
			return key
		end
	}) do
		if not fn() then
			--Condition not met — GUI closed.
			ImGui.End()
			return
		end
	end

	local editor = deep(editor_data, format("%s*%s", name, appName)) ---@cast editor IEditorPresetData
	editor.CurrentName = editor.CurrentName or key
	editor.FileName = editor.FileName or key

	if ImGui.BeginTable("PresetInfo", 2, ImGuiTableFlags.Borders) then
		ImGui.TableSetupColumn(Text.GUI_TBL_HEAD_KEY, ImGuiTableColumnFlags.WidthFixed, -1)
		ImGui.TableSetupColumn(Text.GUI_TBL_HEAD_VAL, ImGuiTableColumnFlags.WidthStretch)
		ImGui.TableHeadersRow()

		local keyVal = (editor.CurrentName ~= key or presetFileExists(editor.CurrentName)) and editor.CurrentName or id
		local dict = {
			{ key = Text.GUI_TBL_LABL_VEH,   value = name },
			{ key = Text.GUI_TBL_LABL_APP,   value = appName },
			{ key = Text.GUI_TBL_LABL_CAMID, value = id },
			{ key = Text.GUI_TBL_LABL_PSET,  value = keyVal },
			{ key = Text.GUI_TBL_LABL_ISDEF, value = key == nil and Text.GUI_TRUE or Text.GUI_FALSE }
		}
		for _, item in ipairs(dict) do
			ImGui.TableNextRow()
			ImGui.TableSetColumnIndex(0)
			ImGui.Text(item.key)

			local text = item.value or Text.GUI_NONE
			ImGui.TableSetColumnIndex(1)
			if item.key == Text.GUI_TBL_LABL_PSET then
				local value = text
				local file = ensureLuaExt(value)

				local width = ImGui.CalcTextSize(file) + 8
				ImGui.PushItemWidth(width)

				local isntDef = value ~= id
				local pushdCols = isntDef and pushColors(ImGuiCol.FrameBg, Colors.CUSTOM) or 0
				local newVal, changed = ImGui.InputText("##FileName", file, 96)
				if changed and newVal then
					editor.CurrentName = trimLuaExt(newVal)
					editor.RenamePending = true
				end
				popColors(pushdCols)
				addTooltip(
					format(Text.GUI_TBL_VAL_PSET_TIP,
						isntDef and file or ensureLuaExt(name),
						name,
						appName,
						chopUnderscoreParts(name),
						chopUnderscoreParts(appName)))

				ImGui.PopItemWidth()
			else
				ImGui.Text(tostring(text))
			end
		end

		ImGui.EndTable()
	end

	if editor.RenamePending then
		editor.RenamePending = editor.CurrentName ~= editor.FileName and presetFileExists(editor.FileName)
	end

	--Camera preset editor allowing adjustments to Angle, X, Y, and Z coordinates — if certain conditions are met.
	local preset = editor.Current or getPreset(id)
	if not preset then
		log(LogLevels.WARN, Text.LOG_NO_PSET_FOUND)

		--GUI closed — no further controls required.
		ImGui.End()
		return
	end

	if editor.RefreshPending or not editor.Origin then
		editor.RefreshPending = false

		local copy = clone(preset)
		editor.Origin = copy
		editor.OriginToken = checksum(copy)

		if editor.SavePending ~= true then
			copy = clone(copy)
			editor.File = copy
			editor.FileToken = checksum(copy)
		end

		editor.Current = preset

		if not editor.Default then
			local original = getDefaultPreset(preset) ---@cast original ICameraPreset
			copy = clone(original)
			copy.IsDefault = nil

			editor.Default = copy
			editor.DefaultToken = checksum(copy)
		end
	end

	local default = editor.Default
	if not default then
		log(LogLevels.ERROR, Text.LOG_NO_DEF_PSET, id, name)

		--GUI ends early — default preset not found.
		ImGui.End()
		return
	end

	if ImGui.BeginTable("PresetEditor", 5, ImGuiTableFlags.Borders) then
		local labels = {
			Text.GUI_TBL_HEAD_LVL,
			Text.GUI_TBL_HEAD_ANG,
			Text.GUI_TBL_HEAD_X,
			Text.GUI_TBL_HEAD_Y,
			Text.GUI_TBL_HEAD_Z
		}
		for i, label in ipairs(labels) do
			local flag = i < 3 and ImGuiTableColumnFlags.WidthFixed or ImGuiTableColumnFlags.WidthStretch
			ImGui.TableSetupColumn(label, flag, -1)
		end

		ImGui.TableHeadersRow()

		local tooltips = {
			Text.GUI_TBL_VAL_ANG_TIP,
			Text.GUI_TBL_VAL_X_TIP,
			Text.GUI_TBL_VAL_Y_TIP,
			Text.GUI_TBL_VAL_Z_TIP
		}
		for _, level in ipairs(PresetLevels) do
			ImGui.TableNextRow()
			ImGui.TableSetColumnIndex(0)
			ImGui.Text(level)

			for i, field in ipairs(PresetOffsets) do
				local defVal = get(default, 0, level, field)
				local curVal = get(preset, defVal, level, field)
				local speed = pick(i, 1, 5e-3)
				local minVal = pick(i, -45, -5, -10, 0)
				local maxVal = pick(i, 90, 5, 10, 32)
				local fmt = pick(i, "%.0f", "%.3f")

				ImGui.TableSetColumnIndex(i)
				ImGui.PushItemWidth(-1)

				local pushd = not equals(curVal, defVal) and pushColors(ImGuiCol.FrameBg, Colors.CUSTOM) or 0
				local newVal = ImGui.DragFloat(format("##%s_%s", level, field), curVal, speed, minVal, maxVal, fmt)
				if not equals(newVal, curVal) then
					newVal = min(max(newVal, minVal), maxVal)
					deep(preset, level)[field] = newVal
					editor.RefreshPending = true
				end
				popColors(pushd)

				local tip = tooltips[i]
				if tip then
					local origVal = get(editor.Origin, defVal, level, field)
					addTooltip(split(format(tip, defVal, minVal, maxVal, origVal), "|"))
				end

				ImGui.PopItemWidth()
			end
		end

		ImGui.EndTable()
		ImGui.Dummy(0, 1)
	end

	if editor.RefreshPending then
		editor.RefreshPending = false
		editor.Current = preset
		editor.CurrentToken = checksum(editor.Current)
		editor.ApplyPending = editor.CurrentToken ~= editor.OriginToken
		editor.SavePending = editor.CurrentToken ~= editor.FileToken
		if editor.SavePending then
			editor.SaveIsRestore = editor.CurrentToken == editor.DefaultToken
		end
	end
	key = validatePresetKey(name, appName, key or name, editor.CurrentName)
	if key ~= editor.CurrentName then
		editor.CurrentName = key
	end

	--Button to apply previously configured values in-game.
	local color = editor.SaveIsRestore and Colors.RESTORE or Colors.CONFIRM
	local pushed = editor.ApplyPending and pushColors(ImGuiCol.Button, color) or 0
	if ImGui.Button(Text.GUI_APPLY, contentWidth, 24) then
		editor.RefreshPending = true
		editor.ApplyPending = false
		camera_presets[key] = preset
		logE(DevLevels.ALERT, LogLevels.INFO, Text.LOG_PSET_UPD, key)
	end
	popColors(pushed)
	addTooltip(Text.GUI_APPLY_TIP)
	ImGui.Dummy(0, 1)

	--Button to save configured values to a file for future automatic use.
	local saveConfirmed = false
	pushed = (editor.SavePending or editor.RenamePending) and pushColors(ImGuiCol.Button, color) or 0
	if ImGui.Button(Text.GUI_SAVE, contentWidth, 24) then
		local path = key == editor.FileName and key or editor.FileName ---@cast path string
		if presetFileExists(path) then
			overwrite_confirm = true
			ImGui.OpenPopup(key)
		else
			saveConfirmed = true
		end
	end
	popColors(pushed)
	addTooltip(format(editor.SaveIsRestore and Text.GUI_REST_TIP or Text.GUI_SAVE_TIP, key))

	if overwrite_confirm then
		local confirmed = addPopupYesNo(key, format(Text.GUI_OVWR_CONFIRM, key), Colors.CONFIRM)
		if confirmed ~= nil then
			overwrite_confirm = false
			saveConfirmed = confirmed
		end
	end
	if saveConfirmed then
		saveConfirmed = false

		if editor.ApplyPending then
			camera_presets[key] = preset
			editor.RefreshPending = true
			editor.ApplyPending = false
			log(LogLevels.INFO, Text.LOG_PSET_UPD, key)
		end

		--Saving is always performed, even if no changes were made in the editor. The
		--user could theoretically delete preset files manually outside the game, and
		--the mod wouldn't detect that at runtime. It would be problematic if saving
		--were blocked just because the mod assumes there are no changes.
		if savePreset(key, preset, true) then
			editor.SavePending = false
			if editor.RenamePending then
				editor.RenamePending = false
				local path = getPresetFilePath(editor.FileName) ---@cast path string
				local ok = os.remove(path)
				if ok then
					editor.FileName = editor.CurrentName
				end
			end
		else
			logE(DevLevels.ALERT, LogLevels.WARN, Text.LOG_PSET_NOT_SAVED, key)
		end
	end

	ImGui.Dummy(0, 4)

	--Button to open Preset File Manager
	local x, y, w, h
	ImGui.Separator()
	ImGui.Dummy(0, 4)
	if ImGui.Button(Text.GUI_OPEN_FMAN, contentWidth, 24) then
		x, y = ImGui.GetWindowPos()
		w, h = ImGui.GetWindowSize()
		file_man_open = not file_man_open
	end
	ImGui.Dummy(0, 2)

	--GUI creation of Main window is complete.
	ImGui.End()

	--Preset File Manager window
	if not file_man_open then return end

	local files = dir("presets")
	if not files then
		file_man_open = false
		logE(DevLevels.FULL, LogLevels.ERROR, Text.LOG_DIR_NOT_EXIST, "presets")
		return
	end

	if x and y and w and h then
		ImGui.SetNextWindowPos(x, y)
		ImGui.SetNextWindowSize(w, h)
	end

	local flags = bor(ImGuiWindowFlags.NoCollapse, ImGuiWindowFlags.NoResize, ImGuiWindowFlags.NoMove)
	file_man_open = ImGui.Begin(Text.GUI_FMAN_TITLE, file_man_open, flags)
	if not file_man_open then return end

	local anyFiles = false
	if ImGui.BeginTable("PresetFiles", 2, ImGuiTableFlags.Borders) then
		ImGui.TableSetupColumn(Text.GUI_FMAN_HEAD_NAME, ImGuiTableColumnFlags.WidthStretch)
		ImGui.TableSetupColumn(Text.GUI_FMAN_HEAD_ACTION, ImGuiTableColumnFlags.WidthFixed)
		ImGui.TableHeadersRow()

		for _, f in ipairs(files) do
			local file = f.name
			if not hasLuaExt(file) then goto continue end

			local k = trimLuaExt(file)
			if not contains(camera_presets, trimLuaExt(file)) then goto continue end

			anyFiles = true

			ImGui.TableNextRow()
			ImGui.TableSetColumnIndex(0)

			local columnWidth = ImGui.GetColumnWidth(0) - 4
			local textWidth = ImGui.CalcTextSize(file)
			if columnWidth < textWidth then
				local short = file
				local dots = "..."
				local cutoff = columnWidth - ImGui.CalcTextSize(dots)
				while #short > 0 and ImGui.CalcTextSize(short) > cutoff do
					short = short:sub(1, -2)
				end
				ImGui.Text(short .. dots)
				addTooltip(file)
			else
				ImGui.Text(file)
			end

			ImGui.TableSetColumnIndex(1)
			if ImGui.Button(format(Text.GUI_FMAN_DEL_BTN, file)) then
				ImGui.OpenPopup(file)
			end

			if addPopupYesNo(file, format(Text.GUI_FMAN_DEL_CONFIRM, file), Colors.DELETE) then
				local path = getPresetFilePath(file) ---@cast path string
				local ok = os.remove(path)
				if ok then
					for n, _ in pairs(editor_data) do
						local parts = split(n, "*")
						if #parts < 2 then goto continue end

						local vName, aName = parts[1], parts[2]
						if startsWith(vName, k) or startsWith(aName, k) then
							editor_data[n] = nil
						end

						::continue::
					end
					setPresetEntry(k)
					logE(DevLevels.ALERT, LogLevels.INFO, Text.LOG_DEL_SUCCESS, file)
				else
					logE(DevLevels.ALERT, LogLevels.WARN, Text.LOG_DEL_FAILURE, file)
				end
			end

			::continue::
		end

		ImGui.EndTable()
	end

	if not anyFiles then
		ImGui.Dummy(0, 180)
		ImGui.Dummy(controlPadding - 4, 0)
		ImGui.SameLine()
		ImGui.PushStyleColor(ImGuiCol.Text, adjustColor(Colors.DELETE, 0xff))
		ImGui.Text(Text.GUI_FMAN_NO_PSETS)
		ImGui.PopStyleColor()
	end

	--GUI creation of Preset File Manager window is complete.
	ImGui.End()
end)

--Restores default camera offsets for vehicles upon mod shutdown.
registerForEvent("onShutdown", function()
	restoreAllPresets()
end)
