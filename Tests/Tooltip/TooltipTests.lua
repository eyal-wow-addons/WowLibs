local T = LibStub("UnitTest-1.0"):Test("Tooltip-1.0")

do
    local UseTooltip = T:Test("UseTooltip")

    UseTooltip["Should throw when the tooltip is not a table"] = function(self)
        T:Capture(function()
            self:UseTooltip(nil)
        end)
    end

    UseTooltip["Should return the wrapper when the tooltip is GameTooltip"] = function(self)
        local actualTooltip = self:UseTooltip(GameTooltip)

        T:Assert(actualTooltip == self)
    end

    UseTooltip["Should return itself when the tooltip is the wrapper"] = function(self)
        local actualTooltip = self:UseTooltip(self)

        T:Assert(actualTooltip == self)
    end

    UseTooltip["Should redirect the tooltip to the wrapper"] = function(self)
        local tooltip = CreateFrame("GameTooltip", nil, nil, "GameTooltipTemplate")
        local actualTooltip = self:UseTooltip(tooltip)
        T:Assert(actualTooltip == tooltip)
        T:Assert(tooltip.CreateProxy ~= nil)
    end
end

do
    local CreateProxy = T:Test("CreateProxy")

    CreateProxy["Should throw when the frame is not a table"] = function(self)
        T:Capture(function()
            self:CreateProxy(nil, {})
        end)
    end

    CreateProxy["Should throw when the proxy is not a table"] = function(self)
        T:Capture(function()
            self:CreateProxy({}, nil)
        end)
    end

    CreateProxy["Should return the proxy object"] = function(self)
        local tooltip = CreateFrame("GameTooltip", nil, nil, "GameTooltipTemplate")

        local proxy = {}
        local actualProxy = self:CreateProxy(tooltip, proxy)

        T:Assert(actualProxy == proxy)
        T:Assert(actualProxy:NumLines() == 0)
    end
end