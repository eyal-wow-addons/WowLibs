local Type, Version = "vertical-layout", 0
local Settings = LibStub and LibStub("Settings-1.0", true)
if not Settings or (Settings:GetControlVersion(Type) or 0) >= Version then return end

local function Constructor(template)
    local category = Settings.RegisterVerticalLayoutCategory(template.name)

    template:RegisterCategory(category)
end

Settings:RegisterType(Type, Version, Constructor)