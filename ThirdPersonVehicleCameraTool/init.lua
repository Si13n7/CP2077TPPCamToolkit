--[[
==============================================
This file is distributed under the MIT License
==============================================

Third-Person Vehicle Camera Tool

Allows you to adjust third-person perspective
(TPP) camera offsets for any vehicle.

Filename: init.lua
Version: 2025-04-11, 20:01 UTC+01:00 (MEZ)

Copyright (c) 2025, Si13n7 Developments(tm)
All rights reserved.
______________________________________________
--]]



--[[====================================================
		STANDARD DEFINITIONS FOR INTELLISENSE
=======================================================]]


---Provides functions to create graphical user interface elements within the Cyber Engine Tweaks overlay.
---@class ImGui
---@field Begin fun(title: string, flags?: integer): boolean # Begins a new ImGui window with optional flags. Must be closed with `ImGui.End()`. Returns `true` if the window is open and should be rendered.
---@field Begin fun(title: string, open: boolean, flags?: integer): boolean # Begins a new ImGui window. Returns `true` if the window is open and should be rendered. If `open` is `false`, the window is not shown.
---@field End fun(): nil # Ends the creation of the current ImGui window. Must always be called after `ImGui.Begin()`.
---@field Separator fun(): nil # Draws a horizontal line to visually separate UI sections.
---@field Dummy fun(width: number, height: number): nil # Creates an invisible element of specified width and height, useful for spacing.
---@field SameLine fun(offsetX?: number, spacing?: number): nil # Places the next UI element on the same line. Optionally adds horizontal offset and spacing.
---@field Text fun(text: string): nil # Displays text within the current window or tooltip.
---@field PushTextWrapPos fun(wrapLocalPosX?: number): nil # Sets a maximum width (in pixels) for wrapping text. Applies to subsequent Text elements until `PopTextWrapPos()` is called. If no value is provided, wraps at the edge of the window.
---@field PopTextWrapPos fun(): nil # Restores the previous text wrapping position. Should be called after `PushTextWrapPos()` to reset wrapping behavior.
---@field Button fun(label: string, width?: number, height?: number): boolean # Creates a clickable button with optional width and height. Returns true if the button was clicked.
---@field Checkbox fun(label: string, value: boolean): (boolean, boolean) # Creates a toggleable checkbox. Returns `changed` (true if state has changed) and `value` (the new state).
---@field InputText fun(label: string, value: string, maxLength?: integer): (string, boolean) # Creates a single-line text input field. Returns a tuple: the `new value` and `changed` (true if the text was edited).
---@field SliderInt fun(label: string, value: integer, min: integer, max: integer): integer # Creates an integer slider. Returns the new `value`.
---@field DragFloat fun(label: string, value: number, speed?: number, min?: number, max?: number, format?: string): number # Creates a draggable float input widget. Allows the user to adjust the value by dragging or with arrow keys. Optional speed, min/max limits, and format string. Returns the updated float value.
---@field IsItemHovered fun(): boolean # Returns true if the last item is hovered by the mouse cursor.
---@field IsItemActive fun(): boolean # Returns true while the last item is being actively used (e.g., held with mouse or keyboard input).
---@field PushItemWidth fun(width: number): nil # Sets the width of the next UI element (e.g., slider, text input).
---@field PopItemWidth fun(): nil # Resets the width of the next UI element to the default value.
---@field BeginTooltip fun(): nil # Begins creating a tooltip. Must be paired with `ImGui.EndTooltip()`.
---@field EndTooltip fun(): nil # Ends the creation of a tooltip. Must be called after `ImGui.BeginTooltip()`.
---@field BeginTable fun(id: string, columns: integer, flags?: integer): boolean # Begins a table with the specified number of columns. Returns `true` if the table is created successfully and should be rendered.
---@field TableSetupColumn fun(label: string, flags?: integer, init_width_or_weight?: number): nil # Defines a column in the current table with optional flags and initial width or weight.
---@field TableHeadersRow fun(): nil # Automatically creates a header row using column labels defined by `TableSetupColumn()`. Must be called right after defining the columns.
---@field TableNextRow fun(): nil # Advances to the next row of the table. Must be called between rows.
---@field TableSetColumnIndex fun(index: integer): nil # Moves the focus to a specific column index within the current table row.
---@field EndTable fun(): nil # Ends the creation of the current table. Must always be called after `ImGui.BeginTable()`.
---@field GetColumnWidth fun(columnIndex?: integer): number # Returns the current width in pixels of the specified column index (default: 0). Only valid when called within an active table.
---@field GetContentRegionAvail fun(): number # Returns the width of the remaining content region inside the current window, excluding padding. Useful for calculating dynamic layouts or centering elements.
---@field CalcTextSize fun(text: string): number # Calculates the width of a given text string as it would be displayed using the current font. Returns the width in pixels as a floating-point number.
---@field GetStyle fun(): ImGuiStyle # Returns the current ImGui style object, which contains values for UI layout, spacing, padding, rounding, and more.
---@field GetWindowPos fun(): number, number # Returns the X and Y position of the current window, relative to the screen.
---@field GetWindowSize fun(): number, number # Returns the width and height of the current window in pixels.
---@field SetNextWindowPos fun(x: number, y: number): nil # Sets the position for the next window before calling ImGui.Begin().
---@field SetNextWindowSize fun(width: number, height: number): nil # Sets the size for the next window before calling ImGui.Begin().
---@field OpenPopup fun(id: string): nil # Opens a popup by identifier. Should be followed by ImGui.BeginPopup().
---@field BeginPopup fun(id: string): boolean # Starts a popup window with the given ID. Returns true if it should be drawn.
---@field CloseCurrentPopup fun(): nil # Closes the currently open popup window. Should be called inside the popup itself.
---@field EndPopup fun(): nil # Ends the current popup window. Always call after BeginPopup().
---@field PushStyleColor fun(idx: integer, color: integer): nil # Pushes a new color style override for the current ImGui context.
---@field PopStyleColor fun(count?: integer): nil # Removes one or more pushed style colors from the stack. Default count is 1.
ImGui = ImGui

---Flags used to configure ImGui window behavior and appearance.
---@class ImGuiWindowFlags
---@field AlwaysAutoResize integer # Automatically resizes the window to fit its content each frame.
---@field NoCollapse integer # Disables the ability to collapse the window.
---@field NoResize integer # Disables window resizing.
---@field NoMove integer # Disables window moving.
ImGuiWindowFlags = ImGuiWindowFlags

---Flags to customize table behavior and appearance.
---@class ImGuiTableFlags
---@field Borders integer # Draws borders between cells.
ImGuiTableFlags = ImGuiTableFlags

---Flags to customize individual columns within a table.
---@class ImGuiTableColumnFlags
---@field WidthFixed integer # Makes the column have a fixed width.
---@field WidthStretch integer # Makes the column stretch to fill available space.
ImGuiTableColumnFlags = ImGuiTableColumnFlags

---UI color indices used for styling via ImGui.PushStyleColor().
---Each index refers to a specific UI element's color.
---@class ImGuiCol
---@field Text integer # Color of text.
---@field Button integer # Color of button.
---@field ButtonHovered integer # Color of hovered button.
---@field ButtonActive integer # Color of pressed button.
---@field FrameBg integer # Background color of widgets with a frame (e.g., InputText, DragFloat, etc.) when idle.
---@field FrameBgHovered integer # Background color of framed widgets when hovered by the mouse.
---@field FrameBgActive integer # Background color of framed widgets when active (being edited or held).
ImGuiCol = ImGuiCol

