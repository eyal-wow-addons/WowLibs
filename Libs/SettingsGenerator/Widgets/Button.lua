local Type, Version = "button", 1
local SG = LibStub and LibStub("SettingsGenerator-1.0", true)
if not SG or SG:GetWidgetVersion(Type) >= Version then return end

local Schema = {
    click = "function",
    tooltip = "string?",
    addSearchTags = "boolean?"
}

local function Constructor(template, parent)
    template:Validate(Schema)

    local layout = parent:GetLayout()
    local addSearchTags = false

    if template.tag then
        addSearchTags = true
    end

    local initializer = CreateSettingsButtonInitializer(
        template.tag,
        template.name,
        template.click,
        template.tooltip,
        addSearchTags)

    layout:AddInitializer(initializer)
end

SG:RegisterType(Type, Version, Constructor)