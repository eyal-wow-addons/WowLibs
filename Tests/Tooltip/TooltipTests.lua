local M = LibStub("UnitTest-1.0"):CreateModule("Tooltip-1.0")

do
    local UseTooltip = M:Test("UseTooltip")

    UseTooltip["Should throw when the tooltip is not a table"] = function(self)
        M:Capture(function()
            self:UseTooltip(nil)
        end)
    end

    UseTooltip["Should return the wrapper when the tooltip is GameTooltip"] = function(self)
        local actualTooltip = self:UseTooltip(GameTooltip)

        M:Assert(actualTooltip == self)
    end

    UseTooltip["Should return itself when the tooltip is the wrapper"] = function(self)
        local actualTooltip = self:UseTooltip(self)

        M:Assert(actualTooltip == self)
    end

    UseTooltip["Should redirect the tooltip to the wrapper"] = function(self)
        local tooltip = CreateFrame("GameTooltip", nil, nil, "GameTooltipTemplate")
        local actualTooltip = self:UseTooltip(tooltip)
        M:Assert(actualTooltip == tooltip)
        M:Assert(tooltip.CreateProxy ~= nil)
    end
end

do
    local CreateProxy = M:Test("CreateProxy")

    CreateProxy["Should throw when the frame is not a table"] = function(self)
        M:Capture(function()
            self:CreateProxy(nil, {})
        end)
    end

    CreateProxy["Should throw when the proxy is not a table"] = function(self)
        M:Capture(function()
            self:CreateProxy({}, nil)
        end)
    end

    CreateProxy["Should return the proxy object"] = function(self)
        local tooltip = CreateFrame("GameTooltip", nil, nil, "GameTooltipTemplate")

        local proxy = {}
        local actualProxy = self:CreateProxy(tooltip, proxy)

        M:Assert(actualProxy == proxy)
        M:Assert(actualProxy:NumLines() == 0)
    end
end