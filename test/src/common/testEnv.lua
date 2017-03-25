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

function Test:testEnv_scriptPath()

    u.assertNotNil(zpm.env.getScriptPath())
    u.assertStrContains(zpm.env.getScriptPath(), "src")
end

function Test:testEnv_getCacheDirectory()

    local dir = zpm.env.getCacheDirectory()
    u.assertNotNil(dir)
    u.assertStrContains(dir, "zpm")
end

function Test:testEnv_getCacheDirectory_SetENV()
    
    local mock = os.getenv
    os.getenv = function() return "foo" end
   
    local dir = zpm.env.getCacheDirectory()
    u.assertNotNil(dir)
    u.assertEquals(dir, "foo")
    
    os.getenv = mock
end

function Test:testEnv_getDataDirectory()

    local dir = zpm.env.getDataDirectory()
    u.assertNotNil(dir)
    u.assertStrContains(dir, "zpm")
end

function Test:testEnv_getDataDirectory_SetENV()
    
    local mock = os.getenv
    os.getenv = function() return "foo2" end
   
    local dir = zpm.env.getDataDirectory()
    u.assertNotNil(dir)
    u.assertEquals(dir, "foo2")
    
    os.getenv = mock
end