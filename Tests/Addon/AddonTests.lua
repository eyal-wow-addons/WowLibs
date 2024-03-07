local U = LibStub("UnitTest-1.0")

local addon = LibStub("Addon-1.0")

do
    local New = U:CreateScope("New")

    New["Should return the passed table"] = function(self)
        local table = {}
        local actualTable = addon:New("WowLibs", table)

        self:Assert(actualTable ~= table)
    end

    New["Should throw when addonName is not a string"] = function(self)
        self:Capture(function()
            addon:New("WowLibs", {})
        end)
    end

    New["Should throw when addonName is not valid"] = function(self)
        self:Capture(function()
            addon:New("Foo", {})
        end)
    end

    New["Should throw when addonTable is not a table"] = function(self)
        self:Capture(function()
            addon:New("WowLibs", nil)
        end)
    end
end

