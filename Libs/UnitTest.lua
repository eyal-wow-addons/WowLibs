assert(LibStub, "UnitTest-1.0 requires LibStub")

local C = LibStub("Contracts-1.0")
assert(C, "UnitTest-1.0 requires Contracts-1.0")

local lib = LibStub:NewLibrary("UnitTest-1.0", 0)
if not lib then return end

local Tests = {}

function lib:Assert(condition)
    assert(condition, "Assertion failed: The test condition should have been true, but it was false.")
end

function lib:Capture(func, showError)
    C:IsFunction(func, 2)
	local success, err = pcall(func)
    if showError and err then
        print(err)
    end
    assert(not success, "Capture failed: The function should have thrown an error, but it did not.")
end

function lib:Test(name, func)
    C:IsString(name, 2)
    C:IsFunction(func, 3)
    local testCase = {
        name = name,
        func = func
    }
    table.insert(Tests, testCase)
end

local function ExecuteTest(self, name, func, ...)
	local success, err = pcall(func, self, ...)
    if not success then
        print(name .. ":\n" .. err)
    end
    return success
end

function lib:Run()
    local totalTests, passedCounter = #Tests, 0
    for _, testCase in ipairs(Tests) do
        if not ExecuteTest(self, testCase.name, testCase.func) then
            return
        else
            passedCounter = passedCounter + 1
        end
    end
    print(("Total Tests: %d Passed: %d."):format(totalTests, passedCounter))
end