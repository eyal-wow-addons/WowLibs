local T = LibStub("UnitTest-1.0"):Test("Tooltip-1.0")

do
    local UseTooltip = T:Test("UseTooltip")

    UseTooltip["Should throw when the tooltip is not a table"] = function(self, lib)
        self:Capture(function()
            lib:UseTooltip(nil)
        end)
    end

    UseTooltip["Should return the wrapper when the tooltip is GameTooltip"] = function(self, lib)
        local actualTooltip = lib:UseTooltip(GameTooltip)

        self:Assert(actualTooltip == lib)
    end

    UseTooltip["Should return itself when the tooltip is the wrapper"] = function(self, lib)
        local actualTooltip = lib:UseTooltip(lib)

        self:Assert(actualTooltip == lib)
    end

    UseTooltip["Should redirect the tooltip to the wrapper"] = function(self, lib)
        local tooltip = CreateFrame("GameTooltip", nil, nil, "GameTooltipTemplate")
        local actualTooltip = lib:UseTooltip(tooltip)
        self:Assert(actualTooltip == tooltip)
        self:Assert(tooltip.CreateProxy ~= nil)
    end
end

do
    local CreateProxy = T:Test("CreateProxy")

    CreateProxy["Should throw when the frame is not a table"] = function(self, lib)
        self:Capture(function()
            lib:CreateProxy(nil, {})
        end)
    end

    CreateProxy["Should throw when the proxy is not a table"] = function(self, lib)
        self:Capture(function()
            lib:CreateProxy({}, nil)
        end)
    end

    CreateProxy["Should return the proxy object"] = function(self, lib)
        local tooltip = CreateFrame("GameTooltip", nil, nil, "GameTooltipTemplate")

        local proxy = {}
        local actualProxy = lib:CreateProxy(tooltip, proxy)

        self:Assert(actualProxy == proxy)
        self:Assert(actualProxy:NumLines() == 0)
    end
end