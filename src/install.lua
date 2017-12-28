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

Installer = newclass "Installer"

function Installer:init(loader)

    self.loader = loader
    self.premakeSystemFile = self:_getPremakeSystem()
    self.cacheTime = self.loader.config("cache.premake.cacheTime")
end

function Installer:install()

    self:_writePremakeSystem()

    if os.isfile(self.premakeSystemFile) then
        dofile(self.premakeSystemFile)

        premake.action.call("update-bootstrap")
        premake.action.call("update-zpm")
        premake.action.call("update-registry")
    end

    self:_installPremake()
    self:_installInPath()
end

function Installer:update()

    self:_writePremakeSystem()

    premake.action.call("update-bootstrap")
    premake.action.call("update-zpm")
    premake.action.call("update-registry")

    self:_updatePremake()
end

function Installer:checkVersion()

    if not zpm.util.isMainScriptDisabled() then
        local latest, allowCompilation = self:_getLatestPremake()
        print(table.tostring(latest))
        if self:_getCurrentVersion() < latest.version then
            printf("%%{green bright}A new premake version '%s' is available!\nPlease run 'zpm self-update'", tostring(latest.version))
        end
    end
end

function Installer:_getPremakeSystem()

    return path.join(zpm.env.getBinDirectory(), "premake-system.lua")
end

function Installer:_writePremakeSystem()

    local folder = zpm.env.getDataDirectory()
    local file = io.open(self.premakeSystemFile, "wb")
    file:write(("local CMD = \"%s\"\n"):format(folder) ..
    ("local ZPM_DIR = \"%s\"\n"):format("zpm") ..
    ("local ZPM_REPO = \"%s\"\n"):format(self.loader.config("install.zpm.repository")) ..
    ("local ZPM_BRANCH = \"%s\"\n"):format(self.loader.config("install.zpm.branch")) ..
    ("local REGISTRY_DIR = \"%s\"\n"):format(self.loader.config("install.registry.directory")) ..
    ("local REGISTRY_REPO = \"%s\"\n"):format(self.loader.config("install.registry.repository")) ..
    ("local REGISTRY_BRANCH = \"%s\"\n"):format(self.loader.config("install.registry.branch")) ..
    ("local BOOTSTRAP_DIR = \"%s\"\n"):format(self.loader.config("install.bootstrap.directory")) ..
    ("local BOOTSTRAP_REPO = \"%s\"\n"):format(self.loader.config("install.bootstrap.repository")) ..
    ("local BOOTSTRAP_BRANCH = \"%s\"\n"):format(self.loader.config("install.bootstrap.branch")))

    file:write(zpm.util.readAll(path.join(zpm.env.getScriptPath(), "premake-system.lua")))
    file:close()
end

function Installer:_getCurrentVersion()
    return zpm.semver(self.loader.config("cache.version"))
end

