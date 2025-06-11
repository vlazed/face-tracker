---@diagnostic disable-next-line: undefined-global
FaceTracker = FaceTracker or {}

if SERVER then
	print("Initializing Face Tracker on the server")

	AddCSLuaFile("facetracker/shared/helpers.lua")
	AddCSLuaFile("facetracker/shared/mathparser.lua")

	AddCSLuaFile("facetracker/client/parser.lua")
	AddCSLuaFile("facetracker/client/socket.lua")
	AddCSLuaFile("facetracker/client/system.lua")
	AddCSLuaFile("facetracker/client/ui.lua")

	include("facetracker/shared/presets.lua")

	include("facetracker/server/net.lua")
	include("facetracker/server/system.lua")
else
	print("Initializing Face Tracker on the client")

	include("facetracker/client/parser.lua")
	include("facetracker/client/socket.lua")
	include("facetracker/client/system.lua")
end
