local Type, Version = "button", 0
local Settings = LibStub and LibStub("Settings-1.0", true)
if not Settings or (Settings:GetControlVersion(Type) or 0) >= Version then return end

local Schema = {
    click = "function",
    tooltip = "string?",
    addSearchTags = "boolean"
}

local function Constructor(template)
    template:Validate(Schema)

    local layout = template:GetLayout()
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

Settings:RegisterType(Type, Version, Constructor)