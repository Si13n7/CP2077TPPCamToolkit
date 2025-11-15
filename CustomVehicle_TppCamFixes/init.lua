--[[
==============================================
This file is distributed under the MIT License
==============================================

Custom Vehicle - TPP Camera Fixes

Adjusts third-person perspective (TPP) camera
offsets for specific custom vehicles that are
misaligned compared to stock ones.
----------------------------------------------

Filename: init.lua
Version: 2025-03-20, 19:56:27 UTC+01:00 (MEZ)

Copyright (c) 2025, Si13n7 Developments(tm)
All rights reserved.
______________________________________________
--]]


--- TweakDB Definition
---@class TweakDB
--- Provides access to game data stored in the database, including camera offsets and various other game settings.
---@field GetFlat fun(self: TweakDB, key: string): Vector3|nil -- Retrieves a value from the database based on the provided key.(self: TweakDB, key: string): Vector3|nil
---@field SetFlat fun(self: TweakDB, key: string, value: Vector3) -- Sets or modifies a value in the database for the specified key.(self: TweakDB, key: string, value: Vector3)
TweakDB = TweakDB

--- Game Definition
---@class Game
--- Provides various global game functions, such as getting the player, mounted vehicles, and converting names to strings.
---@field NameToString fun(value: any): string -- Converts a game name object to a readable string.(value: any): string
---@field GetPlayer fun(): Player|nil -- Retrieves the current player instance if available.(): Player|nil
---@field GetMountedVehicle fun(player: Player): Vehicle|nil -- Returns the vehicle the player is currently mounted in, if any.(player: Player): Vehicle|nil
Game = Game

--- Player Definition
---@class Player
--- Represents the player character in the game, providing functions to interact with the player instance.
---@field SetWarningMessage fun(self: Player, message: string, duration: number): nil -- Displays a warning message on the player's screen for a specified duration.(self: Player, message: string, duration: number): nil
Player = Player

--- Vehicle Definition
---@class Vehicle
--- Represents a vehicle entity within the game, providing functions to interact with it, such as getting the appearance name.
---@field GetCurrentAppearanceName fun(self: Vehicle): string|nil -- Retrieves the current appearance name of the vehicle.(self: Vehicle): string|nil
Vehicle = Vehicle

--- Vector3 Definition
---@class Vector3
--- Represents a three-dimensional vector, commonly used for positions or directions in the game.
---@field x number -- The X-coordinate.
---@field y number -- The Y-coordinate.
---@field z number -- The Z-coordinate.
---@field new fun(x: number, y: number, z: number): Vector3 -- Creates a new Vector3 instance with specified x, y, and z coordinates.(x: number, y: number, z: number): Vector3
Vector3 = Vector3

--- Observe Definition
---@class Observe
--- Provides functionality to observe game events, allowing custom functions to be executed when certain events occur.
---@field Observe fun(className: string, functionName: string, callback: fun(...): nil) -- Sets up an observer for a specified function within the game.(className: string, functionName: string, callback: fun(...): nil)
Observe = Observe

--- registerForEvent Definition
---@class registerForEvent
--- Allows the registration of functions to be executed when certain game events occur, such as initialization or shutdown.
---@field registerForEvent fun(eventName: string, callback: fun(...): nil) -- Registers a callback function for a specified event (e.g., 'onInit', 'onShutdown').(eventName: string, callback: fun(...): nil)
registerForEvent = registerForEvent

--- spdlog Definition
---@class spdlog
--- Provides logging functionality, allowing messages to be printed to the console or log files for debugging purposes.
---@field error fun(message: string) -- Logs an error message, usually when something goes wrong.(message: string)
spdlog = spdlog

---@type number
-- The current debug mode level controlling logging and alerts:
-- 0 = Disabled; 1 = Alert; 2 = Alert, and Print; 3 = Alert,
-- Print, and Log
local devMode = 2

---@type string
-- The template string for accessing camera lookAtOffset values in TweakDB.
local cameraPathTemplate = "Camera.VehicleTPP_%s_%s.lookAtOffset"

---@class VehicleMap
---@field [string] string -- Maps vehicle appearance names to their respective camera IDs.
---@type VehicleMap|nil
local defaultVehicleMap = {
	["archer_hella__basic_player_01"]  = "4w_Archer_Hella",
	["porsche_911turbo__basic_johnny"] = "4w_911"
}

