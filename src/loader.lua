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

    self:_preInit()
    
    self.config = Config()
    self.config:load()

    self.settings = Config()
    self.settings.storeFile = nil

    self.cacheTime = self.config("cache.temp.cacheTime")

    self:fixMainScript()
    self:checkGitVersion()
    self:initialiseFolders()

    self.install = Installer(self)
    self.github = Github(self)
    self.http = Http(self)
    self.definition = Definition(self)

    self.registries = Registries(self)
    self.registries.isRoot = true

    self.manifests = Manifests(self, self.registries)

    self.project = Project(self)
end

function Loader:solve()

    if (not zpm.util.isMainScriptDisabled() 
       and not zpm.cli.showHelp()) 
       or zpm.cli.run() then
        self.project:solve()
    end
end

function Loader:fixMainScript()

    if zpm.cli.showVersion() then
        -- disable main script
        zpm.util.disableMainScript()

    elseif os.isfile(path.join(_MAIN_SCRIPT_DIR, "zpm.lua")) and not zpm.util.isMainScriptDisabled() then
        _MAIN_SCRIPT = path.join(_MAIN_SCRIPT_DIR, "zpm.lua")
    end
end

function Loader:checkGitVersion()

    local version = self.config("cache.git")
    if not version then

        version = self:_readGitVersion()
        self.config:set("cache.git", version, true)
    end

    if premake.checkVersion(version, ">=2.13.0") then
        self.gitCheckPassed = true

        -- retry without caching
    else
        version = self:_readGitVersion()
        if not premake.checkVersion(version, ">=2.13.0") then
            warningf("Git version should be >=2.13.0, current is '%s'", mversion)
        else
            self.config:set("cache.git", version, true)
        end
    end
end

function Loader:initialiseFolders()

    local binDir = zpm.env.getBinDirectory()
    if not os.isdir(binDir) then
        zpm.assert(os.mkdir(binDir), "The bin directory '%s' could not be made!", binDir)
    end

    if os.isdir(self.temp) and self:_mayClean() then
        zpm.util.rmdir(self.temp)

        if os.isdir(self.temp) then
            warningf("Failed to clean temporary directory '%s'", self.temp)
        else
            zpm.assert(os.mkdir(self.temp), "The temp directory '%s' could not be made!", self.temp)
        end
    end
end

function Loader:_readGitVersion()

    local mversion, errorCode = os.outputof("git --version")
    zpm.assert(mversion:contains("git version"), "Failed to detect git on PATH:\n %s", version)

    return mversion:match(".*(%d+%.%d+%.%d).*")
end

function Loader:_preInit()

    self:_initialiseCache()

    if bootstrap then
        -- allow module loading in the correct directory
        bootstrap.directories = zpm.util.concat( { path.join(self.cache, "modules") }, bootstrap.directories)
    end

    local prof = zpm.cli.profile()
    if prof then
        if prof == "pepper_fish" then
            profiler = newProfiler("time", 1000)
            profiler:start()
        elseif prof == "ProFi" then
            ProFi = require("mindreframer/ProFi", "@head")
            ProFi:setHookCount(0)
            ProFi:start()
        end
    end
end

function Loader:_initialiseCache()

    self.cache = zpm.env.getCacheDirectory()

    if not os.isdir(self.cache) then
        zpm.assert(os.mkdir(self.cache), "The cache directory '%s' could not be made!", self.cache)
    end

    self.temp = zpm.env.getTempDirectory()

    if not os.isdir(self.temp) then
        zpm.assert(os.mkdir(self.temp), "The temp directory '%s' could not be made!", self.temp)
    end

    self.tools = zpm.env.getToolsDirectory()

    if not os.isdir(self.tools) then
        zpm.assert(os.mkdir(self.tools), "The tools directory '%s' could not be made!", self.temp)
    end
end

function Loader:_mayClean()

    if self.__cacheMayClean ~= nil then
        return self.__cacheMayClean
    end

    self.__cacheMayClean = false
    local checkTime = self.config("cache.temp.checkTime")
    if not checkTime or os.difftime(os.time(), checkTime) > self.cacheTime then

        self.config:set("cache.temp.checkTime", os.time(), true)
        self.__cacheMayClean = true
    end

    return self.__cacheMayClean

end