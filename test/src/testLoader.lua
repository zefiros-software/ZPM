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

function Test:testLoaderExists()
    u.assertNotEquals(Loader, nil)
    u.assertIsTable(Loader)
end

function Test:testLoader_fixMainScript()

    u.assertNotEquals(_MAIN_SCRIPT, "zpm.lua")

    local ld = Loader:new()

    u.assertNotEquals(_MAIN_SCRIPT, "zpm.lua")
end

function Test:testLoader_fixMainScriptZpmlua()

    _MAIN_SCRIPT = "premake5.lua"

    local zpmFile = path.join(_MAIN_SCRIPT_DIR, "zpm.lua")
    local f = io.open(zpmFile, "w")
    f:write("")
    f:close()

    local ld = Loader:new()

    u.assertEquals(_MAIN_SCRIPT, zpmFile)

    os.remove(zpmFile)

    _MAIN_SCRIPT = ""
end

function Test:testLoader_fixMainScriptDisabledZpmlua()

    _MAIN_SCRIPT = ""

    local zpmFile = path.join(_MAIN_SCRIPT_DIR, "zpm.lua")
    local f = io.open(zpmFile, "w")
    f:write("")
    f:close()

    local ld = Loader:new()

    u.assertEquals(_MAIN_SCRIPT, "")

    os.remove(zpmFile)

    _MAIN_SCRIPT = ""
end

function Test:testLoader_fixMainScriptZpmlua2()

    _ACTION = "self-update"
    _MAIN_SCRIPT = ""

    local ld = Loader:new()

    u.assertEquals(_MAIN_SCRIPT, "")

    _ACTION = ""
end

function Test:testLoader_checkGitVersion()

    local ld = Loader:new()

    u.assertTrue(ld.gitCheckPassed)
end

function Test:testLoader_initialiseCache()

    local ld = Loader:new()

    u.assertTrue(os.isdir(ld.cache))
    u.assertTrue(os.isdir(ld.temp))
end