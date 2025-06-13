---@module "facetracker.shared.helpers"
local helpers = include("facetracker/shared/helpers.lua")

local ipairs_sparse = helpers.ipairs_sparse

---@type ClientFlexableInfo
local flexableInfo = {
	flexables = {},
	previousCount = 0,
	count = 0,
}

local system = {}

---Make a table to store the entity, its bones, and other fields,
---rather than storing it in the entity itself to avoid Entity.__index calls
---@param entity Entity
---@param expressions FlexExpressions
---@return ClientFlexable
local function constructFlexable(entity, expressions, eyeExpressions)
	local expressionMap = {}
	for i = 0, entity:GetFlexNum() - 1 do
		expressionMap[i] = entity:GetFlexName(i)
	end

	return {
		entity = entity,
		expressions = expressions,
		eyeExpressions = eyeExpressions,
		flex = {},
		eyeTarget = {},
		eye = { x = 0.5, y = 0.5 },
		flexCount = entity:GetFlexNum(),
		nameToId = table.Flip(expressionMap),
		idToName = expressionMap,
	}
end

---@param entIndex integer
local function removeFlexable(entIndex)
	flexableInfo.flexables[entIndex] = nil
	flexableInfo.count = flexableInfo.count - 1
end

---@param entIndex number
---@param expressions FlexExpressions
---@param eyeExpressions EyeExpression
---@return ClientFlexable
local function addFlexable(entIndex, expressions, eyeExpressions)
	local flexable = constructFlexable(Entity(entIndex), expressions, eyeExpressions)
	flexableInfo.flexables[entIndex] = flexable
	flexableInfo.count = flexableInfo.count + 1
	return flexable
end

---@source https://github.com/Facepunch/garrysmod/blob/0cc9b3d432cb1cc88910b81f87e7782476f64e75/garrysmod/gamemodes/sandbox/entities/weapons/gmod_tool/stools/eyeposer.lua#L48C1-L77C4
---@param ent Entity
---@param x number
---@param y number
---@param s number
---@return Vector, Angle?
local function calculateEyeTarget(ent, x, y, s)
	x = math.Remap(x, 0, 1, -1, 1)
	y = math.Remap(y, 0, 1, -1, 1)
	local fwd = Angle(y * 45, x * 45, 0):Forward()
	s = math.Clamp(s, -1, 1)
	local distance = 1000

	if s < 0 then
		s = math.Remap(s, -1, 0, 0, 1)
		distance = distance * math.pow(10000, s - 1)
	elseif s > 0 then
		distance = distance * -math.pow(10000, -s)
	end

	-- Gotta do this for NPCs...
	if IsValid(ent) and ent:IsNPC() then
		local eyeattachment = ent:LookupAttachment("eyes")
		if eyeattachment == 0 then
			return fwd * distance
		end

		local attachment = ent:GetAttachment(eyeattachment)
		if not attachment then
			return fwd * distance
		end

		return LocalToWorld(fwd * distance, angle_zero, attachment.Pos, attachment.Ang)
	end

	return fwd * distance
end

---@param flexable ClientFlexable
local function parseExpression(flexable)
	local flex = {}
	local entity = flexable.entity
	local eyeExpressions = flexable.eyeExpressions

	for i = 1, flexable.flexCount do
		flex[i] = entity:GetFlexWeight(i - 1)
		local expression = flexable.expressions[flexable.idToName[i - 1] or -1]
		if expression then
			flex[i] = FaceTracker.Parser:solve(expression)
		end
	end

	local x = eyeExpressions.x and FaceTracker.Parser:solve(eyeExpressions.x) or 0.5
	local y = eyeExpressions.y and FaceTracker.Parser:solve(eyeExpressions.y) or 0.5
	local s = eyeExpressions.s or 0
	local eyeTarget = calculateEyeTarget(entity, x, y, s)

	flexable.flex = flex
	flexable.eyeTarget = eyeTarget
	flexable.eye.x = x
	flexable.eye.y = y
end

