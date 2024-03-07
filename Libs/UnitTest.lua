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
        scope = scope,
        name = testName,
        func = testFunc
    }
    table.insert(TestsCases, testCase)
end

local function ExecuteTestCase(self, testName, testFunc, resultsHandler, ...)
	local success, err = pcall(testFunc, self, ...)
    if not success then
        resultsHandler("test", testName, err)
    end
    return success
end

local function PrintHandler(type, ...)
    if type == "scope" then
        local name, totalTests = ...
        print("----------------------------------------------------------------------------------")
        print("+ " .. name .. " (" .. totalTests .. " Tests)")
    elseif type == "test" then
        local name, err = ...
        print("   ---")
        print("   + " .. name .. ": " .. err)
    elseif type == "summary" then
        print("----------------------------------------------------------------------------------")
        local totalTests, totalScopes, passedCounter, failedCounter = ...
        print(("Tests: %d | Scopes: %d | Passed: %d | Failed: %d"):format(totalTests, totalScopes, passedCounter, failedCounter))
        print("----------------------------------------------------------------------------------")
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
        name = scopeName,
        total = 0
    }
    return setmetatable(scope, {  __newindex = function(self, testName, testFunc)
        AddTestCase(self, testName, testFunc)
        self.total = self.total + 1
    end })
end

function lib:IterableTestsCases()
    local i = 1
    local n = #TestsCases
    local scope = nil
    return function()
        while i <= n do
            local testCase = TestsCases[i]
            if not scope or testCase.scope ~= scope then
                scope = testCase.scope
                return "scope", testCase.scope
            end
            i = i + 1
            return "test", testCase
        end
    end
end

function lib:Run(resultsHandler)
    resultsHandler = resultsHandler or PrintHandler
    local totalTests, totalScopes, passedCounter, failCounter = #TestsCases, 0, 0, 0
    for type, info in self:IterableTestsCases() do
        if type == "scope" then
            resultsHandler(type, info.name, info.total)
            totalScopes = totalScopes + 1
        elseif type == "test" then
            if ExecuteTestCase(self, info.name, info.func, resultsHandler) then
                passedCounter = passedCounter + 1
            else
                failCounter = failCounter + 1
            end
        end
    end
    resultsHandler("summary", totalTests, totalScopes, passedCounter, failCounter)
end