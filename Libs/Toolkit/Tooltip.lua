assert(LibStub, "Tooltip-1.0 requires LibStub")

local C = LibStub("Contracts-1.0")
assert(C, "Addon-1.0 requires Contracts-1.0")

local lib = LibStub:NewLibrary("Tooltip-1.0", 0)
if not lib then return end

local setmetatable = setmetatable

local GameTooltip = GameTooltip
local HIGHLIGHT_FONT_COLOR = HIGHLIGHT_FONT_COLOR
local GRAY_FONT_COLOR = GRAY_FONT_COLOR
local RED_FONT_COLOR = RED_FONT_COLOR
local GREEN_FONT_COLOR = GREEN_FONT_COLOR
local YELLOW_FONT_COLOR = YELLOW_FONT_COLOR
local ORANGE_FONT_COLOR = ORANGE_FONT_COLOR

local EMPTY = " "

local ICON_TEXTURE_SETTINGS = {
    width = 20,
    height = 20,
    verticalOffset = 3,
    margin = { right = 5, bottom = 5 },
}

local function CreateWidgetProxy(frame, proxy)
    C:IsTable(frame, 1)
    C:IsTable(proxy, 2)

    local mt  = {
        __index = frame
    }

    local wrapper = setmetatable(proxy, mt)

    -- Sets the userdata so the widget API would work with the wrapper
    wrapper[0] = frame[0]

    return wrapper
end

local Tooltip = CreateWidgetProxy(GameTooltip, lib)

function Tooltip:CreateProxy(proxy)
    C:IsTable(proxy, 2)
    return CreateWidgetProxy(self, proxy)
end

function Tooltip:AddEmptyLine()
    self:AddLine(EMPTY)
end

local TooltipLineMetadata = {
    isHeader = false,
    isDoubleLine = false,
    leftText = nil,
    rightText = nil,
    leftColor = nil,
    rightColor = nil,
    texture = nil
}

function TooltipLineMetadata:Clear()
    self.isHeader = false
    self.isDoubleLine = false
    self.leftText = nil
    self.rightText = nil
    self.leftColor = nil
    self.rightColor = nil
    self.texture = nil
end

function TooltipLineMetadata:SetLeftColor(color)
    self.leftColor = color
end

function TooltipLineMetadata:SetRightColor(color)
    self.rightColor = color
end

function TooltipLineMetadata:GetLeftColor()
    if self.leftColor then
        return self.leftColor:GetRGB()
    else
        return nil, nil, nil
    end
end

function TooltipLineMetadata:GetRightColor()
    if self.rightColor then
        return self.rightColor:GetRGB()
    else
        return nil, nil, nil
    end
end

function Tooltip:SetText(text)
    C:IsString(text, 2)
    local data = TooltipLineMetadata
    if not data.leftText then
        data.leftText = text
    elseif not data.rightText then
        data.rightText = text
        data.isDoubleLine = true
    end
    return self
end

function Tooltip:Format(pattern, ...)
    C:IsString(pattern, 2)
    return self:SetText(pattern:format(...))
end

function Tooltip:SetColor(color)
    local data = TooltipLineMetadata
    if not data.isDoubleLine then
        data:SetLeftColor(color)
    else
        data:SetRightColor(color)
    end
    return self
end

function Tooltip:SetRedColor()
    self:SetColor(RED_FONT_COLOR)
    return self
end

function Tooltip:SetGreenColor()
    self:SetColor(GREEN_FONT_COLOR)
    return self
end

function Tooltip:SetGrayColor()
    self:SetColor(GRAY_FONT_COLOR)
    return self
end

function Tooltip:SetYellowColor()
    self:SetColor(YELLOW_FONT_COLOR)
    return self
end

function Tooltip:SetOrangeColor()
    self:SetColor(ORANGE_FONT_COLOR)
    return self
end

function Tooltip:SetClassColor()
    local classFilename = select(2, UnitClass("player"))
	local color = RAID_CLASS_COLORS[classFilename] or NORMAL_FONT_COLOR
    self:SetColor(color)
    return self
end

function Tooltip:WrapWithClassColor()
    local data = TooltipLineMetadata
    if not data.isDoubleLine then
        data.leftText = GetClassColoredTextForUnit("player", data.leftText)
    else
        data.rightText = GetClassColoredTextForUnit("player", data.rightText)
    end
    return self
end

function Tooltip:Indent()
    local data = TooltipLineMetadata
    if not data.isDoubleLine then
        data.leftText = "  " .. data.leftText
    else
        data.rightText = "  " .. data.rightText
    end
    return self
end

-- TODO: NYI
function Tooltip:SetIcon(texture)
    C:Requires(texture, 2, "string", "number")
    -- self:AddTexture(texture, ICON_TEXTURE_SETTINGS)
    TooltipLineMetadata.texture = texture
end

function Tooltip:AsHeader()
    local data = TooltipLineMetadata
    data.isHeader = true
    data:SetLeftColor(HIGHLIGHT_FONT_COLOR)
    data:SetRightColor(HIGHLIGHT_FONT_COLOR)
    return self
end

function Tooltip:ToHeader(leftPattern, rightPattern)
    self:AsHeader()

    local data = TooltipLineMetadata

    if leftPattern and data.leftText then
        data.leftText = leftPattern:format(data.leftText)
    end

    if rightPattern and data.rightText then
        data.rightText = rightPattern:format(data.rightText)
    end

    if not data.isDoubleLine then
        self:ToLine()
    else
        self:ToDoubleLine()
    end
end

function Tooltip:ToLine()
    local data = TooltipLineMetadata
    local lR, lG, lB = data:GetLeftColor()

    if data.isHeader then
        self:AddEmptyLine()
    end

    self:AddLine(data.leftText, lR, lG, lB)

    data:Clear()
end

function Tooltip:ToDoubleLine()
    local data = TooltipLineMetadata
    local lR, lG, lB = data:GetLeftColor()
    local rR, rG, rB = data:GetRightColor()

    if data.isHeader then
        self:AddEmptyLine()
    end

    self:AddDoubleLine(data.leftText, data.rightText, lR, lG, lB, rR, rG, rB)

    data:Clear()
end