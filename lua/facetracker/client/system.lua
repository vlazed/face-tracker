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
local function constructFlexable(entity, expressions)
	local expressionMap = {}
	for i = 0, entity:GetFlexNum() - 1 do
		expressionMap[i] = entity:GetFlexName(i)
	end

	return {
		entity = entity,
		expressions = expressions,
		flex = {},
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
---@return ClientFlexable
local function addFlexable(entIndex, expressions)
	local flexable = constructFlexable(Entity(entIndex), expressions)
	flexableInfo.flexables[entIndex] = flexable
	flexableInfo.count = flexableInfo.count + 1
	return flexable
end

---@param flexable ClientFlexable
local function parseExpression(flexable)
	local flex = {}

	for i = 1, flexable.flexCount do
		flex[i] = 0
		local expression = flexable.expressions[flexable.idToName[i - 1] or -1]
		if expression then
			flex[i] = FaceTracker.Parser:solve(expression)
		end
	end

	flexable.flex = flex
end

---Set `expressions` of an `entity`
---@param entity Entity
---@param expressions FlexExpressions
function system.setExpressions(entity, expressions)
	local entIndex = entity:EntIndex()
	local flexable = flexableInfo.flexables[entIndex]
	if flexable then
		flexable.expressions = expressions
		if not next(flexable.expressions) then
			removeFlexable(entIndex)
		end
	else
		addFlexable(entIndex, expressions)
	end
end

---Get `expressions` from an `entity`
---@param entity Entity
---@return { [string]: string }?
function system.getExpressions(entity)
	local entIndex = entity:EntIndex()
	local flexable = flexableInfo.flexables[entIndex]

	if flexable then
		return flexable.expressions
	end
end

---@param entIndex integer
---@param flexArray number[]
local function replicate(entIndex, flexArray)
	net.Start("facetracker_replicate")
	net.WriteUInt(entIndex, 14)
	for _, flexValue in ipairs(flexArray) do
		net.WriteFloat(flexValue)
	end
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
				replicate(entIndex, flexable.flex)
			end
		end
		flexableInfo.previousCount = flexableInfo.count
	end)
end

FaceTracker.System = system
