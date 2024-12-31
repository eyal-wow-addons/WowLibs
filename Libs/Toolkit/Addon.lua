---@diagnostic disable: undefined-field
assert(LibStub, "Addon-1.0 requires LibStub")

local C = LibStub("Contracts-1.0")
assert(C, "Addon-1.0 requires Contracts-1.0")

local lib = LibStub:NewLibrary("Addon-1.0", 0)
if not lib then return end

local Addon = {}
local Object = {}

local ipairs, pairs = ipairs, pairs
local pcall, geterrorhandler = pcall, geterrorhandler
local select = select
local setmetatable = setmetatable
local tinsert, tremove = table.insert, table.remove
local type = type

local IsEventValid = C_EventUtils.IsEventValid

--[[ Localization ]]

local L = {
    ["ADDON_CONTEXT_DOES_NOT_EXIST"] = "The required table '__AddonContext' does not exist.",
	["OBJECT_ALREADY_EXISTS"] = "the object '%s' already exists.",
	["OBJECT_DOES_NOT_EXIST"] = "the object '%s' does not exist.",
	["CANNOT_REGISTER_EVENT"] = "cannot register event '%s'.",
    ["CANNOT_UNREGISTER_EVENT"] = "cannot unregister event '%s'."
}

--[[ Library Helpers ]]

local function SafeCall(func, ...)
	local success, err = pcall(func, ...)
	if not success then
		geterrorhandler()(err)
	end
end

--[[ Addon API ]]

do
    local function NewObject(self, name)
        C:IsTable(self, 1)
        C:IsString(name, 2)

        local context = self.__AddonContext
        C:Ensures(context, L["ADDON_CONTEXT_DOES_NOT_EXIST"])

        local object = context.Objects[name]

        if not object then
            object = {
                __ObjectContext = {
                    name = name,
                    addonName = context.name,
                    isSuspended = false,
                    Events = {},
                    Frame = {
                        RegisterEvent = context.Frame.RegisterEvent,
                        UnregisterEvent = context.Frame.UnregisterEvent
                    }
                }
            }
            
            context.Objects[name] = object
            tinsert(context.Names, name)

            for key, value in pairs(Object) do
                if type(value) == "function" and not object[key] then
                    object[key] = value
                end
            end
    
            return object
        end

        C:Ensures(false, L["OBJECT_ALREADY_EXISTS"], name)
    end

    function Addon:GetName()
        return self.__AddonContext.name
    end

    function Addon:NewObject(name)
        C:IsString(name, 2)

        local object = NewObject(self, name)
        local storage = self:GetObject(name .. ".Storage", true)

        if storage then
            object.storage = storage
        end

        return object
    end

    function Addon:GetObject(name, silence)
        C:IsString(name, 2)

        local context = self.__AddonContext
        local object = context.Objects[name]

        if not silence then
            C:Ensures(object ~= nil, L["OBJECT_DOES_NOT_EXIST"], name)
        end

        return object
    end

    function Addon:NewStorage(name)
        C:IsString(name, 2)

        local storage = NewObject(self, name .. ".Storage")
        local addonTable  = self

        function storage:RegisterDB(defaults)
            return addonTable.DB:RegisterNamespace(name, defaults)
        end

        return storage
    end

    function Addon:GetStorage(name)
        C:IsString(name, 2)

        local fullName = name .. ".Storage"

        return self:GetObject(fullName)
    end

    function Addon:IterableObjects()
        local context = self.__AddonContext
        local names, objects = context.Names, context.Objects
        local i, n = 1, #names
        return function()
            if i <= n then
                local name = names[i]
                i = i + 1
                return objects[name]
            end
        end
    end

    function Addon:Broadcast(eventName, ...)
        for object in self:IterableObjects() do
            object:TriggerEvent(eventName, ...)
        end
    end
end

--[[ Object API ]]

function Object:GetName()
    return self.__ObjectContext.name
end

function Object:GetAddonName()
    return self.__ObjectContext.addonName
end

function Object:GetFullName()
    return self:GetAddonName() .. "." .. self:GetName()
end

function Object:IsSuspended()
    return self.__ObjectContext.isSuspended
end

function Object:Suspend()
    self.__ObjectContext.isSuspended = true
    self:TriggerEvent("OBJECT_EVENTS_SUSPENDED")
end

function Object:Resume()
    self.__ObjectContext.isSuspended = false
    self:TriggerEvent("OBJECT_EVENTS_RESUMED")
end

function Object:RegisterEvent(eventName, callback)
    C:IsString(eventName, 2)
    C:IsFunction(callback, 3)

    local context = self.__ObjectContext
    local callbacks = context.Events[eventName]

    if not callbacks then
        callbacks = {}
        context.Events[eventName] = callbacks
        if IsEventValid(eventName) then
            context.Frame:RegisterEvent(eventName)
        end
    else
        for _, currentCallback in ipairs(callbacks) do
            if currentCallback == callback then
                return
            end
        end
    end

    tinsert(callbacks, callback)
