---@diagnostic disable: undefined-field

assert(LibStub, "Player-1.0 requires LibStub")

local C = LibStub("Contracts-1.0")
assert(C, "Addon-1.0 requires Contracts-1.0")

local lib = LibStub:NewLibrary("Player-1.0", 0)
if not lib then return end

local ipairs = ipairs
local select = select
local sjoin = string.join

local GetRealmName = GetRealmName
local UnitName = UnitName
local UnitFullName = UnitFullName

local REALM_PATTERN = "% - (.+)"

local charName, charRealm1, charRealm2, charFullName
local realms = GetAutoCompleteRealms() or {}
local IsRealmConnectedRealm

do
    local realmsMap = {}
    for _, v in ipairs(realms) do
        realmsMap[v] = true
    end

    IsRealmConnectedRealm = function(realm, includeOwn)
        C:IsString(realm, 2)
        realm = realm:gsub("[ -]", "")
        return (realm ~= charRealm2 or includeOwn) and realmsMap[realm]
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
    charName, charRealm1 = UnitName("player"), GetRealmName()
    charRealm2 = select(2, UnitFullName("player"))
    charFullName = sjoin(" - ", charName, charRealm1)
end)

function lib:IterableConnectedRealms(preIterationCallback)
    local i = 0
    local n = #realms
    if n > 0 and preIterationCallback then
        preIterationCallback()
    end
    return function ()
        i = i + 1
        if i <= n then
            local realm = realms[i]
            return charRealm2 == realm, realm
        end
    end
end

function lib:GetName()
    return charName
end

function lib:GetRealm(trimmed)
    return trimmed and charRealm2 or charRealm1
end

function lib:GetFullName()
    return charFullName
end

function lib:IsSameCharacter(name)
    C:IsString(name, 2)
    return name == self:GetFullName()
end

function lib:IsOnCurrentRealm(name)
    C:IsString(name, 2)
    return name:find(self:GetRealm())
end

function lib:IsOnConnectedRealm(name)
    C:IsString(name, 2)
    return IsRealmConnectedRealm(name:match(REALM_PATTERN))
end

function lib:RemoveRealm(name)
    C:IsString(name, 2)
    return name:gsub(REALM_PATTERN, "")
end

function lib:ShortConnectedRealm(name)
    C:IsString(name, 2)
    return name:gsub(REALM_PATTERN, "*")
end