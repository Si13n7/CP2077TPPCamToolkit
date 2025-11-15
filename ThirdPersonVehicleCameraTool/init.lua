--[[
==============================================
This file is distributed under the MIT License
==============================================

Third-Person Vehicle Camera Tool

Allows you to adjust third-person perspective
(TPP) camera offsets for any vehicle.

Filename: init.lua
Version: 2025-04-28, 00:00 UTC+01:00 (MEZ)

Copyright (c) 2025, Si13n7 Developments(tm)
All rights reserved.
______________________________________________
--]]


--#region 🚧 Core Definitions

--Aliases for commonly used standard library functions to simplify code.
local format, rep, concat, insert, unpack, ceil, floor, max, min, band, bor, lshift, rshift =
	string.format,
	string.rep,
	table.concat,
	table.insert,
	table.unpack,
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
---@field CARAMEL integer # Caramel is a warm, golden brown with rich amber tones.
---@field FIR integer # Fir is a dark, cool green with subtle blue undertones.
---@field GARNET integer # Garnet is a deep, muted red with a subtle brown undertone.
---@field MULBERRY integer # Mulberry is a deep, muted purple with rich red undertones and a cool, berry-like hue.
---@field OLIVE integer # Olive is a muted yellow-green with an earthy, natural tone.
---@type ColorEnum
local Colors = {
	CARAMEL = 0x8a295c7a,
	FIR = 0x8a6a7a29,
	GARNET = 0x8a29297a,
	MULBERRY = 0x8a68297a,
	OLIVE = 0x8a297a68
}

---Determines whether the mod is enabled.
---@type boolean
local mod_enabled = true

---Represents a parsed version number in structured format.
---@class IVersion
---@field Major number # Major version number (required).
---@field Minor number # Minor version number (optional, defaults to 0 if missing).
---@field Build number # Build number (optional, defaults to 0 if missing).
---@field Revision number # Revision number (optional, defaults to 0 if missing).

---Indicates whether the running CET version meets the minimum required version.
---@type boolean
local runtime_min = false

---Indicates whether the running CET version supports all required features.
---@type boolean
local runtime_full = false

---The current debug mode level controlling logging and alerts:
---0 = Disabled
---1 = Print
---2 = Print + Alert
---3 = Print + Alert + Log
---@type DevLevelType
local dev_mode = DevLevels.DISABLED

---Indicates whether there are active toast notifications pending.
---@type boolean
local toaster_active = false

---Maps `ImGui.ToastType` to their combined message strings.
---@type table<ImGui.ToastType, string>
local toaster_bumps = {}

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

---Constant array of all camera levels.
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

---Constant array of base camera levels.
---@type string[]
local PresetLevels = { "Close", "Medium", "Far" }

---Constant array of `IOffsetData` keys.
---@type string[]
local PresetOffsets = { "a", "x", "y", "z" }

---Stores original custom parameter values before resetting them to global defaults.
---Keys are TweakDB paths (string), and values are the original values.
---Allows potential restoration of vehicle-specific parameters on shutdown.
---@type table<string, any>
local custom_params = {}

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

---Represents optional overrides for how camera presets are accessed in TweakDB.
---@class ICameraAccessOverrides
---@field Key string? # Optional format string to override the TweakDB record key (replacing "Camera.VehicleTPP_4w_911").
---@field Levels string[]? # Optional list of level identifiers to use instead of the default `CameraLevels` array.
---@field Due boolean? # If true, indicates that these overrides are pending and should be applied on the next preset update action.

---Represents a vehicle camera preset or links to another one.
---@class ICameraPreset
---@field ID string? # The camera ID used for the vehicle.
---@field Close IOffsetData? # The offset data for close camera view.
---@field Medium IOffsetData? # The offset data for medium camera view.
---@field Far IOffsetData? # The offset data for far camera view.
---@field Link string? # The name of another vehicle appearance to link to (if applicable).
---@field Overrides ICameraAccessOverrides? # Optional overrides for TweakDB access, used when a custom record key is specified.
---@field IsDefault boolean? # Determines whether this camera preset is a vanilla one.

---Contains all camera presets and linked vehicles.
---@type table<string, ICameraPreset>
local camera_presets = {}

---A single camera preset entry in the editor, including its data and metadata.
---@class IEditorPreset
---@field Preset ICameraPreset # The actual preset data (angles and offsets).
---@field Key string # Internal identifier for lookups and invalid name detection.
---@field Name string # User-modifiable display name of the preset.
---@field Token number # Adler‑32 checksum of `Preset`, used to detect changes.
---@field IsPresent boolean # True if a corresponding preset file exists on disk.

---Flags for pending editor actions on a modified camera preset.
---@class IEditorTasks
---@field Rename boolean # True if the preset has been renamed but the file itself still needs to be renamed.
---@field Validate boolean # True if angles or offsets have changed, used to highlight buttons.
---@field Apply boolean # True if there are unapplied changes ready to be applied in-game.
---@field Save boolean # True if there are unsaved modifications that need to be written to disk.
---@field Restore boolean # True if saving will revert the preset back to its default configuration.

---Represents all versions and pending actions for a vehicle’s camera preset in the UI editor.
---@class IEditorBundle
---@field Nexus IEditorPreset # Immutable default preset for the mounted vehicle.
---@field Flux IEditorPreset # Live preset reflecting current UI edits.
---@field Pivot IEditorPreset # Snapshot of Flux at the last apply action.
---@field Finale IEditorPreset # Snapshot of Flux at the last save action.
---@field Tasks IEditorTasks # Flags for pending rename, validate, apply, save, or restore actions.

---Holds per-vehicle editor state for all mounted and recently edited vehicles.
---The key is always the vehicle name and appearance name, separated by an asterisk (*).
---Each entry tracks editor data and preset version states for the given vehicle.
---@type table<string, IEditorBundle|nil>
local editor_bundles = {}

---Determines whether overwriting the preset file is allowed.
---@type boolean
local overwrite_confirm

---Determines whether the Preset File Manager is open.
---@type boolean
local file_man_open = false

--#endregion

--#region 🔧 Utility Functions

---Parses a version string or returns an existing IVersion table.
---Accepts version formats like "[v]major[.minor[.build[.revision]]]" or numeric/string variants.
---@param x table|string # A version input as a string, or IVersion table.
---@return IVersion # A table with Major, Minor, Build, and Revision fields as numbers.
local function getVersion(x)
	if type(x) == "table" and type(x.Major) == "number" then return x end
	if type(x) ~= "string" then x = tostring(x) end
	local v1, v2, v3, v4 = x:match("^v?(%d+)%.?(%d*)%.?(%d*)%.?(%d*)$")
	return {
		Major = tonumber(v1) or 0,
		Minor = tonumber(v2) or 0,
		Build = tonumber(v3) or 0,
		Revision = tonumber(v4) or 0
	}
end

---Compares two version strings in "[v]major.minor[.build[.revision]]" format.
---Returns 1 if a > b, -1 if a < b, or 0 if equal.
---@param a IVersion|string # First version.
---@param b IVersion|string # Second version.
---@return integer # 1 if `a > b`, -1 if `a < b`, 0 if equal.
local function compareVersion(a, b)
	local v1 = getVersion(a)
	local v2 = getVersion(b)
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

---Checks if the runtime version is greater than or equal to a specified minimum version.
---@param v string # Minimum required version in "[v]major[.minor[.build[.revision]]]" format.
---@return boolean # `true` if the runtime version is >= the specified version, `false` otherwise.
local function isRuntimeVersionAtLeast(v)
	return compareVersion(GetVersion(), v) >= 0
