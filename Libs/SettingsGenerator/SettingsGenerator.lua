---@diagnostic disable: undefined-field
assert(LibStub, "SettingsGenerator-1.0 requires LibStub")

local C = LibStub("Contracts-1.0")
assert(C, "SettingsGenerator-1.0 requires Contracts-1.0")

local lib = LibStub:NewLibrary("SettingsGenerator-1.0", 0)
if not lib then return end

lib.Types = lib.Types or {}
lib.Schema = lib.Schema or {
    name = "string",
    type = "string",
    props = "table?"
}

local Template = {}

--[[ Localization ]]

local L = {
    ["TYPE_ALREADY_REGISTERED"] = "the type '%s version %d' already registered.",
    ["TYPE_IS_MISSING_CONSTRUCTOR"] = "the type '%s' is missing a constructor.",
    ["TYPE_IS_NOT_SUPPORTED"] = "the type '%s' is not supported. the type can either be 'boolean', 'number', 'string', 'table' or 'function'.",
    ["TEMPLATE_TYPE_NOT_PROVIDED"] = "the template '%s' does not have a type.",
    ["TEMPLATE_TYPE_UNKNOWN"] = "the template '%s' contains unknown type '%s'.",
    ["TEMPLATE_PROPERTY_IS_REQUIRED"] = "the template's property '%s' is required.",
    ["TEMPLATE_PROPERTY_VALUE_IS_INVALID"] = "the template's property '%s' has an invalid value '%s'.",
}

--[[ Template APIs ]]

function Template:Validate(schema)
    lib:Validate(schema, self)
end

function Template:RegisterCategory(category, layout)
    self.__category = category
    self.__layout = layout
end

function Template:GetParent()
    return self.__parent
end

function Template:GetLayout()
    return self.__layout
end

function Template:GetCategory()
    return self.__category
end

-- [[ Library APIs ]]

function lib:RegisterType(type, version, ctor)
    C:IsString(type, 2)
    C:IsNumber(version, 3)
    C:IsFunction(ctor, 4)

    C:Ensures(not self.Types[type] or self.Types[type].version == version, L["TYPE_ALREADY_REGISTERED"], type, version)

    self.Types[type] = {
        version = version,
        constructor = ctor
    }
end

function lib:GetWidgetVersion(type)
    C:IsString(type, 2)
    return self.Types[type] and self.Types[type].version or 0
end

do
    local LuaType = {
        ["boolean"] = true,
        ["number"] = true,
        ["string"] = true,
        ["table"] = true,
        ["function"] = true
    }

    local function GetSchemaType(schemaType)
        local actualType, optional = string.match(schemaType, "^([a-z]+)([?]?)$")
        local isOptional = optional ~= ""

        actualType = LuaType[actualType] and actualType

        C:Ensures(actualType, L["TYPE_IS_NOT_SUPPORTED"], schemaType)

        return actualType, isOptional
    end

    local function IsValidValue(schemaType, propValue)
        local actualType, isOptional = GetSchemaType(schemaType)

        return isOptional and propValue == nil or type(propValue) == actualType
    end

    local function Validate(schema, template)
        for propName, propType in pairs(schema) do
            local propValue = template[propName]

            C:Ensures(IsValidValue(propType, propValue), L["TEMPLATE_PROPERTY_VALUE_IS_INVALID"], template.name, tostring(propValue))
        end
    end

     function lib:Validate(schema, template)
        C:IsTable(schema, 2)
        C:IsTable(template, 3)

        Validate(self.Schema, template)
        Validate(schema, template)
    end
end

do
    local function ConstructType(template)
        local type = lib.Types[template.type]

        C:Ensures(template.type, L["TEMPLATE_TYPE_NOT_PROVIDED"], template.name)
        C:Ensures(type, L["TEMPLATE_TYPE_UNKNOWN"], template.name, template.type)

        type.constructor(setmetatable(template, { __index = Template }), template:GetParent())
    end

    local function ConstructChildTypes(template)
        if type(template.props) == "table" then
            for _, t in ipairs(template.props) do
                t.__parent = template
                ConstructType(t)
                ConstructChildTypes(t)
            end
        end
    end

    local function ConstructParentType(template)
        ConstructType(template)
        ConstructChildTypes(template)
    end

    function lib:Generate(template)
        C:IsTable(template, 2)

        C:Ensures(template.name, L["TEMPLATE_PROPERTY_IS_REQUIRED"], 'name')
        C:Ensures(template.props, L["TEMPLATE_PROPERTY_IS_REQUIRED"], 'props')

        ConstructParentType(template)

        local topCategory = template:GetCategory()

        return topCategory:GetID()
    end
end