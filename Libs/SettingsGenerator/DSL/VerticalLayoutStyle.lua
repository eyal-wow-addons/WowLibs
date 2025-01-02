local lib = LibStub and LibStub("SettingsGenerator-1.0", true)
if not lib then return end

local C = LibStub("Contracts-1.0")

--[[ Example:
local settings = {
    {
        name = "AddonName"
    },
    {
        name = "Category 1",
        layout = {
            {
                name = "Click Me!",
                type = "button",
                click = ClickHandler
            }
        }
    },
    {
        name = "Category 2",
        layout = {}
    },
    {
        name = "Category 3",
        layout = {}
    }
}]]

local function ConvertToTraditionalStyle(template)
    local topLevelName = template[1].name

    local dest = {
        name = topLevelName,
        type = "vertical-layout",
        props = {}
    }

    for i = 2, #template do
        local field = template[i]
        table.insert(dest.props, {
            name = field.name,
            type = "vertical-layout",
            props = field.layout
        })
    end

    return dest
end

function lib:FromVerticalLayoutStyle(template)
    C:IsTable(template, 2)

    template = ConvertToTraditionalStyle(template)

    return self:Generate(template)
end