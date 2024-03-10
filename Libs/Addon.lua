assert(LibStub, "Addon-1.0 requires LibStub")

local C = LibStub("Contracts-1.0")
assert(C, "Addon-1.0 requires Contracts-1.0")

local lib = LibStub:NewLibrary("Addon-1.0", 0)
if not lib then return end

lib.Addons = {}

local ipairs, pairs = ipairs, pairs
local pcall, geterrorhandler = pcall, geterrorhandler
local select = select
local setmetatable = setmetatable
local tinsert, tremove = table.insert, table.remove
local type = type

local NewTicker = C_Timer.NewTicker
local IsEventValid = C_EventUtils.IsEventValid

local Objects = {}
local Callbacks = {}
Callbacks["PLAYER_LOGIN"] = {}

--[[ Localization ]]

local L = {
    ["ADDON_MISSING"] = "The addon '%s' is missing or does not exist.",
	["OBJECT_ALREADY_EXISTS"] = "the object '%s' already exists.",
	["OBJECT_DOES_NOT_EXIST"] = "the object '%s' does not exist.",
	["CANNOT_REGISTER_EVENT"] = "cannot register event '%s'.",
    ["CANNOT_UNREGISTER_EVENT"] = "cannot unregister event '%s'."
}

--[[ Library Helper Methods ]]

local function SafeCall(func, ...)
	local success, err = pcall(func, ...)
	if not success then
		geterrorhandler()(err)
	end
end

--[[ Events Management ]]

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, eventName, ...)
    if eventName == "ADDON_LOADED" then
        local arg1 = ...
        if lib.Addons[arg1] then
            for _, object in ipairs(Objects) do
                local callback = object.OnInitializing
                if callback then
                    SafeCall(callback, object)
                    object.OnInitializing = nil
                end
            end
        end
        return
    elseif eventName == "PLAYER_LOGIN" then
        for _, object in ipairs(Objects) do
            local callback = object.OnInitialized
            if callback then
                SafeCall(callback, object)
            end
        end
        self:UnregisterEvent(eventName)
    end
    Callbacks:TriggerEvent(eventName, ...)
end)

function Callbacks:RegisterCallback(callback)
    C:IsFunction(callback, 2)
    tinsert(Callbacks["PLAYER_LOGIN"], callback)
end

function Callbacks:RegisterHookScript(frame, eventName, callback)
    C:IsTable(frame, 2)
    C:IsString(eventName, 3)
    C:IsFunction(callback, 4)
    self:RegisterCallback(function()
        frame:HookScript(eventName, callback)
    end)
end

function Callbacks:RegisterEvent(eventName, callback)
    C:IsString(eventName, 2)
    C:IsFunction(callback, 3)
    C:Ensures(eventName ~= "ADDON_LOADED", L["CANNOT_REGISTER_EVENT"], eventName)
    local callbacks = Callbacks[eventName]
    if not callbacks then
        callbacks = {}
        Callbacks[eventName] = callbacks
        if IsEventValid(eventName) then
            frame:RegisterEvent(eventName)
        end
    end
    tinsert(callbacks, callback)
end

function Callbacks:RegisterEvents(...)
    local eventNames = {}
    local callback
    for i = 1, select("#", ...) do
        local arg = select(i, ...)
        if type(arg) == "string" then
            C:Ensures(arg ~= "ADDON_LOADED", L["CANNOT_REGISTER_EVENT"], arg)
            tinsert(eventNames, arg)
        elseif type(arg) == "function" then
            callback = arg
            break
        end
    end
    if callback then
        for _, eventName in ipairs(eventNames) do
            self:RegisterEvent(eventName, callback)
        end
    end
end

function Callbacks:UnregisterEvent(eventName, callback)
    C:IsString(eventName, 2, "string")
    C:IsFunction(callback, 3, "function")
    C:Ensures(eventName ~= "ADDON_LOADED", L["CANNOT_UNREGISTER_EVENT"], eventName)
    local callbacks = Callbacks[eventName]
    if callbacks then
        for i = #callbacks, 1, -1 do
            local registeredCallback = callbacks[i]
            if not callback or registeredCallback == callback then
                tremove(Callbacks[eventName], i)
                if callback then
                    break
                end
            end
        end
        if #Callbacks[eventName] == 0 then
            if IsEventValid(eventName) then
                frame:UnregisterEvent(eventName)
            end
            Callbacks[eventName] = nil
        elseif not callback then
            Callbacks[eventName] = nil
        end
    end
end

function Callbacks:TriggerEvent(eventName, ...)
    C:IsString(eventName, 2)
    local callbacks = Callbacks[eventName]
    if callbacks then
        for _, callback in ipairs(callbacks) do
            SafeCall(callback, self, eventName, ...)
        end
    end
end

--[[ Core API ]]

do
    local Api = {}

    local function New(self, name)
        C:IsTable(self, 1)
        C:IsString(name, 2)
        local object = self[name]

        if not object then
            object = {}
            self[name] = object
        else
            C:Ensures(false, L["OBJECT_ALREADY_EXISTS"], name)
        end

        tinsert(Objects, object)

        for key, value in pairs(Callbacks) do
            if type(value) == "function" and not object[key] then
                object[key] = value
            end
        end

        return object
    end

    function Api:NewObject(name)
        C:IsString(name, 2)
        local object = New(self, name)

        --Mixin(object, ...)

        local storage = self[name .. "Storage"]

        if storage then
            object.storage = storage
        end

        return object
    end

    function Api:NewStorage(name)
        C:IsString(name, 2)
        local storage = New(self, name .. "Storage")

        function storage:RegisterDB(defaults)
            return self.DB:RegisterNamespace(name, defaults)
        end

        return storage
    end

    function Api:GetStorage(name)
        C:IsString(name, 2)
        local fullName = name .. "Storage"
        local storage = self[fullName]
        C:Ensures(storage ~= nil, L["OBJECT_DOES_NOT_EXIST"], fullName)
        return storage
    end

    function Api:SetDependency(dependencyName)
        C:IsString(dependencyName, 2)
        local dependencyTable = lib.Addons[dependencyName]

        if dependencyTable then
            setmetatable(self, { __index = dependencyTable })
        end
    end

    function Api:CreateTimer(callback)
        local t = {}
        local __handle = nil
        local __callback = callback
    
        function t:Start(seconds)
            self:Cancel()
            __handle = NewTicker(seconds, __callback)
        end
    
        function t:StartOnce(seconds)
            self:Cancel()
            __handle = NewTicker(seconds, __callback, 1)
        end
    
        function t:Cancel()
            if __handle then
                __handle:Cancel()
                __handle = nil
            end
        end
    
        return t
    end

    function lib:New(name, table)
        C:IsString(name, 2)
        C:IsTable(table, 3)
        if not self.Addons[name] then
            tinsert(Objects, table)
            for key, value in pairs(Api) do
                if type(value) == "function" and not table[key] then
                    table[key] = value
                end
            end
            self.Addons[name] = table
            return table
        end
    end
end