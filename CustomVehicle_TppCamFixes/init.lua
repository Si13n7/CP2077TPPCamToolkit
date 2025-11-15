--[[
==============================================
This file is distributed under the MIT License
==============================================

Custom Vehicle - TPP Camera Fixes

Adjusts third-person perspective (TPP) camera
offsets for specific custom vehicles.
----------------------------------------------

Filename: init.lua
Version: 2025-03-31, 12:31 UTC+01:00 (MEZ)

Copyright (c) 2025, Si13n7 Developments(tm)
All rights reserved.
______________________________________________
--]]



--[[====================================================
		STANDARD DEFINITIONS FOR INTELLISENSE
=======================================================]]


--- ImGui Definition
---@class ImGui
--- Provides functions to create graphical user interface elements within the Cyber Engine Tweaks overlay.
---@field Begin fun(title: string, flags?: number): boolean -- Begins a new ImGui window with optional flags. Must be closed with `ImGui.End()`. Returns `true` if the window is open and should be rendered.
---@field End fun(): nil -- Ends the creation of the current ImGui window. Must always be called after `ImGui.Begin()`.
---@field Dummy fun(width: number, height: number): nil -- Creates an invisible element of specified width and height, useful for spacing.
---@field SameLine fun(offsetX?: number, spacing?: number): nil -- Places the next UI element on the same line. Optionally adds horizontal offset and spacing.
---@field PushItemWidth fun(width: number): nil -- Sets the width of the next UI element (e.g., slider, text input).
---@field PopItemWidth fun(): nil -- Resets the width of the next UI element to the default value.
---@field Text fun(text: string): nil -- Displays text within the current window or tooltip.
---@field Button fun(label: string, width?: number, height?: number): boolean -- Creates a clickable button with optional width and height. Returns true if the button was clicked.
---@field Checkbox fun(label: string, value: boolean): (boolean, boolean) -- Creates a toggleable checkbox. Returns `changed` (true if state has changed) and `value` (the new state).
---@field SliderInt fun(label: string, value: number, min: number, max: number): number -- Creates an integer slider. Returns the new `value`.
---@field SliderFloat fun(label: string, value: number, min: number, max: number): number -- Creates a float slider that allows users to select a value between a specified minimum and maximum. Returns the updated float value.
---@field IsItemHovered fun(): boolean -- Returns true if the last item is hovered by the mouse cursor.
---@field BeginTooltip fun(): nil -- Begins creating a tooltip. Must be paired with `ImGui.EndTooltip()`.
---@field EndTooltip fun(): nil -- Ends the creation of a tooltip. Must be called after `ImGui.BeginTooltip()`.
---@field BeginTable fun(id: string, columns: number, flags?: number): boolean -- Begins a table with the specified number of columns. Returns `true` if the table is created successfully and should be rendered.
---@field TableSetupColumn fun(label: string, flags?: number, init_width_or_weight?: number): nil -- Defines a column in the current table with optional flags and initial width or weight.
---@field TableHeadersRow fun(): nil -- Automatically creates a header row using column labels defined by `TableSetupColumn()`. Must be called right after defining the columns.
---@field TableNextRow fun(): nil -- Advances to the next row of the table. Must be called between rows.
---@field TableSetColumnIndex fun(index: number): nil -- Moves the focus to a specific column index within the current table row.
---@field EndTable fun(): nil -- Ends the creation of the current table. Must always be called after `ImGui.BeginTable()`.
---@field GetWindowSize fun(): number -- Returns the current width of the window as a floating-point number.
---@field CalcTextSize fun(text: string): number -- Calculates the width of a given text string as it would be displayed using the current font. Returns the width in pixels as a floating-point number.
ImGui = ImGui

--- ImGuiWindowFlags Definition
---@class ImGuiWindowFlags
---@field AlwaysAutoResize number -- Automatically resizes the window to fit its content each frame.
ImGuiWindowFlags = ImGuiWindowFlags

