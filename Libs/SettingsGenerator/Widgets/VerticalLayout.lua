local Type, Version = "vertical-layout", 1
local SG = LibStub and LibStub("SettingsGenerator-1.0", true)
if not SG or SG:GetWidgetVersion(Type) >= Version then return end

local function Constructor(template, parent)
    if not parent then
        local category = Settings.RegisterVerticalLayoutCategory(template.name)

        template:RegisterCategory(category)

        Settings.RegisterAddOnCategory(category)
    else
        local subCategory, layout = Settings.RegisterVerticalLayoutSubcategory(parent:GetCategory(), template.name)

        template:RegisterCategory(subCategory, layout)
    end
end

SG:RegisterType(Type, Version, Constructor)