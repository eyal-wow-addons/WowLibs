assert(LibStub, "Tooltip-1.0 requires LibStub")

local C = LibStub("Contracts-1.0")
assert(C, "Addon-1.0 requires Contracts-1.0")

local lib = LibStub:NewLibrary("Tooltip-1.0", 0)
if not lib then return end

local setmetatable = setmetatable

local GameTooltip = GameTooltip
local HIGHLIGHT_FONT_COLOR = HIGHLIGHT_FONT_COLOR
local GRAY_FONT_COLOR = GRAY_FONT_COLOR
local GREEN_FONT_COLOR = GREEN_FONT_COLOR

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

do
    local Tooltip_Redirect = function(t, k)
        return Tooltip[k]
    end

    local Tooltip_MT = { __index = Tooltip_Redirect }

    -- This is used to interop with broker panels
    function Tooltip:UseTooltip(tooltip)
        C:IsTable(tooltip, 1)
        if tooltip ~= self.__tooltip then
            if tooltip == GameTooltip or tooltip == Tooltip then
                self.__tooltip = self
            else
                self.__tooltip = setmetatable(tooltip, Tooltip_MT)
            end
        end
        return self.__tooltip
    end
end

function Tooltip:CreateProxy(frame, proxy)
    C:IsTable(frame, 2)
    C:IsTable(proxy, 3)
    return CreateWidgetProxy(frame, proxy)
end

function Tooltip:AddEmptyLine()
    self:AddLine(EMPTY)
end

function Tooltip:AddTitleLine(text, addOnce)
    C:IsString(text, 2)
    if addOnce then
        local numLines = self:NumLines()
        for i = 1, numLines do
            local line = _G["GameTooltipTextLeft" .. i]
            if line then
                local lineText = line:GetText()
                if lineText == text then
                    return
                end
            end
        end
    end
    self:AddEmptyLine()
    self:AddHighlightLine(text)
end

function Tooltip:AddIndentedLine(text, ...)
    C:IsString(text, 2)
    self:AddLine("  " .. text, ...)
end

function Tooltip:AddHighlightLine(text)
    C:IsString(text, 2)
    self:AddLine(text, HIGHLIGHT_FONT_COLOR:GetRGB())
end

function Tooltip:AddGrayLine(text)
    C:IsString(text, 2)
    self:AddLine(text, GRAY_FONT_COLOR:GetRGB())
end

function Tooltip:AddGreenLine(text)
    C:IsString(text, 2)
    self:AddLine(text, GREEN_FONT_COLOR:GetRGB())
end

function Tooltip:AddTitleDoubleLine(textLeft, textRight)
    C:IsString(textLeft, 2)
    C:IsString(textRight, 3)
    self:AddEmptyLine()
    self:AddHighlightDoubleLine(textLeft, textRight)
end

function Tooltip:AddIndentedDoubleLine(textLeft, ...)
    C:IsString(textLeft, 2)
    self:AddDoubleLine("  " .. textLeft, ...)
end

function Tooltip:AddLeftHighlightDoubleLine(textLeft, textRight, r, g, b)
    C:IsString(textLeft, 2)
    C:IsString(textRight, 3)
    self:AddDoubleLine(textLeft, textRight, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, r, g, b)
end

function Tooltip:AddRightRedDoubleLine(textLeft, textRight, r, g, b)
    C:IsString(textLeft, 2)
    C:IsString(textRight, 3)
    self:AddDoubleLine(textLeft, textRight, r, g, b, RED_FONT_COLOR:GetRGB())
end

function Tooltip:AddRightYellowDoubleLine(textLeft, textRight, r, g, b)
    C:IsString(textLeft, 2)
    C:IsString(textRight, 3)
    self:AddDoubleLine(textLeft, textRight, r, g, b, YELLOW_FONT_COLOR:GetRGB())
end

function Tooltip:AddRightOrangeDoubleLine(textLeft, textRight, r, g, b)
    C:IsString(textLeft, 2)
    C:IsString(textRight, 3)
    self:AddDoubleLine(textLeft, textRight, r, g, b, ORANGE_FONT_COLOR:GetRGB())
end

function Tooltip:AddRightHighlightDoubleLine(textLeft, textRight, r, g, b)
    C:IsString(textLeft, 2)
    C:IsString(textRight, 3)
    self:AddDoubleLine(textLeft, textRight, r, g, b, HIGHLIGHT_FONT_COLOR:GetRGB())
end

function Tooltip:AddHighlightDoubleLine(textLeft, textRight)
    C:IsString(textLeft, 2)
    C:IsString(textRight, 3)
    self:AddDoubleLine(textLeft, textRight, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR:GetRGB())
end

function Tooltip:AddGrayDoubleLine(textLeft, textRight)
    C:IsString(textLeft, 2)
    C:IsString(textRight, 3)
    self:AddDoubleLine(textLeft, textRight, GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b, GRAY_FONT_COLOR:GetRGB())
end

function Tooltip:AddLeftGrayDoubleLine(textLeft, textRight)
    C:IsString(textLeft, 2)
    C:IsString(textRight, 3)
    self:AddDoubleLine(textLeft, textRight, nil, nil, nil, GRAY_FONT_COLOR:GetRGB())
end

function Tooltip:AddIcon(texture)
    C:Requires(texture, 2, "string", "number")
    self:AddTexture(texture, ICON_TEXTURE_SETTINGS)
end

--[[local FluentApi = {}

function FluentApi:SetLeftText(text, r, g, b)
    return FluentApi
end

function FluentApi:SetRightText(text, r, g, b)
    return FluentApi
end

function FluentApi:Indent()
    return FluentApi
end

function FluentApi:NewLine()
    return FluentApi
end

function FluentApi:SetIcon()
    return FluentApi
end

function FluentApi:ToSingle()
end

function FluentApi:ToDouble()
end

function FluentApi:ToTitle()
end]]

