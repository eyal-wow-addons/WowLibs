---@diagnostic disable: undefined-field
assert(LibStub, "Addon-1.0 requires LibStub")

local C = LibStub("Contracts-1.0")
assert(C, "Addon-1.0 requires Contracts-1.0")

local lib = LibStub:NewLibrary("Addon-1.0", 0)
if not lib then return end

lib.Addons = lib.Addons or {}

local Core = {}
local Callbacks = {}

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

        local object = context.objects[name]

        if not object then
            object = {
                name = name,
                callbacks = {
                    ["PLAYER_LOGIN"] = {}
                },
                Frame_RegisterEvent = context.Frame_RegisterEvent,
                Frame_UnregisterEvent = context.Frame_UnregisterEvent
            }
            
            context.objects[name] = object
            tinsert(context.names, name)

            for key, value in pairs(Callbacks) do
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

        local storage = self:GetObject(name .. "Storage", true)

        if storage then
            object.storage = storage
        end

        return object
    end

    function Core:GetObject(name, silence)
        C:IsString(name, 2)
        local context = self.__AddonContext
        local object = context.objects[name]
        if not silence then
            C:Ensures(object ~= nil, L["OBJECT_DOES_NOT_EXIST"], name)
        end
        return object
    end

    function Core:NewStorage(name)
        C:IsString(name, 2)
        local storage = NewObject(self, name .. "Storage")
        local addonTable  = self

        function storage:RegisterDB(defaults)
            return addonTable.DB:RegisterNamespace(name, defaults)
        end

        return storage
    end

    function Core:GetStorage(name)
        C:IsString(name, 2)
        local fullName = name .. "Storage"
        return self:GetObject(fullName)
    end

    function Core:GetName()
        return self.__AddonContext.name
    end
end

--[[ Callbacks API ]]

function Callbacks:RegisterCallback(callback)
    C:IsFunction(callback, 2)
    tinsert(self.callbacks["PLAYER_LOGIN"], callback)
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
    local callbacks = self.callbacks[eventName]
    if not callbacks then
        callbacks = {}
        self.callbacks[eventName] = callbacks
        if IsEventValid(eventName) then
            self:Frame_RegisterEvent(eventName)
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
    C:Ensures(eventName ~= "ADDON_LOADED", L["CANNOT_UNREGISTER_EVENT"], eventName)
    local callbacks = self.callbacks[eventName]
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
                self:Frame_UnregisterEvent(eventName)
            end
            self.callbacks[eventName] = nil
        end
    end
end

function Callbacks:TriggerEvent(eventName, ...)
    C:IsString(eventName, 2)
    local callbacks = self.callbacks[eventName]
    if callbacks then
        for _, callback in ipairs(callbacks) do
            SafeCall(callback, self, eventName, ...)
        end
    end
end

--[[ Library API ]]

do
    local function IterableObjects(context)
        local names, objects = context.names, context.objects
        local i, n = 1, #names
        return function()
            if i <= n then
                local name = names[i]
                i = i + 1
                return objects[name]
            end
        end
    end

    local function OnEvent(self, eventName, ...)
        local context = self.__AddonContext
        if eventName == "ADDON_LOADED" then
            local arg1 = ...
            local addon = lib.Addons[arg1]
            if addon and arg1 == context.name then
                for object in IterableObjects(context) do
                    local onInitializing = object.OnInitializing
                    if onInitializing then
                        SafeCall(onInitializing, object)
                        object.OnInitializing = nil
                    end
                end
            end
            return
        elseif eventName == "PLAYER_LOGIN" then
            for object in IterableObjects(context) do
                local onInitialized = object.OnInitialized
                if onInitialized then
                    SafeCall(onInitialized, object)
                    object.OnInitialized = nil
                end
            end
            self:UnregisterEvent(eventName)
        end
        for object in IterableObjects(context) do
            if object.TriggerEvent then
                object:TriggerEvent(eventName, ...)
            end
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
            frame:SetScript("OnEvent", OnEvent)
            
            context = {
                name = addonName,
                objects = { [addonName] = addonTable },
                names = { addonName },
                Frame_RegisterEvent = function(_, eventName)
                    C:IsString(eventName, 2)
                    C:Ensures(eventName ~= "ADDON_LOADED", L["CANNOT_REGISTER_EVENT"], eventName)
                    if frame and not frame:IsEventRegistered(eventName) then
                        frame:RegisterEvent(eventName)
                    end
                end,
                Frame_UnregisterEvent = function(_, eventName)
                    C:IsString(eventName, 2)
                    C:Ensures(eventName ~= "ADDON_LOADED", L["CANNOT_UNREGISTER_EVENT"], eventName)
                    if frame then
                        frame:UnregisterEvent(eventName)
                    end
                end,
                Frame_Release = function()
                    frame:UnregisterAllEvents()
                    frame:SetScript("OnEvent", nil)
                    frame.__AddonContext = nil
                    frame = nil
                end
            }

            frame.__AddonContext = context
            addonTable.__AddonContext = context

            self.Addons[addonName] = addonTable
            return setmetatable(addonTable, { __index = Core })
        end
    end

    function lib:Delete(addonName)
        C:IsString(addonName, 2)
        local addonTable = self.Addons[addonName]
        if addonTable then
            local context = addonTable.__AddonContext
            if context then
                context:Frame_Release()
                for i = #context.names, 1, -1 do
                    local objName = context.names[i]
                    context.objects[objName] = nil
                    context.names[i] = nil
                end
                for eventName in pairs(context.callbacks) do
                    twipe(context.callbacks[eventName])
                    context.callbacks[eventName] = nil
                end
                for k in pairs(context) do
                    context[k] = nil
                end
            end
            addonTable.__AddonContext = nil
            self.Addons[addonName] = nil
            return true
        end
        return false
    end

    function lib:GetAddon(addonName)
        C:IsString(addonName, 2)
        return self.Addons[addonName]
    end
end