--- ImGuiTableFlags Definition
---@class ImGuiTableFlags
--- Flags to customize table behavior and appearance.
---@field Borders number -- Draws borders between cells.
ImGuiTableFlags = ImGuiTableFlags

--- ImGuiTableColumnFlags Definition
---@class ImGuiTableColumnFlags
--- Flags to customize individual columns within a table.
---@field WidthFixed number -- Makes the column have a fixed width.
---@field WidthStretch number -- Makes the column stretch to fill available space.
ImGuiTableColumnFlags = ImGuiTableColumnFlags

--- TweakDB Definition
---@class TweakDB
--- Provides access to game data stored in the database, including camera offsets and various other game settings.
---@field GetFlat fun(self: TweakDB, key: string): Vector3|nil -- Retrieves a value from the database based on the provided key.
---@field SetFlat fun(self: TweakDB, key: string, value: Vector3) -- Sets or modifies a value in the database for the specified key.
TweakDB = TweakDB

--- Game Definition
---@class Game
--- Provides various global game functions, such as getting the player, mounted vehicles, and converting names to strings.
---@field NameToString fun(value: any): string -- Converts a game name object to a readable string.
---@field GetPlayer fun(): Player|nil -- Retrieves the current player instance if available.
---@field GetMountedVehicle fun(player: Player): Vehicle|nil -- Returns the vehicle the player is currently mounted in, if any.
Game = Game

--- Player Definition
---@class Player -- Represents the player character in the game, providing functions to interact with the player instance.
---@field SetWarningMessage fun(self: Player, message: string, duration: number): nil -- Displays a warning message on the player's screen for a specified duration.
Player = Player

--- Vehicle Definition
---@class Vehicle
--- Represents a vehicle entity within the game, providing functions to interact with it, such as getting the appearance name.
---@field GetCurrentAppearanceName fun(self: Vehicle): string|nil -- Retrieves the current appearance name of the vehicle.
---@field GetRecordID fun(self: Vehicle): any -- Returns the unique TweakDBID associated with the vehicle.
Vehicle = Vehicle

--- Vector3 Definition
---@class Vector3
--- Represents a three-dimensional vector, commonly used for positions or directions in the game.
---@field x number -- The X-coordinate.
---@field y number -- The Y-coordinate.
---@field z number -- The Z-coordinate.
---@field new fun(x: number, y: number, z: number): Vector3 -- Creates a new Vector3 instance with specified x, y, and z coordinates.
Vector3 = Vector3

--- Observe Definition
---@class Observe
--- Provides functionality to observe game events, allowing custom functions to be executed when certain events occur.
---@field Observe fun(className: string, functionName: string, callback: fun(...): nil) -- Sets up an observer for a specified function within the game.
Observe = Observe

--- registerForEvent Definition
---@class registerForEvent
--- Allows the registration of functions to be executed when certain game events occur, such as initialization or shutdown.
---@field registerForEvent fun(eventName: string, callback: fun(...): nil) -- Registers a callback function for a specified event (e.g., 'onInit', 'onShutdown').
registerForEvent = registerForEvent

--- spdlog Definition
---@class spdlog
--- Provides logging functionality, allowing messages to be printed to the console or log files for debugging purposes.
---@field error fun(message: string) -- Logs an error message, usually when something goes wrong.
spdlog = spdlog

--- dir Definition
---@class dir
--- Retrieves a list of files and folders from a specified directory.
---@return table -- Returns a table containing information about each file and folder within the directory.
dir = dir



--[[====================================================
						MOD START
=======================================================]]

---@type string
-- The window title.
local _title = "Custom Vehicle - TPP Camera Fixes"

---@type boolean
-- Determines whether the CET overlay is open.
local _isOverlayOpen = false

---@type boolean
-- Determines whether the mod is enabled.
local _isEnabled = true

