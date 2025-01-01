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
    ["TYPE_IS_NOT_SUPPORTED"] = "the type '%s' is not supported. the type can either be 'boolean', 'number', 'string', 'table' or 'function'.",
    ["TEMPLATE_FIELD_IS_REQUIRED"] = "the top-level template field '%s' is required.",
    ["TEMPLATE_FIELD_VALUE_IS_INVALID"] = "the template field '[%s].%s' has an invalid value '%s'. Expected type '%s'.",
    ["TEMPLATE_FIELD_NAME_IS_REQUIRED_AT_INDEX"] = "the template field '[%s].props#%d.name' is required.",
    ["TEMPLATE_FIELD_TYPE_IS_MISSING"] = "the template '[%s].type' is nil or missing.",
    ["TEMPLATE_FIELD_TYPE_IS_INVALID"] = "the template field '[%s].type' is invalid.",
}

--[[ Template APIs ]]

function Template:Validate(schema)
    lib:Validate(self, schema)
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

    local function IsValidValue(propValue, schemaType)
        local actualType, isOptional = GetSchemaType(schemaType)

        return isOptional and propValue == nil or type(propValue) == actualType
    end

    function lib:Validate(template, schema)
        C:IsTable(template, 1)
        C:IsTable(schema, 2)

        for propName, propType in pairs(schema) do
            local propValue = template[propName]

            C:Ensures(IsValidValue(propValue, propType), L["TEMPLATE_FIELD_VALUE_IS_INVALID"], template.name, propName, tostring(propValue), propType)
        end
    end
end

do
    local function ConstructType(template, index)
        template = setmetatable(template, { __index = Template })

        local type = lib.Types[template.type]
        local parent = template:GetParent()

        C:Ensures(template.name, L["TEMPLATE_FIELD_NAME_IS_REQUIRED_AT_INDEX"], parent and parent.name, index)
        C:Ensures(template.type, L["TEMPLATE_FIELD_TYPE_IS_MISSING"], template.name)
        C:Ensures(type, L["TEMPLATE_FIELD_TYPE_IS_INVALID"], template.name, template.type)

        type.constructor(template, parent)
    end

    local function ConstructChildTypes(template)
        lib:Validate(template, lib.Schema)

        if type(template.props) == "table" then
            for index, t in ipairs(template.props) do
                t.__parent = template
                ConstructType(t, index)
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

        C:Ensures(template.name, L["TEMPLATE_FIELD_IS_REQUIRED"], 'name')
        C:Ensures(template.props, L["TEMPLATE_FIELD_IS_REQUIRED"], 'props')

        ConstructParentType(template)

        local topCategory = template:GetCategory()

        return topCategory:GetID()
    end
end