assert(LibStub, "Tooltip-1.0 requires LibStub")

local C = LibStub("Contracts-1.0")
assert(C, "Addon-1.0 requires Contracts-1.0")

local lib = LibStub:NewLibrary("Tooltip-1.0", 0)
if not lib then return end

local rep = string.rep
local select = select

local UnitClass = UnitClass

local GameTooltip = GameTooltip
local NORMAL_FONT_COLOR = NORMAL_FONT_COLOR
local HIGHLIGHT_FONT_COLOR = HIGHLIGHT_FONT_COLOR
local GRAY_FONT_COLOR = GRAY_FONT_COLOR
local RED_FONT_COLOR = RED_FONT_COLOR
local GREEN_FONT_COLOR = GREEN_FONT_COLOR
local BLUE_FONT_COLOR = BLUE_FONT_COLOR
local WHITE_FONT_COLOR = WHITE_FONT_COLOR
local YELLOW_FONT_COLOR = YELLOW_FONT_COLOR
local ORANGE_FONT_COLOR = ORANGE_FONT_COLOR
local RAID_CLASS_COLORS = RAID_CLASS_COLORS

do
    lib.Line = lib.Line or {}

    local TooltipLine = {
        isHeader = false,
        isDoubleLine = false,
        leftText = nil,
        rightText = nil,
        leftColor = nil,
        rightColor = nil
    }

    function lib.Line:Clear()
        TooltipLine.isHeader = false
        TooltipLine.isDoubleLine = false
        TooltipLine.leftText = nil
        TooltipLine.rightText = nil
        TooltipLine.leftColor = nil
        TooltipLine.rightColor = nil
    end

    function lib.Line:IsHeader()
        return TooltipLine.isHeader
    end

    function lib.Line:SetHeader()
        if not TooltipLine.leftColor then
            self:SetLeftColor(HIGHLIGHT_FONT_COLOR)
        end
        if not TooltipLine.rightColor then
            self:SetRightColor(HIGHLIGHT_FONT_COLOR)
        end
        TooltipLine.isHeader = true
    end

    function lib.Line:IsDoubleLine()
        return TooltipLine.isDoubleLine
    end

    function lib.Line:SetLeftText(text)
        TooltipLine.leftText = text
    end

    function lib.Line:SetRightText(text)
        TooltipLine.rightText = text
        TooltipLine.isDoubleLine = true
    end

    function lib.Line:GetText()
        return TooltipLine.leftText, TooltipLine.rightText
    end

    function lib.Line:SetLeftColor(color)
        TooltipLine.leftColor = color
    end

    function lib.Line:SetRightColor(color)
        TooltipLine.rightColor = color
    end

    function lib.Line:GetLeftColor()
        if TooltipLine.leftColor then
            return TooltipLine.leftColor:GetRGB()
        else
            return nil, nil, nil
        end
    end

    function lib.Line:GetRightColor()
        if TooltipLine.rightColor then
            return TooltipLine.rightColor:GetRGB()
        else
            return nil, nil, nil
        end
    end
end

function lib:SetLine(text)
    C:Requires(text, 2, "string", "number")
    local line = self.Line
    local leftText = line:GetText()
    if not leftText then
        line:SetLeftText(text)
    else
        line:SetRightText(text)
    end
    return self
end

function lib:SetFormattedLine(pattern, ...)
    C:IsString(pattern, 2)
    return self:SetLine(pattern:format(...))
end

function lib:SetDoubleLine(leftText, rightText)
    C:Requires(leftText, 2, "string", "number")
    C:Requires(rightText, 3, "string", "number")
    return self:SetLine(leftText):SetLine(rightText)
end

function lib:SetColor(color)
    C:Requires(color, 2, "table")
    local line = self.Line
    if not line:IsDoubleLine() then
        line:SetLeftColor(color)
    else
        line:SetRightColor(color)
    end
    return self
end

function lib:WrapText(color)
    C:Requires(color, 2, "table")
    local line = self.Line
    local leftText, rightText = line:GetText()
    if not line:IsDoubleLine() then
        leftText = color and color:WrapTextInColorCode(leftText) or leftText
        line:SetLeftText(leftText)
    else
        rightText = color and color:WrapTextInColorCode(rightText) or rightText
        line:SetRightText(rightText)
    end
    return self
end

