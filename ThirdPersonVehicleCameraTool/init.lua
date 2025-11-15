--[[
==============================================
This file is distributed under the MIT License
==============================================

Third-Person Vehicle Camera Tool

Allows you to adjust third-person perspective
(TPP) camera offsets for any vehicle.

Filename: init.lua
Version: 2025-04-03, 17:43 UTC+01:00 (MEZ)

Copyright (c) 2025, Si13n7 Developments(tm)
All rights reserved.
______________________________________________
--]]



--[[====================================================
		STANDARD DEFINITIONS FOR INTELLISENSE
=======================================================]]


---`ImGui` Definition
---@class ImGui
---Provides functions to create graphical user interface elements within the Cyber Engine Tweaks overlay.
---@field Begin fun(title: string, flags?: number): boolean # Begins a new ImGui window with optional flags. Must be closed with `ImGui.End()`. Returns `true` if the window is open and should be rendered.
---@field End fun(): nil # Ends the creation of the current ImGui window. Must always be called after `ImGui.Begin()`.
---@field Dummy fun(width: number, height: number): nil # Creates an invisible element of specified width and height, useful for spacing.
---@field SameLine fun(offsetX?: number, spacing?: number): nil # Places the next UI element on the same line. Optionally adds horizontal offset and spacing.
---@field PushItemWidth fun(width: number): nil # Sets the width of the next UI element (e.g., slider, text input).
---@field PopItemWidth fun(): nil # Resets the width of the next UI element to the default value.
---@field Text fun(text: string): nil # Displays text within the current window or tooltip.
---@field Button fun(label: string, width?: number, height?: number): boolean # Creates a clickable button with optional width and height. Returns true if the button was clicked.
---@field Checkbox fun(label: string, value: boolean): (boolean, boolean) # Creates a toggleable checkbox. Returns `changed` (true if state has changed) and `value` (the new state).
---@field SliderInt fun(label: string, value: number, min: number, max: number): number # Creates an integer slider. Returns the new `value`.
---@field SliderFloat fun(label: string, value: number, min: number, max: number): number # Creates a float slider that allows users to select a value between a specified minimum and maximum. Returns the updated float value.
---@field IsItemHovered fun(): boolean # Returns true if the last item is hovered by the mouse cursor.
---@field BeginTooltip fun(): nil # Begins creating a tooltip. Must be paired with `ImGui.EndTooltip()`.
---@field EndTooltip fun(): nil # Ends the creation of a tooltip. Must be called after `ImGui.BeginTooltip()`.
---@field BeginTable fun(id: string, columns: number, flags?: number): boolean # Begins a table with the specified number of columns. Returns `true` if the table is created successfully and should be rendered.
---@field TableSetupColumn fun(label: string, flags?: number, init_width_or_weight?: number): nil # Defines a column in the current table with optional flags and initial width or weight.
---@field TableHeadersRow fun(): nil # Automatically creates a header row using column labels defined by `TableSetupColumn()`. Must be called right after defining the columns.
---@field TableNextRow fun(): nil # Advances to the next row of the table. Must be called between rows.
---@field TableSetColumnIndex fun(index: number): nil # Moves the focus to a specific column index within the current table row.
---@field EndTable fun(): nil # Ends the creation of the current table. Must always be called after `ImGui.BeginTable()`.
---@field GetWindowSize fun(): number # Returns the current width of the window as a floating-point number.
---@field CalcTextSize fun(text: string): number # Calculates the width of a given text string as it would be displayed using the current font. Returns the width in pixels as a floating-point number.
ImGui = ImGui

---`ImGuiWindowFlags` Definition
---@class ImGuiWindowFlags
---@field AlwaysAutoResize number # Automatically resizes the window to fit its content each frame.
ImGuiWindowFlags = ImGuiWindowFlags

---`ImGuiTableFlags` Definition
---@class ImGuiTableFlags
---Flags to customize table behavior and appearance.
---@field Borders number # Draws borders between cells.
ImGuiTableFlags = ImGuiTableFlags

---`ImGuiTableColumnFlags` Definition
---@class ImGuiTableColumnFlags
---Flags to customize individual columns within a table.
---@field WidthFixed number # Makes the column have a fixed width.
---@field WidthStretch number # Makes the column stretch to fill available space.
ImGuiTableColumnFlags = ImGuiTableColumnFlags

