---@diagnostic disable: undefined-field

assert(LibStub, "Contracts-1.0 requires LibStub")

local lib = LibStub:NewLibrary("Contracts-1.0", 0)
if not lib then return end

local error, assert = error, assert
local select = select
local sjoin = string.join
local smatch = string.match
local type = type

local BAD_ARGUMENT = "bad argument #%d to '%s' (%s expected, got %s)"
local ENSURES_MESSAGE_IS_NOT_A_STRING = "<Contracts> Ensures 'message' is not a string."

function lib:Ensures(condition, message, ...)
    self:IsString(ENSURES_MESSAGE_IS_NOT_A_STRING, 3)

    if not condition then
        assert(condition, message:format(...))
    end
end

function lib:Requires(value, num, ...)
    if type(num) ~= "number" then
        error(BAD_ARGUMENT:format(2, "Requires", "number", type(num)), 1)
    end

    for i = 1, select("#", ...) do
        if type(value) == select(i, ...) then return end
    end

    local types = sjoin(", ", ...)
    local name = smatch(debugstack(2, 2, 0), ": in function [`<](.-)['>]")
    error(BAD_ARGUMENT:format(num, name, types, type(value)), 3)
end

function lib:IsTable(value, num)
    self:Requires(value, num, "table")
end

function lib:IsFunction(value, num)
    self:Requires(value, num, "function")
end

function lib:IsString(value, num)
    self:Requires(value, num, "string")
end

function lib:IsNumber(value, num)
    self:Requires(value, num, "number")
end

function lib:IsBoolean(value, num)
    self:Requires(value, num, "boolean")
end