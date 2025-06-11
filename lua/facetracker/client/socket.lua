---@diagnostic disable: undefined-global

if not GWSockets then
	require("gwsockets")
end

local HOST, PORT = "localhost", 8667

---@class SocketSystem
---@field private _socketTimerId string
---@field private _socket any
---@field private _timeout number
local system = {
	_socket = GWSockets.createWebSocket("ws://" .. HOST .. ":" .. PORT, false),
	_socketTimerId = "facetracker_timeout",
	_timeout = 5,
}

---@package
function system._socket:onMessage(text)
	-- print("Got message:", text)
	FaceTracker.Socket:onMessage(text)
end

---@package
function system._socket:onConnected()
	timer.Remove(system._socketTimerId)
	self:write(LocalPlayer():Nick())

	print("Connected to server")
	FaceTracker.Socket:onConnected()
end

---@package
function system._socket:onDisconnected()
	print("Disconnected from server")
	FaceTracker.Socket:onDisconnected()
end

---@package
function system._socket:onError(text)
	print("Error: ", text)
	FaceTracker.Socket:onError()
end

function system:onError() end

function system:onConnected() end

function system:onDisconnected() end

---@param text string
function system:onMessage(text) end

---@return boolean
function system:isConnected()
	return self._socket:isConnected()
end

function system:toggleConnection()
	if self:isConnected() then
		self._socket:close()
		if timer.Exists(self._socketTimerId) then
			timer.Remove(self._socketTimerId)
		end
	else
		if not timer.Exists(self._socketTimerId) then
			timer.Create(self._socketTimerId, self._timeout, 1, function()
				timer.Remove(self._socketTimerId)
				if not self._socket:isConnected() then
					print("Timed out")
					self._socket:close()
				end
			end)
		end

		print("Attempt connection")
		self._socket:open()
		timer.Start(self._socketTimerId)
	end
end

FaceTracker.Socket = system
