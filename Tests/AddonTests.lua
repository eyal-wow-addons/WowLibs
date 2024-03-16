local T = LibStub("UnitTest-1.0"):Test("Addon-1.0")

do
    local Addon = T:Test("Addon")

    local eventsOrder = {
        ["addon:OnInitializing"] = 1,
        ["object:OnInitializing"] = 2,
        ["addon:OnInitialized"] = 3,
        ["object:OnInitialized"] = 4,
        ["object:RegisterCallback"] = 5,
        ["object:RegisterEvents:PLAYER_LOGIN"] = 6,
        ["object:RegisterEvent:CUSTOM_EVENT:PLAYER_LOGIN"] = 7,
        ["object:RegisterEvents:PLAYER_ENTERING_WORLD"] = 8,
        ["object:RegisterEvent:CUSTOM_EVENT:PLAYER_ENTERING_WORLD"] = 9
    }

    local actualEventsOrder = {}

    local addon = T:Ref():New("WowLibs", {})
    local LifeCycleObjectTest = addon:NewObject("LifeCycleObjectTest")

    function addon:OnInitializing()
        table.insert(actualEventsOrder, "addon:OnInitializing")
    end
    
    function addon:OnInitialized()
        table.insert(actualEventsOrder, "addon:OnInitialized")
    end
    
    function LifeCycleObjectTest:OnInitializing()
        table.insert(actualEventsOrder, "object:OnInitializing")
    end
    
    function LifeCycleObjectTest:OnInitialized()
        table.insert(actualEventsOrder, "object:OnInitialized")
    end
    
    LifeCycleObjectTest:RegisterCallback(function()
        table.insert(actualEventsOrder, "object:RegisterCallback")
    end)
    
    LifeCycleObjectTest:RegisterEvents(
        "PLAYER_LOGIN",
        "PLAYER_ENTERING_WORLD", function(self, eventName)
            table.insert(actualEventsOrder, ("object:RegisterEvents:%s"):format(eventName))
            self:TriggerEvent("CUSTOM_EVENT", eventName)
        end)
    
    LifeCycleObjectTest:RegisterEvent("CUSTOM_EVENT", function(_, eventName, arg1)
        table.insert(actualEventsOrder, ("object:RegisterEvent:%s:%s"):format(eventName, arg1))
    end)

    Addon["Should fire the events in the correct order"] = function(self)
        local isEventsOrdered = false

        for index, value in ipairs(actualEventsOrder) do
            isEventsOrdered = false
            if eventsOrder[value] == index then
                isEventsOrdered = true
            else
                break
            end
        end

        self:Assert(isEventsOrdered == true)
    end
end

do
    local New = T:Test("New")

    New["Should return the passed table"] = function(self, lib)
        local tbl = {}

        lib:Delete("Addon1")

        local actualTable = lib:New("Addon1", tbl)

        self:Assert(actualTable == tbl)
    end

    New["Should return nil when the addon was already created"] = function(self, lib)
        local tbl = {}
        
        lib:New("Addon2", tbl)
        
        local actualTable = lib:New("Addon2", tbl)

        self:Assert(actualTable == nil)
    end

    New["Should throw when addonName is not a string"] = function(self, lib)
        self:Capture(function()
            lib:New(nil, {})
        end)
    end

    New["Should throw when addonTable is not a table"] = function(self, lib)
        self:Capture(function()
            lib:New("WowLibs", nil)
        end)
    end
end

