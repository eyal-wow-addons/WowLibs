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
    ["TYPE_ALREADY_REGISTERED"] = "the type '%s' already registered."
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

    C:Ensures(t, L["TYPE_ALREADY_REGISTERED"], Types[type])

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
    local function IsTypeValid(propType, propValue)
        local actualType, optional = string.match(propType, "^([a-z]+)([?]?)$")
        local isOptional = optional ~= ""
        return isOptional and propValue == nil or type(propValue) == actualType
     end
    
     function lib:Validate(schema, template)
        for propName, propType in pairs(schema) do
            local propValue = template[propName]
            assert(IsTypeValid(propType, propValue), ("The property '%s' has an invalid value."):format(propName))
         end
    end
end

do
    local function ConstructControl(template)
        local type = Types[template.type]
        if type and type.constructor then
            type.constructor(setmetatable(template, { __index = Template }))
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
        C:Ensures(template.props, L["TEMPLATE_REQUIRED_FIELD"], 'categories')

        ConstructControls(template)
    end
end