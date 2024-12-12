---@diagnostic disable: undefined-field
assert(LibStub, "Settings-1.0 requires LibStub")

local C = LibStub("Contracts-1.0")
assert(C, "Settings-1.0 requires Contracts-1.0")

local lib = LibStub:NewLibrary("Settings-1.0", 0)
if not lib then return end

local Types = {}

local Schema = {
    name = "string",
    type = "string",
    props = "table"
}

local Template = {}

--[[ Localization ]]

local L = {
    ["TYPE_ALREADY_REGISTERED"] = "the type '%s' already registered.",
    ["TYPE_WAS_NOT_FOUND"] = "",
    ["TYPE_IS_MISSING_CONSTRUCTOR"] = "",
    ["SCHEMA_TYPE_IS_INVALID"] = "",
    ["TEMPLATE_REQUIRED_FIELD"] = "",
    ["TEMPLATE_PROPERTY_VALUE_IS_INVALID"] = "the property '%s' has an invalid value.",
}

--[[ Template APIs ]]

function Template:Validate(Schema)
    lib:Validate(Schema, self)
end

function Template:RegisterCategory(category, layout)
    self.__category = category
    self.__layout = layout
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
    C:IsString(version, 3)
    C:IsFunction(ctor, 4)

    C:Ensures(Types[type] ~= nil and Types[type].version == version, L["TYPE_ALREADY_REGISTERED"], type, version)

    Types[type] = {
        type = type,
        version = version,
        constructor = ctor
    }
end

function lib:GetControlVersion(type)
    C:IsString(type, 2)

    return Types[type].version
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
        
        actualType = LuaType[actualType]

        C:Ensures(actualType, L["SCHEMA_TYPE_IS_INVALID"], schemaType)

        return actualType, isOptional
    end

    local function IsValidValue(schemaType, propValue)
        local actualType, isOptional = GetSchemaType(schemaType)
        return isOptional and propValue == nil or type(propValue) == actualType
    end
    
     function lib:Validate(schema, template)
        C:IsTable(schema, 2)
        C:IsTable(template, 3)

        for propName, propType in pairs(schema) do
            local propValue = template[propName]

            C:Ensures(IsValidValue(propType, propValue), L["TEMPLATE_PROPERTY_VALUE_IS_INVALID"], propName)
         end
    end
end

do
    local function ConstructControl(template)
        local type = Types[template.type]

        C:Ensures(type, L["TYPE_WAS_NOT_FOUND"], template.type)
        C:Ensures(type.constructor, L["TYPE_IS_MISSING_CONSTRUCTOR"], template.type)

        if type and type.constructor and not type.isInitialized then
            type.constructor(setmetatable(template, { __index = Template }))
            type.isInitialized = true
        end
    end

    local function ConstructControls(template)
        ConstructControl(template)

        if template.props then
            for _, t in ipairs(template.props) do
                if t.props then
                    ConstructControls(t)
                else
                    ConstructControl(template)
                end
            end
        end
    end

    function lib:RegisterSettings(template)
        C:IsTable(template, 2)
    
        C:Ensures(template.name, L["TEMPLATE_REQUIRED_FIELD"], 'name')
        C:Ensures(template.props, L["TEMPLATE_REQUIRED_FIELD"], 'props')

        ConstructControls(template)
    end
end