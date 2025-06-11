---@class DVHScrollPanel: DPanel
local PANEL = {}

AccessorFunc(PANEL, "Padding", "Padding")
AccessorFunc(PANEL, "pnlCanvas", "Canvas")

function PANEL:Init()
	self.pnlCanvas = vgui.Create("Panel", self)
	self.pnlCanvas.OnMousePressed = function(slf, code)
		slf:GetParent():OnMousePressed(code)
	end
	self.pnlCanvas:SetMouseInputEnabled(true)
	self.pnlCanvas.PerformLayout = function(pnl)
		self:PerformLayoutInternal()
		self:InvalidateParent()
	end

	-- Create the vertical scroll bar
	self.VBar = vgui.Create("DVScrollBar", self)
	self.VBar:Dock(RIGHT)

	-- Create the horizontal scroll bar
	self.HBar = vgui.Create("DHScrollBar", self)
	self.HBar:Dock(BOTTOM)

	self.PanelWidth = 1000
	self.LastWidth = 1

	---@diagnostic disable-next-line: undefined-field
	self:SetPadding(0)
	self:SetMouseInputEnabled(true)

	-- This turns off the engine drawing
	self:SetPaintBackgroundEnabled(false)
	self:SetPaintBorderEnabled(false)
	self:SetPaintBackground(false)
end

function PANEL:AddItem(pnl)
	pnl:SetParent(self:GetCanvas())
end

function PANEL:OnChildAdded(child)
	self:AddItem(child)
end

function PANEL:SizeToContents()
	self:SetSize(self.pnlCanvas:GetSize())
end

---@return DVScrollBar
function PANEL:GetVBar()
	return self.VBar
end

---@return DHScrollBar
function PANEL:GetHBar()
	return self.HBar
end

function PANEL:GetCanvas()
	return self.pnlCanvas
end

function PANEL:InnerWidth()
	return self:GetCanvas():GetWide()
end

function PANEL:Rebuild()
	local can = self:GetCanvas()
	can:SizeToChildren(false, true)

	-- Although this behaviour isn't exactly implied, center vertically too
	---@diagnostic disable-next-line: undefined-field
	if self.m_bNoSizing and can:GetTall() < self:GetTall() then
		local y = (self:GetTall() - can:GetTall()) * 0.5
		can:SetPos(can:GetX(), y)
	end

	---@diagnostic disable-next-line: undefined-field
	if self.m_bNoSizing and can:GetWide() < self:GetWide() then
		local x = (self:GetWide() - can:GetWide()) * 0.5
		can:SetPos(x, can:GetY())
	end
end

function PANEL:OnMouseWheeled(dlta)
	if input.IsButtonDown(KEY_LSHIFT) then
		---@diagnostic disable-next-line: undefined-field
		return self.HBar:OnMouseWheeled(dlta)
	end

	---@diagnostic disable-next-line: undefined-field
	return self.VBar:OnMouseWheeled(dlta)
end

function PANEL:OnVScroll(iOffset)
	self.pnlCanvas:SetPos(self.pnlCanvas:GetX(), iOffset)
end

function PANEL:OnHScroll(iOffset)
	self.pnlCanvas:SetPos(iOffset, self.pnlCanvas:GetY())
end

function PANEL:ScrollToChild(panel)
	self:InvalidateLayout(true)

	local x, y = self.pnlCanvas:GetChildPosition(panel)
	local w, h = panel:GetSize()

	y = y + h * 0.5
	y = y - self:GetTall() * 0.5

	x = x + w * 0.5
	x = x - self:GetWide() * 0.5

	self.VBar:AnimateTo(y, 0.5, 0, 0.5)
	self.HBar:AnimateTo(x, 0.5, 0, 0.5)
end

-- Avoid an infinite loop
function PANEL:PerformLayoutInternal()
	local HTall, VTall = self:GetTall(), self.pnlCanvas:GetTall()
	local HWide, VWide = self:GetWide(), self.PanelWidth
	local XPos, YPos = 0, 0

	self:Rebuild()

	self.VBar:SetUp(self:GetTall(), self.pnlCanvas:GetTall())
	self.HBar:SetUp(self:GetWide(), self.pnlCanvas:GetWide())
	YPos = self.VBar:GetOffset()
	XPos = self.HBar:GetOffset()

	---@diagnostic disable-next-line: undefined-field
	if self.VBar.Enabled then
		VWide = VWide - self.VBar:GetWide()
	end
	---@diagnostic disable-next-line: undefined-field
	if self.HBar.Enabled then
		HTall = HTall - self.HBar:GetTall()
	end

	self.pnlCanvas:SetPos(XPos, YPos)
	self.pnlCanvas:SetSize(VWide, HTall)

	self:Rebuild()

	if HWide ~= self.LastWidth then
		self.HBar:SetScroll(self.HBar:GetScroll()) -- Make sure we are not too far wide!
	end
	if VTall ~= self.pnlCanvas:GetTall() then
		self.VBar:SetScroll(self.VBar:GetScroll()) -- Make sure we are not too far down!
	end

	self.LastWidth = HWide
end

function PANEL:UpdateWidth(newWidth)
	self.PanelWidth = newWidth
	self:InvalidateLayout()
end

function PANEL:PerformLayout()
	self:PerformLayoutInternal()
end

function PANEL:Clear()
	return self.pnlCanvas:Clear()
end

derma.DefineControl("DVHScrollPanel", "", PANEL, "DPanel")