---@type number
-- The current debug mode level controlling logging and alerts:
-- 0 = Disabled; 1 = Alert; 2 = Alert, and Print; 3 = Alert,
-- Print, and Log
local _devMode = 0

---@type CameraOffsetPreset|nil
---The preset currently being edited.
local _currentEntryEdit = nil

---@type table<string, CameraOffsetPreset>|nil
---Includes copies of the original camera presets for comparison with editing presets.
local _originalEntries = nil

---@type string
-- The template string for accessing camera lookAtOffset values in TweakDB.
local _cameraPathTemplate = "Camera.VehicleTPP_%s_%s.lookAtOffset"

---@type string|nil
-- The currently mounted vehicle name.
local _mountedVehicleName = nil

---@type table<string>|nil
---The default camera IDs used for preloading.
local _defaultVehicleCamIDs = {
	"2w_Preset",
	"4w_911",
	"4w_Alvarado_Preset",
	"4w_Archer_Hella",
	"4w_Archer_Quartz",
	"4w_BMF",
	"4w_Columbus",
	"4w_Cortes_Preset",
	"4w_Galena",
	"4w_Galena_Nomad",
	"4w_Hozuki",
	"4w_Limo_Thrax",
	"4w_Mahir_Supron_Kurtz",
	"4w_Makigai",
	"4w_Medium_Preset",
	"4w_Quadra66",
	"4w_Quadra66_Nomad",
	"4w_Quadra",
	"4w_Shion",
	"4w_Shion_Nomad",
	"4w_SubCompact_Preset",
	"4w_Tanishi",
	"4w_Thorton_Colby",
	"4w_Thorton_Colby_Pickup",
	"4w_Thorton_Colby_Pickup_Kurtz",
	"4w_Truck_Preset",
	"4w_aerondight",
	"4w_caliburn",
	"4w_herrera_outlaw",
	"4w_herrera_riptide",
	"4w_mizutani_Preset",
	"Default_Preset",
	"v_standard25_mahir_supron_CameraPreset",
	"v_utilitruck4_mainh_supron_CameraPreset",
	"v_utility4_kaukaz_bratsk_Preset",
	"v_utility4_kaukaz_zenya_Preset",
	"v_utility4_zeya_behemoth_Preset",
	"v_militech_basilisk_CameraPreset"
}

---@class CameraOffsetPreset
---@field ID string|nil -- The camera ID used for the vehicle.
---@field Close table|nil -- The Y-offset for close camera view.
---@field Medium table|nil -- The Y-offset for medium camera view.
---@field Far table|nil -- The Y-offset for far camera view.
---@field Link string|nil -- The name of another vehicle appearance to link to (if applicable).
---@field Shutdown boolean|nil -- Whether to reset to default camera offsets on shutdown.
---@type table<string, CameraOffsetPreset>
---Contains all camera presets and linked vehicles.
local _cameraOffsetPresets = {}

---@type string[]
-- Paths corresponding to different camera positions.
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

---@param msg string -- The message to display to the player.
---@param secs number|nil -- The duration in seconds for which the message is displayed.
---Displays a warning message to the player for a specified duration using the 'SetWarningMessage' function.
local function alert(msg, secs)
	if not msg then return end

	local player = Game.GetPlayer()
	if player then
		player:SetWarningMessage(msg, secs or 5)
	end
end

---@param format string -- The format string for the message.
---@vararg any -- Additional arguments for formatting the message.
---Logs and displays messages based on the current `_devMode` level. Messages can be logged to the console, printed, or shown as alerts.
local function write(format, ...)
	if _devMode <= 0 then return end

	local msg = "[CVTPPCF] " .. format
	local args = { ... }
	if #args > 0 then
		for i = 1, #args do
			args[i] = tostring(args[i])
		end
		msg = string.format(msg, table.unpack(args))
	end

	if _devMode >= 3 then spdlog.error(msg) end
	if _devMode >= 2 then print(msg) end
	if _devMode >= 1 then alert(msg) end
