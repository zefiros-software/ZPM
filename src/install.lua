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

    local latest = self:_getLatestPremake()
    if self:_getCurrentVersion() < latest.version then
        printf("%%{green bright}A new premake version '%s' is available!\nPlease run 'zpm self-update'", tostring(latest.version))
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
    return zpm.semver(_PREMAKE_VERSION)
end

function Installer:_updatePremake()

    local latest = self:_getLatestPremake()
    zpm.assert(#latest.assets == 1, "Found more than one matching premake versions to download!")

    if self:_getCurrentVersion() < latest.version then
        printf("%%{green bright} - Updating premake version from '%s' to '%s'", _PREMAKE_VERSION, tostring(latest.version))

        self:_installNewVersion(latest.assets[1])

        return true
    end

    return false
end

function Installer:_installPremake()

    local latest = self:_getLatestPremake()

    zpm.assert(#latest.assets > 0, "Found no matching premake versions to download!")
    zpm.assert(#latest.assets == 1, "Found more than one matching premake versions to download!")

    printf("%%{green bright}- Installing premake version '%s'", tostring(latest.version))

    self:_installNewVersion(latest.assets[1])
end

function Installer:_installNewVersion(asset)

    -- first try to download the new file
    local file = self.loader.http:downloadFromArchive(asset.url, "premake*")[1]

    zpm.assert(file, "Failed to download '%s'!", asset.url)

    local globalCmd = path.join(zpm.env.getBinDirectory(), iif(os.is("windows"), "zpm.exe", "zpm"))
    if os.isfile(globalCmd) then
        zpm.util.hideProtectedFile(globalCmd)
    end
    
    printf("Installed in '%s' in directory '%s'", globalCmd, zpm.env.getBinDirectory())

    zpm.assert(os.rename(file, globalCmd), "Failed to install premake '%s'!", file)
    zpm.assert(os.isfile(globalCmd), "Failed to install premake '%s'!", file)
end

function Installer:_getLatestPremake()

    if not self.__latestPremake then

        -- check once a day
        local checkTime = self.loader.config("cache.premake.checkTime")
        if checkTime and os.difftime(os.time(), checkTime) < self.cacheTime then
            local cache = self.loader.config("cache.premake")
            self.__latestPremake = {
                version = zpm.semver(cache.version),
                assets = cache.assets,
                isCached = true
            }
        else
            self.__latestPremake = self:_getPremakeVersions()[1]
            -- cache the value for a day
            self.loader.config:set("cache", { 
                premake = { 
                    checkTime = os.time(),
                    version = tostring(self.__latestPremake.version),
                    assets = self.__latestPremake.assets
                } 
            }, true)
        end

    end

    return self.__latestPremake
end

function Installer:_getPremakeVersions()

    if not self.__PremakeVersion then
        local vendor = self.loader.config("install.premake.vendor")
        local name = self.loader.config("install.premake.name")
        self.__PremakeVersion = self.loader.github:getReleases(vendor, name, ("premake-.*%s.*"):format(os.host()), self.loader.config("install.premake.release"))
    end

    return self.__PremakeVersion

end

function Installer:_installInPath()

    if os.is("windows") then
    
        local cPath = os.getenv( "PATH" )
        local dir = zpm.env.getBinDirectory()
        if not string.contains( cPath, dir ) then
            printf( "- Installing zpm in path" )

            local cmd = path.join( self.loader.temp, "path.ps1" )

            zpm.util.writeAll(cmd,[[
                $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $true)
                $path = $key.GetValue('Path',$null,'DoNotExpandEnvironmentNames')
                $key.SetValue('Path', $path + ';]] .. dir .. [[', 'ExpandString')
                $key.Dispose()
            ]])            
            os.executef( "@powershell -NoProfile -ExecutionPolicy ByPass -Command \"%s\" && SET PATH=\"%%PATH%%;%s\"", cmd, dir )
        end
    
    elseif os.is("linux") or os.is("macosx") then
    
        self:_exportPath()
    
    else
        zpm.assert( false, "Current platform '%s' not supported!", os.get() )
    end
end

function Installer:_exportPath()

    local prof = path.join( os.getenv("HOME"), iif(os.is("macosx"), ".bash_profile", ".bashrc") )
    local line = ("export PATH=\"%s:$PATH\""):format(zpm.env.getBinDirectory())

    if os.isfile( prof ) then
                            
        local profStr = zpm.util.readAll(prof)
        if not profStr:contains(line) then
            local f = assert(io.open(prof, "a"))
            f:write("\n"..line)
            f:close()
        end                
    else
        warningf("Tried to add ZPM to your path by writing '%s' in '%s', but the file does not exist!", line, prof)
    end

    printf("%%{yellow bright}We have added ZPM installation path in your '%s' file, however if this does not work\n%%{yellow bright}you have to add " ..
           "'%s' manually in your shell profile.", prof, line)
end