---@diagnostic disable: undefined-field

assert(LibStub, "Contracts-1.0 requires LibStub")

local lib = LibStub:NewLibrary("Contracts-1.0", 0)
if not lib then return end

local error, assert = error, assert
local select = select
local unpack = unpack
local sjoin = string.join
local smatch = string.match
local type = type

local BAD_ARGUMENT = "Bad argument '#%d' to '%s'. '%s' expected, got '%s'."
local REQUIRES_POS_NOT_NUMBER = "<Contracts> Requires 'pos' is not a number. got '%s'."
local ENSURES_MESSAGE_NOT_STRING = "<Contracts> Ensures 'message' is not a string. got '%s'."

function lib:Ensures(condition, message, ...)
    if type(message) ~= "string" then
        error(ENSURES_MESSAGE_NOT_STRING:format(type(message)), 3)
    end

    if not condition then
        local args = {...}
        for i = 1, select("#", ...) do
            if args[i] == nil then
                args[i] = "???"
            end
        end
        error(message:format(unpack(args)), 3)
    end
end

function lib:Requires(value, pos, ...)
    if type(pos) ~= "number" then
        error(REQUIRES_POS_NOT_NUMBER:format(type(pos)), 3)
    end

    for i = 1, select("#", ...) do
        if type(value) == select(i, ...) then return end
    end

    local types = sjoin(", ", ...)
    local name = smatch(debugstack(2, 2, 0), ": in function [`<](.-)['>]")
    error(BAD_ARGUMENT:format(pos, name, types, type(value)), 3)
end

function lib:IsTable(value, pos)
    self:Requires(value, pos, "table")
end

function lib:IsFunction(value, pos)
    self:Requires(value, pos, "function")
end

function lib:IsString(value, pos)
    self:Requires(value, pos, "string")
end

function lib:IsNumber(value, pos)
    self:Requires(value, pos, "number")
end

function lib:IsBoolean(value, pos)
    self:Requires(value, pos, "boolean")
end