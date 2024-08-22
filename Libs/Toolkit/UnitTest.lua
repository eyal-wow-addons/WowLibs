assert(LibStub, "UnitTest-1.0 requires LibStub")

local C = LibStub("Contracts-1.0")
assert(C, "UnitTest-1.0 requires Contracts-1.0")

local lib = LibStub:NewLibrary("UnitTest-1.0", 0)
if not lib then return end

lib.Addons = lib.Addons or {}

local assert = assert
local pcall = pcall
local print = print
local setmetatable = setmetatable
local tinsert = table.insert

do
    local Module = {}
    local TestSuite = {}
    local AssertionApi = {}

    function AssertionApi:Assert(condition)
        self.__calls = self.__calls + 1
        assert(condition, "Assertion failed: The test condition should have been true, but it was false.")
    end

    function AssertionApi:Capture(func, errorHandler)
        C:IsFunction(func, 2)
        self.__calls = self.__calls + 1
        local success, err = pcall(func)
        if errorHandler and err then
            errorHandler(err)
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
                func = func,
                api = {
                    -- NOTE: This is used to determine whether any assertions were executed during the execution of the test.
                    __calls = 0
                }
            }
            setmetatable(test.api, { __index = AssertionApi })
            tinsert(scope.tests, test)
        end

        function Module:CreateScope(name)
            C:IsString(name, 2)
            local scope = {
                name = name,
                tests = {}
            }
            tinsert(self.scopes, scope)
            return setmetatable(scope, { __newindex = function(_, testName, testFunc)
                AddTest(scope, testName, testFunc)
            end })
        end
    end

    function Module:Test(name)
        C:IsString(name, 2)
        return self:CreateScope(name)
    end

    function Module:Ref()
        return self.ref
    end

    function TestSuite:CreateModule(name, tbl)
        C:IsString(name, 2)
        local ref = tbl or LibStub(name, true)
        local module = {
            scopes = {},
            name = name,
            ref = ref,
            hasUnitUnderTest = ref ~= nil,
        }
        tinsert(self.modules, module)
        return setmetatable(module, { __index = Module })
    end

    function lib:Configure(addonName, addonTable)
        C:IsString(addonName, 2)
        C:IsTable(addonTable, 3)
        local testSuite = addonTable.TestSuite
        if not testSuite then
            testSuite = {
                name = addonName,
                modules = {}
            }
            addonTable.TestSuite = testSuite
            setmetatable(testSuite, { __index = TestSuite })
            tinsert(lib.Addons, testSuite)
        end
        return testSuite
    end

    function lib:TestLibrary(libName, ...)
        C:IsString(libName, 2)
        return self:Configure(...):CreateModule(libName)
    end

    function lib:TestTable(tblName, tbl, ...)
        C:IsString(tblName, 2)
        C:IsTable(tbl, 3)
        return self:Configure(...):CreateModule(tblName, tbl)
    end

    function UnitTest_Library(libName, ...)
        C:IsString(libName, 2)
        return LibStub("UnitTest-1.0"):TestLibrary(libName, ...)
    end
    
    function UnitTest_Table(tblName, tbl, ...)
        C:IsString(tblName, 2)
        C:IsTable(tbl, 3)
        return LibStub("UnitTest-1.0"):TestTable(tblName, tbl, ...)
    end
end

function lib:IterableTestInfo()
    local addons, modules, scopes, tests = self.Addons, nil, nil, nil
    local addon, module, scope = nil, nil, nil
    local a, m, s, t = 1, 1, 1, 1
    return function()
        while a <= #addons do
            addon = addons[a]

            modules = addon and addon.modules or modules
            scopes = module and module.scopes or scopes
            tests = scope and scope.tests or tests

            if tests and t <= #tests then
                local test = tests[t]
                t = t + 1
                return addon, module, scope, test
            elseif scopes and s <= #scopes then
                tests = nil
                scope = scopes[s]
                s, t = s + 1, 1
            elseif modules and m <= #modules then
                scopes, scope, tests = nil, nil, nil
                module = modules[m]
                m, s, t = m + 1, 1, 1
            else
                modules, module, scopes, scope, tests = nil, nil, nil, nil, nil
                a, m, s, t = a + 1, 1, 1, 1
            end
        end
    end
end

do
    local function PrintHandler(type, ...)
        if type == "addon" then
            local addonName, totalTests = ...
            print("-----------------------------------------------------------------------------------------------")
            print("+ " .. addonName .. " (Modules: " .. totalTests .. ")")
        elseif type == "module" then
            local addonName, moduleName, totalTests = ...
            print("-----------------------------------------------------------------------------------------------")
            print("    + " .. moduleName .. " (Scopes: " .. totalTests .. ")")
        elseif type == "scope" then
            local addonName, moduleName, scopeName, totalTests = ...
            print("        + " .. scopeName .. " (Tests: " .. totalTests .. ")")
        elseif type == "test" then
            local addonName, moduleName, scopeName, testName, err = ...
            print("            + " .. testName .. ": " .. err)
        elseif type == "summary" then
            print("-----------------------------------------------------------------------------------------------")
            local totalTests, totalAddons, totalModules, totalScopes, passedCounter, failedCounter = ...
            print(("Tests: %d | Addons: %d | Modules: %d | Scopes: %d | Passed: %d | Failed: %d"):format(totalTests, totalAddons, totalModules, totalScopes, passedCounter, failedCounter))
            print("-----------------------------------------------------------------------------------------------")
        end
    end

    local function ExecuteTest(type, addon, module, scope, test, resultsHandler)
        local success, err = pcall(test.func, test.api, module.ref)
        if not success then
            resultsHandler(type, addon.name, module.name, scope.name, test.name, err)
        end
        return test.api.__calls > 0, success
    end

    function lib:Run(resultsHandler)
        resultsHandler = resultsHandler or PrintHandler
        local lastAddon, lastModule, lastScope
        local totalTests, totalAddons, totalModules, totalScopes, passedCounter, failedCounter = 0, #self.Addons, 0, 0, 0, 0
        for addon, module, scope, test in self:IterableTestInfo() do
            if lastAddon ~= addon then
                totalModules = totalModules + #addon.modules
                resultsHandler("addon", addon.name, #addon.modules)
                lastAddon = addon
            end
            if lastModule ~= module then
                totalScopes = totalScopes + #module.scopes
                resultsHandler("module", addon.name, module.name, #module.scopes)
                lastModule = module
            end
            if lastScope ~= scope then
                resultsHandler("scope", addon.name, module.name, scope.name, #scope.tests)
                lastScope = scope
            end
            totalTests = totalTests + 1
            -- NOTE: A valid test is one that calls one of the assertions apis at least once during its execution.
            local valid, success = ExecuteTest("test", addon, module, scope, test, resultsHandler)
            if valid then
                if success then
                    passedCounter = passedCounter + 1
                else
                    failedCounter = failedCounter + 1
                end
            end
        end
        resultsHandler("summary", totalTests, totalAddons, totalModules, totalScopes, passedCounter, failedCounter)
    end
end

function UnitTest_Run(resultsHandler)
    LibStub("UnitTest-1.0"):Run(resultsHandler)
end