end

---Creates a deep copy of a table, including all nested tables.
---@param original table -- The table to copy.
---@return table -- A deep copy of the original table.
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

---@param str string    -- The string to check.
---@param prefix string -- The prefix to look for.
---@return boolean      -- True if the string starts with the prefix, false otherwise.
---Checks if a given string begins with the specified prefix.
local function stringStartsWith(str, prefix)
	return #prefix <= #str and str:sub(1, #prefix) == prefix
end

--- Checks if a string ends with a specified suffix.
---@param str string The string to check.
---@param suffix string The suffix to look for.
---@return boolean Returns true if the string ends with the specified suffix, otherwise false.
local function stringEndsWith(str, suffix)
	return #suffix <= #str and str:sub(- #suffix) == suffix
end

---@param id string -- The camera ID.
---@param path string -- The camera path to retrieve the offset for.
---@return Vector3|nil -- The camera offset as a Vector3.
---Fetches the current camera offset from 'TweakDB' based on the specified ID and path.
local function getCameraLookAtOffset(id, path)
	return TweakDB:GetFlat(string.format(_cameraPathTemplate, id, path))
end

---@param id string -- The camera ID.
---@param path string -- The camera path to set the offset for.
---@param x number -- The X-coordinate of the camera position.
---@param y number -- The Y-coordinate of the camera position.
---@param z number -- The Z-coordinate of the camera position.
---Sets a camera offset in 'TweakDB' to the specified position values.
local function setCameraLookAtOffset(id, path, x, y, z)
	TweakDB:SetFlat(string.format(_cameraPathTemplate, id, path), Vector3.new(x, y, z))
end

---@param id string -- The camera ID.
---@param path string -- The camera path to update.
---@param y number -- The new Y-coordinate value.
---@param z number|nil -- The optional Z-coordinate value.
---Updates the Y (and optionally Z) offset of a camera path in 'TweakDB'.
local function setCameraLookAtOffsetYZ(id, path, y, z)
	local vec3 = getCameraLookAtOffset(id, path)
	if vec3 then
		setCameraLookAtOffset(id, path, vec3.x, y, z or vec3.z)
	end
end

---@param id string -- The camera ID.
---@return CameraOffsetPreset|nil -- The camera offset data retrieved from 'TweakDB'.
---Retrieves the current camera offset data for the specified camera ID from 'TweakDB' and returns it as a 'CameraOffsetPreset' table.
local function getCurrentCameraOffset(id)
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
			return entry
		end
	end
	return nil
end

---Loads or updates all custom camera offset presets from files in the 'presets' directory.
---@param reload boolean|nil -- If true, existing entries will be overwritten. Defaults to false.
local function loadCustomCameraOffsetPresets(reload)
	if reload == nil then reload = false end

	local files = dir("./presets")
	for _, file in ipairs(files) do
		local name = file.name
		if not stringEndsWith(name, ".lua") then goto continue end

		local key = name:gsub("%.lua$", "")
		if not reload and _cameraOffsetPresets[key] ~= nil then
			goto continue
		end

		local chunk, err = loadfile("presets/" .. name)
		if not chunk then
			write("Failed to load preset '%s': %s", name, err)
			goto continue
		end

		local success, result = pcall(chunk)
		if success and type(result) == "table" then
			_cameraOffsetPresets[key] = result
		else
			write("Failed to execute preset '%s'", name)
		end

		::continue::
	end
end

---Loads default camera offsets from TweakDB and stores them in '_cameraOffsetPresets'.
local function loadDefaultCameraOffsetPresets()
	if not _defaultVehicleCamIDs then return end

	local vehicleIds = _defaultVehicleCamIDs
	_defaultVehicleCamIDs = nil

	for _, id in ipairs(vehicleIds) do
		if _cameraOffsetPresets[id] then goto continue end

		local entry = getCurrentCameraOffset(id)
		if entry then
			entry.Shutdown = true
			_cameraOffsetPresets[id] = entry
		end

		::continue::
	end