end

---Logs and displays messages based on the current `dev_mode` level.
---Messages can be written to the log file, printed to the console, or shown as in-game alerts.
---@param lvl LogLevelType # Logging level (0 = Info, 1 = Warning, 2 = Error).
---@param id integer # The ID used for location tracing.
---@param fmt string # A format string for the message.
---@vararg any # Additional arguments for formatting the message.
local function log(lvl, id, fmt, ...)
	if dev_mode == DevLevels.DISABLED then return end

	local msg = format("[TPVCamTool]  [%04d]  ", id and id or -1)
	if fmt == nil then
		lvl = LogLevels.ERROR
	end

	if lvl >= LogLevels.ERROR then
		msg = msg .. "[Error]  "
	elseif lvl == LogLevels.WARN then
		msg = msg .. "[Warn]  "
	else
		msg = msg .. "[Info]  "
	end
	msg = format(msg .. (fmt or "Format in log() is empty!"), ...)

	if dev_mode >= DevLevels.FULL then
		if lvl == LogLevels.ERROR then
			spdlog.error(msg)
		else
			spdlog.info(msg)
		end
	end
	if dev_mode >= DevLevels.ALERT then
		if runtime_full then
			local t
			if lvl == LogLevels.ERROR then
				t = ImGui.ToastType.Error
			elseif lvl == LogLevels.WARN then
				t = ImGui.ToastType.Warning
			else
				t = ImGui.ToastType.Info
			end

			local s = toaster_bumps[t]
			toaster_bumps[t] = "\u{f035f} " .. (s and format("%s\n\n%s", msg, s) or msg)

			toaster_active = true
		else
			local player = Game.GetPlayer()
			if player then
				player:SetWarningMessage(msg, 5)
			end
		end
	end
	if dev_mode >= DevLevels.BASIC then
		print(msg)
	end
end

---Forces a log message to be emitted using a temporary `dev_mode` override.
---Useful for outputting messages regardless of the current developer mode setting.
---Internally calls `log()` with the given parameters, then restores the previous `dev_mode`.
---@param mode DevLevelType # Temporary debug mode to use.
---@param lvl LogLevelType # Log level passed to `log()`.
---@param id integer # The ID used for location tracing.
---@param fmt string # Format string for the message.
---@vararg any # Optional arguments for formatting the message.
local function logF(mode, lvl, id, fmt, ...)
	if mode <= DevLevels.DISABLED then return end
	local prev = dev_mode
	dev_mode = prev < mode and mode or prev
	log(lvl, id, fmt, ...)
	dev_mode = prev
end

---Checks whether all provided arguments are of the specified type.
---Supports both built-in Lua types (e.g., "number", "string", "table", etc.)
---and custom types (by matching `__name` from metatables for userdata objects).
---@param t string # The expected type name (either a Lua base type or a custom `__name` string).
---@param ... any # A variable number of values to check against the specified type.
---@return boolean # Returns `true` if all arguments match the specified type, `false` otherwise.
local function isType(t, ...)
	local special = ({
		["function"] = true,
		boolean = true,
		number = true,
		string = true,
		table = true,
		userdata = true,
		thread = true
	})[t] == nil
	for i = 1, select("#", ...) do
		local v = select(i, ...)

		if special then
			if type(v) ~= "userdata" then
				return false
			end

			local m = getmetatable(v)
			if not (m and m.__name == t) then
				return false
			end

			goto continue
		end

		if type(v) ~= t then
			return false
		end

		::continue::
	end
	return true
end

---Checks whether all provided arguments are of type `boolean`.
---@param ... any # A variable number of values to check.
---@return boolean # Returns true only if all arguments are booleans.
local function isBoolean(...)
	return isType("boolean", ...)
end

---Checks whether all provided arguments are of type `number`.
---@param ... any # A variable number of values to check.
---@return boolean # Returns true only if all arguments are numbers.
local function isNumber(...)
	return isType("number", ...)
end

---Checks whether all provided arguments are of type `string`.
---@param ... any # A variable number of values to check.
---@return boolean # Returns true only if all arguments are strings.
local function isString(...)
	return isType("string", ...)
end

---Checks whether all provided arguments are of type `table`.
---@param ... any # A variable number of values to check.
---@return boolean # Returns true only if all arguments are tables.
local function isTable(...)
	return isType("table", ...)
end

---Checks whether all provided arguments are non-empty tables.
---Returns false if any argument is not a table or is an empty table.
---@param ... any # A variable number of values to check.
---@return boolean # True if all arguments are non-empty tables, false otherwise.
local function isTableNotEmpty(...)
	for i = 1, select("#", ...) do
		local t = select(i, ...)
		if type(t) ~= "table" or not next(t) then
			return false
		end
	end
	return true
end

---Determines whether a table is a pure sequence (array) with contiguous integer keys 1..#t.
---Returns false if any key is non‑numeric or if there are gaps in the numeric index.
---@param t table? # The table to test (nil or non‑table will be treated as not an array).
---@return boolean # True if `t` is an array of length `#t` with no non‑numeric keys.
local function isArray(t)
	if not isTable(t) then return false end
	---@cast t table
	local n = #t
	local c = 0
	for k in pairs(t) do
		if type(k) ~= "number" then
			return false
		end
		c = c + 1
	end
	return c == n
end

---Checks whether all provided arguments are of type `Vector3`.
---@param ... any # A variable number of values to check.
---@return boolean # Returns true only if all arguments are Vector3s.
local function isVector3(...)
	return isType("sol.Vector3", ...)
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
	elseif hasNumber(a) then
		return math.abs(tonumber(a) - tonumber(b)) < 1e-4
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
---@param caseInsensitive boolean? # True if string comparisons ignore letter case.
---@return boolean # True if `s` starts with `v`, false otherwise.
local function startsWith(s, v, caseInsensitive)
	if not s or not v then return false end
	s, v = tostring(s), tostring(v)
	if caseInsensitive then
		s = s:lower()
		v = v:lower()
	end
	if #s == #v then return s == v end
	return #s > #v and s:sub(1, #v) == v
end

---Checks if a string ends with a specified suffix.
---@param s string # The string to check.
---@param v string # The suffix to look for.
---@param caseInsensitive boolean? # True if string comparisons ignore letter case.
---@return boolean Returns # True if the `s` ends with the specified `v`, otherwise false.
local function endsWith(s, v, caseInsensitive)
	if not s or not v then return false end
	s, v = tostring(s), tostring(v)
	if caseInsensitive then
		s = s:lower()
		v = v:lower()
	end
	if #s == #v then return s == v end
	return #s > #v and s:sub(- #v) == v
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

