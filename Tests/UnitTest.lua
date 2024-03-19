local T = UnitTest_Library("UnitTest-1.0", ...)

do
    local CreateModule = T:Test("CreateModule")

    CreateModule["Fail first"] = function(self, ref)
    end
end