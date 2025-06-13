---@module "facetracker.shared.helpers"
local helpers = include("facetracker/shared/helpers.lua")

local getValidModelChildren = helpers.getValidModelChildren
local getModelName, getModelNameNice, getModelNodeIconPath =
	helpers.getModelName, helpers.getModelNameNice, helpers.getModelNodeIconPath
local vectorFromString = helpers.vectorFromString

local ui = {}

local PRESETS_DIR = "facetracker/presets"

---Add hooks and model tree pointers
---@param parent TreePanel_Node
---@param entity Entity
---@param info EntityTree
---@param rootInfo EntityTree
---@return TreePanel_Node
local function addEntityNode(parent, entity, info, rootInfo)
	local node = parent:AddNode(getModelNameNice(entity))
	---@cast node TreePanel_Node

	node:SetExpanded(true, true)

	node.Icon:SetImage(getModelNodeIconPath(entity))
	node.info = info

	return node
end

---Construct the model tree
---@param parent Entity
---@return EntityTree
local function entityHierarchy(parent)
	local tree = {}
	if not IsValid(parent) then
		return tree
	end

	---@type Entity[]
	local children = getValidModelChildren(parent)

	for i, child in ipairs(children) do
		if child.GetModel and child:GetModel() ~= "models/error.mdl" then
			---@type EntityTree
			local node = {
				parent = parent:EntIndex(),
				entity = child:EntIndex(),
				children = entityHierarchy(child),
			}
			table.insert(tree, node)
		end
	end

	return tree
end

---Construct the DTree from the entity model tree
---@param tree EntityTree
---@param nodeParent TreePanel_Node
---@param root EntityTree
local function hierarchyPanel(tree, nodeParent, root)
	for _, child in ipairs(tree) do
		local childEntity = Entity(child.entity)
		if not IsValid(childEntity) or not childEntity.GetModel or not childEntity:GetModel() then
			continue
		end

		local node = addEntityNode(nodeParent, childEntity, child, root)

		if #child.children > 0 then
			hierarchyPanel(child.children, node, root)
		end
	end
end

---Construct the `entity`'s model tree
---@param treePanel TreePanel
---@param entity Entity
---@returns EntityTree
local function buildTree(treePanel, entity)
	if IsValid(treePanel.ancestor) then
		treePanel.ancestor:Remove()
	end

	---@type EntityTree
	local hierarchy = {
		entity = entity:EntIndex(),
		children = entityHierarchy(entity),
	}

	---@type TreePanel_Node
	---@diagnostic disable-next-line
	treePanel.ancestor = addEntityNode(treePanel, entity, hierarchy, hierarchy)
	treePanel.ancestor.Icon:SetImage(getModelNodeIconPath(entity))
	treePanel.ancestor.info = hierarchy
	hierarchyPanel(hierarchy.children, treePanel.ancestor, hierarchy)

	return hierarchy
end

---Helper for DForm
---@param cPanel ControlPanel|DForm
---@param name string
---@param type "ControlPanel"|"DForm"
---@return ControlPanel|DForm
local function makeCategory(cPanel, name, type)
	---@type DForm|ControlPanel
	local category = vgui.Create(type, cPanel)

	category:SetLabel(name)
	cPanel:AddItem(category)
	return category
end

---@param form DForm|ControlPanel
---@return EyeSlider eyeSlider
---@return DNumSlider strabismus
local function eyePanel(form)
	local sliderBackground = vgui.Create("DPanel", form)
	sliderBackground:Dock(TOP)
	sliderBackground:SetTall(225)
	form:AddItem(sliderBackground)

	-- 2 axis slider for the eye position
	---@class EyeSlider: DSlider
	---@field Knob Panel
	local eyeSlider = vgui.Create("DSlider", sliderBackground)
	eyeSlider:Dock(FILL)
	eyeSlider:SetLockY()
	eyeSlider:SetSlideX(0.5)
	eyeSlider:SetSlideY(0.5)
	eyeSlider:SetTrapInside(true)
	-- Draw the 'button' different from the slider
	eyeSlider.Knob.Paint = function(panel, w, h)
		derma.SkinHook("Paint", "Button", panel, w, h)
	end

	eyeSlider.xp = vgui.Create("DTextEntry", sliderBackground)
	eyeSlider.yp = vgui.Create("DTextEntry", sliderBackground)
	eyeSlider.xp.type = "x"
	eyeSlider.yp.type = "y"

	eyeSlider:SetEnabled(false)

	local oldPerformLayout = eyeSlider.PerformLayout

	function eyeSlider:PerformLayout(w, h)
		oldPerformLayout(self, w, h)
		local x, y = 90, 20
		local margin = 10

		self.xp:SetSize(x, y)
		self.yp:SetSize(x, y)
		self.xp:SetPos(w - x - margin, h * 0.5 - y * 0.5)
		self.yp:SetPos(w * 0.5 - x * 0.5, margin)
	end

	function eyeSlider:Paint(w, h)
		local knobX, knobY = self.Knob:GetPos()
		local knobW, knobH = self.Knob:GetSize()
		surface.SetDrawColor(0, 0, 0, 250)
		surface.DrawLine(knobX + knobW / 2, knobY + knobH / 2, w / 2, h / 2)
		surface.DrawRect(w / 2 - 2, h / 2 - 2, 5, 5)
	end

	local strabismus = form:NumSlider("#tool.eyeposer.strabismus", "", -1, 1)
	---@cast strabismus DNumSlider

	return eyeSlider, strabismus
