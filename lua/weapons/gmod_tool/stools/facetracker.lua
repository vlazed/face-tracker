TOOL.Category = "Poser"
TOOL.Name = "#tool.facetracker.name"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar["updateinterval"] = "10"

local lastFlexable = NULL
local lastValidFlexable = false
function TOOL:Think()
	local currentFlexable = self:GetFlexable()
	local validFlexable = IsValid(currentFlexable)

	if currentFlexable == lastFlexable and validFlexable == lastValidFlexable then
		return
	end

	if CLIENT then
		self:RebuildControlPanel(currentFlexable)
	end
	lastFlexable = currentFlexable
	lastValidFlexable = validFlexable
end

---@param newFlexable Entity
function TOOL:SetFlexable(newFlexable)
	self:GetWeapon():SetNW2Entity("facetracker_entity", IsValid(newFlexable) and newFlexable or NULL)
end

---@return Entity flexable
function TOOL:GetFlexable()
	return self:GetWeapon():GetNW2Entity("facetracker_entity")
end

---Select an entity to add flex drivers
---@param tr table|TraceResult
---@return boolean
function TOOL:RightClick(tr)
	if CLIENT then
		return true
	end

	if IsValid(tr.Entity) and tr.Entity:GetClass() == "prop_effect" then
		---@diagnostic disable-next-line: undefined-field
		tr.Entity = tr.Entity.AttachedEntity
	end

	self:SetFlexable(tr.Entity)

	return true
end

if SERVER then
	return
end

TOOL:BuildConVarList()

---@module "facetracker.client.ui"
local ui = include("facetracker/client/ui.lua")

---@type PanelState
local panelState = {
	flexable = NULL,
	expressions = {},
}

---@param cPanel ControlPanel|DForm
---@param flexable Entity
function TOOL.BuildCPanel(cPanel, flexable)
	local panelProps = {
		flexable = flexable,
	}
	panelState.flexable = flexable
	local panelChildren = ui.ConstructPanel(cPanel, panelProps, panelState)
	ui.HookPanel(panelChildren, panelProps, panelState)
end

TOOL.Information = {
	{ name = "info" },
	{ name = "right" },
}