---Set `expressions` of an `entity`
---@param entity Entity
---@param expressions FlexExpressions
---@param eyeExpressions EyeExpression
function system.setExpressions(entity, expressions, eyeExpressions)
	local entIndex = entity:EntIndex()
	local flexable = flexableInfo.flexables[entIndex]
	if flexable then
		flexable.expressions = expressions
		flexable.eyeExpressions = eyeExpressions
		if not next(flexable.expressions) and not next(flexable.eyeExpressions) then
			removeFlexable(entIndex)
		end
	else
		addFlexable(entIndex, expressions, eyeExpressions)
	end
end

---Get `expressions` from an `entity`
---@param entity Entity
---@return FlexExpressions
---@return EyeExpression
function system.getExpressions(entity)
	local entIndex = entity:EntIndex()
	local flexable = flexableInfo.flexables[entIndex]

	if flexable then
		return flexable.expressions, flexable.eyeExpressions
	end

	return {}, {}
end

---Get `expressions` from an `entity`
---@param entity Entity
---@return number[]?
---@return Vector?
function system.getFlex(entity)
	local entIndex = entity:EntIndex()
	local flexable = flexableInfo.flexables[entIndex]

	if flexable then
		return flexable.flex, flexable.eyeTarget
	end
end

---Get `expressions` from an `entity`
---@param entity Entity
---@return Eye?
function system.getEye(entity)
	local entIndex = entity:EntIndex()
	local flexable = flexableInfo.flexables[entIndex]

	if flexable then
		return flexable.eye
	end
end

---@param entIndex integer
---@param flexArray number[]
local function replicate(entIndex, flexArray, eyeTarget)
	net.Start("facetracker_replicate")
	net.WriteUInt(entIndex, 14)
	for _, flexValue in ipairs(flexArray) do
		net.WriteFloat(flexValue)
	end

	net.WriteVector(eyeTarget)
	net.SendToServer()
end

---Check if the entity passes rules on the client
---Useful to ensure the client doesn't send what it can't see
---@param entity Entity
local function checkReplication(entity)
	-- TODO: Implement replication rules
	return true
end

do
	local checkReplicationConVar = GetConVar("facetracker_checkreplication")
	local shouldCheckReplication = checkReplicationConVar and checkReplicationConVar:GetBool()
	cvars.AddChangeCallback("facetracker_checkreplication", function(_, _, newValue)
		shouldCheckReplication = tobool(newValue) or shouldCheckReplication
	end)
	local updateIntervalConVar = GetConVar("facetracker_updateinterval")
	local updateInterval = updateIntervalConVar and updateIntervalConVar:GetFloat()
	cvars.AddChangeCallback("facetracker_updateinterval", function(_, _, newValue)
		updateInterval = tonumber(newValue) or updateInterval
	end)

	local lastThink = 0

	-- The client is responsible for parsing the expressions
	hook.Remove("Think", "facetracker_system")
	hook.Add("Think", "facetracker_system", function()
		checkReplicationConVar = checkReplicationConVar or GetConVar("facetracker_checkreplication")
		updateIntervalConVar = updateIntervalConVar or GetConVar("facetracker_updateinterval")
		if not shouldCheckReplication and checkReplicationConVar then
			shouldCheckReplication = checkReplicationConVar:GetBool()
		end
		if not updateInterval and updateIntervalConVar then
			updateInterval = updateIntervalConVar:GetFloat()
		end

		local now = CurTime()
		if (now - lastThink) < updateInterval / 1000 then
			return
		end
		lastThink = now

		local flexables = flexableInfo.flexables
		for entIndex, flexable in
			ipairs_sparse(flexables, "facetracker_system", flexableInfo.count ~= flexableInfo.previousCount)
		do
			-- Cleanup invalid entities
			if not flexable or not IsValid(flexable.entity) then
				removeFlexable(entIndex)
				continue
			end

			if not shouldCheckReplication or (shouldCheckReplication and checkReplication(flexable.entity)) then
				parseExpression(flexable)
				replicate(entIndex, flexable.flex, flexable.eyeTarget)
			end
		end
		flexableInfo.previousCount = flexableInfo.count
	end)
end

FaceTracker.System = system
