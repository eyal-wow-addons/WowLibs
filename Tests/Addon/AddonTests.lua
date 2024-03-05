local U = LibStub("UnitTest-1.0")
local addon = LibStub("Addon-1.0")

do -- New
    U:Test("New: Should return the passed table", function(self)
        local table = {}
        local actualTable = addon:New("WowLibs", table)

        self:Assert(actualTable == table)
    end)

    U:Test("New: Should throw when addonName is not a string", function(self)
        self:Capture(function()
            addon:New(nil, {})
        end)
    end)

    U:Test("New: Should throw when addonName is not valid", function(self)
        self:Capture(function()
            addon:New("Foo", {})
        end)
    end)

    U:Test("New: Should throw when addonTable is not a table", function(self)
        self:Capture(function()
            addon:New("WowLibs", nil)
        end)
    end)
end