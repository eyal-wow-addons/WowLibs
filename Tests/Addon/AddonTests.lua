local M = LibStub("UnitTest-1.0"):CreateModule("Addon-1.0")

do
    local New = M:Test("New")

    New["Should return the passed table"] = function(self)
        local table = {}
        local actualTable = self:New("Addon1", table)

        M:Assert(actualTable == table)
    end

    New["Should return nil when the addon was already created"] = function(self)
        local table = {}
        local actualTable = self:New("Addon1", table)

        M:Assert(actualTable == nil)
    end

    New["Should throw when addonName is not a string"] = function(self)
        M:Capture(function()
            self:New(nil, {})
        end)
    end

    New["Should throw when addonTable is not a table"] = function(self)
        M:Capture(function()
            self:New("WowLibs", nil)
        end)
    end
end

