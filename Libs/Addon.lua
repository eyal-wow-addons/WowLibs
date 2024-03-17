assert(LibStub, "Addon-1.0 requires LibStub")

local C = LibStub("Contracts-1.0")
assert(C, "Addon-1.0 requires Contracts-1.0")

local lib = LibStub:NewLibrary("Addon-1.0", 0)
if not lib then return end

lib.Addons = lib.Addons or {}
lib.Objects = lib.Objects or {}

local ipairs, pairs = ipairs, pairs
local pcall, geterrorhandler = pcall, geterrorhandler
local select = select
local setmetatable = setmetatable
local tinsert, tremove = table.insert, table.remove
local type = type

local IsEventValid = C_EventUtils.IsEventValid

--[[ Localization ]]

local L = {
    ["ADDON_MISSING"] = "The addon '%s' is missing or does not exist.",
    ["ADDON_DATA_DOES_NOT_EXIST"] = "The required table '__AddonData' does not exist for addon '%s'.",
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
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, eventName, ...)
    if eventName == "ADDON_LOADED" then
        local arg1 = ...
        local addon = lib.Addons[arg1]
        if addon then
            local data = addon.__AddonData
            for _, name in ipairs(data.names) do
                local object = data.objects[name]
                tinsert(lib.Objects, object)
                local callback = object.OnInitializing
                if callback then
                    SafeCall(callback, object)
                    object.OnInitializing = nil
                end
            end
        end
        return
    elseif eventName == "PLAYER_LOGIN" then
        for _, object in ipairs(lib.Objects) do
            local callback = object.OnInitialized
            if callback then
                SafeCall(callback, object)
                object.OnInitialized = nil
            end
        end
        self:UnregisterEvent(eventName)
    end
    Callbacks:TriggerEvent(eventName, ...)
end)

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
    local callbacks = self.callbacks[eventName]
    if callbacks then
        for i = #callbacks, 1, -1 do
            local registeredCallback = callbacks[i]
            if not callback or registeredCallback == callback then
                tremove(self.callbacks[eventName], i)
                if callback then
                    break
                end
            end
        end
        if #self.callbacks[eventName] == 0 then
            if IsEventValid(eventName) then
                frame:UnregisterEvent(eventName)
            end
            self.callbacks[eventName] = nil
        elseif not callback then
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

        local data = self.__AddonData
        C:Ensures(data, L["ADDON_DATA_DOES_NOT_EXIST"], data.name)

        local object = data.objects[name]

        if not object then
            object = {
                callbacks = data.callbacks
            }
            data.objects[name] = object
            tinsert(data.names, name)
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

    --[[function Api:SetDependency(dependencyName)
        C:IsString(dependencyName, 2)
        local dependencyTable = lib.Addons[dependencyName]

        if dependencyTable then
            setmetatable(self, { __index = dependencyTable })
        end
    end]]

    function lib:New(name, tbl)
        C:IsString(name, 2)
        C:IsTable(tbl, 3)
        local data = tbl.__AddonData
        if not data then
            data = {
                name = name,
                objects = { [name] = tbl },
                names = { name },
                callbacks = {
                    ["PLAYER_LOGIN"] = {}
                }
            }
            tbl.__AddonData = data
            self.Addons[name] = tbl
            return setmetatable(tbl, { __index = Api })
        end
    end

    --[[function lib:Delete(name)
        C:IsString(name, 2)
        local tbl = self.Addons[name]
        if tbl then
            for i = 1, #Objects, 1 do
                if Objects[i] == tbl then
                    table.remove(Objects, i)
                end
            end
            self.Addons[name] = nil
            return true
        end
        return false
    end]]
end