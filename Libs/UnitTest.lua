assert(LibStub, "UnitTest-1.0 requires LibStub")

local C = LibStub("Contracts-1.0")
assert(C, "UnitTest-1.0 requires Contracts-1.0")

local lib = LibStub:NewLibrary("UnitTest-1.0", 0)
if not lib then return end

local TestsCases = {}

local function AddTestCase(scope, testName, testFunc)
    C:IsTable(scope, 2)
    C:IsString(testName, 3)
    C:IsFunction(testFunc, 4)
    local testCase = {
        parent = scope,
        name = testName,
        func = testFunc
    }
    table.insert(TestsCases, testCase)
end

local function ExecuteTestCase(self, name, func, resultsHandler, ...)
	local success, err = pcall(func, self, ...)
    if not success then
        resultsHandler("TestCase", name, err)
    end
    return success
end

local function PrintHandler(type, ...)
    if type == "Scope" then
        local name = ...
        print("------------------------------------------------------------")
        print("+ " .. name)
    elseif type == "TestCase" then
        local name, err = ...
        print("   ---")
        print("   + " .. name .. ": " .. err)
    elseif type == "Summary" then
        print("------------------------------------------------------------")
        local totalTests, passedCounter, failedCounter = ...
        print(("Total Tests: %d Passed: %d Failed: %d"):format(totalTests, passedCounter, failedCounter))
        print("------------------------------------------------------------")
    end
end

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

function lib:CreateScope(scopeName)
    C:IsString(scopeName, 2)
    local scope = {
        __name = scopeName
    }
    return setmetatable(scope, {  __newindex = function(self, testName, testFunc)
        AddTestCase(self, testName, testFunc)
    end })
end

function lib:IterableTestsCases()
    local i = 1
    local n = #TestsCases
    local scope = nil
    return function()
        while i <= n do
            local testCase = TestsCases[i]
            if not scope or testCase.parent ~= scope then
                scope = testCase.parent
                return "Scope", testCase.parent.__name
            end
            i = i + 1
            return "TestCase", testCase.name, testCase.func
        end
    end
end

function lib:Run(resultsHandler)
    resultsHandler = resultsHandler or PrintHandler
    local totalTests, passedCounter, failCounter = #TestsCases, 0, 0
    for type, name, func in self:IterableTestsCases() do
        if type == "Scope" then
            resultsHandler(type, name)
        elseif type == "TestCase" then
            if ExecuteTestCase(self, name, func, resultsHandler) then
                passedCounter = passedCounter + 1
            else
                failCounter = failCounter + 1
            end
        end
    end
    resultsHandler("Summary", totalTests, passedCounter, failCounter)
end