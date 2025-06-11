---Similar to the DTree, but instead of a scroll, it uses a DPanPanel
---@class DTreeScroller: DVHScrollPanel
---@field m_bShowIcons boolean
---@field SetShowIcons fun(self: DTreeScroller, showIcons: boolean)
---@field GetShowIcons fun(self: DTreeScroller): showIcons: boolean
---@field m_iIndentSize integer
---@field SetIndentSize fun(self: DTreeScroller, indentSize: integer)
---@field GetIndentSize fun(self: DTreeScroller): indentSize: integer
---@field m_iLineHeight integer
---@field SetLineHeight fun(self: DTreeScroller, lineHeight: integer)
---@field GetLineHeight fun(self: DTreeScroller): lineHeight: integer
---@field m_pSelectedItem DTree_Node|DTreeScroller
---@field SetSelectedItem fun(self: DTreeScroller, selectedItem: DTree_Node|DTreeScroller)
---@field GetSelectedItem fun(self: DTreeScroller): selectedItem: DTree_Node|DTreeScroller
---@field m_bClickOnDragHover boolean
---@field SetClickOnDragHover fun(self: DTreeScroller, clickOnDragHover: boolean)
---@field GetClickOnDragHover fun(self: DTreeScroller): clickOnDragHover: boolean
---@field pnlCanvas Panel
---@field GetCanvas fun(self: DTreeScroller): pnlCanvas: Panel
---@field SetCanvas fun(self: DTreeScroller, pnlCanvas: Panel)
local PANEL = {}

AccessorFunc(PANEL, "m_bShowIcons", "ShowIcons")
AccessorFunc(PANEL, "m_iIndentSize", "IndentSize")
AccessorFunc(PANEL, "m_iLineHeight", "LineHeight")
AccessorFunc(PANEL, "m_pSelectedItem", "SelectedItem")
AccessorFunc(PANEL, "m_bClickOnDragHover", "ClickOnDragHover")

function PANEL:Init()
	--self:SetMouseInputEnabled( true )
	--self:SetClickOnDragHover( false )

	self:SetShowIcons(true)
	self:SetIndentSize(14)
	self:SetLineHeight(17)
	--self:SetPadding( 2 )

	self.RootNode = self:GetCanvas():Add("DTree_Node")
	self.RootNode:SetRoot(self)
	self.RootNode:SetParentNode(self)
	self.RootNode:Dock(TOP)
	self.RootNode:SetText("")
	self.RootNode:SetExpanded(true, true)
	self.RootNode:DockMargin(0, 4, 0, 0)

	self.Width = 0

	self:SetPaintBackground(true)
end

--
-- Get the root node
--
function PANEL:Root()
	return self.RootNode
end

function PANEL:AddNode(strName, strIcon)
	return self.RootNode:AddNode(strName, strIcon)
end

function PANEL:ChildExpanded(bExpand)
	self:InvalidateLayout()
end

function PANEL:ShowIcons()
	return self.m_bShowIcons
end

function PANEL:ExpandTo(bExpand) end

function PANEL:SetExpanded(bExpand)

	-- The top most node shouldn't react to this.
end

function PANEL:Clear()
	self:Root():Clear()
end

function PANEL:Paint(w, h)
	derma.SkinHook("Paint", "Tree", self, w, h)
	return true
end

function PANEL:DoClick(node)
	return false
end

function PANEL:DoRightClick(node)
	return false
end

function PANEL:SetSelectedItem(node)
	if IsValid(self.m_pSelectedItem) then
		self.m_pSelectedItem:SetSelected(false)
	end

	self.m_pSelectedItem = node

	if node then
		node:SetSelected(true)
		node:OnNodeSelected(node)
	end
end

function PANEL:OnNodeSelected(node) end

function PANEL:MoveChildTo(child, pos)
	---@diagnostic disable-next-line: undefined-field
	self:InsertAtTop(child)
end

function PANEL:LayoutTree()
	self:InvalidateChildren(true)
end

vgui.Register("DTreeScroller", PANEL, "DVHScrollPanel")