---Represents the current ImGui style configuration, controlling layout, spacing, padding, rounding, and more.
---@class ImGuiStyle
---@field ItemSpacing { x: number, y: number } # Horizontal and vertical spacing between widgets.
ImGuiStyle = ImGuiStyle

---Bitwise operations (Lua 5.1 compatibility).
---@class bit32
---@field bor fun(...: integer): integer # Bitwise OR of all given integer values.
---@field band fun(x: integer, y: integer): integer # Returns the bitwise AND of two integers.
---@field rshift fun(x: integer, disp: integer): integer # Shifts `x` right by `disp` bits, filling in with zeros from the left.
---@field lshift fun(x: integer, disp: integer): integer # Shifts `x` left by `disp` bits, discarding bits shifted out on the left.
bit32 = bit32

---Provides access to game data stored in the database, including camera offsets and various other game settings.
---@class TweakDB
---@field GetFlat fun(self: TweakDB, key: string): any|nil # Retrieves a value from the database based on the provided key.
---@field SetFlat fun(self: TweakDB, key: string, value: any) # Sets or modifies a value in the database for the specified key.
TweakDB = TweakDB

---Represents a TweakDB ID used to reference records in the game database.
---@class TDBID
---@field ToStringDEBUG fun(id: TDBID): string|nil # Converts a TDBID to a readable string, typically starting with a namespace like "Vehicle.".
TDBID = TDBID

---Provides various global game functions, such as getting the player, mounted vehicles, and converting names to strings.
---@class Game
---@field NameToString fun(value: any): string # Converts a game name object to a readable string.
---@field GetPlayer fun(): Player|nil # Retrieves the current player instance if available.
---@field GetMountedVehicle fun(player: Player): Vehicle|nil # Returns the vehicle the player is currently mounted in, if any.
Game = Game

---Represents the player character in the game, providing functions to interact with the player instance.
---@class Player
---@field SetWarningMessage fun(self: Player, message: string, duration: number): nil # Displays a warning message on the player's screen for a specified duration.
Player = Player

---Represents a vehicle entity within the game, providing functions to interact with it, such as getting the appearance name.
---@class Vehicle
---@field GetCurrentAppearanceName fun(self: Vehicle): string|nil # Retrieves the current appearance name of the vehicle.
---@field GetRecordID fun(self: Vehicle): any # Returns the unique TweakDBID associated with the vehicle.
---@field GetTDBID fun(self: Vehicle): TDBID|nil # Retrieves the internal TweakDB identifier used to reference this vehicle in the game database. Returns `nil` if unavailable.
Vehicle = Vehicle

---Represents a three-dimensional vector, commonly used for positions or directions in the game.
---@class Vector3
---@field x number # The X-coordinate.
---@field y number # The Y-coordinate.
---@field z number # The Z-coordinate.
---@field new fun(x: number, y: number, z: number): Vector3 # Creates a new Vector3 instance with specified x, y, and z coordinates.
Vector3 = Vector3

---Provides functionality to observe game events, allowing custom functions to be executed when certain events occur.
---@class Observe
---@field Observe fun(className: string, functionName: string, callback: fun(...): nil) # Sets up an observer for a specified function within the game.
Observe = Observe

---Allows the registration of functions to be executed when certain game events occur, such as initialization or shutdown.
---@class registerForEvent
---@field registerForEvent fun(eventName: string, callback: fun(...): nil) # Registers a callback function for a specified event (e.g., `onInit`, `onIsDefault`).
registerForEvent = registerForEvent

---Provides logging functionality, allowing messages to be printed to the console or log files for debugging purposes.
---@class spdlog
---@field info fun(message: string) # Logs an informational message, typically used for general debug output.
---@field error fun(message: string) # Logs an error message, usually when something goes wrong.
spdlog = spdlog

---Retrieves a list of files and folders from a specified directory.
---@class dir
---(IntelliSense needs this extra line, as it is dissatisfied with the name `dir`, which we cannot change.)
---@return table # Returns a table containing information about each file and folder within the directory.
dir = dir



--[[====================================================
						MOD START
=======================================================]]


---This function is equivalent to `string.format(...)` and exists for convenience and brevity.
---@type fun(format: string|number, ...: any): string
F = string.format

---Loads all static UI and log string constants from `text.lua` into the global `Text` table.
---This is the most efficient way to manage display strings separately from logic and code.
---@type table<string, string>
Text = dofile("text.lua")

---Developer mode levels used to control the verbosity and behavior of debug output.
---@alias DevLevelType 0|1|2|3
---@class DevLevelEnum
---@field DISABLED DevLevelType # No debug output.
---@field BASIC DevLevelType # Print only.
---@field ALERT DevLevelType # Print + alert.
---@field FULL DevLevelType # Print + alert + log.
---@type DevLevelEnum
DevLevel = {
	DISABLED = 0,
	BASIC = 1,
	ALERT = 2,
	FULL = 3
}

---The current debug mode level controlling logging and alerts:
---0 = Disabled
---1 = Print
---2 = Print + Alert
---3 = Print + Alert + Log
---@type DevLevelType
DevMode = DevLevel.DISABLED

---Log levels used to classify the severity of log messages.
---@alias LogLevelType 0|1|2
---@class LogLevelEnum
---@field INFO LogLevelType # General informational output.
---@field WARN LogLevelType # Non-critical issues or unexpected behavior.
---@field ERROR LogLevelType # Critical failures or important errors that need attention.
---@type LogLevelEnum
LogLevel = {
	INFO = 0,
	WARN = 1,
	ERROR = 2
}

---Format string for generating a TweakDB path to a vehicle's default rotation pitch value.
---First `%s` = camera ID, second `%s` = camera level (e.g., "High_Close").
---@type string
local TWEAKDB_PATH_FORMAT_DRP = "Camera.VehicleTPP_%s_%s.defaultRotationPitch"

---Format string for generating a TweakDB path to a vehicle's look-at offset vector.
---First `%s` = camera ID, second `%s` = camera level (e.g., "Low_Medium").
---@type string
local TWEAKDB_PATH_FORMAT_LAO = "Camera.VehicleTPP_%s_%s.lookAtOffset"

