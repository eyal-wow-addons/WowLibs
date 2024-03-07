local U = LibStub("UnitTest-1.0")

local addon = LibStub("Addon-1.0")

do
    local New = U:CreateScope("New")

    New["Should return the passed table"] = function(self)
        local table = {}
        local actualTable = addon:New("Addon1", table)

        self:Assert(actualTable == table)
    end

    New["Should return nil when the addon was already created"] = function(self)
        local table = {}
        local actualTable = addon:New("Addon1", table)

        self:Assert(actualTable == nil)
    end

    New["Should throw when addonName is not a string"] = function(self)
        self:Capture(function()
            addon:New(nil, {})
        end)
    end

    New["Should throw when addonTable is not a table"] = function(self)
        self:Capture(function()
            addon:New("WowLibs", nil)
        end)
    end
end

