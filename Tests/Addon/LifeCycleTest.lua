local addon = LibStub("Addon-1.0"):New(...)

local LifeCycleTest = addon:NewObject("LifeCycleTest")

function addon:OnInitializing()
    print("<LifeCycleTest> addon:OnInitializing")
end

function addon:OnInitialized()
    print("<LifeCycleTest> addon:OnInitialized")
end

function LifeCycleTest:OnInitializing()
    print("<LifeCycleTest> LifeCycleTest:OnInitializing")
end

function LifeCycleTest:OnInitialized()
    print("<LifeCycleTest> LifeCycleTest:OnInitialized")
end

LifeCycleTest:RegisterCallback(function()
    print("<LifeCycleTest> LifeCycleTest:RegisterCallback")
end)

LifeCycleTest:RegisterEvents(
    "PLAYER_LOGIN",
    "PLAYER_MONEY", function(self, eventName)
        print("<LifeCycleTest> LifeCycleTest:RegisterEvents:" .. eventName)
        self:TriggerEvent("CUSTOM_EVENT", "Hey!")
    end)

LifeCycleTest:RegisterEvent("CUSTOM_EVENT", function(self, eventName, arg1)
    print(("<LifeCycleTest> LifeCycleTest:RegisterEvent:%s %s"):format(eventName, arg1))
end)