end

---@param cPanel DForm|ControlPanel
---@param panelProps PanelProps
---@param panelState PanelState
---@return PanelChildren
function ui.ConstructPanel(cPanel, panelProps, panelState)
	local flexable = panelProps.flexable

	cPanel:Help("#tool.facetracker.general")

	local treeForm = makeCategory(cPanel, "Entity Hierarchy", "DForm")
	if IsValid(flexable) then
		treeForm:Help("#tool.facetracker.tree")
	end
	treeForm:Help(IsValid(flexable) and "Entity hierarchy for " .. getModelName(flexable) or "No entity selected")
	local treePanel = vgui.Create("DTreeScroller", treeForm)
	---@cast treePanel TreePanel
	if IsValid(flexable) then
		panelState.tree = buildTree(treePanel, flexable)
	end
	treeForm:AddItem(treePanel)
	treePanel:Dock(TOP)
	treePanel:SetSize(treeForm:GetWide(), 125)

	local presets = vgui.Create("facetracker_presetsaver", cPanel)
	presets:SetEntity(flexable)
	presets:SetDirectory(PRESETS_DIR)
	presets:RefreshDirectory()

	cPanel:AddItem(presets)

	local connect = cPanel:Button(
		FaceTracker.Socket:isConnected() and language.GetPhrase("#tool.facetracker.disconnect")
			or language.GetPhrase("#tool.facetracker.connect"),
		""
	)

	cPanel:Help("#tool.facetracker.help1")
	cPanel:Help("#tool.facetracker.help2")

	local remove = cPanel:Button("#tool.facetracker.remove", "")
	local expressionForm = makeCategory(cPanel, "#tool.facetracker.expressions", "DForm")

	local eyeForm = makeCategory(cPanel, "#tool.facetracker.eyetracking", "DForm")
	local eyeSlider, strabismus = eyePanel(eyeForm)

	local arkitForm = makeCategory(cPanel, "#tool.facetracker.blendshapes", "DForm")
	local latency = arkitForm:Help(Format("%s (ms): %d", language.GetPhrase("#tool.facetracker.latency"), 0))
	latency.now = SysTime()
	for _, blendshape in ipairs(FaceTracker.Parser.blendshapes) do
		arkitForm[blendshape] = arkitForm:Help(Format("%s: %d", blendshape, 0))
	end

	local replicationSettings = makeCategory(cPanel, "Replication Settings", "DForm")
	replicationSettings:Help("#tool.facetracker.replication.warning")
	local updateInterval =
		replicationSettings:NumSlider("#tool.facetracker.replication.interval", "facetracker_updateinterval", 0, 1000)
	updateInterval:SetTooltip("#tool.facetracker.replication.interval.tooltip")

	return {
		treePanel = treePanel,
		updateInterval = updateInterval,
		expressionForm = expressionForm,
		presets = presets,
		connect = connect,
		arkitForm = arkitForm,
		latency = latency,
		remove = remove,
		eyeSlider = eyeSlider,
		strabismus = strabismus,
	}
end