---@class CameraOffsetPreset
---@field ID string|nil        -- The camera ID used for the vehicle.
---@field Close number|nil     -- The Y-offset for close camera view.
---@field Medium number|nil    -- The Y-offset for medium camera view.
---@field Far number|nil       -- The Y-offset for far camera view.
---@field Link string|nil      -- The name of another vehicle appearance to link to (if applicable).
---@field Shutdown boolean|nil -- Whether to reset to default camera offsets on shutdown.
---@type table<string, CameraOffsetPreset>
-- Contains all camera presets and linked vehicles.
local cameraOffsetPresets = {
	-- Fixes
	["yv_s2000"] = {
		ID     = "4w_Archer_Hella",
		Close  = 1.25,
		Medium = 1.15,
		Far    = 0.8
	},
	["fordgt_base"] = {
		ID     = "4w_911",
		Close  = 0.3,
		Medium = 0.2,
		Far    = 0.1
	},
	-- Links
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

---@param msg string      -- The message to display to the player.
---@param secs number|nil -- The duration in seconds for which the message is displayed.
local function alert(msg, secs)
	if not msg then return end

	local player = Game.GetPlayer()
	if player then
		player:SetWarningMessage(msg, secs or 5)
	end
end

---@param format string -- The format string for the message.
---@vararg any          -- Additional arguments for formatting the message.
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
local function stringStartsWith(str, prefix)
	return #prefix <= #str and str:sub(1, #prefix) == prefix
end

---@param id string -- The camera ID.
---@param path string -- The camera path to retrieve the offset for.
---@return Vector3|nil -- The camera offset as a Vector3.
local function getCameraLookAtOffset(id, path)
	return TweakDB:GetFlat(string.format(cameraPathTemplate, id, path))
end

---@param id string   -- The camera ID.
---@param path string -- The camera path to set the offset for.
---@param x number    -- The X-coordinate of the camera position.
---@param y number    -- The Y-coordinate of the camera position.
---@param z number    -- The Z-coordinate of the camera position.
local function setCameraLookAtOffset(id, path, x, y, z)
	TweakDB:SetFlat(string.format(cameraPathTemplate, id, path), Vector3.new(x, y, z))
end

---@param id string   -- The camera ID.
---@param path string -- The camera path to update.
---@param y number    -- The new Y-coordinate value.
local function setCameraLookAtOffsetY(id, path, y)
	local vec3 = getCameraLookAtOffset(id, path)
	if vec3 then
		setCameraLookAtOffset(id, path, vec3.x, y, vec3.z)
	end
end

---@param id string               -- The camera ID.
---@return CameraOffsetPreset|nil -- The camera offset data retrieved from TweakDB.
local function getCurrentCameraOffset(id)
	local entry = {
		ID = id,
		Shutdown = true
	}
	for i, path in ipairs(cameraOffsetPaths) do
		local vec3 = getCameraLookAtOffset(id, path)
		if not vec3 or not vec3.y then return nil end

		local p = (i - 1) % 3
		if p == 0 then
			entry.Close = vec3.y
		elseif p == 1 then
			entry.Medium = vec3.y
		else
			entry.Far = vec3.y
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
			cameraOffsetPresets[key] = entry
		end

		::continue::
	end
end

---@param entry CameraOffsetPreset -- The camera offset data to apply.
-- Applies the specified camera offsets to the vehicle using TweakDB.
local function applyCameraOffsetPresets(entry)
	if entry and entry.Link and cameraOffsetPresets[entry.Link] then
		entry = cameraOffsetPresets[entry.Link]
	end
	for i, path in ipairs(cameraOffsetPaths) do
		local p = (i - 1) % 3
		local y = p == 0 and entry.Close or p == 1 and entry.Medium or entry.Far
		setCameraLookAtOffsetY(entry.ID, path, y or 0)
	end
end

-- Initializes the mod by loading default camera offsets and setting up the observer for vehicle mounting events.
registerForEvent("onInit", function()
	loadDefaultCameraOffsetPresets()

	Observe("VehicleComponent", "OnMountingEvent", function()
		local player = Game.GetPlayer()
		if not player then return end

		local vehicle = Game.GetMountedVehicle(player)
		if not vehicle then return end

		local name = Game.NameToString(vehicle:GetCurrentAppearanceName())
		for key, entry in pairs(cameraOffsetPresets) do
			if name == key or stringStartsWith(name, key) then
				write("Apply camera preset '%s'.", entry.Link or name)
				applyCameraOffsetPresets(entry)
				break
			end
		end
	end)
end)

-- Restores default camera offsets for vehicles upon mod shutdown.
registerForEvent("onShutdown", function()
	for _, entry in pairs(cameraOffsetPresets) do
		if entry.Shutdown then
			applyCameraOffsetPresets(entry)
		end
	end
end)
