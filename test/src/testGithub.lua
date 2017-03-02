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

function Test:testGithub()
    local loader = Loader:new()
    u.assertNotEquals(loader.github, nil)
    u.assertIsTable(Loader)
end

function Test:testGithub_getReleases()
    local loader = Loader:new()
    local results = loader.github:getReleases("premake", "premake-core")
    u.assertTrue(#results > 5)
    u.assertTrue(results[1].version == zpm.semver(5, 0, 0, "alpha11"))
    u.assertTrue(results[2].version == zpm.semver(5, 0, 0, "alpha10"))
    u.assertTrue(results[3].version == zpm.semver(5, 0, 0, "alpha9"))

    u.assertTrue(results[1].assets[1].name:contains("premake-5.0.0-alpha11"))
    u.assertTrue(results[2].assets[2].name:contains("premake-5.0.0-alpha10"))
    u.assertTrue(results[3].assets[3].name:contains("premake-5.0.0-alpha9"))

    for _, release in ipairs(results) do
        u.assertNotNil(release.version)
        u.assertNotNil(release.assets)
        for _, asset in ipairs(release.assets) do
            u.assertNotNil(asset.name)
            u.assertNotNil(asset.url)
        end
    end
end

function Test:testGithub_getToken()

    local ghtoken = _OPTIONS["github-token"]
    local mock = os.getenv
    os.getenv = function() return nil end
    _OPTIONS["github-token"] = nil

    local loader = Loader:new()
    loader.config("github.token", nil)

    local token = loader.github:_getToken()
    u.assertEquals(token, nil)
    
    os.getenv = mock
    _OPTIONS["github-token"] = ghtoken
end

function Test:testGithub_getToken2()

    local ghtoken = _OPTIONS["github-token"]
    local mock = os.getenv
    os.getenv = function() return "test-foo" end
    _OPTIONS["github-token"] = nil

    local loader = Loader:new()
    loader.config("github.token", nil)

    local token = loader.github:_getToken()
    u.assertEquals(token, "test-foo")
    
    os.getenv = mock
    _OPTIONS["github-token"] = ghtoken
end

function Test:testGithub_getToken3()

    local ghtoken = _OPTIONS["github-token"]
    local mock = os.getenv
    os.getenv = function() return nil end
    _OPTIONS["github-token"] = "test-foo"

    local loader = Loader:new()
    loader.config("github.token", nil)

    local token = loader.github:_getToken()
    u.assertEquals(token, "test-foo")
    
    os.getenv = mock
    _OPTIONS["github-token"] = ghtoken
end

function Test:testGithub_getToken4()

    local ghtoken = _OPTIONS["github-token"]
    local mock = os.getenv
    os.getenv = function() return nil end
    _OPTIONS["github-token"] = nil

    local loader = Loader:new()
    loader.config.printf = function() end
    loader.config:set("github", {token = "Test-foo"})

    u.assertEquals(loader.config("github.token"), "Test-foo")

    local token = loader.github:_getToken()
    u.assertEquals(token, "Test-foo")
    
    os.getenv = mock
    _OPTIONS["github-token"] = ghtoken
end