end

---@param entry CameraOffsetPreset -- The camera offset data to apply.
-- Applies the specified camera offsets to the vehicle using 'TweakDB'.
local function applyCameraOffsetPreset(entry)
	if entry and entry.Link and _cameraOffsetPresets[entry.Link] then
		entry = _cameraOffsetPresets[entry.Link]
	end
	for i, path in ipairs(_cameraOffsetPaths) do
		local p = (i - 1) % 3
		local v = p == 0 and entry.Close or p == 1 and entry.Medium or entry.Far
		if v and v.y then
			setCameraLookAtOffsetYZ(entry.ID, path, v.y, v.z)
		end
	end
end

--- Restores default camera offsets for vehicles.
local function applyDefaultCameraOffsetPresets()
	for _, entry in pairs(_cameraOffsetPresets) do
		if entry.Shutdown then
			applyCameraOffsetPreset(entry)
		end
	end
end

---Extracts the record name from a TweakDBID string representation.
---@param data any -- The TweakDBID to be parsed.
---@return string|nil -- The extracted record name, or nil if not found.
local function getRecordName(data)
	if not data then return nil end
	return tostring(data):match("%-%-%[%[(.-)%-%-%]%]"):match("^%s*(.-)%s*$")
end

local function getMountedVehicle()
	local player = Game.GetPlayer()
	if not player then return end

	return Game.GetMountedVehicle(player)
end

---Attempts to retrieve the camera ID associated with a given vehicle.
---@param vehicle Vehicle|nil -- The vehicle from which to extract the camera ID.
---@return string|nil -- The extracted camera ID (e.g., "4w_911") or nil if not found.
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
---@return string|nil -- The appearance name (e.g., "porsche_911turbo__basic_johnny") or nil if not found.
local function getVehicleName(vehicle)
	if not vehicle then return nil end

	local name = vehicle:GetCurrentAppearanceName()
	if not name then return nil end

	return Game.NameToString(name)
end

---Applies the appropriate camera offset preset when the player mounts a vehicle, if available.
local function autoApplyCameraOffsetPreset()
	local vehicle = getMountedVehicle()
	if not vehicle then return end

	local name = getVehicleName(vehicle)
	if not name then return end

	if name == _mountedVehicleName then return end
	_mountedVehicleName = name;

	if _devMode > 1 then
		write("Mounted vehicle: '%s'", name)

		local vehicleID = getVehicleCameraID(vehicle)
		if vehicleID then
			write("Camera preset ID: '%s'", vehicleID)
		end
	end

	for key, entry in pairs(_cameraOffsetPresets) do
		if name == key or stringStartsWith(name, key) then
			write("Apply camera preset: '%s'", entry.Link or name)
			applyCameraOffsetPreset(entry)
			break
		end
	end
end

---Saves the current preset to 'presets/<name>.lua' only if the file does not already exist.
---@param name string -- The name of the preset.
---@param preset table -- The current preset to save.
---@param overwrite boolean|nil -- Whether to overwrite the file if it exists (default: false).
---@return boolean -- True if saved successfully or already exists, false if error occurred.
local function savePreset(name, preset, overwrite)
	if type(name) ~= "string" or type(preset) ~= "table" then return false end

	local path = "presets/" .. name .. ".lua"
	if not overwrite then
		local check = io.open(path, "r")
		if check then
			check:close()
			write("File already exists and overwrite is disabled: '%s'", path)
			return false
		end
	end

	local function isDifferent(a, b)
		if type(a) ~= type(b) then return true end
		if type(a) == "number" then
			return math.abs(a - b) > 0.0001
		end
		return a ~= b
	end

	local function round(v)
		return string.format("%.3f", v)
	end

	local norm = _originalEntries and _originalEntries[name] or {}
	local save = false
	local parts = { "return{" }
	table.insert(parts, string.format('ID=%q,', preset.ID))
	for _, mode in ipairs({ "Close", "Medium", "Far" }) do
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
			table.insert(parts, string.format('%s={%s},', mode, table.concat(sub, ",")))
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

