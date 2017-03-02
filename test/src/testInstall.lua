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

    local inst = Installer:new(nil)

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