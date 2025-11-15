--[[
==============================================
This file is distributed under the MIT License
==============================================

Custom Vehicle - TPP Camera Fixes

Adjusts third-person perspective (TPP) camera
offsets for specific custom vehicles.
----------------------------------------------

Filename: init.lua
Version: 2025-03-24, 00:22 UTC+01:00 (MEZ)

Copyright (c) 2025, Si13n7 Developments(tm)
All rights reserved.
______________________________________________
--]]


--- ImGui Definition
---@class ImGui
--- Provides functions to create graphical user interface elements within the Cyber Engine Tweaks overlay.
---@field Begin fun(title: string, flags?: number): boolean -- Begins a new ImGui window with optional flags. Must be closed with `ImGui.End()`. Returns `true` if the window is open and should be rendered.
---@field End fun(): nil -- Ends the creation of the current ImGui window. Must always be called after `ImGui.Begin()`.
---@field Checkbox fun(label: string, value: boolean): (boolean, boolean) -- Creates a toggleable checkbox. Returns `changed` (true if state has changed) and `value` (the new state).
ImGui = ImGui

--- ImGuiWindowFlags Definition
---@class ImGuiWindowFlags
---@field AlwaysAutoResize number -- Automatically resizes the window to fit its content each frame.
ImGuiWindowFlags = ImGuiWindowFlags

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

---@type string
-- The window title.
local title = "Custom Vehicle - TPP Camera Fixes"

---@type boolean
-- Determines whether the CET overlay is open.
local isOverlayOpen = false

---@type boolean
-- Determines whether the mod is enabled.
local isEnabled = true

---@type number
-- The current debug mode level controlling logging and alerts:
-- 0 = Disabled; 1 = Alert; 2 = Alert, and Print; 3 = Alert,
-- Print, and Log
local devMode = 0

---@type string
-- The template string for accessing camera lookAtOffset values in TweakDB.
local cameraPathTemplate = "Camera.VehicleTPP_%s_%s.lookAtOffset"

---@type string|nil
-- The currently mounted vehicle name.
local mountedVehicleName = nil

