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

local function _scriptPath()

    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
end

function Installer:init(loader)

    self.loader = loader
end

function Installer:install()

    self:_writePremakeSystem()

    local system = self:_getPremakeSystem()
    if os.isfile(system) then
        dofile(system)

        premake.action.call("update-bootstrap")
        premake.action.call("update-zpm")
        premake.action.call("update-registry")
    end

    self:_installPremake()
    self:_installInPath()
end

function Installer:checkVersion()

    local latest = self:_getLatestPremake()
    if self:_getCurrentVersion() < latest.version then
        printf("%%{green bright}A new premake version '%s' is available!\nPlease run 'zpm self-update'", tostring(latest.version))
    end
end

function Installer:_getPremakeSystem()

    return path.join(_PREMAKE_DIR, "premake-system.lua")
end

function Installer:_writePremakeSystem()

    local folder = zpm.env.getDataDirectory()
    local file = io.open(self:_getPremakeSystem(), "wb")
    file:write(("local CMD = \"%s\"\n"):format(folder) ..
    ("local BOOTSTRAP_DIR = \"%s\"\n"):format(self.loader.config("install.bootstrap.directory")) ..
    ("local BOOTSTRAP_REPO = \"%s\"\n"):format(self.loader.config("install.bootstrap.repository")) ..
    ("local INSTALL_DIR = \"%s\"\n"):format(zpm.env.getSrcDirectory()) ..
    ("local INSTALL_REPO = \"%s\"\n"):format(self.loader.config("install.repository")) ..
    ("local REGISTRY_DIR = \"%s\"\n"):format(self.loader.config("install.registry.directory")) ..
    ("local REGISTRY_REPO = \"%s\"\n"):format(self.loader.config("install.registry.repository")) ..
    ("local ZPM_BRANCH = \"%s\"\n"):format(self.loader.config("install.branch")))

    file:write(zpm.util.readAll(path.join(_scriptPath(), "premake-system.lua")))
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

    local globalCmd = path.join(zpm.env.getBinDirectory(), _PREMAKE_COMMAND)
    if os.isfile(globalCmd) then
        zpm.util.hideProtectedFile(globalCmd)
    end
    
    print("Installed in '%s'", globalCmd)

    zpm.assert(os.rename(file, globalCmd), "Failed to install premake '%s'!", file)
    zpm.assert(os.isfile(globalCmd), "Failed to install premake '%s'!", file)
end

function Installer:_getLatestPremake()

    if not self.__latestPremake then

        -- check once a day
        local checkTime = self.loader.config("cache.premake.checkTime")
        if checkTime and os.difftime(os.time(), checkTime) < (60 * 60 * 24) then
            local cache = self.loader.config("cache.premake")
            self.__latestPremake = {
                version = zpm.semver(cache.version),
                assets = cache.assets
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
        self.__PremakeVersion = self.loader.github:getReleases("premake", "premake-core", string.format("premake-.*-%s.*", os.get()))
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
            os.executef( "@powershell -NoProfile -ExecutionPolicy ByPass -Command \"%s\" && SET PATH=%%PATH%%;%s", cmd, dir )
        end
    
    elseif os.is("linux") or os.is("macosx") then
    
        self:_exportPath()
    
    else
        zpm.assert( false, "Current platform '%s' not supported!", os.get() )
    end
end

function Installer:_exportPath()

    if not (os.is("linux") or os.is("macosx")) then
        return nil
    end

    local prof = path.join( os.getenv("HOME"), iif(os.is("macosx"), ".bash_profile", ".bashrc") )
    if os.isfile( prof ) then
                            
        local profStr = zpm.util.readAll(prof)
        local line = ("export PATH=\"%s:$PATH\""):format(zpm.env.getBinDirectory())
        if not profStr:contains(line) then
            local f = assert(io.open(prof, "a"))
            f:write("\n"..line)
            f:close()
        end                
    end
end