---`TweakDB` Definition
---@class TweakDB
---Provides access to game data stored in the database, including camera offsets and various other game settings.
---@field GetFlat fun(self: TweakDB, key: string): any|nil # Retrieves a value from the database based on the provided key.
---@field SetFlat fun(self: TweakDB, key: string, value: any) # Sets or modifies a value in the database for the specified key.
TweakDB = TweakDB

---`Game` Definition
---@class Game
---Provides various global game functions, such as getting the player, mounted vehicles, and converting names to strings.
---@field NameToString fun(value: any): string # Converts a game name object to a readable string.
---@field GetPlayer fun(): Player|nil # Retrieves the current player instance if available.
---@field GetMountedVehicle fun(player: Player): Vehicle|nil # Returns the vehicle the player is currently mounted in, if any.
Game = Game

---`Player` Definition
---@class Player # Represents the player character in the game, providing functions to interact with the player instance.
---@field SetWarningMessage fun(self: Player, message: string, duration: number): nil # Displays a warning message on the player's screen for a specified duration.
Player = Player

---`Vehicle` Definition
---@class Vehicle
---Represents a vehicle entity within the game, providing functions to interact with it, such as getting the appearance name.
---@field GetCurrentAppearanceName fun(self: Vehicle): string|nil # Retrieves the current appearance name of the vehicle.
---@field GetRecordID fun(self: Vehicle): any # Returns the unique TweakDBID associated with the vehicle.
Vehicle = Vehicle

---`Vector3` Definition
---@class Vector3
---Represents a three-dimensional vector, commonly used for positions or directions in the game.
---@field x number # The X-coordinate.
---@field y number # The Y-coordinate.
---@field z number # The Z-coordinate.
---@field new fun(x: number, y: number, z: number): Vector3 # Creates a new Vector3 instance with specified x, y, and z coordinates.
Vector3 = Vector3

---`Observe` Definition
---@class Observe
---Provides functionality to observe game events, allowing custom functions to be executed when certain events occur.
---@field Observe fun(className: string, functionName: string, callback: fun(...): nil) # Sets up an observer for a specified function within the game.
Observe = Observe

---`registerForEvent` Definition
---@class registerForEvent
---Allows the registration of functions to be executed when certain game events occur, such as initialization or shutdown.
---@field registerForEvent fun(eventName: string, callback: fun(...): nil) # Registers a callback function for a specified event (e.g., 'onInit', 'onIsDefault').
registerForEvent = registerForEvent

---`spdlog` Definition
---@class spdlog
---Provides logging functionality, allowing messages to be printed to the console or log files for debugging purposes.
---@field info fun(message: string) # Logs an informational message, typically used for general debug output.
---@field error fun(message: string) # Logs an error message, usually when something goes wrong.
spdlog = spdlog

---`dir` Definition
---@class dir
---Retrieves a list of files and folders from a specified directory.
---@return table # Returns a table containing information about each file and folder within the directory.
dir = dir



--[[====================================================
						MOD START
=======================================================]]


---This function is equivalent to `string.format(...)` and exists for convenience and brevity.
---@type fun(format: string|integer, ...: any): string
F = string.format

---Developer mode levels used to control the verbosity and behavior of debug output.
---@alias DevLevelType 0 | 1 | 2 | 3
---@class DevLevelEnum
---@field Disabled DevLevelType # No debug output.
---@field Basic DevLevelType # Print only.
---@field Alert DevLevelType # Print + alert.
---@field Full DevLevelType # Print + alert + log.
---@type DevLevelEnum
DevLevel = {
	Disabled = 0,
	Basic = 1,
	Alert = 2,
	Full = 3
}

---The current debug mode level controlling logging and alerts:
---0 = Disabled
---1 = Print
---2 = Print + Alert
---3 = Print + Alert + Log
---@type DevLevelType
DevMode = DevLevel.Disabled

---Log levels used to classify the severity of log messages.
---@alias LogLevelType 0 | 1 | 2
---@class LogLevelEnum
---@field Info LogLevelType # General informational output.
---@field Warn LogLevelType # Non-critical issues or unexpected behavior.
---@field Error LogLevelType # Critical failures or important errors that need attention.
---@type LogLevelEnum
LogLevel = {
	Info = 0,
	Warn = 1,
	Error = 2
}