---Constant array of possible camera levels used in TweakDB path generation.
---Each level corresponds to the second `%s` in the `TWEAKDB_PATH_FORMAT` strings.
---@type string[]
local TWEAKDB_PATH_LEVELS = {
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

---Constant array of camera levels.
---@type string[]
local CAMERA_LEVELS = { "Close", "Medium", "Far" }

---Constant array of `OffsetData` keys.
---@type string[]
local OFFSETDATA_KEYS = { "a", "x", "y", "z" }

---Determines whether the mod is enabled.
---@type boolean
local _isEnabled = true

---Determines whether a vehicle is currently mounted.
---@type boolean
local _isVehicleMounted = false

---List of camera preset IDs that were modified at runtime to enable selective restoration.
---@type string[]
local _modifiedPresets = {}

---Represents a camera offset configuration with rotation and positional data.
---@class OffsetData
---@field a number # The camera's angle in degrees.
---@field x number # The offset on the X-axis.
---@field y number # The offset on the Y-axis.
---@field z number # The offset on the Z-axis.

---Represents a vehicle camera preset or links to another one.
---@class CameraPreset
---@field ID string|nil # The camera ID used for the vehicle.
---@field Close OffsetData|nil # The offset data for close camera view.
---@field Medium OffsetData|nil # The offset data for medium camera view.
---@field Far OffsetData|nil # The offset data for far camera view.
---@field Link string|nil # The name of another vehicle appearance to link to (if applicable).
---@field IsDefault boolean|nil # Whether to reset to default camera offsets.

---Contains all camera presets and linked vehicles.
---@type table<string, CameraPreset>
local _cameraPresets = {}

---Determines whether the CET overlay is open.
---@type boolean
local _isOverlayOpen = false

---Current horizontal padding value used for centering UI elements.
---Dynamically adjusted based on available window width.
---@type number
local _guiPadding

---When set to true, disables dynamic window padding adjustments and uses the fixed `_guiPadding` value.
---@type boolean
local _guiLockPadding

---The currently mounted vehicle camera preset for the editor.
---@type CameraPreset|nil
local _guiEditorPreset

---The default preset entry used for comparison in the editor (e.g., when checking if a value has changed).
---@type CameraPreset|nil
local _guiEditorPresetDef

---The file name used for saving the current edited preset (including `.lua` extension).
---@type string|nil
local _guiEditorPresetName

---Tracks unsaved editor changes for individual vehicles.
---Each key is a vehicle name, and the boolean value indicates whether unsaved changes exist.
---@type table<string, boolean>
local _guiEditorUnsavedChanges = {}

---Determines whether overwriting the preset file is allowed.
---@type boolean
local _guiEditorAllowOverwrite = false

---Determines whether the Preset File Manager is open.
---@type boolean
local _fileManToggle = false

---Logs and displays messages based on the current `DevMode` level.
---Messages can be written to the log file, printed to the console, or shown as in-game alerts.
---@param level LogLevelType # Logging level (0 = Info, 1 = Warning, 2 = Error).
---@param format string # A format string for the message.
---@vararg any # Additional arguments for formatting the message.
function Log(level, format, ...)
	if DevMode == DevLevel.DISABLED then return end

	local msg = F "[TPVCamTool]  "
	if level >= LogLevel.ERROR then
		msg = msg .. "[Error]  "
	elseif level == LogLevel.WARN then
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

	if DevMode >= DevLevel.FULL then
		if level == LogLevel.ERROR then
			spdlog.error(msg)
		else
			spdlog.info(msg)
		end
	end
	if DevMode >= DevLevel.ALERT then
		local player = Game.GetPlayer()
		if player then
			player:SetWarningMessage(msg, 5)
		end
	end
	if DevMode >= DevLevel.BASIC then
		print(msg)
	end
end

---Enforces a log message to be emitted using a temporary `DevMode` override.
---Useful for outputting messages regardless of the current developer mode setting.
---Internally calls `Log()` with the given parameters, then restores the previous `DevMode`.
---@param mode DevLevelType # Temporary debug mode to use.
---@param level LogLevelType # Log level passed to `Log()`.
---@param format string # Format string for the message.
---@vararg any # Optional arguments for formatting the message.
function LogE(mode, level, format, ...)
	if mode < 1 then return end
	local previous = DevMode
	DevMode = mode
	Log(level, format, ...)
	DevMode = previous
end

---Checks if two floating-point numbers are nearly equal within a small epsilon tolerance.
---@param a number # The first value to compare.
---@param b number # The second value to compare.
---@param epsilon number|nil # Optional tolerance. Defaults to 0.0001.
---@return boolean # True if the values are nearly equal.
local function floatEquals(a, b, epsilon)
	epsilon = epsilon or 0.0001
	return math.abs(a - b) < epsilon
end

---Rounds a floating-point number to 3 decimal places and trims unnecessary trailing zeros and dots.
---@param v number # The float value to round.
---@return string # The formatted string representing the rounded float.
local function floatToString(v)
	local str, _ = F("%.3f", v):gsub("0+$", ""):gsub("%.$", "")
	return str
end

---Checks if a string starts with a given prefix.
---@param str string # The string to check.
---@param prefix string # The prefix to match.
---@return boolean # True if `str` starts with `prefix`, false otherwise.
local function strStartsWith(str, prefix)
	if not str or not prefix then return false end
	str, prefix = tostring(str), tostring(prefix)
	return #str >= #prefix and str:sub(1, #prefix) == prefix
end

---Checks if a string ends with a specified suffix.
---@param str string # The string to check.
---@param suffix string # The suffix to look for.
---@return boolean Returns # True if the `str` ends with the specified `suffix`, otherwise false.
local function strEndsWith(str, suffix)
	if not str or not suffix then return false end
	str, suffix = tostring(str), tostring(suffix)
	return #str >= #suffix and str:sub(- #suffix) == suffix
end

---Returns a shortened version of the input string by removing a number of trailing underscore-separated parts.
---The number of parts removed depends on how many underscores are in the string.
---@param str string # The input string (e.g., "v_sport2_porsche_911turbo_player").
---@return string # The shortened string (e.g., "v_sport2_porsche").
local function nameShortenSmart(str)
	str = tostring(str or "")
	local parts = {}

	for part in str:gmatch("[^_]+") do
		table.insert(parts, part)
	end

	local count = #parts
	if count >= 3 then
		count = count - 2
	elseif count >= 2 then
		count = count - 1
	end

	return table.concat(parts, "_", 1, count)
end

---Checks if a given filename string ends with `.lua`.
---@param name string # The value to check, typically a string representing a filename.
---@return boolean # Returns `true` if the filename ends with `.lua`, otherwise `false`.
local function fileIsLua(name)
	if not name then return false end
	name = tostring(name)
	return strEndsWith(name, ".lua")
end

---Returns the file name with a `.lua` extension. If the input already ends with `.lua`, it is returned unchanged.
---@param name string # The input value to be converted to a Lua file name.
---@return string # The file name with `.lua` extension, or an empty string if the input is `nil`.
local function fileWithLuaExt(name)
	if not name then return "" end
	name = tostring(name)
	return fileIsLua(name) and name or name .. ".lua"
end

---Removes the `.lua` extension from a filename if present.
---@param name string # The filename to process.
---@return string # The filename without `.lua` extension, or the original string if no `.lua` extension is found.
local function fileWithoutLuaExt(name)
	if not name then return "" end
	name = tostring(name)
	return fileIsLua(name) and name:gsub("%.lua$", "") or name
end

---Checks whether a given value exists in a sequential table.
---@param tbl table # The table to search through (must be a sequential array).
---@param value any # The value to search for in the table.
---@return boolean # Returns true if the value exists in the table, otherwise false.
local function tblContains(tbl, value)
	if type(tbl) ~= "table" or value == nil then return false end
	for _, v in ipairs(tbl) do
		if v == value then return true end
	end
	return false
end

---Safely retrieves a nested value from a table (e.g., table[one][two][three]).
---Returns a default value if any level is missing or invalid.
---@param tbl table|nil # The root table to access.
---@param fallback any # The fallback value if the lookup fails.
---@param ... string|number # One or more keys representing the path.
---@return any # The nested value if it exists, or the default value.
local function get(tbl, fallback, ...)
	if type(tbl) ~= "table" then return fallback end
	local value = tbl
	for i = 1, select("#", ...) do
		local key = select(i, ...)
		if type(value) ~= "table" or key == nil then
			return fallback
		end
		value = rawget(value, key)
	end
	return value ~= nil and value or fallback
end

---Returns the value at the specified index from a variable list of arguments.
---If the index is beyond the number of available arguments, the last value is returned instead.
---@param i number # The index of the value to retrieve (1-based).
---@param ... any # A variable number of values to select from.
---@return any # The value at index `i`, or the last value if `i` is too large.
local function pick(i, ...)
	local args = { ... }
	return args[i] or args[#args]
end

---Fetches the default rotation pitch value for a vehicle camera.
---@param id string # The preset ID of the vehicle.
---@param path string # The camera path for the vehicle.
---@return number # The default rotation pitch for the given camera path.
local function getCameraDefaultRotationPitch(id, path)
	return TweakDB:GetFlat(F(TWEAKDB_PATH_FORMAT_DRP, id, path)) or 11
end

---Sets the default rotation pitch value for a vehicle camera.
---@param id string # The preset ID of the vehicle.
---@param path string # The camera path for the vehicle.
---@param value number # The value to set for the default rotation pitch.
local function setCameraDefaultRotationPitch(id, path, value)
	local fallback = getCameraDefaultRotationPitch(id, path)
	if not fallback or floatEquals(value, fallback) then
		return
	end
	TweakDB:SetFlat(F(TWEAKDB_PATH_FORMAT_DRP, id, path), value or fallback)
end

---Fetches the current camera offset from TweakDB based on the specified ID and path.
---@param id string # The camera ID.
---@param path string # The camera path to retrieve the offset for.
---@return Vector3|nil # The camera offset as a Vector3.
local function getCameraLookAtOffset(id, path)
	return TweakDB:GetFlat(F(TWEAKDB_PATH_FORMAT_LAO, id, path))
end

---Sets a camera offset in TweakDB to the specified position values.
---@param id string # The camera ID.
---@param path string # The camera path to set the offset for.
---@param x number # The X-coordinate of the camera position.
---@param y number # The Y-coordinate of the camera position.
---@param z number # The Z-coordinate of the camera position.
local function setCameraLookAtOffset(id, path, x, y, z)
	local fallback = getCameraLookAtOffset(id, path)
	if not fallback or (floatEquals(x, fallback.x) and floatEquals(y, fallback.y) and floatEquals(z, fallback.z)) then
		return
	end
	local value = Vector3.new((x or fallback.x), (y or fallback.y), (z or fallback.z))
	TweakDB:SetFlat(F(TWEAKDB_PATH_FORMAT_LAO, id, path), value)
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
		_guiEditorPreset = nil
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

---Attempts to retrieve the name of the specified vehicle.
---@param vehicle Vehicle|nil # The vehicle object to retrieve the name from.
---@return string|nil # The resolved vehicle name as a string, or `nil` if it could not be determined.
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
---@param vehicle Vehicle|nil # The vehicle object to retrieve the appearance name from.
---@return string|nil # The resolved vehicle name as a string, or `nil` if it could not be determined.
local function getVehicleAppearanceName(vehicle)
	if not vehicle then return nil end

	local name = vehicle:GetCurrentAppearanceName()
	if not name then return nil end

	local result = Game.NameToString(name)
	return result
end

---Attempts to find the best matching key in the `_cameraPresets` table using one or more candidate values.
---It first checks for exact matches, and then for prefix-based partial matches.
---@param ... string # One or more strings to match against known preset keys (e.g., vehicle name, appearance name).
---@return string|nil # The matching key from `_cameraPresets`, or `nil` if no match was found.
local function findPresetKey(...)
	for pass = 1, 2 do
		for i = 1, select("#", ...) do
			local search = select(i, ...)
			for key in pairs(_cameraPresets) do
				local exact = pass == 1 and search == key
				local partial = pass == 2 and strStartsWith(search, key)
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
---@param newKey string|nil # The newly entered preset key that should be validated.
---@return string # Returns the validated preset key (without `.lua` extension), or `currentKey` if validation fails.
local function validatePresetKey(vehicleName, appearanceName, currentKey, newKey)
	if type(vehicleName) ~= "string" or
		type(appearanceName) ~= "string" then
		return currentKey
	end
	if type(currentKey) ~= "string" then return vehicleName end
	if type(newKey) ~= "string" then return currentKey end

	local name = fileWithoutLuaExt(newKey)
	local len = #name
	if len < 1 then
		Log(LogLevel.WARN, Text.LOG_BLANK_NAME)
		return currentKey
	end
	if strStartsWith(vehicleName, name) or
		strStartsWith(appearanceName, name) then
		return name
	end
	if vehicleName ~= appearanceName then
		Log(LogLevel.WARN, Text.LOG_NAMES_MISMATCH, vehicleName, appearanceName)
	else
		Log(LogLevel.WARN, Text.LOG_NAME_MISMATCH, vehicleName)
	end
	return currentKey
end

---Retrieves the current camera offset data for the specified camera ID from TweakDB and returns it as a `CameraPreset` table.
---@param id string # The camera ID to query.
---@return CameraPreset|nil # The retrieved camera offset data, or nil if not found.
local function getPreset(id)
	if not id then return nil end

	local preset = { ID = id }
	for i, path in ipairs(TWEAKDB_PATH_LEVELS) do
		local vec3 = getCameraLookAtOffset(id, path)
		if not vec3 or (not vec3.x and not vec3.y and not vec3.z) then return nil end

		local level = CAMERA_LEVELS[(i - 1) % 3 + 1]
		local angle = getCameraDefaultRotationPitch(id, path)

		---@cast preset table<string, OffsetData>
		preset[level] = {
			a = angle,
			x = vec3.x,
			y = vec3.y,
			z = vec3.z
		}

		if preset.Far and preset.Medium and preset.Close then
			if DevMode >= DevLevel.FULL then
				Log(LogLevel.INFO, Text.LOG_CAMERA_OFFSET_COMPLETE, id)
			end
			return preset
		end
	end

	Log(LogLevel.ERROR, Text.LOG_COULD_NOT_RETRIEVE, id)
	return nil
end

---Retrieves the default preset that matches the given preset's camera ID.
---@param preset CameraPreset # The preset to search for a default version.
---@return CameraPreset|nil # Returns the default preset if found, otherwise nil.
local function getDefaultPreset(preset)
	if not preset then return nil end

	local id = preset.ID
	if not id then return nil end

	for _, item in pairs(_cameraPresets) do
		if item.IsDefault and item.ID == id then
			if DevMode >= DevLevel.FULL then
				Log(LogLevel.INFO, Text.LOG_FOUND_DEFAULT, id)
			end
			return item
		end
	end

	Log(LogLevel.ERROR, Text.LOG_MISSING_DEFAULT, id)

	local fallback = getPreset(id)
	if not fallback then return nil end

	fallback.IsDefault = true
	_cameraPresets[id] = fallback
	return fallback
end

---Returns the Y and Z offset values from a preset or its fallback.
---@param preset CameraPreset|nil # The main preset table containing `Close`, `Medium`, or `Far` levels.
---@param fallback CameraPreset|nil # The fallback preset table used if values are missing in the main preset.
---@param level "Close"|"Medium"|"Far" # The level to fetch ("Close", "Medium", or "Far").
---@return number a # The angle value. Falls back to 11 if not found.
---@return number x # The X offset value. Falls back to 0 if not found.
---@return number y # The Y offset value. Falls back to 0 if not found.
---@return number z # The Z offset value. Falls back to a default per level (Close = 1.115, Medium = 1.65, Far = 2.25).
local function getOffsetData(preset, fallback, level)
	if type(preset) ~= "table" or not tblContains(CAMERA_LEVELS, level) then
		Log(LogLevel.ERROR, Text.LOG_NO_PRESET_FOR_LEVEL, level)
		return 0, 0, 0, 0 --Should never be returned with the current code.
	end

	local p = preset[level]
	local f = (fallback and fallback[level]) or {}

	local a = (p and p.a) or f.a or 11
	local x = (p and p.x) or f.x or 0
	local y = (p and p.y) or f.y or 0
	local z = (p and p.z) or f.z or ({ Close = 1.115, Medium = 1.65, Far = 2.25 })[level]

	return a, x, y, z
end

---Applies a camera offset preset to the vehicle by updating values in TweakDB.
---If no `preset` is provided, the preset is looked up automatically based on the mounted vehicle.
---If the preset includes a `Link` field, the function follows the link recursively
---until a final preset is found or the recursion depth limit (8) is reached.
---Missing values in the preset are replaced with fallback values from the default preset, if available.
---Each successfully applied preset ID is recorded in `_modifiedPresets`.
---@param preset CameraPreset|nil # The preset to apply. May be `nil` to auto-resolve via the current vehicle.
---@param count number|nil # Internal recursion counter to prevent infinite loops via `Link`. Do not set manually.
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

		if DevMode >= DevLevel.ALERT then
			Log(LogLevel.INFO, Text.LOG_CAMERA_PRESET, key)
		end

		applyPreset(_cameraPresets[key], 0)
		return
	end

	if preset and preset.Link then
		count = (count or 0) + 1
		if DevMode >= DevLevel.FULL then
			Log(LogLevel.INFO, Text.LOG_LINKED_PRESET, count, preset.Link)
		end
		preset = _cameraPresets[preset.Link]
		if preset and preset.Link and count < 8 then
			applyPreset(preset, count)
			return
		end
	end

	if not preset or not preset.ID then
		Log(LogLevel.ERROR, Text.LOG_FAILED_APPLY)
		return
	end

	local fallback = getDefaultPreset(preset) or {}
	for i, path in ipairs(TWEAKDB_PATH_LEVELS) do
		local level = CAMERA_LEVELS[(i - 1) % 3 + 1]
		local a, x, y, z = getOffsetData(preset, fallback, level)

		setCameraLookAtOffset(preset.ID, path, x, y, z)
		setCameraDefaultRotationPitch(preset.ID, path, a)
	end

	table.insert(_modifiedPresets, preset.ID)
end

---Restores all camera offset presets to their default values.
local function restoreAllPresets()
	for _, preset in pairs(_cameraPresets) do
		if preset.IsDefault then
			applyPreset(preset)
		end
	end
	_modifiedPresets = {}

	Log(LogLevel.INFO, Text.LOG_RESTORED_ALL_DEFAULTS)
end

---Restores modified camera offset presets to their default values.
local function restoreModifiedPresets()
	local changed = _modifiedPresets
	if #changed == 0 then return end

	local amount = #changed
	local restored = 0
	for _, preset in pairs(_cameraPresets) do
		if preset.IsDefault and tblContains(changed, preset.ID) then
			applyPreset(preset)
			Log(LogLevel.INFO, Text.LOG_RESTORED_PRESET, preset.ID)
			restored = restored + 1
		end
		if restored >= amount then break end
	end
	_modifiedPresets = {}

	Log(LogLevel.INFO, Text.LOG_RESTORED_SOME_PRESETS, restored, amount)
end

---Validates whether the given camera offset preset is structurally valid.
---A preset is valid if it either:
---1. Has a string ID and at least one of Close, Medium, or Far contains a numeric `y` or `z` value.
---2. Or: has only a string `Link` and no other keys.
---@param preset CameraPreset # The preset to validate.
---@return boolean # Returns true if the preset is valid, false otherwise.
local function isPresetValid(preset)
	if type(preset) ~= "table" then return false end

	if type(preset.ID) == "string" then
		for _, e in ipairs(CAMERA_LEVELS) do
			local offset = preset[e]
			if type(offset) ~= "table" then
				goto continue
			end
			for _, k in ipairs(OFFSETDATA_KEYS) do
				if type(offset[k]) == "number" then
					return true
				end
			end
			::continue::
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

---Adds, updates, or removes a preset entry in the `_cameraPresets` table.
---@param key string # The key under which the preset is stored (usually the preset name without ".lua").
---@param preset CameraPreset|nil # The preset to store. If `nil`, the existing entry will be removed.
---@return boolean # True if the operation was successful (added, updated or removed), false if the key is invalid or the preset is not valid.
local function setPresetEntry(key, preset)
	if type(key) ~= "string" then return false end

	if preset == nil then
		if _cameraPresets[key] ~= nil then
			_cameraPresets[key] = nil
		end
		return true
	end

	if not isPresetValid(preset) then return false end

	_cameraPresets[key] = preset
	return true
end

---Clears all currently loaded camera offset presets.
local function purgePresets()
	_cameraPresets = {}
	Log(LogLevel.WARN, Text.LOG_CLEARED_PRESETS)
end

---Loads camera offset presets from `./defaults/` (first) and `./presets/` (second).
---Each `.lua` file must return a `CameraPreset` table with at least an `ID` field.
---Skips already loaded presets unless `refresh` is true (then clears and reloads all).
---@param refresh boolean|nil — If true, clears existing presets before loading (default: false).
local function loadPresets(refresh)
	local function loadFrom(path)
		local files = dir("./" .. path)
		if not files then
			LogE(DevLevel.FULL, LogLevel.ERROR, Text.LOG_DIR_NOT_EXISTS, path)
			return -1
		end

		local count = 0
		for _, file in ipairs(files) do
			local name = file.name
			if not name or not fileIsLua(name) then goto continue end

			local key = name:sub(1, -5)
			if _cameraPresets[key] then
				count = count + 1
				Log(LogLevel.WARN, Text.LOG_SKIPPED_PRESET, key, path, name)
				goto continue
			end

			local chunk, err = loadfile(path .. "/" .. name)
			if not chunk then
				LogE(DevLevel.BASIC, LogLevel.ERROR, Text.LOG_FAILED_TO_LOAD_PRESET, path, name, err)
				goto continue
			end

			local ok, result = pcall(chunk)
			if ok and setPresetEntry(key, result) then
				count = count + 1
				Log(LogLevel.INFO, Text.LOG_LOADED_PRESET, key, path, name)
				goto continue
			end

			LogE(DevLevel.BASIC, LogLevel.ERROR, Text.LOG_INVALID_PRESET, path, name)

			::continue::
		end

		return count
	end

	if refresh then
		purgePresets()
	end

	if loadFrom("defaults") < 38 then
		_isEnabled = false
		LogE(DevLevel.FULL, LogLevel.ERROR, Text.LOG_DEFAULTS_INCOMPLETE)
		return
	end

	_isEnabled = loadFrom("presets") >= 0
end

---Saves a camera preset to file, either as a regular preset or as a default.
---It serializes only values that differ from the default (unless saving as default).
---@param name string # The name of the preset file (with or without `.lua` extension).
---@param preset table # The preset data to save (must include an `ID` and valid offset data).
---@param allowOverwrite boolean|nil # Whether existing files may be overwritten.
---@param saveAsDefault boolean|nil # If true, saves the preset to the `./defaults/` directory instead of `./presets/`.
---@return boolean # Returns `true` on success, or `false` if writing failed or nothing needed to be saved.
local function savePreset(name, preset, allowOverwrite, saveAsDefault)
	if type(name) ~= "string" or type(preset) ~= "table" then return false end

	local path = (saveAsDefault and "defaults/" or "presets/") .. fileWithLuaExt(name)
	if not allowOverwrite then
		local check = io.open(path, "r")
		if check then
			check:close()
			Log(LogLevel.WARN, Text.LOG_FILE_EXISTS, path)
			return false
		end
	end

	local default = getDefaultPreset(preset) or {}
	local save = false
	local parts = { "return{" }
	table.insert(parts, F("ID=%q,", preset.ID))
	for _, mode in ipairs(CAMERA_LEVELS) do
		local p = preset[mode]
		local d = default[mode]
		local sub = {}

		if type(p) == "table" then
			d = type(d) == "table" and d or {}
			for _, k in ipairs(OFFSETDATA_KEYS) do
				if saveAsDefault or not floatEquals(p[k], d[k]) then
					save = true
					table.insert(sub, F("%s=%s", k, floatToString(p[k])))
				end
			end
		end

		if #sub > 0 then
			table.insert(parts, F("%s={%s},", mode, table.concat(sub, ",")))
		end
	end

	if not save then
		Log(LogLevel.WARN, Text.LOG_PRESET_NOT_CHANGED, name, default.ID)
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

---Retrieves the available content width and calculates dynamic padding for UI alignment.
---If padding changes are locked, returns the last used padding.
---@return number width # The available content width inside the current window.
---@return number padding # The calculated horizontal padding for centering elements.
local function getMetrics()
	local width = ImGui.GetContentRegionAvail()
	if _guiLockPadding then return width, _guiPadding end
	local style = ImGui.GetStyle()
	_guiPadding = math.max(10, math.floor((width - 230) * 0.5 + 18) - style.ItemSpacing.x)
	return width, _guiPadding
end

---Adjusts an ABGR color by modifying its blue, green, and red (weird order in LUA) components.
---The alpha channel remains unchanged. Component values are clamped to 255.
---@param col integer # The input color in 0xAARRGGBB format.
---@param db integer # Amount to add to the blue channel.
---@param dg integer # Amount to add to the green channel.
---@param dr integer # Amount to add to the red channel.
---@return integer # The resulting adjusted color in 0xAARRGGBB format.
local function adjustColor(col, db, dg, dr)
	if type(col) ~= "number" or type(db) ~= "number" or type(dg) ~= "number" or type(dr) ~= "number" then return 0 end
	local a = bit32.band(bit32.rshift(col, 24), 0xff)
	local b = math.min(0xff, bit32.band(bit32.rshift(col, 16), 0xff) + db)
	local g = math.min(0xff, bit32.band(bit32.rshift(col, 8), 0xff) + dg)
	local r = math.min(0xff, bit32.band(col, 0xff) + dr)
	return bit32.bor(bit32.lshift(a, 24), bit32.lshift(b, 16), bit32.lshift(g, 8), r)
end

---Generates three color variants from a base color for use in UI styling (e.g., normal, hovered, active).
---Each subsequent variant increases brightness slightly on BGR channels.
---@param base integer # The base color in 0xAAGGBBRR format.
---@return integer, integer, integer # Returns three color variants: base, hover, and active.
local function getThreeColorsFrom(base)
	local hover = adjustColor(base, 32, 32, 32)
	local active = adjustColor(base, 64, 64, 64)
	return base, hover, active
end

---Pushes a set of three related style colors to ImGui's style stack: base, hovered, and active.
---Calculated automatically from a single base color by brightening B, G, and R channels.
---Returns the number of pushed styles so they can be popped accordingly.
---@param idx integer # The ImGuiCol index for the base color (e.g. ImGuiCol.FrameBg or ImGuiCol.Button).
---@param color integer # The base color in 0xAAGGBBRR format.
---@return integer # The number of style colors pushed (atm always 3). Returns 0 if arguments are invalid.
local function pushStyleColors(idx, color)
	if type(idx) ~= "number" or type(color) ~= "number" then return 0 end
	local hoveredIdx = idx + 1
	local activeIdx = idx + 2
	local base, hover, active = getThreeColorsFrom(color)
	ImGui.PushStyleColor(idx, base)
	ImGui.PushStyleColor(hoveredIdx, hover)
	ImGui.PushStyleColor(activeIdx, active)
	return 3
end

---Displays a tooltip when the current UI item is hovered.
---@param text string # Text to display in the tooltip.
local function addTooltip(text)
	if not ImGui.IsItemHovered() or type(text) ~= "string" then return end
	ImGui.BeginTooltip()
	ImGui.PushTextWrapPos(420)
	ImGui.Text(text)
	ImGui.PopTextWrapPos()
	ImGui.EndTooltip()
end

--This event is triggered when the CET environment initializes for a particular game session.
registerForEvent("onInit", function()
	--Save default presets.
	--[[
	local defaults = {
		"4w_911"
	}
	for _, value in ipairs(defaults) do
		local preset = getPreset(value)
		preset.IsDefault = true
		if preset then
			savePreset(preset.ID, preset, true, true)
		end
	end
	--]]

	--Load all saved presets from disk.
	loadPresets(true)

	--This step is mainly necessary here in case all mods are reloaded while the player is already inside a vehicle.
	applyPreset()

	--When the player mounts a vehicle, automatically apply the matching camera preset if available.
	--This event can fire even if the player is already mounted, so we guard with `_isVehicleMounted`.
	Observe("VehicleComponent", "OnMountingEvent", function()
		if not _isEnabled or _isVehicleMounted then return end
		_guiEditorPreset = nil
		applyPreset()
	end)

	--When the player unmounts from a vehicle, reset to default camera offsets.
	Observe("VehicleComponent", "OnUnmountingEvent", function()
		if not _isEnabled then return end
		_isVehicleMounted = false
		_guiEditorPreset = nil
		restoreModifiedPresets()
	end)

	--Reset the current editor state when the player takes control of their character
	--(usually after loading a save game). This ensures UI does not persist stale data.
	Observe("PlayerPuppet", "OnTakeControl", function(self)
		if not _isEnabled or self:GetEntityID().hash ~= 1 then return end
		_isVehicleMounted = false
		_guiEditorPreset = nil
		_guiEditorUnsavedChanges = {}
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

--Display a simple GUI with some options.
registerForEvent("onDraw", function()
	--Main window begins
	if not _isOverlayOpen or not ImGui.Begin(Text.GUI_TITLE, ImGuiWindowFlags.AlwaysAutoResize) then return end

	--Minimum window width and height padding.
	ImGui.Dummy(230, 4)

	--Retrieves the available content width and the dynamically calculated control padding for UI element alignment.
	local contentWidth, controlPadding = getMetrics()

	--Checkbox to toggle mod functionality and handle enable/disable logic.
	ImGui.Dummy(controlPadding, 0)
	ImGui.SameLine()
	local isEnabled = ImGui.Checkbox(Text.GUI_MOD_TOGGLE, _isEnabled)
	addTooltip(Text.GUI_MOD_TOGGLE_TOOLTIP)
	if isEnabled ~= _isEnabled then
		_isEnabled = isEnabled
		_guiEditorPreset = nil
		_guiEditorUnsavedChanges = {}
		if isEnabled then
			loadPresets()
			applyPreset()
			LogE(DevLevel.ALERT, LogLevel.INFO, Text.LOG_MOD_ENABLED)
		else
			restoreAllPresets()
			purgePresets()
			LogE(DevLevel.ALERT, LogLevel.INFO, Text.LOG_MOD_DISABLED)

			--Mod is disabled — nothing left to add.
			ImGui.End()
			return
		end
	end
	ImGui.Dummy(0, 2)

	--The button that reloads all presets.
	ImGui.Dummy(controlPadding, 0)
	ImGui.SameLine()
	if ImGui.Button(Text.GUI_PRESETS_RELOAD, 192, 24) then
		_guiEditorPreset = nil
		_guiEditorUnsavedChanges = {}
		loadPresets(true)
		restoreAllPresets()
		applyPreset()
		LogE(DevLevel.ALERT, LogLevel.INFO, Text.LOG_PRESETS_RELOADED)
	end
	addTooltip(Text.GUI_PRESETS_RELOAD_TOOLTIP)
	ImGui.Dummy(0, 2)

	--Slider to set the developer mode level.
	ImGui.Dummy(controlPadding, 0)
	ImGui.SameLine()
	ImGui.PushItemWidth(77)
	DevMode = ImGui.SliderInt(Text.GUI_DEVMODE, DevMode, DevLevel.DISABLED, DevLevel.FULL)
	_guiLockPadding = ImGui.IsItemActive()
	addTooltip(Text.GUI_DEVMODE_TOOLTIP)
	ImGui.PopItemWidth()
	ImGui.Dummy(0, 8)

	--Table showing vehicle name, camera ID and more — if certain conditions are met.
	local vehicle, name, appName, id
	for _, fn in ipairs({
		function()
			return DevMode > DevLevel.DISABLED
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
		end
	}) do
		if not fn() then
			--Condition not met — GUI closed.
			ImGui.End()
			return
		end
	end

	local presetKey
	if ImGui.BeginTable("InfoTable", 2, ImGuiTableFlags.Borders) then
		ImGui.TableSetupColumn(Text.GUI_TABLE_HEADER_KEY, ImGuiTableColumnFlags.WidthFixed, -1)
		ImGui.TableSetupColumn(Text.GUI_TABLE_HEADER_VALUE, ImGuiTableColumnFlags.WidthStretch)
		ImGui.TableHeadersRow()

		presetKey = name == appName and findPresetKey(name) or findPresetKey(name, appName)
		if not _guiEditorPreset then
			_guiEditorPresetDef = nil
			_guiEditorPresetName = nil
		end

		local dict = {
			{ key = Text.GUI_TABLE_LABEL_VEHICLE,    value = name },
			{ key = Text.GUI_TABLE_LABEL_APPEARANCE, value = appName },
			{ key = Text.GUI_TABLE_LABEL_CAMERAID,   value = id },
			{ key = Text.GUI_TABLE_LABEL_PRESET,     value = presetKey or id },
			{ key = Text.GUI_TABLE_LABEL_IS_DEFAULT, value = presetKey == nil and Text.GUI_TRUE or Text.GUI_FALSE }
		}
		for _, item in ipairs(dict) do
			ImGui.TableNextRow()
			ImGui.TableSetColumnIndex(0)
			ImGui.Text(item.key)

			local text = item.value or Text.GUI_NONE
			ImGui.TableSetColumnIndex(1)
			if item.key == Text.GUI_TABLE_LABEL_PRESET then
				local rawValue = _guiEditorPresetName or text
				local extValue = fileWithLuaExt(rawValue)

				local width = ImGui.CalcTextSize(extValue) + 8
				ImGui.PushItemWidth(width)

				local isNotDefault = rawValue ~= id
				local pushedStyles = 0
				if isNotDefault then
					pushedStyles = pushStyleColors(ImGuiCol.FrameBg, 0xff505020)
				end

				local newValue, changed = ImGui.InputText("##Preset", extValue, 96)
				if changed and newValue then
					_guiEditorPresetName = newValue
				end

				if pushedStyles > 0 then
					ImGui.PopStyleColor(pushedStyles)
				end

				addTooltip(F(Text.GUI_TABLE_VALUE_PRESET_TOOLTIP, isNotDefault and extValue or fileWithLuaExt(name), name,
				appName, nameShortenSmart(name), nameShortenSmart(appName)))

				ImGui.PopItemWidth()
			else
				ImGui.Text(tostring(text))
			end
		end

		ImGui.EndTable()
	end

	--Camera preset editor allowing adjustments to Angle, X, Y, and Z coordinates — if certain conditions are met.
	local preset = _guiEditorPreset or getPreset(id)
	if not preset then
		Log(LogLevel.WARN, Text.LOG_NO_PRESET_FOUND)

		--GUI closed — no further controls required.
		ImGui.End()
		return
	end
	if not _guiEditorPreset then
		_guiEditorPreset = preset
	end

	local original = _guiEditorPresetDef or getDefaultPreset(preset)
	if not original then
		Log(LogLevel.ERROR, Text.LOG_NO_ORIGINAL_PRESET, id, name)

		--GUI ends early — original preset not found.
		ImGui.End()
		return
	end
	if not _guiEditorPresetDef then
		_guiEditorPresetDef = original
	end

	if ImGui.BeginTable("CameraOffsetEditor", 5, ImGuiTableFlags.Borders) then
		local labels = {
			Text.GUI_TABLE_HEADER_LEVEL,
			Text.GUI_TABLE_HEADER_ANGLE,
			Text.GUI_TABLE_HEADER_X,
			Text.GUI_TABLE_HEADER_Y,
			Text.GUI_TABLE_HEADER_Z
		}
		for i, label in ipairs(labels) do
			local flag = i < 3 and ImGuiTableColumnFlags.WidthFixed or ImGuiTableColumnFlags.WidthStretch
			ImGui.TableSetupColumn(label, flag, -1)
		end
		ImGui.TableHeadersRow()

		local tooltips = {
			Text.GUI_TABLE_VALUE_ANGLE_TOOLTIP,
			Text.GUI_TABLE_VALUE_X_TOOLTIP,
			Text.GUI_TABLE_VALUE_Y_TOOLTIP,
			Text.GUI_TABLE_VALUE_Z_TOOLTIP
		}
		for _, level in ipairs(CAMERA_LEVELS) do
			local data = preset[level]
			if type(data) ~= "table" then goto continue end

			ImGui.TableNextRow()
			ImGui.TableSetColumnIndex(0)
			ImGui.Text(level)

			for i, field in ipairs(OFFSETDATA_KEYS) do
				local orgValue = get(original, 0, level, field)
				local curValue = get(data, orgValue, field)
				local speed = pick(i, 1, 0.005)
				local min = pick(i, -45, -5, -10, 0)
				local max = pick(i, 90, 5, 10, 32)
				local format = pick(i, "%.0f", "%.3f")

				ImGui.TableSetColumnIndex(i)
				ImGui.PushItemWidth(-1)

				local isNotDefault = not floatEquals(orgValue, curValue)
				local pushedStyles = 0
				if isNotDefault then
					pushedStyles = pushStyleColors(ImGuiCol.FrameBg, 0xff505020)
				end

				local newValue = ImGui.DragFloat(F("##%s_%s", level, field), curValue, speed, min, max, format)
				if newValue ~= curValue then
					_guiEditorUnsavedChanges[name] = true
					data[field] = math.min(math.max(newValue, min), max)
				end

				if pushedStyles > 0 then
					ImGui.PopStyleColor(pushedStyles)
				end

				local tip = tooltips[i]
				if tip then
					addTooltip(F(tip, min, max))
				end

				ImGui.PopItemWidth()
			end

			::continue::
		end

		ImGui.EndTable()
		ImGui.Dummy(0, 1)
	end

	--The validated preset key, required for the apply and save buttons.
	local validKey = validatePresetKey(name, appName, presetKey or name, _guiEditorPresetName)

	--Button to apply previously configured values in-game.
	if ImGui.Button(Text.GUI_PRESET_APPLY, contentWidth, 24) then
		_cameraPresets[validKey] = preset
		_guiEditorPresetName = validKey
		LogE(DevLevel.ALERT, LogLevel.INFO, Text.LOG_PRESET_UPDATED, validKey)
	end
	addTooltip(Text.GUI_PRESET_APPLY_TOOLTIP)
	ImGui.Dummy(0, 1)

	--Button to save configured values to a file for future automatic use.
	local pushedStyles = 0
	if _guiEditorUnsavedChanges[name] then
		pushedStyles = pushStyleColors(ImGuiCol.Button, 0xff204050)
	end
	if ImGui.Button(Text.GUI_PRESET_SAVE, contentWidth, 24) then
		if savePreset(validKey, preset, _guiEditorAllowOverwrite) then
			_guiEditorUnsavedChanges[name] = nil
			_guiEditorAllowOverwrite = false
			_cameraPresets[validKey] = preset
			_guiEditorPresetName = validKey
			LogE(DevLevel.ALERT, LogLevel.INFO, Text.LOG_PRESET_SAVED, validKey)
		else
			LogE(DevLevel.ALERT, LogLevel.WARN, Text.LOG_PRESET_NOT_SAVED, validKey)
		end
	end
	if pushedStyles > 0 then
		ImGui.PopStyleColor(pushedStyles)
	end
	addTooltip(F(Text.GUI_PRESET_SAVE_TOOLTIP, validKey))
	ImGui.Dummy(0, 2)

	--Checkbox to toggle allowing file overwrites.
	ImGui.Dummy(controlPadding, 0)
	ImGui.SameLine()
	_guiEditorAllowOverwrite = ImGui.Checkbox(Text.GUI_ALLOW_OVERWRITE, _guiEditorAllowOverwrite)
	addTooltip(Text.GUI_ALLOW_OVERWRITE_TOOLTIP)
	ImGui.Dummy(0, 2)

	--Button to open Preset File Manager
	local x, y, w, h
	ImGui.Separator()
	ImGui.Dummy(0, 2)
	if ImGui.Button(Text.GUI_PRESET_MANAGER, contentWidth, 24) then
		x, y = ImGui.GetWindowPos()
		w, h = ImGui.GetWindowSize()
		_fileManToggle = not _fileManToggle
	end
	ImGui.Dummy(0, 2)

	--GUI creation of Main window is complete.
	ImGui.End()

	--Preset File Manager window
	if not _fileManToggle then return end

	local files = dir("./presets")
	if not files then
		_fileManToggle = false
		LogE(DevLevel.FULL, LogLevel.ERROR, Text.LOG_DIR_NOT_EXISTS, "presets")
		return
	end

	if x and y and w and h then
		ImGui.SetNextWindowPos(x, y)
		ImGui.SetNextWindowSize(w, h)
	end

	local flags = bit32.bor(ImGuiWindowFlags.NoCollapse, ImGuiWindowFlags.NoResize, ImGuiWindowFlags.NoMove)
	_fileManToggle = ImGui.Begin(Text.GUI_FMAN_TITLE, _fileManToggle, flags)
	if not _fileManToggle then return end

	local anyFiles = false
	if ImGui.BeginTable("PresetFilesTable", 2, ImGuiTableFlags.Borders) then
		ImGui.TableSetupColumn(Text.GUI_FMAN_HEADER_NAME, ImGuiTableColumnFlags.WidthStretch)
		ImGui.TableSetupColumn(Text.GUI_FMAN_HEADER_ACTIONS, ImGuiTableColumnFlags.WidthFixed)
		ImGui.TableHeadersRow()

		for _, file in ipairs(files) do
			name = file.name
			if not fileIsLua(name) then goto continue end

			anyFiles = true

			ImGui.TableNextRow()
			ImGui.TableSetColumnIndex(0)

			local columnWidth = ImGui.GetColumnWidth(0) - 4
			local textWidth = ImGui.CalcTextSize(name)
			if columnWidth < textWidth then
				local short = name
				local dots = "..."
				local cutoff = columnWidth - ImGui.CalcTextSize(dots)
				while #short > 0 and ImGui.CalcTextSize(short) > cutoff do
					short = string.sub(short, 1, -2)
				end
				ImGui.Text(short .. dots)
				addTooltip(name)
			else
				ImGui.Text(name)
			end

			ImGui.TableSetColumnIndex(1)
			if ImGui.Button(F(Text.GUI_FMAN_DELETE_BUTTON, name)) then
				ImGui.OpenPopup("ConfirmDelete_" .. name)
			end

			if ImGui.BeginPopup("ConfirmDelete_" .. name) then
				ImGui.Text(F(Text.GUI_FMAN_DELETE_CONFIRM, name))
				ImGui.Dummy(0, 2)
				ImGui.Separator()
				ImGui.Dummy(0, 2)
				local pushedStyles = pushStyleColors(ImGuiCol.Button, 0xff202050)
				if ImGui.Button(Text.GUI_YES, 80, 30) then
					local ok = os.remove("presets/" .. name)
					if ok then
						local key = fileWithoutLuaExt(name)
						setPresetEntry(key, nil)
						LogE(DevLevel.ALERT, LogLevel.INFO, Text.LOG_DELETE_SUCCESS, name)
					else
						LogE(DevLevel.ALERT, LogLevel.WARN, Text.LOG_DELETE_FAILURE, name)
					end
					ImGui.CloseCurrentPopup()
				end
				if pushedStyles > 0 then
					ImGui.PopStyleColor(pushedStyles)
				end
				ImGui.SameLine()
				if ImGui.Button(Text.GUI_NO, 80, 30) then
					ImGui.CloseCurrentPopup()
				end
				ImGui.EndPopup()
			end

			::continue::
		end

		ImGui.EndTable()
	end

	if not anyFiles then
		ImGui.Dummy(0, 180)
		ImGui.Dummy(controlPadding - 4, 0)
		ImGui.SameLine()
		ImGui.PushStyleColor(ImGuiCol.Text, 0xff6060dd)
		ImGui.Text(Text.GUI_FMAN_NO_PRESETS)
		ImGui.PopStyleColor()
	end

	--GUI creation of Preset File Manager window is complete.
	ImGui.End()
end)

--Restores default camera offsets for vehicles upon mod shutdown.
registerForEvent("onShutdown", function()
	restoreAllPresets()
end)
