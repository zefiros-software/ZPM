--[[ @cond ___LICENSE___
-- Copyright (c) 2017 Zefiros Software.
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--
-- @endcond
--]]

function Test:testInstall_premakeSystemFile()

    local loader = Loader:new()
    local inst = loader.install

    u.assertStrContains(inst.premakeSystemFile, "premake-system.lua")
end

function Test:testInstall_writePremakeSystem()

    local loader = Loader:new()
    local inst = loader.install
    inst.premakeSystemFile = "test-premake-system.lua"

    u.assertFalse(os.isfile(inst.premakeSystemFile))

    inst:_writePremakeSystem()

    u.assertTrue(os.isfile(inst.premakeSystemFile))

    u.assertStrContains(zpm.util.readAll(inst.premakeSystemFile), zpm.util.readAll(path.join(zpm.env.getScriptPath(), "../../src/premake-system.lua")))

    os.remove(inst.premakeSystemFile)
end

function Test:testInstall_install()

    local loader = Loader:new()
    loader.install:install()
end

function Test:testInstall_update()

    local loader = Loader:new()
    loader.install:update()
end

function Test:testInstall_update2()
    local mock = Installer._getCurrentVersion
    Installer._getCurrentVersion = function() return zpm.semver("0.0.0") end
    local loader = Loader:new()
    loader.install:update()
    Installer._getCurrentVersion = mock
end

function Test:testInstall_getLatestPremake()
    local loader = Loader:new() 
    loader.config.printf = function() end
    loader.config.values.cache.premake = nil
    loader.__latestPremake = nil

    local latest = loader.install:_getLatestPremake()
    u.assertEquals(latest.isCached, nil)

    local latest2 = loader.install:_getLatestPremake()
    u.assertEquals(latest2.isCached, nil)

    loader.install.__latestPremake = nil

    local latest3 = loader.install:_getLatestPremake()
    u.assertEquals(latest3.isCached, true)

end