---Logs and displays messages based on the current `DevMode` level.
---Messages can be written to the log file, printed to the console, or shown as in-game alerts.
---@param level LogLevelType # Logging level (0 = Info, 1 = Warning, 2 = Error).
---@param format string # A format string for the message.
---@vararg any # Additional arguments for formatting the message.
function Log(level, format, ...)
	if DevMode == DevLevel.Disabled then return end

	local msg = "[ThirdPersonVehicleCameraTool]  "
	if level >= LogLevel.Error then
		msg = msg .. "[Error]  "
	elseif level == LogLevel.Warn then
		msg = msg .. "[Warn]  "
	else
		msg = msg .. "[Info]  "
	end
	msg = msg .. format

	local args = { ... }
	local ok, formatted = pcall(F, msg, table.unpack(args))
	if ok then
		msg = formatted
	end

	if DevMode >= DevLevel.Full then
		if level == LogLevel.Error then
			spdlog.error(msg)
		else
			spdlog.info(msg)
		end
	end
	if DevMode >= DevLevel.Alert then
		local player = Game.GetPlayer()
		if player then
			player:SetWarningMessage(msg, 5)
		end
	end
	if DevMode >= DevLevel.Basic then
		print(msg)
	end
end

---Enforces a log message to be emitted using a temporary `DevMode` override.
---Useful for outputting messages regardless of the current developer mode setting.
---Internally calls `Log()` with the given parameters, then restores the previous `DevMode`.
---@param mode DevLevelType # Temporary debug mode to use (e.g., 1 = Print, 2 = Print + Alert, 3 = Print + Alert + Log).
---@param level LogLevelType # Log level passed to `Log()` (0 = Info, 1 = Warning, 2 = Error).
---@param format string # Format string for the message.
---@vararg any # Optional arguments for formatting the message.
function LogE(mode, level, format, ...)
	if mode < 1 then return end
	local previous = DevMode
	DevMode = mode
	Log(level, format, ...)
	DevMode = previous
end

---The window title string constant.
---@type string
local WINDOW_TITLE = "Third-Person Vehicle Camera Tool"

---Template string constant for accessing `lookAtOffset` values in `TweakDB`.
---@type string
local TWEAKDB_PATH_TEMPLATE = "Camera.VehicleTPP_%s_%s.lookAtOffset"

---Determines whether the CET overlay is open.
---@type boolean
local _isOverlayOpen = false

---Determines whether the mod is enabled.
---@type boolean
local _isEnabled = true

---Determines whether a vehicle is currently mounted.
---@type boolean
local _isVehicleMounted = false

---List of camera preset IDs that were modified at runtime to enable selective restoration.
---@type string[]
local _modifiedPresets = {}

---Represents a vehicle camera preset or links to another one.
---@class CameraOffsetPreset
---@field ID string|nil # The camera ID used for the vehicle.
---@field Close table|nil # The Y-offset for close camera view.
---@field Medium table|nil # The Y-offset for medium camera view.
---@field Far table|nil # The Y-offset for far camera view.
---@field Link string|nil # The name of another vehicle appearance to link to (if applicable).
---@field IsDefault boolean|nil # Whether to reset to default camera offsets.

---Contains all camera presets and linked vehicles.
---@type table<string, CameraOffsetPreset>
local _cameraOffsetPresets = {}