end

function Object:RegisterEvents(...)
    local eventNames = {}
    local callback

    for i = 1, select("#", ...) do
        local arg = select(i, ...)
        if type(arg) == "string" then
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

function Object:UnregisterEvent(eventName, callback)
    C:IsString(eventName, 2, "string")

    local context = self.__ObjectContext
    local callbacks = context.Events[eventName]

    if callbacks then
        for i = #callbacks, 1, -1 do
            local registeredCallback = callbacks[i]
            if not callback or registeredCallback == callback then
                tremove(callbacks, i)
                if callback then
                    break
                end
            end
        end
        if not callback or #callbacks == 0 then
            local canUnregister = eventName ~= "PLAYER_LOGIN" and eventName ~= "PLAYER_LOGOUT"
            if canUnregister and IsEventValid(eventName) then
                context.Frame:UnregisterEvent(eventName)
            end
            context.Events[eventName] = nil
        end
    end
end

function Object:TriggerEvent(eventName, ...)
    C:IsString(eventName, 2)

    if self:IsSuspended() then
        return
    end

    local context = self.__ObjectContext
    local callbacks = context.Events[eventName]

    if callbacks then
        for _, callback in ipairs(callbacks) do
            SafeCall(callback, self, eventName, ...)
        end
    end
end

--[[ Library API ]]

do
    local function OnInitializing(object)
        if object.OnInitializing then
            SafeCall(object.OnInitializing, object)
            object.OnInitializing = nil
        end
    end

    local function OnInitialized(object)
        if object.OnInitialized then
            SafeCall(object.OnInitialized, object)
            object.OnInitialized = nil
        end
    end

    local function ClearTable(t)
        if not t or next(t) == nil then
            return nil
        end
        for k, v in pairs(t) do
            if type(v) == "table" then
                ClearTable(v)
            end
            t[k] = nil
        end
    end

    local function Dispose(addonTable)
        local addonContext = addonTable.__AddonContext
        
        if addonContext then
            for i = #addonContext.Names, 1, -1 do
                local objectName = addonContext.Names[i]
                local object = addonContext.Objects[objectName]
                local objectContext = object.__ObjectContext

                if objectContext then
                    ClearTable(objectContext)
                    object.__ObjectContext = nil
                end
                
                addonContext.Objects[objectName] = nil
                addonContext.Names[i] = nil
            end

            ClearTable(addonContext)
            addonTable.__AddonContext = nil
        end
    end

    local function OnEvent(self, eventName, ...)
        local context = self.__AddonContext

        if not context then
            return
        end

        if eventName == "ADDON_LOADED" then
            local arg1 = ...
            if arg1 == self:GetName() then
                OnInitializing(self)
                for object in self:IterableObjects() do
                    OnInitializing(object)
                end
            end
            return
        end

        if eventName == "PLAYER_LOGIN" then
            OnInitialized(self)
            for object in self:IterableObjects() do
                OnInitialized(object)
            end
        end

        self:Broadcast(eventName, ...)

        if eventName == "PLAYER_LOGOUT" then
            context.Frame:Dispose()
        end
    end

    function lib:New(addonName, addonTable)
        C:IsString(addonName, 2)
        C:IsTable(addonTable, 3)

        local context = addonTable.__AddonContext

        if not context then
            local frame = CreateFrame("Frame")
            frame:RegisterEvent("ADDON_LOADED")
            frame:RegisterEvent("PLAYER_LOGIN")
            frame:RegisterEvent("PLAYER_LOGOUT")
            frame:SetScript("OnEvent", function(self, ...)
                OnEvent(addonTable, ...)
            end)
            
            context = {
                name = addonName,
                Objects = {},
                Names = {},
                Frame = {
                    RegisterEvent = function(_, eventName)
                        C:IsString(eventName, 2)
                        C:Ensures(eventName ~= "ADDON_LOADED", L["CANNOT_REGISTER_EVENT"], eventName)
                        if frame and not frame:IsEventRegistered(eventName) then
                            frame:RegisterEvent(eventName)
                        end
                    end,
                    UnregisterEvent = function(_, eventName)
                        C:IsString(eventName, 2)
                        C:Ensures(eventName ~= "ADDON_LOADED", L["CANNOT_UNREGISTER_EVENT"], eventName)
                        C:Ensures(eventName ~= "PLAYER_LOGIN", L["CANNOT_UNREGISTER_EVENT"], eventName)
                        C:Ensures(eventName ~= "PLAYER_LOGOUT", L["CANNOT_UNREGISTER_EVENT"], eventName)
                        if frame then
                            frame:UnregisterEvent(eventName)
                        end
                    end,
                    Dispose = function()
                        frame:UnregisterAllEvents()
                        frame:SetScript("OnEvent", nil)
                        frame = nil
                        Dispose(addonTable)
                    end
                }
            }

            addonTable.__AddonContext = context
            
            return setmetatable(addonTable, { __index = Addon })
        end
    end
end