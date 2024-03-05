local addon = LibStub("Addon-1.0"):New(...)

function addon:OnInitializing()
    LibStub("UnitTest-1.0"):Run()
end