function Installer:_updatePremake()

    local latest, allowCompilation = self:_getLatestPremake()
    zpm.assert(#latest.assets == 1 or allowCompilation, "Found more than one matching premake versions to download!")

    if true or self:_getCurrentVersion() < latest.version then
        printf("%%{green bright} - Updating premake version from '%s' to '%s'", tostring(self:_getCurrentVersion()), tostring(latest.version))

        self:_emplaceNewVersion(latest, allowCompilation)

        return true
    end

    return false
end


function Installer:_installPremake()

    local latest, allowCompilation = self:_getLatestPremake()

    zpm.assert(#latest.assets > 0 or allowCompilation, "Found no matching premake versions to download!")
    zpm.assert(#latest.assets == 1 or allowCompilation, "Found more than one matching premake versions to download!")

    printf("%%{green bright}- Installing premake version '%s'", tostring(latest.version))

    self:_emplaceNewVersion(latest, allowCompilation)
end

function Installer:_installNewVersion(asset, version)

    -- first try to download the new file
    local files = self.loader.http:downloadFromArchive(asset.url, "premake*")

    zpm.assert(files, "Failed to download '%s'!", asset.url)
    
    return files
end

function Installer:_emplaceNewVersion(latest, allowCompilation)

    -- try the downloaded binary first
    local files = self:_installNewVersion(latest.assets[1], tostring(latest.version))

    local result, errorCode = os.outputoff("%s --version", file)
    if errorCode ~= 0 and allowCompilation then
        warningf("Failed to load downloaded binary, compiling premake from source now.")
        file = self:_compileNewVersion(latest.zip, tostring(latest.version))
    end
    
    local globalCmd = path.join(zpm.env.getBinDirectory(), iif(os.ishost("windows"), "zpm.exe", "zpm"))
    local globalCmdd = path.join(zpm.env.getBinDirectory(), iif(os.ishost("windows"), "zpmd.exe", "zpmd"))
    if os.isfile(globalCmd) then
        zpm.util.hideProtectedFile(globalCmd)
    end    
    if os.isfile(globalCmdd) then
        zpm.util.hideProtectedFile(globalCmdd)
    end

    printf("Installed in '%s'", globalCmd)

    local normal = files[1]
    local zpmd = files[2]
    if normal:contains("premake5d") then
        normal = files[2]
        zpmd = files[1]
    end

    zpm.assert(os.rename(normal, globalCmd), "Failed to install premake '%s'!", normal)
    zpm.assert(os.isfile(globalCmd), "Failed to install premake '%s'!", normal)

    if zpmd then
        zpm.assert(os.rename(zpmd, globalCmdd), "Failed to install premake '%s'!", zpmd)
        zpm.assert(os.isfile(globalCmdd), "Failed to install premake '%s'!", zpmd)
    end

    self.loader.config:set("cache.version", version, true)
end


function Installer:_compileNewVersion(zip, version)

    -- first try to download the new file
    local destination = self.loader.http:downloadFromZip(zip, false)

    local current = os.getcwd()

    os.chdir(destination)
    
    subdir = os.matchdirs("*")[1]
    os.chdir(subdir)

    host = os.host()
    if host == "macosx" then
        host = "osx"
    end

    os.executef("make -f Bootstrap.mak %s", host)
    os.execute("make -C build/bootstrap -j config=debug")
   
    file = path.join(destination, subdir, "bin/release/premake5")

    os.chdir(current)

    return {file}
end

function Installer:_getLatestPremake()

    local versions, allowCompilation = false
    if not self.__latestPremake then

        -- check once a day
        local checkTime = self.loader.config("cache.premake.checkTime")
        if checkTime and os.difftime(os.time(), checkTime) < self.cacheTime then
            local cache = self.loader.config("cache.premake")
            self.__latestPremake = {
                version = zpm.semver(cache.version),
                assets = cache.assets,
                isCached = true,
                zip = cache.zip
            }
            allowCompilation = cache.allowCompilation
        else
            versions, allowCompilation = self:_getPremakeVersions()
            self.__latestPremake = versions[1]
            -- cache the value for a day
            self.loader.config:set("cache.premake", {
                checkTime = os.time(),
                version = tostring(self.__latestPremake.version),
                assets = self.__latestPremake.assets,
                zip = self.__latestPremake.zip,
                allowCompilation = allowCompilation
            }, true)
        end

    end

    return self.__latestPremake, allowCompilation
end

function Installer:_getPremakeVersions()

    local allowCompilation = false
    if not self.__PremakeVersion then
        local vendor = self.loader.config("install.premake.vendor")
        local name = self.loader.config("install.premake.name")

        self.__PremakeVersion = self.loader.github:getReleases(vendor, name,("premake-.*%s.*"):format(os.host()), self.loader.config("install.premake.release"))
        if not os.ishost("windows") then
            allowCompilation = true
        end        
    end
    
    return self.__PremakeVersion, allowCompilation

end

function Installer:_installInPath()

    if os.ishost("windows") then

        local cPath = os.getenv("PATH")
        local dir = zpm.env.getBinDirectory()
        if not string.contains(cPath, dir) then
            printf("- Installing zpm in path")

            local cmd = path.join(self.loader.temp, "path.ps1")

            zpm.util.writeAll(cmd, [[
                            $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $true)
                            $path = $key.GetValue('Path',$null,'DoNotExpandEnvironmentNames')
                            if( $PATH -notlike "*]] .. dir .. [[*" ){
                                $key.SetValue('Path', $path + ';]] .. dir .. [[', 'ExpandString')
                            }
                            $key.Dispose()
                        ]])
            os.executef("powershell -NoProfile -ExecutionPolicy ByPass -Command \"%s\" && set PATH=%%PATH%%;%s", cmd, dir)
        end

    elseif os.ishost("linux") or os.ishost("macosx") then

        self:_exportPath()

    else
        zpm.assert(false, "Current platform '%s' not supported!", os.host())
    end
end

function Installer:_exportPath()

    local prof = path.join(os.getenv("HOME"), ".profile")
    local line =("export PATH=\"$PATH:%s\""):format(zpm.env.getBinDirectory())

    if not os.isfile(prof) then
        warningf("Tried to add ZPM to your path by writing '%s' in '%s', but the file did not exist!\nWe created the file instead.", line, prof)
    end

    local profStr = zpm.util.readAll(prof)
    if not profStr:contains(line) then
        local f = assert(io.open(prof, "a"))
        f:write("\n" .. line)
        f:close()
    end

    printf("%%{yellow bright}We have added ZPM installation path in your '%s' file, however if this does not work\n%%{yellow bright}you have to add " ..
    "'%s' manually in your shell profile.", prof, line)
end
