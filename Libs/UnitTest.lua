assert(LibStub, "UnitTest-1.0 requires LibStub")

local C = LibStub("Contracts-1.0")
assert(C, "UnitTest-1.0 requires Contracts-1.0")

local lib = LibStub:NewLibrary("UnitTest-1.0", 0)
if not lib then return end

local pcall = pcall
local print = print
local setmetatable = setmetatable
local tinsert = table.insert

local Modules = {}

do
    local Api = {}

    function Api:Assert(condition)
        assert(condition, "Assertion failed: The test condition should have been true, but it was false.")
    end

    function Api:Capture(func, showError)
        C:IsFunction(func, 2)
        local success, err = pcall(func)
        if showError and err then
            print(err)
        end
        assert(not success, "Capture failed: The function should have thrown an error, but it did not.")
    end

    do
        local function AddTest(scope, name, func)
            C:IsTable(scope, 2)
            C:IsString(name, 3)
            C:IsFunction(func, 4)
            local test = {
                name = name,
                func = func
            }
            tinsert(scope.tests, test)
        end

        function Api:CreateScope(name)
            C:IsString(name, 2)
            local module = self
            local scope = {
                name = name,
                tests = {}
            }
            tinsert(module.scopes, scope)
            return setmetatable(scope, { __newindex = function(_, testName, testFunc)
                AddTest(scope, testName, testFunc)
            end })
        end

        function Api:Test(name)
            C:IsString(name, 2)
            return self:CreateScope(name)
        end
    end

    function lib:CreateModule(name, tbl)
        C:IsString(name, 2)
        local uut = tbl or LibStub(name, true)
        local module = {
            scopes = {},
            name = name,
            uut = uut,
            hasUnitUnderTest = uut ~= nil,
        }
        tinsert(Modules, module)
        return setmetatable(module, { __index = Api })
    end

    function lib:Test(name, tbl)
        C:IsString(name, 2)
        return self:CreateModule(name, tbl)
    end
end

function lib:IterableTestInfo()
    local m, s, t = 1, 1, 1
    local modules, scopes, tests = Modules, nil, nil
    local module, scope, test = nil, nil, nil
    return function()
        while m <= #modules do
            module = modules[m]
            scopes = module.scopes
            while s <= #scopes do
                scope = scopes[s]
                tests = scope.tests 
                while t <= #tests do
                    test = tests[t]
                    t = t + 1
                    return module, scope, test
                end
                s, t = s + 1, 1
            end
            m, s, t = m + 1, 1, 1
        end
    end
end

do
    local function PrintHandler(type, ...)
        if type == "module" then
            local moduleName, totalTests = ...
            print("----------------------------------------------------------------------------------")
            print("+ " .. moduleName .. " (Scopes: " .. totalTests .. ")")
        elseif type == "scope" then
            local moduleName, scopeName, totalTests = ...
            print("   + " .. scopeName .. " (Tests: " .. totalTests .. ")")
        elseif type == "test" then
            local moduleName, scopeName, testName, err = ...
            print("      + " .. testName .. ": " .. err)
        elseif type == "summary" then
            print("----------------------------------------------------------------------------------")
            local totalTests, totalModules, totalScopes, passedCounter, failedCounter = ...
            print(("Tests: %d | Modules: %d | Scopes: %d | Passed: %d | Failed: %d"):format(totalTests, totalModules, totalScopes, passedCounter, failedCounter))
            print("----------------------------------------------------------------------------------")
        end
    end

    local function ExecuteTest(type, module, scope, test, resultsHandler)
        local success, err = pcall(test.func, module.uut)
        if not success then
            resultsHandler(type, module.name, scope.name, test.name, err)
        end
        return success
    end

    function lib:Run(resultsHandler)
        resultsHandler = resultsHandler or PrintHandler
        local lastModule, lastScope
        local totalTests, totalModules, totalScopes, passedCounter, failedCounter = 0, #Modules, 0, 0, 0
        for module, scope, test in self:IterableTestInfo() do
            totalTests = totalTests + 1
            if not lastModule or lastModule ~= module then
                totalScopes = totalScopes + #module.scopes
                resultsHandler("module", module.name, #module.scopes)
                lastModule = module
            end
            if not lastScope or lastScope ~= scope then
                resultsHandler("scope", module.name, scope.name, #scope.tests)
                lastScope = scope
            end
            if ExecuteTest("test", module, scope, test, resultsHandler) then
                passedCounter = passedCounter + 1
            else
                failedCounter = failedCounter + 1
            end
        end
        resultsHandler("summary", totalTests, totalModules, totalScopes, passedCounter, failedCounter)
    end
end