---@diagnostic disable: undefined-field
assert(LibStub, "Addon-1.0 requires LibStub")

local C = LibStub("Contracts-1.0")
assert(C, "Addon-1.0 requires Contracts-1.0")

local lib = LibStub:NewLibrary("Addon-1.0", 0)
if not lib then return end

lib.Addons = lib.Addons or {}

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
    ["ADDON_INFO_DOES_NOT_EXIST"] = "The required table '__AddonInfo' does not exist for addon '%s'.",
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

local Callbacks = {}
local function OnEvent(self, eventName, ...)
    local info = self.__AddonInfo
    if eventName == "ADDON_LOADED" then
        local arg1 = ...
        local addon = lib.Addons[arg1]
        if addon then
            for _, name in ipairs(info.names) do
                local object = info.objects[name]
                local callback = object.OnInitializing
                if callback then
                    SafeCall(callback, object)
                    object.OnInitializing = nil
                end
            end
        end
        return
    elseif eventName == "PLAYER_LOGIN" then
        for _, name in ipairs(info.names) do
            local object = info.objects[name]
            local callback = object.OnInitialized
            if callback then
                SafeCall(callback, object)
                object.OnInitialized = nil
            end
        end
        self:UnregisterEvent(eventName)
    end
    for _, name in ipairs(info.names) do
        local object = info.objects[name]
        if object.TriggerEvent then
            object:TriggerEvent(eventName, ...)
        end
    end
end

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

--[[ Core API ]]

do
    local Api = {}

    local function NewObject(self, name)
        C:IsTable(self, 1)
        C:IsString(name, 2)

        local info = self.__AddonInfo
        C:Ensures(info, L["ADDON_INFO_DOES_NOT_EXIST"], info.name)

        local object = info.objects[name]

        if not object then
            object = {
                name = name,
                callbacks = info.callbacks,
                Frame_RegisterEvent = info.Frame_RegisterEvent,
                Frame_UnregisterEvent = info.Frame_UnregisterEvent
            }
            info.objects[name] = object
            tinsert(info.names, name)
            return setmetatable(object, { __index = Callbacks })
        end

        C:Ensures(false, L["OBJECT_ALREADY_EXISTS"], name)
    end

    function Api:NewObject(name)
        C:IsString(name, 2)
        local object = NewObject(self, name)

        --Mixin(object, ...)

        local storage = self[name .. "Storage"]

        if storage then
            object.storage = storage
        end

        return object
    end

    function Api:NewStorage(name)
        C:IsString(name, 2)
        local storage = NewObject(self, name .. "Storage")

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

    function lib:New(addonName, addonTable)
        C:IsString(addonName, 2)
        C:IsTable(addonTable, 3)
        local info = addonTable.__AddonInfo
        if not info then
            local frame = CreateFrame("Frame")
            frame:RegisterEvent("ADDON_LOADED")
            frame:RegisterEvent("PLAYER_LOGIN")
            frame:SetScript("OnEvent", OnEvent)
            
            info = {
                name = addonName,
                objects = { [addonName] = addonTable },
                names = { addonName },
                callbacks = {
                    ["PLAYER_LOGIN"] = {}
                },
                Frame_RegisterEvent = function(_, eventName)
                    C:IsString(eventName, 2)
                    C:Ensures(eventName ~= "ADDON_LOADED", L["CANNOT_REGISTER_EVENT"], eventName)
                    if frame then
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
                    frame:UnregisterEvent("ADDON_LOADED")
                    frame:UnregisterEvent("PLAYER_LOGIN")
                    frame:SetScript("OnEvent", nil)
                    frame.__AddonInfo = nil
                    frame = nil
                end
            }

            frame.__AddonInfo = info
            addonTable.__AddonInfo = info

            self.Addons[addonName] = addonTable
            return setmetatable(addonTable, { __index = Api })
        end
    end

    function lib:Delete(addonName)
        C:IsString(addonName, 2)
        local addonTable = self.Addons[addonName]
        if addonTable then
            local info = addonTable.__AddonInfo
            if info then
                for i = #info.names, 1, -1 do
                    local objName = info.names[i]
                    local object = info.objects[objName]
                    for eventName in pairs(info.callbacks) do
                        object:UnregisterEvent(eventName)
                        info.callbacks[eventName] = nil
                    end
                    tremove(info.names, i)
                end
                info:Frame_Release()
                for k in pairs(info) do
                    info[k] = nil
                end
            end
            addonTable.__AddonInfo = nil
            self.Addons[addonName] = nil
            return true
        end
        return false
    end
end