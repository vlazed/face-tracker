local enableSystem = CreateConVar("sv_facetracker_enablesystem", "1", FCVAR_NOTIFY + FCVAR_LUA_SERVER)
local enabled = enableSystem:GetBool()
cvars.AddChangeCallback("sv_facetracker_enablesystem", function(convar, oldValue, newValue)
	enabled = tobool(Either(tonumber(newValue) ~= nil, tonumber(newValue) > 0, false))
end)

net.Receive("facetracker_replicate", function(len)
	if not enabled then
		return
	end

	local entIndex = net.ReadUInt(14)
	local entity = Entity(entIndex)
	if not IsValid(entity) then
		return
	end

	for i = 0, entity:GetFlexNum() - 1 do
		entity:SetFlexWeight(i, net.ReadFloat())
	end

	local eyeTarget = net.ReadVector()
	entity:SetEyeTarget(eyeTarget)
end)
