local T = LibStub("UnitTest-1.0"):Test("Addon-1.0")

do
    local New = T:Test("New")

    New["Should return the passed table"] = function(self)
        local table = {}
        local actualTable = self:New("Addon1", table)

        T:Assert(actualTable == table)
    end

    New["Should return nil when the addon was already created"] = function(self)
        local table = {}
        local actualTable = self:New("Addon1", table)

        T:Assert(actualTable == nil)
    end

    New["Should throw when addonName is not a string"] = function(self)
        T:Capture(function()
            self:New(nil, {})
        end)
    end

    New["Should throw when addonTable is not a table"] = function(self)
        T:Capture(function()
            self:New("WowLibs", nil)
        end)
    end
end