---Converts any value to a readable string representation.
---For numbers, a trimmed 3-digit float format is used (e.g., 1.000 → "1", 3.140 → "3.14").
---For tables, the output is compact, recursively formatted, and uses sorted keys.
---@param x any # The value to convert to string.
---@return string # A string representation of the value.
local function serialize(x)
	if not isTable(x) then
		if isString(x) then
			return format("%q", x)
		elseif hasNumber(x) then
			local str = format("%.3f", x):gsub("0+$", ""):gsub("%.$", "")
			return str
		elseif isVector3(x) then
			local t = {}
			for _, a in ipairs({ "x", "y", "z" }) do
				insert(t, serialize(x[a]))
			end
			return format("Vector3{ x = %s, y = %s, z = %s }", unpack(t))
		else
			return tostring(x)
		end
	end

	if isArray(x) then
		local parts = {}
		for i = 1, #x do
			parts[i] = serialize(x[i])
		end
		return "{" .. concat(parts, ",") .. "}"
	end

	local parts = {}
	for k, v in kpairs(x) do
		local key
		if isString(k) and k:match("^[%a_][%w_]*$") ~= nil then
			key = k
		else
			key = "[" .. serialize(k) .. "]"
		end
		parts[#parts + 1] = key .. "=" .. serialize(v)
	end
	return "{" .. concat(parts, ",") .. "}"
end

---Computes an Adler‑32 checksum over one or more values without allocating a new table.
---@param ... any # One or more values to include in the checksum calculation.
---@return integer # 32‑bit checksum combining all arguments.
local function checksum(...)
	local a, b = 1, 0
	local n = select('#', ...)
	for i = 1, n do
		local v = select(i, ...)
		local s = serialize(v)
		for j = 1, #s do
			a = (a + s:byte(j)) % 65521
			b = (b + a) % 65521
		end
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

--#endregion

--#region 🧬 Tweak Accessors

---Returns a formatted TweakDB record key for accessing vehicle camera data.
---@param preset ICameraPreset # The camera preset.
---@param path string # The camera level path (e.g. "High_Close").
---@param var string # The variable name.
---@return string? # The formatted TweakDB record key.
local function getCameraTweakKey(preset, path, var)
	if not isTable(preset) then return nil end

	local id = preset.ID
	if not isString(id, path, var) then return nil end

	local overrides = preset.Overrides ---@cast overrides ICameraAccessOverrides
	if isTable(overrides) and overrides.Due then
		if not isString(overrides.Key) then
			return nil
		end
		local key = format("%s_%s.%s", overrides.Key, path, var)
		return key
	end

	local isBasilisk = preset.ID == "v_militech_basilisk_CameraPreset"
	if isBasilisk and (startsWith(path, "Low") or contains(path, "DriverCombat")) then
		return nil
	end

	local section = isBasilisk and "Vehicle" or "Camera"
	return format("%s.VehicleTPP_%s_%s.%s", section, preset.ID, path, var)
end

---Fetches the default rotation pitch value for a vehicle camera.
---@param preset ICameraPreset # The camera preset.
---@param path string # The camera path for the vehicle.
---@return number # The default rotation pitch for the given camera path.
local function getCameraDefaultRotationPitch(preset, path)
	local key = getCameraTweakKey(preset, path, "defaultRotationPitch")

	local isLow = startsWith(path, "Low", true)
	local defaults = {
		v_militech_basilisk_CameraPreset    = { low = 5, high = 5 },
		v_utility4_militech_behemoth_Preset = { low = 5, high = 12 },
		default                             = { low = 4, high = 11 },
	}

	local def = defaults[preset.ID] or defaults.default
	local defVal = isLow and def.low or def.high

	if not key then return defVal end

	local value = tonumber(TweakDB:GetFlat(key))
	if isLow and value and (value == 11 or value == 12) then
		value = value - 7
	end

	return value or defVal
end

---Sets the default rotation pitch value for a vehicle camera.
---@param preset ICameraPreset # The camera preset.
---@param path string # The camera path for the vehicle.
---@param value number # The value to set for the default rotation pitch.
local function setCameraDefaultRotationPitch(preset, path, value)
	local key = getCameraTweakKey(preset, path, "defaultRotationPitch")
	if not key then return end

	local fallback = getCameraDefaultRotationPitch(preset, path)

	if startsWith(path, "Low", true) then
		value = value - 7
	end

	local overrideDue = get(preset, {}, "Overrides").Due
	if not isNumber(value) or (not overrideDue and equals(value, fallback)) then return end

	if overrideDue and not custom_params[key] then
		custom_params[key] = fallback
		if dev_mode >= DevLevels.ALERT then
			log(LogLevels.INFO, 771, Text.LOG_PARAM_CAM, key, fallback, value)
		end
	end

	TweakDB:SetFlat(key, value or fallback)
end

---Fetches the current camera offset from TweakDB based on the specified ID and path.
---@param preset ICameraPreset # The camera preset.
---@param path string # The camera path to retrieve the offset for.
---@return Vector3? # The camera offset as a Vector3.
local function getCameraLookAtOffset(preset, path)
	local key = getCameraTweakKey(preset, path, "lookAtOffset")
	if not key then return nil end

	return TweakDB:GetFlat(key)
end

---Sets a camera offset in TweakDB to the specified position values.
---@param preset ICameraPreset # The camera preset.
---@param path string # The camera path to set the offset for.
---@param x number # The X-coordinate of the camera position.
---@param y number # The Y-coordinate of the camera position.
---@param z number # The Z-coordinate of the camera position.
local function setCameraLookAtOffset(preset, path, x, y, z)
	local key = getCameraTweakKey(preset, path, "lookAtOffset")
	if not key then return end

	local fallback = getCameraLookAtOffset(preset, path)
	if not fallback or (equals(x, fallback.x) and equals(y, fallback.y) and equals(z, fallback.z)) then return end

	local value = Vector3.new(x or fallback.x, y or fallback.y, z or fallback.z)

	if get(preset, {}, "Overrides").Due and not custom_params[key] then
		custom_params[key] = fallback
		if dev_mode >= DevLevels.ALERT then
			log(LogLevels.INFO, 811, Text.LOG_PARAM_CAM, key, serialize(fallback), serialize(value))
		end
	end

	TweakDB:SetFlat(key, value)
end

---Resets custom camera behavior values for a vehicle to their global defaults.
---Ensures modded vehicles do not override global TweakDB values such as FOV or camera locking.
---This operation is destructive and cannot be undone once executed.
---@param vehicle Vehicle? The vehicle whose camera behavior should be reset.
local function resetCustomCameraParams(vehicle)
	if not vehicle then return end

	local vtid = vehicle:GetTDBID()
	if not vtid then return end

	local vname = TDBID.ToStringDEBUG(vtid)
	if not vname then return end

	local cptid = TweakDB:GetFlat(vname .. ".tppCameraParams")
	if not cptid then return end

	local cparam = TDBID.ToStringDEBUG(cptid)
	if not cparam then return end

	local param = "Camera.VehicleTPP_DefaultParams"
	for _, v in ipairs({ ".fov", ".lockedCamera" }) do
		local path = cparam .. v
		local val = TweakDB:GetFlat(path)
		if not val then goto continue end

		local ref = TweakDB:GetFlat(param .. v)
		if not ref then
			if not isBoolean(val) then goto continue end
			ref = false
		end

		if not equals(val, ref) then
			if not custom_params[path] then
				custom_params[path] = val
			end

			TweakDB:SetFlat(path, ref)

			logF(DevLevels.ALERT, LogLevels.INFO, 833, Text.LOG_PARAM_MANIP, path, val, ref)
		end

		::continue::
	end
end

---Restores previously overridden custom camera behavior values.
---Only re-applies values if they differ from the current ones in TweakDB.
---Requires `custom_params` to contain valid entries; otherwise, nothing happens.
local function restoreCustomCameraParams()
	if not next(custom_params) then return end

	for k, v in pairs(custom_params) do
		local value = TweakDB:GetFlat(k)
		if not equals(value, v) then
			TweakDB:SetFlat(k, v)

			if isVector3(value, v) then
				value, v = serialize(value), serialize(v)
				log(LogLevels.INFO, 877, Text.LOG_PARAM_REST, k, value, v)
			else
				logF(DevLevels.ALERT, LogLevels.INFO, 878, Text.LOG_PARAM_REST, k, value, v)
			end
		end
	end

	custom_params = {}
end

---Extracts the record name from a TweakDBID string representation.
---@param data any # The TweakDBID to be parsed.
---@return string? # The extracted record name, or nil if not found.
local function getRecordName(data)
	if not data then return nil end
	return tostring(data):match("%-%-%[%[(.-)%-%-%]%]"):match("^%s*(.-)%s*$")
end

--#endregion

--#region 🚗 Vehicle Metadata

---Returns the vehicle the player is currently mounted in, if any.
---Internally retrieves the player instance and checks for an active vehicle.
---@return Vehicle? # The currently mounted vehicle instance, or nil if the player is not mounted.
local function getMountedVehicle()
	local player = Game.GetPlayer()
	if not player then
		vehicle_mounted = false
		if dev_mode >= DevLevels.ALERT then
			log(LogLevels.WARN, 912, Text.LOG_NO_PLAYER)
		end
		return nil
	end
	local vehicle = Game.GetMountedVehicle(player)
	vehicle_mounted = vehicle ~= nil
	return vehicle
end

---Retrieves the list of third-person camera preset keys for a given vehicle.
---Each key is in the form "Camera.VehicleTPP_<CameraID>_<Level>".
---@param vehicle Vehicle? # The vehicle object to extract camera keys from.
---@return string[]? # Array of camera preset keys, or `nil` if not found.
local function getVehicleCameraKeys(vehicle)
	if not vehicle then return nil end

	local vid = vehicle:GetRecordID()
	if not vid then
		if dev_mode >= DevLevels.ALERT then
			log(LogLevels.ERROR, 930, Text.LOG_NO_RECID)
		end
		return nil
	end

	local vname = getRecordName(vid)
	if not vname then
		if dev_mode >= DevLevels.ALERT then
			log(LogLevels.ERROR, 930, Text.LOG_NO_RECN)
		end
		return nil
	end

	local record = TweakDB:GetFlat(vname .. ".tppCameraPresets")
	if not isTable(record) then return nil end ---@cast record table

	local list = {}
	for _, v in ipairs(record) do
		local name = getRecordName(v)
		if not name then goto continue end

		insert(list, tostring(name))

		::continue::
	end

	return next(list) and list or nil
end

---Attempts to retrieve the camera ID associated with a given vehicle.
---@param vehicle Vehicle? # The vehicle from which to extract the camera ID.
---@return string? # The extracted camera ID (e.g., "4w_911") or nil if not found.
local function getVehicleCameraID(vehicle)
	local keys = getVehicleCameraKeys(vehicle)
	if not isTable(keys) then return nil end ---@cast keys string[]

	for _, v in pairs(keys) do
		local match, _ = v:match("^[%a]+%.VehicleTPP_([%w_]+)_[%w_]+_[%w_]+")
		if match then
			return match
		end
	end

	return nil
end

---Extracts a custom camera ID and associated level names.
---@param vehicle Vehicle # The vehicle to analyze.
---@return string? customID # The extracted prefix representing the custom camera ID, or nil if not found.
---@return string[]? levels # A list of level suffixes (e.g., "High_Close", "Low_Far") associated with the custom ID.
local function getCustomCameraRecordKeyData(vehicle)
	local keys = getVehicleCameraKeys(vehicle) ---@cast keys string[]
	if not isTableNotEmpty(keys) then return nil, nil end

	local vanillaID = getVehicleCameraID(vehicle)
	if not vanillaID then return nil, nil end

	local customID
	local levels = {}
	for _, s in ipairs(keys) do
		if contains(s, vanillaID) then goto continue end

		local parts = split(s, "_")
		if #parts < 3 then goto continue end

		local prefix = table.concat(parts, "_", 1, #parts - 2)
		local suffix = table.concat(parts, "_", #parts - 1)

		if not customID then
			customID = prefix
		end
		insert(levels, suffix)

		::continue::
	end

	if customID then
		return customID, levels
	end

	return nil, nil
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

	local result, _ = str:gsub("^Vehicle%.", "")
	return result
end

---Attempts to retrieve the appearance name of the specified vehicle.
---@param vehicle Vehicle? # The vehicle object to retrieve the appearance name from.
---@return string? # The resolved vehicle name as a string, or `nil` if it could not be determined.
local function getVehicleAppearanceName(vehicle)
	if not vehicle then return nil end

	local name = vehicle:GetCurrentAppearanceName()
	if not name then return nil end

	return Game.NameToString(name)
end

--#endregion

--#region ⚖️ Preset Management

---Checks whether a preset with the given key exists and matches the specified camera ID.
---Returns true only if the preset is present in `camera_presets` and its `ID` matches `id`.
---@param key string # The key under which the preset is stored in the `camera_presets` table.
---@param id string # The camera ID of the mounted vehicle.
---@return boolean # True if the preset exists and has a matching ID, false otherwise.
local function presetExists(key, id)
	local preset = deep(camera_presets, key)
	return preset.ID == id
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
	if #name < 1 then
		if dev_mode >= DevLevels.ALERT then
			log(LogLevels.WARN, 1086, Text.LOG_BLANK_NAME)
		end
		return currentKey
	end

	if startsWith(vehicleName, name) or
		startsWith(appearanceName, name) then
		return name
	end

	if dev_mode >= DevLevels.ALERT then
		if vehicleName ~= appearanceName then
			log(LogLevels.WARN, 1086, Text.LOG_NAMES_MISM, vehicleName, appearanceName)
		else
			log(LogLevels.WARN, 1086, Text.LOG_NAME_MISM, vehicleName)
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
		local vec3 = getCameraLookAtOffset(preset, path)
		if not vec3 or (not vec3.x and not vec3.y and not vec3.z) then goto continue end

		local level = PresetLevels[(i - 1) % 3 + 1]
		local angle = getCameraDefaultRotationPitch(preset, path)

		preset[level] = {
			a = tonumber(angle),
			x = tonumber(vec3.x),
			y = tonumber(vec3.y),
			z = tonumber(vec3.z)
		}

		if preset.Far and preset.Medium and preset.Close then
			if dev_mode >= DevLevels.FULL then
				log(LogLevels.INFO, 1118, Text.LOG_CAM_OSET_DONE, id)
			end
			return preset
		end

		::continue::
	end

	log(LogLevels.ERROR, 1118, Text.LOG_NO_CAM_OSET, id)
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
				log(LogLevels.INFO, 1153, Text.LOG_FOUND_DEF, id)
			end
			return item
		end
	end

	log(LogLevels.ERROR, 1153, Text.LOG_MISS_DEF, id)

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
		logF(DevLevels.FULL, LogLevels.ERROR, 1186, Text.LOG_NO_PSET_FOR_LVL, level)
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
---@param id string? # The camera ID of the mounted vehicle.
---@param count number? # Internal recursion counter to prevent infinite loops via `Link`. Do not set manually.
local function applyPreset(preset, id, count)
	if not preset and not count then
		local vehicle = getMountedVehicle()
		if not vehicle then return end

		local name = getVehicleName(vehicle)
		if not name then return end

		local appName = getVehicleAppearanceName(vehicle)
		if not appName then return end

		local key = name == appName and findPresetKey(name) or findPresetKey(name, appName)
		if not key then return end

		local cid = getVehicleCameraID(vehicle)
		if not cid then return end

		if dev_mode >= DevLevels.ALERT then
			log(LogLevels.INFO, 1213, Text.LOG_CAM_PSET, key)
		end

		local pre = camera_presets[key]
		if isTableNotEmpty(pre) then
			if isTable(pre.Overrides) then
				resetCustomCameraParams(vehicle)
			end
			applyPreset(camera_presets[key], cid, 0)
		end

		return
	end

	if preset and preset.Link then
		count = (count or 0) + 1
		if dev_mode >= DevLevels.FULL then
			log(LogLevels.INFO, 1213, Text.LOG_LINK_PSET, count, preset.Link)
		end
		preset = camera_presets[preset.Link]
		if preset and preset.Link and count < 8 then
			applyPreset(preset, id, count)
			return
		end
	end

	if not preset or not isString(preset.ID) then
		logF(DevLevels.BASIC, LogLevels.ERROR, 1213, Text.LOG_FAIL_APPLY)
		return
	end

	if isString(id) and id ~= preset.ID then
		if dev_mode >= DevLevels.ALERT then
			log(LogLevels.WARN, 1213, Text.LOG_CAMID_MISM, preset.ID, id)
		end
		return
	end

	local levelMap = { CameraLevels }
	local overrides = preset.Overrides ---@cast overrides ICameraAccessOverrides
	local hasOverrides = isTableNotEmpty(overrides)
	if hasOverrides and overrides.Levels then
		insert(levelMap, overrides.Levels)
	end

	local fallback = getDefaultPreset(preset) or {}
	for _, levels in ipairs(levelMap) do
		if not isTable(levels) then goto continue end

		for i, path in ipairs(levels) do
			local level = PresetLevels[(i - 1) % 3 + 1]
			local a, x, y, z = getOffsetData(preset, fallback, level)

			setCameraLookAtOffset(preset, path, x, y, z)
			setCameraDefaultRotationPitch(preset, path, a)
		end

		::continue::

		if hasOverrides then
			overrides.Due = true
		end
	end

	if hasOverrides and overrides.Due then
		overrides.Due = nil
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

	log(LogLevels.INFO, 1303, Text.LOG_REST_ALL)
end

---Restores modified camera offset presets to their default values.
local function restoreModifiedPresets()
	local changed = used_presets
	if not next(changed) then return end

	local amount = #changed
	local restored = 0
	for _, preset in pairs(camera_presets) do
		if preset.IsDefault and contains(changed, preset.ID) then
			applyPreset(preset)
			restored = restored + 1
			log(LogLevels.INFO, 1315, Text.LOG_REST_PSET, preset.ID)
		end
		if restored >= amount then break end
	end
	used_presets = {}

	log(LogLevels.INFO, 1315, Text.LOG_REST_PSETS, restored, amount)
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

--#endregion

--#region 💾 Preset File Control

---Generates the full file path to a preset file, optionally pointing to the default directory.
---Automatically appends the `.lua` extension if not already present.
---@param name string # The base name of the preset file (with or without `.lua` extension).
---@param isDefault boolean? # If true, returns the path in the `defaults` directory; otherwise in `presets`.
---@return string? # The full file path to the preset, or `nil` if the name is invalid.
local function getPresetFilePath(name, isDefault)
	if not isString(name) then return nil end
	return (isDefault and "defaults/" or "presets/") .. ensureLuaExt(name)
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

---Removes camera presets from the global `camera_presets` table.
---If no key is provided, clears all presets
---If a key is provided, removes only entries whose keys start with the given prefix.
---@param key string? # Optional key prefix used to filter which presets to remove.
local function purgePresets(key)
	if not isString(key) then
		camera_presets = {}
		log(LogLevels.WARN, 1419, Text.LOG_CLEAR_PSETS)
		return
	end

	---@cast key string
	local c = 0
	for k, _ in pairs(camera_presets) do
		if startsWith(k, key) then
			camera_presets[k] = nil
			c = c + 1
		end
	end

	log(LogLevels.WARN, 1419, Text.LOG_CLEAR_NPSETS, c, key)
end

---Loads camera offset presets from `defaults` (first) and `presets` (second).
---Each `.lua` file must return a `ICameraPreset` table with at least an `ID` field.
---Skips already loaded presets unless `refresh` is true (then clears and reloads all).
---@param refresh boolean? — If true, clears existing presets before loading (default: false).
local function loadPresets(refresh)
	local function loadFrom(path)
		local files = dir(path)
		if not files then
			logF(DevLevels.FULL, LogLevels.ERROR, 1442, Text.LOG_DIR_NOT_EXIST, path)
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
				logF(DevLevels.BASIC, LogLevels.WARN, 1442, Text.LOG_SKIP_PSET, key, path, name)
				goto continue
			end

			local chunk, err = loadfile(path .. "/" .. name)
			if not chunk then
				logF(DevLevels.BASIC, LogLevels.ERROR, 1442, Text.LOG_FAIL_LOAD, path, name, err)
				goto continue
			end

			local ok, result = pcall(chunk)
			if not ok or (isDef and not result.IsDefault) or not setPresetEntry(key, result) then
				logF(DevLevels.BASIC, LogLevels.ERROR, 1442, Text.LOG_BAD_PSET, path, name)
				goto continue
			end

			count = count + 1
			if dev_mode >= DevLevels.FULL then
				log(LogLevels.INFO, 1442, Text.LOG_LOAD_PSET, key, path, name)
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
		logF(DevLevels.FULL, LogLevels.ERROR, 1442, Text.LOG_DEFS_INCOMP)
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
			log(LogLevels.WARN, 1506, Text.LOG_FILE_EXIST, path)
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
		log(LogLevels.WARN, 1506, Text.LOG_PSET_NOT_CHANGED, name, default.ID)

		if not saveAsDefault then
			local ok, err = os.remove(path)
			if ok then
				logF(DevLevels.ALERT, LogLevels.WARN, 1506, Text.LOG_DEL_SUCCESS, path)
			else
				logF(DevLevels.FULL, LogLevels.ERROR, 1506, Text.LOG_DEL_FAILURE, path, err)
			end
			return ok and setPresetEntry(name)
		end

		return false
	end

	if saveAsDefault then
		insert(parts, "IsDefault=true")
	else
		local overrides = get(preset, nil, "Overrides")
		if isTable(overrides) then
			local serialized = serialize(overrides)
			insert(parts, format("Overrides=%s", serialized))
		end
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

	logF(DevLevels.ALERT, LogLevels.INFO, 1506, Text.LOG_PSET_SAVED, name)

	return true
end

--#endregion

--#region 🧪 Preset Editor

---Generates a checksum token for a camera preset by combining its ID and offset tables.
---@param preset ICameraPreset? # The camera preset containing fields `ID`, `Close`, `Medium`, and `Far`.
---@return integer # Adler‑32 checksum of `preset.ID`, `preset.Close`, `preset.Medium`, `preset.Far`, or -1 if invalid.
local function getEditorPresetToken(preset)
	if not isTable(preset) then return -1 end ---@cast preset ICameraPreset
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
---If the entries already exist in `editor_bundles`, it simply returns them.
---@param name string # Vehicle name (e.g. "v_sport2_porsche_911turbo_player").
---@param appName string # Appearance name (e.g. "porsche_911turbo__basic_johnny").
---@param id string # Camera‑preset ID for TweakDB lookup.
---@param key string # Preset key/alias used for storage and display.
---@return IEditorPreset? Flux # Live preset entry reflecting current UI edits.
---@return IEditorPreset? Pivot # Snapshot of Flux at the last apply action.
---@return IEditorPreset? Finale # Snapshot of Flux at the last save action.
---@return IEditorPreset? Nexus # Immutable default preset entry.
---@return IEditorTasks? Tasks # Pending action flags (Rename, Validate, Apply, Save, Restore).
local function getEditorBundleUnpacked(vehicle, name, appName, id, key)
	local bundle = deep(editor_bundles, format("%s*%s", name, appName)) ---@cast bundle IEditorBundle

	if not isTable(bundle.Flux, bundle.Pivot, bundle.Finale, bundle.Nexus, bundle.Tasks) then
		local flux = getPreset(id)
		if not flux then
			log(LogLevels.WARN, 1633, Text.LOG_NO_PSET_FOUND, id)
			return
		end

		local legitID, levels = getCustomCameraRecordKeyData(vehicle)
		if isString(legitID) and isTable(levels) then
			flux.Overrides = {
				Key = legitID,
				Levels = levels
			}
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

	return bundle.Flux, bundle.Pivot, bundle.Finale, bundle.Nexus, bundle.Tasks
end

---Replaces an existing editor preset entry with values from another and updating its checksum.
---@param src IEditorPreset # The source preset entry whose data will be copied.
---@param dest IEditorPreset # The preset entry to overwrite (modified in place).
---@param verify boolean? # If true, recomputes `IsPresent` by checking the file system for `src.Key`.
local function replaceEditorPreset(src, dest, verify)
	if not isTable(src, dest) then return end

	local preset = clone(src.Preset)
	dest.Preset = preset
	dest.Key = src.Key
	dest.Name = src.Name
	dest.Token = getEditorPresetToken(preset)
	dest.IsPresent = verify and presetFileExists(src.Key) or false
end

---Applies the current UI-edited camera preset to the internal preset registry.
---Updates the pivot state, clears the old entry, and assigns any preserved overrides.
---@param key string # The key under which the current preset will be stored.
---@param flux IEditorPreset # The edited preset containing user modifications.
---@param pivot IEditorPreset # The previously applied preset; will be overwritten with `flux`.
---@param tasks IEditorTasks # Tracks pending editor actions; `Apply` will be cleared here.
local function applyEditorPreset(key, flux, pivot, tasks)
	if not isString(key) or not isTable(flux, pivot, tasks) then return end

	tasks.Apply = false

	camera_presets[pivot.Key] = nil
	if not tasks.Restore then
		camera_presets[key] = flux.Preset
	end

	replaceEditorPreset(flux, pivot)

	logF(DevLevels.ALERT, LogLevels.INFO, 1691, Text.LOG_PSET_UPD, key)
end

---Saves the current camera preset to disk and updates the saved (finale) state.
---Performs overwrite, cleanup of old files on rename, and syncs the checksum.
---@param key string # The key used as filename for saving the preset (without `.lua` extension).
---@param flux IEditorPreset # The currently edited preset with unsaved modifications.
---@param finale IEditorPreset # The last saved version of the preset; will be updated to match `flux`.
---@param tasks IEditorTasks # Tracks pending editor actions; will reset `Save`, `Restore`, and optionally `Rename`.
local function saveEditorPreset(key, flux, finale, tasks)
	if not isString(key) or not isTable(flux, finale, tasks) then return end

	if not savePreset(key, flux.Preset, true) then
		logF(DevLevels.ALERT, LogLevels.WARN, 1712, Text.LOG_PSET_NOT_SAVED, key)
		return
	end

	tasks.Restore = false
	tasks.Save = false

	if tasks.Rename then
		tasks.Rename = false

		local path = getPresetFilePath(finale.Name) ---@cast path string
		local ok, err = os.remove(path)
		if not ok then
			logF(DevLevels.FULL, LogLevels.ERROR, 1729, Text.LOG_MOVE_FAILURE, finale.Name, flux.Name, err)
		end

		camera_presets[finale.Key] = nil
	end

	replaceEditorPreset(flux, finale, true)
end

--#endregion

--#region 🎨 UI Layout Helpers

---Calculates UI layout metrics based on the current content region and font size.
---Uses a baseline font height of 18px to derive a scale factor.
---If `padding_locked` is true and `padding_width` is already set, returns the locked value.
---@return number width # Available width of the content region in pixels.
---@return number half # Half of `width` minus half the item spacing.
---@return number scale # UI scale factor (fontSize / 18).
---@return number padding # Computed horizontal padding (pixels), at least 10 * scale when unlocked.
local function getMetrics()
	local w  = ImGui.GetContentRegionAvail()

	local st = ImGui.GetStyle()
	local sp = st.ItemSpacing.x
	local hf = ceil(w * 0.5 - (sp * 0.5))

	local h  = ImGui.GetFontSize()
	local s  = h / 18

	if padding_locked and isNumber(padding_width) then
		return w, hf, s, padding_width
	end

	local bw = 230 * s
	local bo = 18 * s
	local rp = (w - bw) * 0.5 + bo - sp
	padding_width = ceil(max(10 * s, rp))

	return w, hf, s, padding_width
end
---Vertically aligns the next drawn item (typically text) within a cell of known height.
---Calculates offset using the current font height to position the item relative to the vertical center.
---@param cellHeight number # The height of the cell to align within.
local function alignVertNext(cellHeight)
	local h = ImGui.GetFontSize()
	local cy = ImGui.GetCursorPosY()
	local oy = (cellHeight - h) * 0.5
	ImGui.SetCursorPosY(cy + oy)
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

	--Currently always 3; may become dynamic someday.
	return 3
end

---Safely pops a number of ImGui style colors from the stack.
---Calls `ImGui.PopStyleColor(num)` only if `num` is a positive integer.
---@param num integer # The number of style colors to pop from the ImGui stack.
local function popColors(num)
	if num <= 0 then return end
	ImGui.PopStyleColor(num)
end

---Adds centered text with custom word wrapping.
---@param text string # The text to display.
---@param wrap number # The maximum width before wrapping.
local function addTextCenterWrap(text, wrap)
	local ln, ww = "", ImGui.GetWindowSize()
	for w in text:gmatch("%S+") do
		local test = (ln == "") and w or (ln .. " " .. w)
		if ImGui.CalcTextSize(test) > wrap and ln ~= "" then
			ImGui.SetCursorPosX((ww - ImGui.CalcTextSize(ln)) * 0.5)
			ImGui.Text(ln)
			ln = w
		else
			ln = test
		end
	end
	if ln ~= "" then
		ImGui.SetCursorPosX((ww - ImGui.CalcTextSize(ln)) * 0.5)
		ImGui.Text(ln)
	end
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
	if item == nil then return end
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
local function addPopupYesNo(id, text, scale, yesBtnColor, noBtnColor)
	if not id or not ImGui.BeginPopup(id) then return nil end

	local result = nil

	ImGui.Text(text)
	ImGui.Dummy(0, 2)
	ImGui.Separator()
	ImGui.Dummy(0, 2)

	local width = ceil(80 * scale)
	local height = floor(30 * scale)

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

--#endregion

--#region 🎬 Runtime Behavior

--This event is triggered when the CET environment initializes for a particular game session.
registerForEvent("onInit", function()
	--CET version check.
	runtime_min = isRuntimeVersionAtLeast("1.35")
	runtime_full = isRuntimeVersionAtLeast("1.35.1")

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
	--Notification system (requires at least CET 1.35.1).
	if runtime_full and toaster_active and next(toaster_bumps) then
		for k, v in pairs(toaster_bumps) do
			local toast = ImGui.Toast.new(k, v)
			ImGui.ShowToast(toast)
		end
		toaster_bumps = {}
	end

	--Stop when CET overlay is hidden.
	if not overlay_open then return end

	--Main window begins.
	if not ImGui.Begin(Text.GUI_TITL, ImGuiWindowFlags.AlwaysAutoResize) then return end

	--Computes scaled layout values (content width, control sizes, and paddings) based on the UI scale factor.
	local contentWidth, halfContentWidth, scale, controlPadding = getMetrics()
	local baseContentWidth = floor(230 * scale)
	local buttonHeight = floor(24 * scale)
	local rowHeight = floor(28 * scale)
	local heightPadding = floor(4 * scale)
	local halfHeightPadding = floor(2 * scale)
	local doubleHeightPadding = floor(8 * scale)

	--Minimum window width and height padding.
	ImGui.Dummy(baseContentWidth, heightPadding)

	--Warning for outdated CET version.
	if not runtime_min and dev_mode <= DevLevels.DISABLED then
		ImGui.Dummy(0, 0)
		ImGui.SameLine()
		ImGui.PushStyleColor(ImGuiCol.Text, adjustColor(Colors.GARNET, 0xff))
		addTextCenterWrap(format(Text.GUI_OLD_CET, GetVersion():gsub("^v", "")), contentWidth)
		ImGui.PopStyleColor()
		ImGui.Dummy(0, doubleHeightPadding)
	end

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
			logF(DevLevels.ALERT, LogLevels.INFO, 1988, Text.LOG_MOD_ON)
		else
			editor_bundles = {}
			restoreCustomCameraParams()
			restoreAllPresets()
			purgePresets()
			dev_mode = DevLevels.DISABLED
			logF(DevLevels.ALERT, LogLevels.INFO, 1988, Text.LOG_MOD_OFF)
		end
	end
	ImGui.Dummy(0, halfHeightPadding)
	if not mod_enabled then
		--Mod is disabled — nothing left to add.
		ImGui.End()
		return
	end

	--The button that reloads all presets.
	local rldBtnWidth = floor(192 * scale)
	ImGui.Dummy(controlPadding, 0)
	ImGui.SameLine()
	if ImGui.Button(Text.GUI_RLD_ALL, rldBtnWidth, buttonHeight) then
		editor_bundles = {}
		loadPresets(true)
		restoreAllPresets()
		applyPreset()
		logF(DevLevels.ALERT, LogLevels.INFO, 1988, Text.LOG_PSETS_RLD)
	end
	addTooltip(Text.GUI_RLD_ALL_TIP)
	ImGui.Dummy(0, halfHeightPadding)

	--Slider to set the developer mode level.
	local sliderWidth = floor(77 * scale)
	ImGui.Dummy(controlPadding, 0)
	ImGui.SameLine()
	ImGui.PushItemWidth(sliderWidth)
	dev_mode = ImGui.SliderInt(Text.GUI_DMODE, dev_mode, DevLevels.DISABLED, DevLevels.FULL)
	padding_locked = ImGui.IsItemActive()
	addTooltip(Text.GUI_DMODE_TIP)
	ImGui.PopItemWidth()
	ImGui.Dummy(0, doubleHeightPadding)

	--Table showing vehicle name, camera ID and more — if certain conditions are met.
	local vehicle, name, appName, id, key
	local steps = {
		function()
			return dev_mode > DevLevels.DISABLED and vehicle_mounted
		end,
		function()
			vehicle = getMountedVehicle()
			if not vehicle then
				log(LogLevels.WARN, 1988, Text.LOG_NO_VEH)
			end
			return vehicle
		end,
		function()
			name = getVehicleName(vehicle)
			if not name then
				log(LogLevels.ERROR, 1988, Text.LOG_NO_NAME)
			end
			return name
		end,
		function()
			appName = getVehicleAppearanceName(vehicle)
			if not appName then
				log(LogLevels.ERROR, 1988, Text.LOG_NO_APP)
			end
			return appName
		end,
		function()
			id = getVehicleCameraID(vehicle)
			if not id then
				log(LogLevels.ERROR, 1988, Text.LOG_NO_ID)
			end
			return id
		end,
		function()
			key = name ~= appName and findPresetKey(name, appName) or findPresetKey(name) or name
			if not key then
				log(LogLevels.ERROR, 1988, Text.LOG_NO_ID)
			end
			return key
		end
	}
	local failed = false
	for _, fn in ipairs(steps) do
		if not fn() then
			failed = true
			break
		end
	end
	if failed then
		if dev_mode > DevLevels.DISABLED and not vehicle then
			ImGui.Dummy(controlPadding, 0)
			ImGui.SameLine()
			ImGui.PushStyleColor(ImGuiCol.Text, adjustColor(Colors.CARAMEL, 0xff))
			ImGui.Text(Text.GUI_NO_VEH)
			ImGui.PopStyleColor()
		end
		ImGui.End()
		return
	end

	local flux, pivot, finale, nexus, tasks = getEditorBundleUnpacked(vehicle, name, appName, id, key)
	---@cast flux IEditorPreset
	---@cast pivot IEditorPreset
	---@cast finale IEditorPreset
	---@cast nexus IEditorPreset
	---@cast tasks IEditorTasks
	if not isTable(flux, pivot, finale, nexus, tasks) then
		--GUI closed — no further controls required.
		ImGui.End()
	end

	if ImGui.BeginTable("PresetInfo", 2, ImGuiTableFlags.Borders) then
		ImGui.TableSetupColumn("\u{f11be}", ImGuiTableColumnFlags.WidthFixed, -1)
		ImGui.TableSetupColumn("\u{f09a8}", ImGuiTableColumnFlags.WidthStretch)
		ImGui.TableHeadersRow()

		local overrides = get(flux, {}, "Preset", "Overrides")

		local rows = {
			{ label = "\u{f010b}", tip = Text.GUI_TBL_LABL_VEH_TIP,   value = name },
			{ label = "\u{f07ac}", tip = Text.GUI_TBL_LABL_APP_TIP,   value = appName },
			{ label = "\u{f0567}", tip = Text.GUI_TBL_LABL_CAMID_TIP, value = id },
			{
				label  = "\u{f0569}",
				tip    = Text.GUI_TBL_LABL_CCAMKEY_TIP,
				value  = overrides.Key,
				valTip = (isTable(overrides.Levels) and next(overrides.Levels)) and
					format(Text.GUI_TBL_VAL_CCAMKEY_TIP, concat(overrides.Levels, "\n")) or nil
			},
			{
				label    = "\u{f1952}",
				tip      = Text.GUI_TBL_LABL_PSET_TIP,
				value    = (flux.Name ~= key or presetExists(key, id)) and flux.Name or id,
				valTip   = Text.GUI_TBL_VAL_PSET_TIP,
				editable = true
			}
		}

		local maxInputWidth = floor((contentWidth - 38) * scale)
		for _, row in ipairs(rows) do
			if not isString(row.label, row.value) then goto continue end

			ImGui.TableNextRow(0, rowHeight)
			ImGui.TableSetColumnIndex(0)

			alignVertNext(rowHeight)
			ImGui.Text(row.label)
			addTooltip(row.tip)

			ImGui.TableSetColumnIndex(1)

			if row.override then
				ImGui.PushItemWidth(maxInputWidth)
				local pushd = pushColors(ImGuiCol.FrameBg, Colors.MULBERRY)

				local newVal, changed = ImGui.InputText("##Override" .. row.label, row.value, 256)
				if changed and newVal then
					if row.isArray then
						overrides.Levels = split(newVal, ",", true)
					else
						overrides.Key = trimLuaExt(newVal)
					end
				end

				popColors(pushd)
				ImGui.PopItemWidth()

				addTooltip(row.valTip)
			elseif row.editable then
				local namWidth, _ = ImGui.CalcTextSize(name)
				local appWidth, _ = ImGui.CalcTextSize(appName)
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

				local maxLen = max(#name, #appName)
				local newVal, changed = ImGui.InputText("##FileName", row.value, maxLen)
				if changed and newVal then
					local trimVal = trimLuaExt(newVal)
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

				addTooltip(format(
					row.valTip,
					color == Colors.CARAMEL and flux.Name or key,
					name,
					appName,
					chopUnderscoreParts(name),
					chopUnderscoreParts(appName)
				))
			else
				alignVertNext(rowHeight)
				ImGui.Text(tostring(row.value or Text.GUI_NONE))
				addTooltip(row.valTip)
			end

			::continue::
		end

		ImGui.EndTable()
	end

	if tasks.Rename then
		tasks.Rename = finale.IsPresent and flux.Name ~= finale.Name
		flux.Key = flux.Name
	end

	--Camera preset editor allowing adjustments to Angle, X, Y, and Z coordinates — if certain conditions are met.
	if ImGui.BeginTable("PresetEditor", 5, ImGuiTableFlags.Borders) then
		local headers = {
			"\u{f066a}",
			"\u{f10f3}\u{f0aee}", --Angles
			"\u{f0d4c}\u{f0b05}", --X-axis
			"\u{f0d51}\u{f0b06}", --Y-axis
			"\u{f0d55}\u{f0b07}" --Z-axis
		}

		for i, header in ipairs(headers) do
			local flag = i < 3 and ImGuiTableColumnFlags.WidthFixed or ImGuiTableColumnFlags.WidthStretch
			local head = header
			if i > 2 and #head < 16 then
				local pad = 16 - #head
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
			Text.GUI_TBL_VAL_Z_TIP
		}

		for i, row in ipairs(rows) do
			local level = PresetLevels[i]

			ImGui.TableNextRow(0, rowHeight)
			ImGui.TableSetColumnIndex(0)

			alignVertNext(rowHeight)
			ImGui.Text(row.label)
			addTooltip(row.tip)

			for j, field in ipairs(PresetOffsets) do
				local defVal = get(nexus.Preset, 0, level, field)
				local curVal = get(flux.Preset, defVal, level, field)
				local speed = pick(j, 1, 5e-2)
				local minVal = pick(j, -45, -5, -10, 0)
				local maxVal = pick(j, 90, 5, 10, 32)
				local fmt = pick(j, "%.0f", "%.3f")

				ImGui.TableSetColumnIndex(j)
				ImGui.PushItemWidth(-1)

				local pushd = not equals(curVal, defVal) and pushColors(ImGuiCol.FrameBg, Colors.FIR) or 0
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
					addTooltip(split(format(tip, defVal, minVal, maxVal, origVal), "|"))
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
	addTooltip(Text.GUI_APPLY_TIP)
	ImGui.SameLine()

	--Button in same line to save configured values to a file for future automatic use.
	local saveConfirmed = false
	pushed = (tasks.Save or tasks.Rename) and pushColors(ImGuiCol.Button, color) or 0
	if ImGui.Button(Text.GUI_SAVE, halfContentWidth, buttonHeight) then
		if presetFileExists(finale.Name) then
			overwrite_confirm = true
			ImGui.OpenPopup(key)
		else
			saveConfirmed = true
		end
	end
	popColors(pushed)
	addTooltip(format(tasks.Restore and Text.GUI_REST_TIP or Text.GUI_SAVE_TIP, key))

	if overwrite_confirm then
		local confirmed = addPopupYesNo(key, format(Text.GUI_OVWR_CONFIRM, key), scale, Colors.CARAMEL)
		if confirmed ~= nil then
			overwrite_confirm = false
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
		saveEditorPreset(key, flux, finale, tasks)
	end

	ImGui.Dummy(0, heightPadding)

	--Button to open Preset File Manager.
	local x, y, w, h
	ImGui.Separator()
	ImGui.Dummy(0, heightPadding)
	if ImGui.Button(Text.GUI_OPEN_FMAN, contentWidth, buttonHeight) then
		x, y = ImGui.GetWindowPos()
		w, h = ImGui.GetWindowSize()
		file_man_open = not file_man_open
	end
	ImGui.Dummy(0, halfHeightPadding)

	--GUI creation of Main window is complete.
	ImGui.End()

	--Preset File Manager window.
	if not file_man_open then return end

	local files = dir("presets")
	if not files then
		file_man_open = false
		logF(DevLevels.FULL, LogLevels.ERROR, 1988, Text.LOG_DIR_NOT_EXIST, "presets")
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
		ImGui.TableSetupColumn(" \u{f09a8}", ImGuiTableColumnFlags.WidthStretch)
		ImGui.TableSetupColumn(" \u{f05e9}", ImGuiTableColumnFlags.WidthFixed)
		ImGui.TableHeadersRow()

		for _, f in ipairs(files) do
			local file = f.name
			if not hasLuaExt(file) then goto continue end

			local k = trimLuaExt(file)
			if not contains(camera_presets, trimLuaExt(file)) then goto continue end

			anyFiles = true

			ImGui.TableNextRow()
			ImGui.TableSetColumnIndex(0)

			alignVertNext(buttonHeight)
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
			if ImGui.Button("\u{f05e8}##" .. file, 0, buttonHeight) then
				ImGui.OpenPopup(file)
			end

			if addPopupYesNo(file, format(Text.GUI_FMAN_DEL_CONFIRM, file), scale, Colors.GARNET) then
				local path = getPresetFilePath(file) ---@cast path string
				local ok, err = os.remove(path)
				if ok then
					for n, _ in pairs(editor_bundles) do
						local parts = split(n, "*")
						if #parts < 2 then goto continue end

						local vName, aName = parts[1], parts[2]
						if startsWith(vName, k) or startsWith(aName, k) then
							editor_bundles[n] = nil
						end

						::continue::
					end
					setPresetEntry(k)
					logF(DevLevels.ALERT, LogLevels.INFO, 1988, Text.LOG_DEL_SUCCESS, file)
				else
					logF(DevLevels.FULL, LogLevels.WARN, 1988, Text.LOG_DEL_FAILURE, file, err)
				end
			end

			::continue::
		end

		ImGui.EndTable()
	end

	if not anyFiles then
		local hPad = ceil(180 * scale)
		local wPad = floor(controlPadding - 4 * scale)
		ImGui.Dummy(0, hPad)
		ImGui.Dummy(wPad, 0)
		ImGui.SameLine()
		ImGui.PushStyleColor(ImGuiCol.Text, adjustColor(Colors.GARNET, 0xff))
		ImGui.Text(Text.GUI_FMAN_NO_PSETS)
		ImGui.PopStyleColor()
	end

	--GUI creation of Preset File Manager window is complete.
	ImGui.End()
end)

--Restores default camera offsets for vehicles upon mod shutdown.
registerForEvent("onShutdown", function()
	restoreCustomCameraParams()
	restoreAllPresets()
end)

--#endregion