-- Initializes the mod by loading default camera offsets and setting up the observer for vehicle mounting events.
registerForEvent("onInit", function()
	loadCustomCameraOffsetPresets()
	loadDefaultCameraOffsetPresets()

	Observe("VehicleComponent", "OnMountingEvent", function()
		if not _isEnabled then return end
		autoApplyCameraOffsetPreset()
	end)

	Observe("VehicleComponent", "OnUnmountingEvent", function()
		if not _isEnabled then return end
		_mountedVehicleName = nil
		_currentEntryEdit = nil
		applyDefaultCameraOffsetPresets()
	end)
end)

-- Detects when the CET overlay is opened.
registerForEvent("onOverlayOpen", function()
	_isOverlayOpen = true
end)

-- Detects when the CET overlay is closed.
registerForEvent("onOverlayClose", function()
	_isOverlayOpen = false
end)

-- Display a simple GUI some options.
registerForEvent("onDraw", function()
	if not _isOverlayOpen then return end
	if not ImGui.Begin(_title, ImGuiWindowFlags.AlwaysAutoResize) then return end

	ImGui.Dummy(230, 4)

	local padding = 10
	ImGui.Dummy(padding, 0)
	ImGui.SameLine()
	local isEnabled = ImGui.Checkbox("  Toggle Mod Functionality", _isEnabled)

	if ImGui.IsItemHovered() then
		ImGui.BeginTooltip()
		ImGui.Text("Enables or disables the mod functionality.")
		ImGui.EndTooltip()
	end

	ImGui.Dummy(0, 2)

	if not isEnabled then
		if _isEnabled then
			_isEnabled = false
			_mountedVehicleName = nil
			applyDefaultCameraOffsetPresets()
		end
		ImGui.End()
		return
	end

	_isEnabled = true
	autoApplyCameraOffsetPreset()

	ImGui.Dummy(padding, 0)
	ImGui.SameLine()
	if ImGui.Button("Reload All Presets", 192, 24) then
		loadCustomCameraOffsetPresets(true)
		alert("Presets have been reloaded!")
	end
	if ImGui.IsItemHovered() then
		ImGui.BeginTooltip()
		ImGui.Text("Reloads all data from custom preset files - only needed if files have been changed or added.")
		ImGui.EndTooltip()
	end

	ImGui.Dummy(0, 2)

	ImGui.Dummy(padding, 0)
	ImGui.SameLine()
	ImGui.PushItemWidth(103)
	_devMode = ImGui.SliderInt("  Debug Level", _devMode, 0, 3)
	if ImGui.IsItemHovered() then
		ImGui.BeginTooltip()
		ImGui.Text("Adjust the level of debugging output:")
		ImGui.Text(" 0 = Disabled")
		ImGui.Text(" 1 = Alert only")
		ImGui.Text(" 2 = Alert & Print")
		ImGui.Text(" 3 = Alert, Print & Log")
		ImGui.EndTooltip()
	end
	ImGui.PopItemWidth()

	ImGui.Dummy(0, 8)

	if _devMode < 1 then
		ImGui.End()
		return
	end

	local vehicle = getMountedVehicle()
	if not vehicle then
		ImGui.End()
		return
	end

	local name = getVehicleName(vehicle)
	if not name then
		ImGui.End()
		return
	end

	local id = getVehicleCameraID(vehicle)
	if not id then
		ImGui.End()
		return
	end

	if ImGui.BeginTable("InfoTable", 2, ImGuiTableFlags.Borders) then
		ImGui.TableSetupColumn("Key", ImGuiTableColumnFlags.WidthFixed, 44)
		ImGui.TableSetupColumn("Value", ImGuiTableColumnFlags.WidthStretch)
		ImGui.TableHeadersRow()

		local data = {
			{ key = "Vehicle", value = name },
			{ key = "Cam ID", value = id }
		}

		for _, item in ipairs(data) do
			ImGui.TableNextRow()
			ImGui.TableSetColumnIndex(0)
			ImGui.Text(item.key)
			ImGui.TableSetColumnIndex(1)
			ImGui.Text(tostring(item.value or "None"))
		end

		ImGui.EndTable()
	end

	local entry
	if not _currentEntryEdit then
		_currentEntryEdit = getCurrentCameraOffset(id)
	end
	entry = _currentEntryEdit
	if not entry then
		ImGui.End()
		return
	end

	if not _originalEntries then
		_originalEntries = {}
	end
	if not _originalEntries[name] then
		_originalEntries[name] = tableDeepCopy(entry)
	end

	if ImGui.BeginTable("CameraOffsetEditor", 3, ImGuiTableFlags.Borders) then
		ImGui.TableSetupColumn("Level", ImGuiTableColumnFlags.WidthFixed, 50)
		ImGui.TableSetupColumn("Y Offset", ImGuiTableColumnFlags.WidthStretch)
		ImGui.TableSetupColumn("Z Offset", ImGuiTableColumnFlags.WidthStretch)
		ImGui.TableHeadersRow()

		for _, key in ipairs({ "Close", "Medium", "Far" }) do
			local value = entry[key]
			if type(value) == "table" then
				ImGui.TableNextRow()

				ImGui.TableSetColumnIndex(0)
				ImGui.Text(key)

				ImGui.TableSetColumnIndex(1)
				value.y = value.y or 0.0
				local y = value.y
				ImGui.PushItemWidth(102)
				y = ImGui.SliderFloat("##" .. key .. "_y", y, 0.0, 5.0)
				if y ~= value.y then value.y = y end

				ImGui.TableSetColumnIndex(2)
				value.z = value.z or 0.0
				local z = value.z
				ImGui.PushItemWidth(102)
				z = ImGui.SliderFloat("##" .. key .. "_z", z, 0.0, 5.0)
				if z ~= value.z then value.z = z end
			end
		end

		ImGui.EndTable()
		ImGui.Dummy(0, 1)
	end

	local width = ImGui.GetWindowSize() - 16

	if ImGui.Button("Apply Changes", width, 24) then
		_cameraOffsetPresets[name] = entry
		write("The preset has been updated.", name)
	end
	if ImGui.IsItemHovered() then
		ImGui.BeginTooltip()
		ImGui.Text("Applies the configured values without saving them permanently.")
		ImGui.Text("Please note that you need to exit and re-enter the vehicle for the changes to take effect.")
		ImGui.EndTooltip()
	end
	ImGui.Dummy(0, 1)

	if ImGui.Button("Save Changes to File", width, 24) then
		if savePreset(name, entry) then
			write("File 'presets/%s.lua' was saved successfully.", name)
		else
			write("File 'presets/%s.lua' could not be saved.", name)
		end
	end
	if ImGui.IsItemHovered() then
		ImGui.BeginTooltip()
		ImGui.Text(string.format("Saves the modified preset permanently under 'presets/%s.lua'.", name))
		ImGui.Text("Please note that existing files cannot be overwritten to prevent accidental changes to existing presets.\nIf you want to overwrite a preset, you must delete the existing file manually first.")
		ImGui.EndTooltip()
	end
	ImGui.Dummy(0, 1)

	ImGui.End()
end)

-- Restores default camera offsets for vehicles upon mod shutdown.
registerForEvent("onShutdown", function()
	applyDefaultCameraOffsetPresets()
end)
