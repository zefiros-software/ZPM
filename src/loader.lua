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

Loader = newclass "Loader"

function Loader:init()

    self:fixMainScript()
    self:checkGitVersion()
    self:initialiseFolders()

    self.install = Installer:new(self)
    
    self.config = Config:new(self)
    self.config:load()
    
    self.github = Github:new(self)
    self.http = Http:new(self)

end

function Loader:fixMainScript()

    if _ACTION == "self-update" or
        _ACTION == "show-cache" or
        _ACTION == "show-install" or
        _ACTION == "install-module" or
        _ACTION == "install-zpm" or
        _ACTION == "install-package" or
        _ACTION == "update-module" or
        _ACTION == "update-modules" or
        _ACTION == "update-bootstrap" or
        _ACTION == "update-registry" or
        _ACTION == "update-zpm" or
        _OPTIONS["version"] then
        -- disable main script
        _MAIN_SCRIPT = "."

    elseif os.isfile(path.join(_MAIN_SCRIPT_DIR, "zpm.lua")) then
        _MAIN_SCRIPT = path.join(_MAIN_SCRIPT_DIR, "zpm.lua")
    end
end

function Loader:checkGitVersion()

    local version, errorCode = os.outputof("git --version")
    zpm.assert(version:contains("git version"), "Failed to detect git on PATH:\n %s", version)

    mversion = version:match(".*(%d+%.%d+%.%d).*")

    if premake.checkVersion(mversion, ">=2.9.0") then
        self.gitCheckPassed = true
    else
        warningf("Git version should be >=2.9.0, current is '%s'", mversion)
    end
end

function Loader:initialiseFolders()

    self:_initialiseCache()

    
    local binDir = zpm.env.getBinDirectory()
    if not os.isdir(binDir) then
        zpm.assert(os.mkdir(binDir), "The bin directory '%s' could not be made!", binDir)
    end
end

function Loader:_initialiseCache()

    self.cache = zpm.env.getCacheDirectory()
    self.temp = path.join(self.cache, "temp")

    if os.isdir(self.temp) then
        os.rmdir(self.temp)
    end

    if not os.isdir(self.cache) then
        zpm.assert(os.mkdir(self.cache), "The cache directory '%s' could not be made!", self.cache)
    end
    
    if not os.isdir(self.temp) then
        zpm.assert(os.mkdir(self.temp), "The temp directory '%s' could not be made!", self.temp)
    end
end