---@param panelChildren PanelChildren
---@param panelProps PanelProps
---@param panelState PanelState
function ui.HookPanel(panelChildren, panelProps, panelState)
	local treePanel = panelChildren.treePanel
	local presets = panelChildren.presets
	local connect = panelChildren.connect
	local arkitForm = panelChildren.arkitForm
	local expressionForm = panelChildren.expressionForm
	local latency = panelChildren.latency
	local remove = panelChildren.remove
	local strabismus = panelChildren.strabismus
	local eyeSlider = panelChildren.eyeSlider

	local flexable = panelState.flexable
	local player = LocalPlayer()

	local blendshapes = FaceTracker.Parser.blendshapes

	---@param coefficients {[FlexName]: number}?
	local function refreshBlendshapes(coefficients)
		coefficients = coefficients or {}
		for i, coefficient in ipairs(coefficients) do
			local blendshape = blendshapes[i]
			arkitForm[blendshape]:SetText(Format("%s: %.2f", blendshape, coefficient or 0))
		end
	end

	local function refreshExpressions()
		expressionForm:Clear()

		for i = 0, flexable:GetFlexNum() - 1 do
			local flexName = flexable:GetFlexName(i)
			local expression = panelState.expressions[flexName] or ""

			local entry = expressionForm:TextEntry(flexName, "")
			entry:SetText(expression)

			function entry:OnValueChange(newVal)
				newVal = string.gsub(newVal, "%s+", "")
				panelState.expressions[flexName] = #newVal > 0 and newVal or nil
				FaceTracker.System.setExpressions(flexable, panelState.expressions, panelState.eyeExpressions)
			end
		end

		eyeSlider.xp:SetText(panelState.eyeExpressions.x or "")
		eyeSlider.yp:SetText(panelState.eyeExpressions.y or "")
		strabismus:SetValue(panelState.eyeExpressions.s or 0)
	end

	function FaceTracker.Socket:onConnected()
		connect:SetText("#tool.facetracker.disconnect")
	end

	function FaceTracker.Socket:onDisconnected()
		connect:SetText("#tool.facetracker.connect")
	end

	function FaceTracker.Socket:onMessage(coefficientString)
		local now = SysTime()
		local ping = now - latency.now
		latency.now = now

		latency:SetText(Format("%s (ms): %d", language.GetPhrase("#tool.facetracker.latency"), ping * 1000))
		local coefficients = util.JSONToTable(coefficientString)
		refreshBlendshapes(coefficients)
		FaceTracker.Parser:updateVariables(coefficients)
	end

	function connect:DoClick()
		FaceTracker.Socket:toggleConnection()
	end

	---@param node TreePanel_Node
	function treePanel:OnNodeSelected(node)
		local selectedEntity = Entity(node.info.entity)
		if flexable == selectedEntity then
			return
		end

		flexable = selectedEntity

		presets:SetEntity(flexable)
		presets:SetText(helpers.getModelNameNice(flexable))

		panelState.expressions, panelState.eyeExpressions = FaceTracker.System.getExpressions(flexable)
		refreshExpressions()
	end

	function strabismus:OnValueChanged(value)
		panelState.eyeExpressions.s = value
		FaceTracker.System.setExpressions(flexable, panelState.expressions, panelState.eyeExpressions)
	end

	local function expressionChanged(panel, newVal)
		panelState.eyeExpressions[panel.type] = #newVal > 0 and newVal or nil
		FaceTracker.System.setExpressions(flexable, panelState.expressions, panelState.eyeExpressions)
	end

	local oldThink = eyeSlider.Think
	function eyeSlider:Think()
		oldThink(self)

		local eye = FaceTracker.System.getEye(flexable)

		if eye then
			self:SetSlideX(eye.x)
			self:SetSlideY(eye.y)
		end
	end

	eyeSlider.xp.OnValueChange = expressionChanged
	eyeSlider.yp.OnValueChange = expressionChanged

	function presets:OnSaveSuccess()
		notification.AddLegacy("Expressions saved", NOTIFY_GENERIC, 5)
	end

	function presets:OnSaveFailure(msg)
		notification.AddLegacy("Failed to save expressions: " .. msg, NOTIFY_ERROR, 5)
	end

	function presets:OnSavePreset()
		local data = {
			expressions = panelState.expressions,
			eyeExpressions = panelState.eyeExpressions,
		}

		return util.TableToJSON(data, true)
	end

	---@param preset {expressions: FlexExpressions, eyeExpressions: EyeExpression}
	function presets:OnLoadPreset(preset)
		if istable(preset) then
			local expressions, eyeExpressions = preset.expressions or preset, preset.eyeExpressions or {}
			panelState.expressions = expressions
			panelState.eyeExpressions = eyeExpressions
			FaceTracker.System.setExpressions(flexable, expressions, eyeExpressions)
			refreshExpressions()
			notification.AddLegacy("Expressions loaded", NOTIFY_GENERIC, 5)
		end
	end

	function remove:DoClick()
		panelState.expressions = {}
		panelState.eyeExpressions = {}
		FaceTracker.System.setExpressions(flexable, panelState.expressions, panelState.eyeExpressions)
		refreshExpressions()
	end

	if IsValid(flexable) then
		panelState.expressions, panelState.eyeExpressions = FaceTracker.System.getExpressions(flexable)
		refreshExpressions()
		presets:SetEnabled(true)
	else
		presets:SetEnabled(false)
	end
end

return ui
