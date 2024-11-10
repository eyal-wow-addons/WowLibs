---@diagnostic disable: undefined-field
assert(LibStub, "Addon-1.0 requires LibStub")

local C = LibStub("Contracts-1.0")
assert(C, "Addon-1.0 requires Contracts-1.0")

local lib = LibStub:NewLibrary("Addon-1.0", 0)
if not lib then return end

local Core = {}
local Object = {}

local ipairs, pairs = ipairs, pairs
local pcall, geterrorhandler = pcall, geterrorhandler
local select = select
local setmetatable = setmetatable
local tinsert, tremove = table.insert, table.remove
local type = type
local twipe = table.wipe

local IsEventValid = C_EventUtils.IsEventValid

--[[ Localization ]]

local L = {
    ["ADDON_MISSING"] = "The addon '%s' is missing or does not exist.",
    ["ADDON_CONTEXT_DOES_NOT_EXIST"] = "The required table '__AddonContext' does not exist for addon '%s'.",
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

--[[ Core API ]]

do
    local function NewObject(self, name)
        C:IsTable(self, 1)
        C:IsString(name, 2)

        local context = self.__AddonContext
        C:Ensures(context, L["ADDON_CONTEXT_DOES_NOT_EXIST"], context.name)

        local object = context.Objects[name]

        if not object then
            object = {
                __ObjectContext = {
                    name = name,
                    addonName = context.name,
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

    function Core:NewObject(name)
        C:IsString(name, 2)
        local object = NewObject(self, name)

        local storage = self:GetObject(name .. ".Storage", true)

        if storage then
            object.storage = storage
        end

        return object
    end

    function Core:GetObject(name, silence)
        C:IsString(name, 2)
        local context = self.__AddonContext
        local object = context.Objects[name]
        if not silence then
            C:Ensures(object ~= nil, L["OBJECT_DOES_NOT_EXIST"], name)
        end
        return object
    end

    function Core:NewStorage(name)
        C:IsString(name, 2)
        local storage = NewObject(self, name .. ".Storage")
        local addonTable  = self

        function storage:RegisterDB(defaults)
            return addonTable.DB:RegisterNamespace(name, defaults)
        end

        return storage
    end

    function Core:GetStorage(name)
        C:IsString(name, 2)
        local fullName = name .. ".Storage"
        return self:GetObject(fullName)
    end

    function Core:IterableObjects()
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

    function Core:Broadcast(eventName, ...)
        for object in self:IterableObjects() do
            if object.TriggerEvent then
                object:TriggerEvent(eventName, ...)
            end
        end
    end

    function Core:GetName()
        return self.__AddonContext.name
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

function Object:RegisterEvent(eventName, callback)
    C:IsString(eventName, 2)
    C:IsFunction(callback, 3)
    C:Ensures(eventName ~= "ADDON_LOADED", L["CANNOT_REGISTER_EVENT"], eventName)
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

function Object:UnregisterEvent(eventName, callback)
    C:IsString(eventName, 2, "string")
    C:Ensures(eventName ~= "ADDON_LOADED", L["CANNOT_UNREGISTER_EVENT"], eventName)
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
            if IsEventValid(eventName) then
                context.Frame:UnregisterEvent(eventName)
            end
            context.Events[eventName] = nil
        end
    end
end

function Object:TriggerEvent(eventName, ...)
    C:IsString(eventName, 2)
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
    local function OnEvent(self, eventName, ...)
        if eventName == "ADDON_LOADED" then
            local arg1 = ...
            if arg1 == self:GetName() then
                for object in self:IterableObjects() do
                    local onInitializing = object.OnInitializing
                    if onInitializing then
                        SafeCall(onInitializing, object)
                        object.OnInitializing = nil
                    end
                end
            end
            return
        elseif eventName == "PLAYER_LOGIN" then
            for object in self:IterableObjects() do
                local onInitialized = object.OnInitialized
                if onInitialized then
                    SafeCall(onInitialized, object)
                    object.OnInitialized = nil
                end
            end
            self.__AddonContext.Frame:UnregisterEvent(eventName)
        end
        self:Broadcast(eventName, ...)
    end

    function lib:New(addonName, addonTable)
        C:IsString(addonName, 2)
        C:IsTable(addonTable, 3)

        local context = addonTable.__AddonContext

        if not context then
            local frame = CreateFrame("Frame")
            frame:RegisterEvent("ADDON_LOADED")
            frame:RegisterEvent("PLAYER_LOGIN")
            frame:SetScript("OnEvent", function(self, ...)
                OnEvent(addonTable, ...)
            end)
            
            context = {
                name = addonName,
                Objects = { [addonName] = addonTable },
                Names = { addonName },
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
                        if frame then
                            frame:UnregisterEvent(eventName)
                        end
                    end,
                    Release = function()
                        frame:UnregisterAllEvents()
                        frame:SetScript("OnEvent", nil)
                        frame = nil
                    end
                }
            }

            addonTable.__AddonContext = context
            
            return setmetatable(addonTable, { __index = Core })
        end
    end

    function lib:Delete(addonTable)
        C:IsTable(addonTable, 2)

        local context = addonTable.__AddonContext
        
        if context then
            context.Frame:Release()

            for i = #context.Names, 1, -1 do
                local objName = context.Names[i]
                context.Objects[objName] = nil
                context.Names[i] = nil
            end

            for eventName in pairs(context.Events) do
                twipe(context.Events[eventName])
                context.Events[eventName] = nil
            end

            for k in pairs(context) do
                context[k] = nil
            end

            addonTable.__AddonContext = nil

            return true
        end

        return false
    end
end