---@class VehicleMap
---@field [string] string -- Maps vehicle appearance names to their respective camera IDs.
---@type VehicleMap|nil
local defaultVehicleMap = {
	["archer_hella__basic_player_01"]   = "4w_Archer_Hella",
	["makigai_maimai__basic_player_01"] = "4w_Makigai",
	["porsche_911turbo__basic_johnny"]  = "4w_911"
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
local cameraOffsetPresets = {
	-- Fixes
	["fordgt_base"] = {
		ID     = "4w_911",
		Close  = { y = 0.3 },
		Medium = { y = 0.2 },
		Far    = { y = 0.1 }
	},
	["mini_cooper_s_basic"] = {
		ID     = "4w_911",
		Close  = { y = 0.5 },
		Medium = { y = 0.3 },
		Far    = { y = 0.1 }
	},
	["oranje3_kart"] = {
		ID     = "4w_Makigai",
		Close  = { y = 0.7, z = 1.0 },
		Medium = { y = 0.5, z = 1.2 },
		Far    = { y = 0.3 }
	},
	["toyota_mr2_basic"] = {
		ID     = "4w_911",
		Close  = { y = 0.35 },
		Medium = { y = 0.25 },
		Far    = { y = 0.15 }
	},
	["yv_350z"] = {
		ID     = "4w_Archer_Hella",
		Close  = { y = 1.15 },
		Medium = { y = 1.1 },
		Far    = { y = 0.9 }
	},
	["yv_s2000"] = {
		ID     = "4w_Archer_Hella",
		Close  = { y = 1.25 },
		Medium = { y = 1.15 },
		Far    = { y = 0.8 }
	},
	-- Links instead of duplicates
	["countachwbk_base"] = {
		Link = "fordgt_base"
	},
	["porsche_911turbo__basic_cabrio_01"] = {
		Link = "porsche_911turbo__basic_johnny"
	},
	["v8vantage77"] = {
		Link = "porsche_911turbo__basic_johnny"
	}
}

---@type string[]
-- Paths corresponding to different camera positions.
local cameraOffsetPaths = {
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
---Logs and displays messages based on the current `devMode` level. Messages can be logged to the console, printed, or shown as alerts.
local function write(format, ...)
	if devMode <= 0 then return end

	local msg = "[CVTPPCF] " .. format
	local args = { ... }
	if #args > 0 then
		for i = 1, #args do
			args[i] = tostring(args[i])
		end
		msg = string.format(msg, table.unpack(args))
	end

	if devMode >= 3 then spdlog.error(msg) end
	if devMode >= 2 then print(msg) end
	if devMode >= 1 then alert(msg) end
end

---@param str string    -- The string to check.
---@param prefix string -- The prefix to look for.
---@return boolean      -- True if the string starts with the prefix, false otherwise.
---Checks if a given string begins with the specified prefix.
local function stringStartsWith(str, prefix)
	return #prefix <= #str and str:sub(1, #prefix) == prefix
end

---@param id string -- The camera ID.
---@param path string -- The camera path to retrieve the offset for.
---@return Vector3|nil -- The camera offset as a Vector3.
---Fetches the current camera offset from 'TweakDB' based on the specified ID and path.
local function getCameraLookAtOffset(id, path)
	return TweakDB:GetFlat(string.format(cameraPathTemplate, id, path))
end

---@param id string -- The camera ID.
---@param path string -- The camera path to set the offset for.
---@param x number -- The X-coordinate of the camera position.
---@param y number -- The Y-coordinate of the camera position.
---@param z number -- The Z-coordinate of the camera position.
---Sets a camera offset in 'TweakDB' to the specified position values.
local function setCameraLookAtOffset(id, path, x, y, z)
	TweakDB:SetFlat(string.format(cameraPathTemplate, id, path), Vector3.new(x, y, z))
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
	for i, path in ipairs(cameraOffsetPaths) do
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

---Loads all default camera offsets from TweakDB and stores them in 'cameraOffsetPresets'.
local function loadDefaultCameraOffsetPresets()
	if not defaultVehicleMap then return end

	local vehicleMap = defaultVehicleMap
	defaultVehicleMap = nil

	for key, id in pairs(vehicleMap) do
		if cameraOffsetPresets[key] then goto continue end

		local entry = getCurrentCameraOffset(id)
		if entry then
			entry.Shutdown = true
			cameraOffsetPresets[key] = entry
		end

		::continue::
	end
end

---@param entry CameraOffsetPreset -- The camera offset data to apply.
-- Applies the specified camera offsets to the vehicle using 'TweakDB'.
local function applyCameraOffsetPreset(entry)
	if entry and entry.Link and cameraOffsetPresets[entry.Link] then
		entry = cameraOffsetPresets[entry.Link]
	end
	for i, path in ipairs(cameraOffsetPaths) do
		local p = (i - 1) % 3
		local v = p == 0 and entry.Close or p == 1 and entry.Medium or entry.Far
		if v and v.y then
			setCameraLookAtOffsetYZ(entry.ID, path, v.y, v.z)
		end
	end
end

--- Restores default camera offsets for vehicles.
local function applyDefaultCameraOffsetPresets()
	for _, entry in pairs(cameraOffsetPresets) do
		if entry.Shutdown then
			applyCameraOffsetPreset(entry)
		end
	end
end

---Applies the appropriate camera offset preset when the player mounts a vehicle, if available.
local function autoApplyCameraOffsetPreset()
	local player = Game.GetPlayer()
	if not player then return end

	local vehicle = Game.GetMountedVehicle(player)
	if not vehicle then return end

	local name = Game.NameToString(vehicle:GetCurrentAppearanceName())
	if mountedVehicleName == name then return end
	mountedVehicleName = name;
	write("Mounted vehicle: '%s'", name)

	for key, entry in pairs(cameraOffsetPresets) do
		if name == key or stringStartsWith(name, key) then
			write("Apply camera preset: '%s'", entry.Link or name)
			applyCameraOffsetPreset(entry)
			break
		end
	end
end

-- Initializes the mod by loading default camera offsets and setting up the observer for vehicle mounting events.
registerForEvent("onInit", function()
	loadDefaultCameraOffsetPresets()

	Observe("VehicleComponent", "OnMountingEvent", function()
		if not isEnabled then return end
		autoApplyCameraOffsetPreset()
	end)

	Observe("VehicleComponent", "OnUnmountingEvent", function()
		if not isEnabled then return end
		mountedVehicleName = nil
		applyDefaultCameraOffsetPresets()
	end)
end)

-- Detects when the CET overlay is opened.
registerForEvent("onOverlayOpen", function()
	isOverlayOpen = true
end)

-- Detects when the CET overlay is closed.
registerForEvent("onOverlayClose", function()
	isOverlayOpen = false
end)

-- Display a simple GUI some options.
registerForEvent("onDraw", function()
	if not isOverlayOpen then return end
	if ImGui.Begin(title, ImGuiWindowFlags.AlwaysAutoResize) then
		local changed = ImGui.Checkbox(title .. ": Enabled", isEnabled)
		if changed ~= isEnabled then
			isEnabled = changed
			if isEnabled then
				autoApplyCameraOffsetPreset()
			else
				mountedVehicleName = nil
				applyDefaultCameraOffsetPresets()
			end
		end
		ImGui.End()
	end
end)

-- Restores default camera offsets for vehicles upon mod shutdown.
registerForEvent("onShutdown", function()
	applyDefaultCameraOffsetPresets()
end)
