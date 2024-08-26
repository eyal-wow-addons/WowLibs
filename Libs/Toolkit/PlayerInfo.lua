---@diagnostic disable: undefined-field

assert(LibStub, "PlayerInfo-1.0 requires LibStub")

local C = LibStub("Contracts-1.0")
assert(C, "PlayerInfo-1.0 requires Contracts-1.0")

local lib = LibStub:NewLibrary("PlayerInfo-1.0", 0)
if not lib then return end

local ipairs = ipairs
local select = select
local sjoin = string.join
local sort = table.sort

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
    sort(realms, function(a, b)
        if a == charRealm2 then
            return true
        elseif b == charRealm2 then
            return false
        else
            return a < b
        end
    end)
end)

function lib:HasConnectedRealms()
    return #realms > 0
end

function lib:IterableConnectedRealms()
    local i = 0
    local n = #realms
    return function ()
        i = i + 1
        if i <= n then
            local realm = realms[i]
            return charRealm2 == realm, realm
        end
    end
end

function lib:GetCharacterName()
    return charName
end

function lib:GetCharacterRealm(trimmed)
    return trimmed and charRealm2 or charRealm1
end

function lib:GetCharacterFullName()
    return charFullName
end

function lib:IsCurrentCharacterOnConnectedRealm()
    local name = self:GetCharacterFullName()
    return IsRealmConnectedRealm(name:match(REALM_PATTERN), true)
end

function lib:IsSameCharacter(name)
    C:IsString(name, 2)
    return name == self:GetCharacterFullName()
end

function lib:IsCharacterOnCurrentRealm(name)
    C:IsString(name, 2)
    return name:find(self:GetCharacterRealm())
end

function lib:IsCharacterOnConnectedRealm(name, includeOwn)
    C:IsString(name, 2)
    return IsRealmConnectedRealm(name:match(REALM_PATTERN), includeOwn)
end

function lib:RemoveRealm(name)
    C:IsString(name, 2)
    return name:gsub(REALM_PATTERN, "")
end

function lib:ShortConnectedRealm(name)
    C:IsString(name, 2)
    return name:gsub(REALM_PATTERN, "*")
end