---Paths corresponding to different camera positions.
---@type string[]
local _cameraOffsetPaths = {
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

---Camera offset levels.
---@type string[]
local _cameraOffsetLevels = {
	"Close",
	"Medium",
	"Far"
}

---The currently mounted vehicle camera preset for the editor.
---@type CameraOffsetPreset|nil
local _editorVehicleEntry = nil

---Includes copies of the original camera presets for comparison with editing presets.
---@type table<string, CameraOffsetPreset>
local _originalEntries = {}

---Creates a deep copy of a table, including all nested tables.
---@param original table # The table to copy.
---@return table # A deep copy of the original table.
local function tableDeepCopy(original)
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then
			copy[k] = tableDeepCopy(v)
		else
			copy[k] = v
		end
	end
	return copy
end

---Checks if a given string is present in a table of strings.
---@param tbl string[] # The table to search.
---@param str string # The string to look for.
---@return boolean # True if the string is found, false otherwise.
local function stringTableContains(tbl, str)
	for _, v in ipairs(tbl) do
		if v == str then return true end
	end
	return false
end

---Checks if a string starts with a given prefix.
---@param str string # The string to check.
---@param prefix string # The prefix to match.
---@return boolean # True if 'str' starts with 'prefix', false otherwise.
local function stringStartsWith(str, prefix)
	return #prefix <= #str and str:sub(1, #prefix) == prefix
end

---Checks if a string ends with a specified suffix.
---@param str string The string to check.
---@param suffix string The suffix to look for.
---@return boolean Returns true if the string ends with the specified suffix, otherwise false.
local function stringEndsWith(str, suffix)
	return #suffix <= #str and str:sub(- #suffix) == suffix
end

---Fetches the current camera offset from 'TweakDB' based on the specified ID and path.
---@param id string # The camera ID.
---@param path string # The camera path to retrieve the offset for.
---@return Vector3|nil # The camera offset as a Vector3.
local function getCameraLookAtOffset(id, path)
	return TweakDB:GetFlat(F(TWEAKDB_PATH_TEMPLATE, id, path))
end

---Retrieves the current camera offset data for the specified camera ID from TweakDB
---and returns it as a `CameraOffsetPreset` table.
---@param id string # The camera ID to query.
---@return CameraOffsetPreset|nil # The retrieved camera offset data, or nil if not found.
local function getCurrentCameraOffset(id)
	if not id then return nil end

	local entry = { ID = id }
	for i, path in ipairs(_cameraOffsetPaths) do
		local vec3 = getCameraLookAtOffset(id, path)
		if not vec3 or not vec3.y then return nil end

		local p = (i - 1) % 3
		local v = { y = vec3.y, z = vec3.z }
		if p == 0 then
			entry.Close = v
		elseif p == 1 then
			entry.Medium = v
		else
			entry.Far = v
		end

		if entry.Far and entry.Medium and entry.Close then
			if DevMode >= DevLevel.Full then
				Log(LogLevel.Info, "Found current camera offset for '%s'.", id)
			end
			return entry
		end
	end

	Log(LogLevel.Warn, "Could not retrieve current camera offset for '%s'.", id)
	return nil
end

---Sets a camera offset in 'TweakDB' to the specified position values.
---@param id string # The camera ID.
---@param path string # The camera path to set the offset for.
---@param x number # The X-coordinate of the camera position.
---@param y number # The Y-coordinate of the camera position.
---@param z number # The Z-coordinate of the camera position.
local function setCameraLookAtOffset(id, path, x, y, z)
	TweakDB:SetFlat(F(TWEAKDB_PATH_TEMPLATE, id, path), Vector3.new(x, y, z))
end

---Updates the Y (and optionally Z) offset of a camera path in 'TweakDB'.
---@param id string # The camera ID.
---@param path string # The camera path to update.
---@param y number # The new Y-coordinate value.
---@param z number|nil # The optional Z-coordinate value.
local function setCameraLookAtOffsetYZ(id, path, y, z)
	local fallback = getCameraLookAtOffset(id, path)
	if fallback then
		setCameraLookAtOffset(id, path, fallback.x, y or fallback.y, z or fallback.z)
	end
end

---Validates whether the given camera offset preset is structurally valid.
---A preset is valid if it either:
---1. Has a string ID and at least one of Close, Medium, or Far contains a numeric `y` or `z` value.
---2. Or: has only a string `Link` and no other keys.
---@param preset CameraOffsetPreset # The preset to validate.
---@return boolean # Returns true if the preset is valid, false otherwise.
local function isCameraOffsetPresetValid(preset)
	if type(preset) ~= "table" then return false end

	if type(preset.ID) == "string" then
		for _, k in ipairs(_cameraOffsetLevels) do
			local offset = preset[k]
			if type(offset) == "table" then
				if type(offset.y) == "number" or type(offset.z) == "number" then
					return true
				end
			end
		end
	end

	if type(preset.Link) == "string" then
		for k, _ in pairs(preset) do
			if k ~= "Link" then
				return false
			end
		end
		return true
	end

	return false
end

---Clears all currently loaded camera offset presets.
local function purgeCameraOffsetPresets()
	_cameraOffsetPresets = {}
	Log(LogLevel.Warn, "Cleared all loaded camera offset presets.")
end

---Loads camera offset presets from `./defaults/` (first) and `./presets/` (second).
---Each `.lua` file must return a `CameraOffsetPreset` table with at least an `ID` field.
---Skips already loaded presets unless `refresh` is true (then clears and reloads all).
---@param refresh boolean|nil — If true, clears existing presets before loading (default: false).
local function loadCameraOffsetPresets(refresh)
	local function loadFrom(path)
		local files = dir("./" .. path)
		for _, file in ipairs(files) do
			local name = file.name
			if not name or not stringEndsWith(name, ".lua") then goto continue end

			local key = name:sub(1, -5)
			if _cameraOffsetPresets[key] then
				Log(LogLevel.Warn, "Skipping already loaded preset: '%s' ('./%s/%s').", key, path, name)
				goto continue
			end

			local chunk, err = loadfile(path .. "/" .. name)
			if not chunk then
				LogE(DevLevel.Basic, LogLevel.Error, "Failed to load preset './%s/%s': %s", path, name, err)
				goto continue
			end

			local ok, result = pcall(chunk)
			if ok and isCameraOffsetPresetValid(result) then
				_cameraOffsetPresets[key] = result
				Log(LogLevel.Info, "Loaded preset '%s' from './%s/%s'.", key, path, name)
				goto continue
			end

			LogE(DevLevel.Basic, LogLevel.Error, "Invalid or failed preset './%s/%s'.", path, name)

			::continue::
		end
	end

	if refresh then
		purgeCameraOffsetPresets()
	end

	loadFrom("defaults")
	loadFrom("presets")
end

---Applies a camera offset preset to the vehicle by updating values in TweakDB.
---If the preset includes a `Link` field, the function will follow it recursively
---until it reaches a final entry (up to 8 levels deep to prevent infinite loops).
---Missing `y` or `z` values in the preset are replaced with fallback values from the default preset, if available.
---@param entry CameraOffsetPreset # The preset to apply. May include a `Link` to another preset.
---@param count number|nil # Internal recursion counter to prevent infinite loops via `Link`. Do not set manually.
local function applyCameraOffsetPreset(entry, count)
	if entry and entry.Link then
		count = (count or 0) + 1
		if DevMode >= DevLevel.Full then
			Log(LogLevel.Info, "Following linked preset (%d): '%s'", count, entry.Link)
		end
		entry = _cameraOffsetPresets[entry.Link]
		if entry and entry.Link and count < 8 then
			applyCameraOffsetPreset(entry, count)
			return
		end
	end

	if not entry or not entry.ID then
		Log(LogLevel.Error, "Failed to apply preset.")
		return
	end

	local fallback = _cameraOffsetPresets[entry.ID] or {}
	for i, path in ipairs(_cameraOffsetPaths) do
		local p = (i - 1) % 3

		local e = p == 0 and entry.Close or p == 1 and entry.Medium or entry.Far
		local f = p == 0 and fallback.Close or p == 1 and fallback.Medium or fallback.Far

		local y = e and e.y or f.y or 0
		local z = e and e.z or f.z or 1.115

		setCameraLookAtOffsetYZ(entry.ID, path, y, z)
	end

	table.insert(_modifiedPresets, entry.ID)
end

---Restores all camera offset presets to their default values.
local function restoreAllCameraOffsetPresets()
	_modifiedPresets = {}

	for _, entry in pairs(_cameraOffsetPresets) do
		if entry.IsDefault then
			applyCameraOffsetPreset(entry)
		end
	end

	Log(LogLevel.Info, "Restored all default presets.")
end

---Restores modified camera offset presets to their default values.
local function restoreModifiedCameraOffsetPresets()
	local changed = _modifiedPresets
	if #changed == 0 then return end

	local amount = #changed
	local restored = 0
	for _, entry in pairs(_cameraOffsetPresets) do
		if entry.IsDefault and stringTableContains(changed, entry.ID) then
			applyCameraOffsetPreset(entry)
			Log(LogLevel.Info, "Preset for ID '%s' has been restored.", entry.ID)
			restored = restored + 1
		end
		if restored >= amount then break end
	end
	_modifiedPresets = {}

	Log(LogLevel.Info, "Restored %d/%d changed preset(s).", restored, amount)
end

---Extracts the record name from a TweakDBID string representation.
---@param data any # The TweakDBID to be parsed.
---@return string|nil # The extracted record name, or nil if not found.
local function getRecordName(data)
	if not data then return nil end
	return tostring(data):match("%-%-%[%[(.-)%-%-%]%]"):match("^%s*(.-)%s*$")
end

---Returns the vehicle the player is currently mounted in, if any.
---Internally retrieves the player instance and checks for an active vehicle.
---@return Vehicle|nil # The currently mounted vehicle instance, or nil if the player is not mounted.
local function getMountedVehicle()
	local player = Game.GetPlayer()
	if not player then
		_isVehicleMounted = false
		_editorVehicleEntry = nil
		return nil
	end
	local vehicle = Game.GetMountedVehicle(player)
	_isVehicleMounted = vehicle ~= nil
	return vehicle
end

---Attempts to retrieve the camera ID associated with a given vehicle.
---@param vehicle Vehicle|nil # The vehicle from which to extract the camera ID.
---@return string|nil # The extracted camera ID (e.g., "4w_911") or nil if not found.
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
			return item:match("Camera%.VehicleTPP_([%w_]+)_[%w_]+_[%w_]+")
		end
	end

	return nil
end

---Attempts to retrieve the appearance name of the currently mounted vehicle.
---@return string|nil # The appearance name (e.g., "porsche_911turbo__basic_johnny") or nil if not found.
local function getVehicleName(vehicle)
	if not vehicle then return nil end

	local name = vehicle:GetCurrentAppearanceName()
	if not name then return nil end

	return Game.NameToString(name)
end

---Finds the best matching preset key for a given vehicle name.
---First tries for an exact match, then falls back to partial match using string prefix.
---@param name string|nil # The vehicle name to match against preset keys.
---@return string|nil # The matching preset key if found, or nil otherwise.
local function getCameraPresetKey(name)
	if not name then return nil end

	for pass = 1, 2 do
		for key in pairs(_cameraOffsetPresets) do
			local exact = pass == 1 and name == key
			local partial = pass == 2 and stringStartsWith(name, key)
			if exact or partial then
				return key
			end
		end
	end

	return nil
end

---Applies the appropriate camera offset preset when the player mounts a vehicle, if available.
local function autoApplyCameraOffsetPreset()
	local vehicle = getMountedVehicle()
	if not vehicle then return end

	local name = getVehicleName(vehicle)
	if not name then return end

	if DevMode >= DevLevel.Alert then
		Log(LogLevel.Info, "Mounted vehicle: '%s'", name)

		local vehicleID = getVehicleCameraID(vehicle)
		if vehicleID then
			Log(LogLevel.Info, "Camera preset ID: '%s'", vehicleID)
		end
	end

	local key = getCameraPresetKey(name)
	if not key then return end

	applyCameraOffsetPreset(_cameraOffsetPresets[key])
end

---Saves the current preset to './presets/<name>.lua' only if the file doesn't already exist.
---By default, only values that differ from the game's defaults are saved.
---If `saveCompletePreset` is true, all values (including unchanged/default ones) are saved explicitly.
---@param name string # The name of the preset.
---@param preset table # The preset data to save.
---@param saveCompletePreset boolean|nil # If true, saves all values, even those that match the game's defaults.
---@return boolean # True if saved successfully or if the file already exists; false if an error occurred.
local function savePreset(name, preset, saveCompletePreset)
	if type(name) ~= "string" or type(preset) ~= "table" then return false end

	local path = "presets/" .. name .. ".lua"
	local check = io.open(path, "r")
	if check then
		check:close()
		Log(LogLevel.Warn, "File '%s' already exists, and overwrite is disabled.", path)
		return false
	end

	local function isDifferent(a, b)
		if saveCompletePreset then return true end
		if type(a) ~= type(b) then return true end
		if type(a) == "number" then
			return math.abs(a - b) > 0.0001
		end
		return a ~= b
	end

	local function round(v)
		return F("%.3f", v):gsub("0+$", ""):gsub("%.$", "")
	end

	local norm = _originalEntries and _originalEntries[name] or {}
	local save = false
	local parts = { "return{" }
	table.insert(parts, F('ID=%q,', preset.ID))
	for _, mode in ipairs(_cameraOffsetLevels) do
		local a = preset[mode]
		local b = norm[mode]
		local sub = {}

		if type(a) == "table" then
			if not b then b = {} end
			if isDifferent(a.y, b.y) then
				save = true
				table.insert(sub, "y=" .. round(a.y))
			end
			if isDifferent(a.z, b.z) then
				save = true
				table.insert(sub, "z=" .. round(a.z))
			end
		end

		if #sub > 0 then
			table.insert(parts, F('%s={%s},', mode, table.concat(sub, ",")))
		end
	end

	if not save then
		return false
	end

	local last = parts[#parts]
	if last and last:sub(-1) == "," then
		parts[#parts] = last:sub(1, -2)
	end

	table.insert(parts, "}")

	local file = io.open(path, "w")
	if not file then
		return false
	end
	file:write(table.concat(parts))
	file:close()

	return true
end

---Displays a tooltip when the current UI item is hovered.
---Accepts multiple lines of text as variadic string arguments.
---@param ... string # One or more lines of text to display in the tooltip.
local function guiTooltip(...)
	if not ImGui.IsItemHovered() then return end
	ImGui.BeginTooltip()
	for _, line in ipairs({ ... }) do
		ImGui.Text(line)
	end
	ImGui.EndTooltip()
end

--This event is triggered when the CET environment initializes for a particular game session.
registerForEvent("onInit", function()
	--Load all saved presets from disk.
	loadCameraOffsetPresets(true)

	--This step is mainly necessary in case all mods are reloaded while the player is already inside a vehicle.
	autoApplyCameraOffsetPreset()

	--When the player mounts a vehicle, automatically apply the matching camera preset if available.
	--This event can fire even if the player is already mounted, so we guard with `_isVehicleMounted`.
	Observe("VehicleComponent", "OnMountingEvent", function()
		if not _isEnabled or _isVehicleMounted then return end
		_editorVehicleEntry = nil
		autoApplyCameraOffsetPreset()
	end)

	--When the player unmounts from a vehicle, reset to default camera offsets.
	Observe("VehicleComponent", "OnUnmountingEvent", function()
		if not _isEnabled then return end
		_isVehicleMounted = false
		_editorVehicleEntry = nil
		restoreModifiedCameraOffsetPresets()
	end)

	--Reset the current editor state when the player takes control of their character
	--(usually after loading a save game). This ensures UI does not persist stale data.
	Observe("PlayerPuppet", "OnTakeControl", function(self)
		if self:GetEntityID().hash ~= 1 or not _isEnabled then return end
		_isVehicleMounted = false
	end)
end)

--Detects when the CET overlay is opened.
registerForEvent("onOverlayOpen", function()
	_isOverlayOpen = true
end)

--Detects when the CET overlay is closed.
registerForEvent("onOverlayClose", function()
	_isOverlayOpen = false
end)

--Display a simple GUI some options.
registerForEvent("onDraw", function()
	if not _isOverlayOpen or not ImGui.Begin(WINDOW_TITLE, ImGuiWindowFlags.AlwaysAutoResize) then return end

	--Minimum window width and height padding.
	ImGui.Dummy(230, 4)

	--Checkbox to toggle mod functionality and handle enable/disable logic.
	ImGui.Dummy(10, 0)
	ImGui.SameLine()
	local isEnabled = ImGui.Checkbox("  Toggle Mod Functionality", _isEnabled)
	guiTooltip("Enables or disables the mod functionality.")
	if isEnabled ~= _isEnabled then
		_isEnabled = isEnabled
		_editorVehicleEntry = nil
		if isEnabled then
			loadCameraOffsetPresets()
			autoApplyCameraOffsetPreset()
			LogE(DevLevel.Alert, LogLevel.Info, "Mod has been enabled!")
		else
			restoreAllCameraOffsetPresets()
			purgeCameraOffsetPresets()
			LogE(DevLevel.Alert, LogLevel.Info, "Mod has been disabled!")

			--Mod is disabled — nothing left to add.
			ImGui.End()
			return
		end
	end
	ImGui.Dummy(0, 2)

	--The button that reloads all presets.
	ImGui.Dummy(10, 0)
	ImGui.SameLine()
	if ImGui.Button("Reload All Presets", 192, 24) then
		_editorVehicleEntry = nil
		loadCameraOffsetPresets(true)
		restoreAllCameraOffsetPresets()
		autoApplyCameraOffsetPreset()
		LogE(DevLevel.Alert, LogLevel.Info, "Presets have been reloaded!")
	end
	guiTooltip(
		"Reloads all data from custom preset files - only\nneeded if files have been changed or added.",
		"\nPlease note that you need to exit and re-enter\nthe vehicle for the changes to take effect."
	)
	ImGui.Dummy(0, 2)

	--Slider to set the developer mode level.
	ImGui.Dummy(10, 0)
	ImGui.SameLine()
	ImGui.PushItemWidth(77)
	DevMode = ImGui.SliderInt("  Developer Mode", DevMode, DevLevel.Disabled, DevLevel.Full)
	guiTooltip(
		"Enables a feature that allows you to create, test, and save your own presets.",
		"\nAlso adjusts the level of debug output:",
		" 0 = Disabled",
		" 1 = Print only",
		" 2 = Print & Alert",
		" 3 = Print, Alert & Log"
	)
	ImGui.PopItemWidth()
	ImGui.Dummy(0, 8)

	--Table showing vehicle name and camera ID — if certain conditions are met.
	local vehicle, name, id
	for _, fn in ipairs({
		function()
			return DevMode > DevLevel.Disabled
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
			id = getVehicleCameraID(vehicle)
			return id
		end
	}) do
		if not fn() then
			--Condition not met — GUI closed.
			ImGui.End()
			return
		end
	end

	if ImGui.BeginTable("InfoTable", 2, ImGuiTableFlags.Borders) then
		ImGui.TableSetupColumn("Key", ImGuiTableColumnFlags.WidthFixed, -1)
		ImGui.TableSetupColumn("Value", ImGuiTableColumnFlags.WidthStretch)
		ImGui.TableHeadersRow()

		local key = getCameraPresetKey(name)
		local dict = {
			{ key = "Vehicle",    value = name },
			{ key = "Camera ID",  value = id },
			{ key = "Preset",     value = (key or id) .. ".lua" },
			{ key = "Is Default", value = tostring(key == nil) }
		}
		for _, item in ipairs(dict) do
			ImGui.TableNextRow()
			ImGui.TableSetColumnIndex(0)
			ImGui.Text(item.key)
			ImGui.TableSetColumnIndex(1)
			ImGui.Text(tostring(item.value or "None"))
		end

		ImGui.EndTable()
	end

	--Camera preset editor allowing Y/Z position adjustments — if certain conditions are met.
	if not _editorVehicleEntry then
		_editorVehicleEntry = getCurrentCameraOffset(id)
	end

	local entry = _editorVehicleEntry
	if not entry then
		Log(LogLevel.Warn, "No preset found.")

		--GUI closed — no further controls required.
		ImGui.End()
		return
	end

	if not _originalEntries[name] then
		local original = getCurrentCameraOffset(entry.ID)
		if not original then
			Log(LogLevel.Error, "Original preset for '%s' not found.", entry.ID)

			--GUI ends early — original preset not found.
			ImGui.End()
			return
		end
		_originalEntries[name] = tableDeepCopy(original)
	end

	if ImGui.BeginTable("CameraOffsetEditor", 3, ImGuiTableFlags.Borders) then
		ImGui.TableSetupColumn("Level", ImGuiTableColumnFlags.WidthFixed, -1)
		ImGui.TableSetupColumn("Y Offset", ImGuiTableColumnFlags.WidthStretch)
		ImGui.TableSetupColumn("Z Offset", ImGuiTableColumnFlags.WidthStretch)
		ImGui.TableHeadersRow()

		for _, key in ipairs(_cameraOffsetLevels) do
			local offsets = entry[key]
			if type(offsets) == "table" then
				ImGui.TableNextRow()

				ImGui.TableSetColumnIndex(0)
				ImGui.Text(key)

				local original = _originalEntries[name][key] or {}
				for i, axis in ipairs({ "y", "z" }) do
					ImGui.TableSetColumnIndex(i)
					ImGui.PushItemWidth(-1)
					local curVal = offsets[axis] or original[axis] or 0.0
					local minVal = i == 1 and -10 or 0
					local maxVal = i == 1 and 10 or 32
					local newVal = ImGui.SliderFloat(F("##%s_%s", key, axis), curVal, minVal, maxVal)
					ImGui.PopItemWidth()

					offsets[axis] = newVal
				end
			end
		end

		ImGui.EndTable()
		ImGui.Dummy(0, 1)
	end

	--Button to apply previously configured values in-game.
	local width = ImGui.GetWindowSize() - 16
	if ImGui.Button("Apply Changes", width, 24) then
		_cameraOffsetPresets[name] = entry
		LogE(DevLevel.Alert, LogLevel.Info, "The preset '%s' has been updated.", name)
	end
	guiTooltip(
		"Applies the configured values without saving them permanently.",
		"\nPlease note that you need to exit and re-enter the vehicle\nfor the changes to take effect."
	)
	ImGui.Dummy(0, 1)

	--Button to save configured values to a file for future automatic use.
	if ImGui.Button("Save Changes to File", width, 24) then
		if savePreset(name, entry) then
			LogE(DevLevel.Alert, LogLevel.Info, "File './presets/%s.lua' was saved successfully.", name)
		else
			LogE(DevLevel.Alert, LogLevel.Warn, "File './presets/%s.lua' could not be saved.", name)
		end
	end
	guiTooltip(
		F("Saves the modified preset permanently under './presets/%s.lua'.", name),
		"\nPlease note that overwriting existing presets is not allowed\nto prevent accidental loss.",
		"\nIf you want to overwrite a preset, you must delete the existing\nfile manually first."
	)
	ImGui.Dummy(0, 1)

	--GUI creation is complete.
	ImGui.End()
end)

--Restores default camera offsets for vehicles upon mod shutdown.
registerForEvent("onShutdown", function()
	restoreAllCameraOffsetPresets()
end)