do
    local function WrapTextOrSetColor(color, wrap)
        return wrap and lib:WrapText(color) or lib:SetColor(color)
    end

    function lib:SetHighlight(wrap)
        return WrapTextOrSetColor(HIGHLIGHT_FONT_COLOR, wrap)
    end

    function lib:SetWhiteColor(wrap)
        return WrapTextOrSetColor(WHITE_FONT_COLOR, wrap)
    end

    function lib:SetRedColor(wrap)
        return WrapTextOrSetColor(RED_FONT_COLOR, wrap)
    end

    function lib:SetGreenColor(wrap)
        return WrapTextOrSetColor(GREEN_FONT_COLOR, wrap)
    end

    function lib:SetBlueColor(wrap)
        return WrapTextOrSetColor(BLUE_FONT_COLOR, wrap)
    end

    function lib:SetGrayColor(wrap)
        return WrapTextOrSetColor(GRAY_FONT_COLOR, wrap)
    end

    function lib:SetYellowColor(wrap)
        return WrapTextOrSetColor(YELLOW_FONT_COLOR, wrap)
    end

    function lib:SetOrangeColor(wrap)
        return WrapTextOrSetColor(ORANGE_FONT_COLOR, wrap)
    end

    function lib:SetClassColor(classFilename, wrap)
        local color = RAID_CLASS_COLORS[classFilename] or NORMAL_FONT_COLOR
        return WrapTextOrSetColor(color, wrap)
    end

    function lib:SetUnitClassColor(unit, wrap)
        C:Requires(unit, 2, "string")
        return self:SetClassColor(select(2, UnitClass(unit)), wrap)
    end

    function lib:SetPlayerClassColor(wrap)
        return self:SetUnitClassColor("player", wrap)
    end

    function lib:SetItemQualityColor(item, wrap)
        local itemColor = item:GetItemQualityColor()
        itemColor = itemColor and itemColor.color or NORMAL_FONT_COLOR
        return WrapTextOrSetColor(itemColor, wrap)
    end
end

function lib:Indent(length)
    length = ((not length or length < 1) and 2) or length
    local indent = rep(" ", length)
    local line = self.Line
    local leftText, rightText = line:GetText()
    if not line:IsDoubleLine() then
        line:SetLeftText(indent .. leftText)
    else
        line:SetRightText(indent .. rightText)
    end
    return self
end

function lib:ToHeader()
    self:AddEmptyLine()
    self.Line:SetHeader()
    return self:ToLine()
end

function lib:ToLine()
    local line = self.Line
    local leftText, rightText = line:GetText()
    local lR, lG, lB = line:GetLeftColor()

    if not line:IsDoubleLine() then
        GameTooltip:AddLine(leftText, lR, lG, lB)
    else
        local rR, rG, rB = line:GetRightColor()
        GameTooltip:AddDoubleLine(leftText, rightText, lR, lG, lB, rR, rG, rB)
    end

    line:Clear()

    return self
end

function lib:AddHeader(text)
    C:Requires(text, 2, "string", "number")
    return self:SetLine(text):ToHeader()
end

function lib:AddFormattedHeader(pattern, ...)
    C:Requires(pattern, 2, "string")
    return self:SetFormattedLine(pattern, ...):ToHeader()
end

function lib:AddLine(text)
    C:Requires(text, 2, "string", "number")
    return self:SetLine(text):ToLine()
end

function lib:AddFormattedLine(pattern, ...)
    C:Requires(pattern, 2, "string")
    return self:SetFormattedLine(pattern, ...):ToLine()
end

function lib:AddDoubleLine(leftText, rightText)
    C:Requires(leftText, 2, "string", "number")
    C:Requires(rightText, 3, "string", "number")
    return self:SetDoubleLine(leftText, rightText):ToLine()
end

do
    local ICON_TEXTURE_SETTINGS = {
        width = 20,
        height = 20,
        verticalOffset = 3,
        margin = { right = 5, bottom = 5 },
    }

    function lib:AddIcon(texture)
        C:Requires(texture, 2, "string", "number")
        GameTooltip:AddTexture(texture, ICON_TEXTURE_SETTINGS)
        return self
    end
end

do
    local EMPTY = " "

    function lib:AddEmptyLine()
        GameTooltip:AddLine(EMPTY)
        return self
    end
end

function lib:Clear()
    GameTooltip:ClearLines()
end

function lib:Show()
    GameTooltip:Show()
end

function lib:Hide()
    GameTooltip:Hide()
end