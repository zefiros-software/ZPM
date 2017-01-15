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


zpm.install = {
    directory = zpm.config.install.directory,
    minReqVersion = zpm.config.install.minReqVersion,
    repository = zpm.config.install.repository,
    modules =
    {
        directory = zpm.config.install.modules.directory,
        fileName = zpm.config.install.modules.fileName
    },
    bootstrap =
    {
        fileName = zpm.config.install.bootstrap.fileName,
        repository = zpm.config.install.bootstrap.repository,
        directory = zpm.config.install.bootstrap.directory
    },
    registry =
    {
        fileName = zpm.config.install.registry.fileName,
        repository = zpm.config.install.registry.repository,
        directory = zpm.config.install.registry.directory,
        directories = zpm.config.install.registry.directories,
        assets = zpm.config.install.registry.assets,
        modules = zpm.config.install.registry.modules,
        manifest = zpm.config.install.registry.manifest,
        registries = zpm.config.install.registry.registries,
        build = zpm.config.install.registry.build
    },
    manifests = {
        manifest = zpm.config.install.manifests.manifest,
        buildFile = zpm.config.install.manifests.buildFile,
        extensions = zpm.config.install.manifests.extensions
    },
    packages =
    {
        fileName = zpm.config.install.packages.fileName
    },
    extern =
    {
        directory = zpm.config.install.extern.directory
    }
}
-- patch settings with the default settings defined for manifest loading
zpm.install.manifests.fileName = zpm.config.install.manifests.fileName
zpm.install.manifests.buildFile = zpm.config.install.manifests.buildFile

function zpm.install.getModulesDir()
    return bootstrap.directories[1]
end

function zpm.install.getMainRegistry()
    return path.join(zpm.install.getMainRegistryDir(), zpm.install.registry.fileName)
end

function zpm.install.getMainRegistryDir()
    return zpm.util.getRelInstalllOrAbsDir(zpm.install.registry.directory, zpm.install.getSharedInstallDir())
end

function zpm.install.getExternDirectory()    
    return zpm.util.getRelInstalllOrAbsDir(zpm.install.extern.directory, _MAIN_SCRIPT_DIR)
end

function zpm.install.getDataDir()

    return zpm.install.getSharedDataDir()

end

function zpm.install.getSharedDataDir()

    if os.getenv("ZPM_SHARED_DIR") ~= "" and os.getenv("ZPM_SHARED_DIR") ~= nil then
        return os.getenv("ZPM_SHARED_DIR")
    end

    local osStr = os.get()

    if osStr == "windows" then
        return os.getenv("ALLUSERSPROFILE")
    elseif osStr == "linux" then
        return "/usr/local/"
    elseif osStr == "macosx" then
        return "/usr/local/"
    else
        zpm.assert(false, "Current platform '%s' is currently not supported!", osStr)
    end

end

function zpm.install.getInstallDir()
    return path.join(zpm.install.getDataDir(), zpm.install.directory)
end

function zpm.install.getSharedInstallDir()
    return path.join(zpm.install.getSharedDataDir(), zpm.install.directory)
end

function zpm.install.getPremakeCmd(version)

    local premakeCmd = "premake"
    if version then
        premakeCmd = string.format("premake%s", version)
    end

    if os.get() == "windows" then
        premakeCmd = premakeCmd .. ".exe"
    end

    return premakeCmd
end

function zpm.install.initialise()

    local folder = zpm.install.getInstallDir()

    if not os.isdir(folder) then

        printf("Creating installation directories...")

        zpm.assert(os.mkdir(folder), "Cannot create instalation folder '%s'!", folder)
    end

end

function zpm.install.writePremakeSystem()

    local folder = zpm.install.getInstallDir()

    local cmd = path.join( folder, "premake-system.lua" )
    local file = io.open( cmd, "w")
    file:write( [[
        
local cmd = "]] .. folder:gsub("\\","\\\\") .. [["

-- workaround
if os.get() == "macosx" then
    premake.path = premake.path .. ";" .. cmd  .. ";"
end

local function updateRepo( destination, url, name )

    local current = os.getcwd()
    
    if os.isdir( destination ) then
    
            print( "Updating " .. name .. "..." )
    
            os.chdir( destination )
            os.execute( "git checkout ." )
            os.execute( "git pull" )
            
            os.chdir( current )
        
    else
        
            print( "Creating " .. name .. "..." )
            os.execute( string.format( "git clone -v --recurse --progress \"%s\" \"%s\"", url, destination ) )
            --os.execute( "git config core.sharedRepository 0777" )        
    end

end
        
newaction {
    trigger     = "update-bootstrap",
    shortname   = "Update module loader",
    description = "Updates the module loader bootstrapping process",
    execute = function ()
    
        local destination = path.join( cmd, "]] .. zpm.install.bootstrap.directory .. [[" )
        local url = "]] .. zpm.install.bootstrap.repository .. [["
        updateRepo( destination, url, "bootstrap loader" )
    end
}      
  
newaction {
    trigger     = "update-zpm",
    shortname   = "Update zpm",
    description = "Updates the zpm module",
    execute = function ()
    
        local destination = path.join( cmd, "]] .. zpm.install.directory .. [[" )
        local url = "]] .. zpm.install.repository .. [["
        updateRepo( destination, url, "zpm" )
    end
}     
  
newaction {
    trigger     = "update-registry",
    shortname   = "Update the registry",
    description = "Updates the zpm library definitions",
    execute = function ()
    
        local destination = path.join( cmd, "]] .. zpm.install.registry.directory .. [[" )
        local url = "]] .. zpm.install.registry.repository .. [["
        updateRepo( destination, url, "registry" )
        
        if os.isdir( "]] .. zpm.install.registry.directories .. [[" ) then
            assert( os.mkdir( "]] .. zpm.install.registry.directories .. [[" ) )
        end
    end
}

if _ACTION ~= "update-bootstrap" and 
   _ACTION ~= "update-zpm" and 
   _ACTION ~= "update-registry" then
   
    if  _ACTION ~= "install-zpm" then
        bootstrap = require( "bootstrap" )
    end
    
    zpm = require( "zpm" )
else    
    _MAIN_SCRIPT = "."
end

]] )

    file:close()
end

function zpm.install.setupSystem()

    zpm.install.writePremakeSystem()
    
    local folder = zpm.install.getInstallDir()
    local system = path.join( folder, "premake-system.lua" )
    if os.isfile( system ) then
        dofile( system  )
    
        premake.action.call( "update-bootstrap" )    
        premake.action.call( "update-zpm" )
        premake.action.call( "update-registry" )
    end
end

function zpm.install.createSymLinks()

    usrPath = "/usr/bin/"
    if os.get() == "macosx" then
        usrPath = "/usr/local/bin/"
    end

    if os.get() == "linux" or os.get() == "macosx" then
        for _, prem in ipairs( os.matchfiles( path.join( zpm.install.getInstallDir(), "premake*" ) ) ) do
            os.execute( string.format( "sudo ln -sf %s %s%s", prem, usrPath, path.getname( prem ) ) )
        end 
        os.execute( string.format( "sudo ln -sf %s %szpm", path.join( zpm.install.getInstallDir(), "premake5"), usrPath ) )
    end

    if  os.get() == "macosx" then
        -- workaround for premake search path in osx
        os.execute( string.format( "sudo ln -sf %s/premake-system.lua %spremake-system.lua", zpm.install.getInstallDir(), usrPath ) )
    end
end

function zpm.install.installInPath()

    if os.get() == "windows" then
    
        local cPath = os.getenv( "PATH" )
        local dir = zpm.install.getInstallDir()
        
        if not string.contains( cPath, dir ) then
            printf( "- Installing premake in path" )
            
            local cmd = path.join( zpm.temp, "path.ps1" )
            local file = io.open( cmd, "w")
            file:write( [[
                if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }
                $PATH = [Environment]::GetEnvironmentVariable("PATH")
                $premakePath = "]] .. dir .. [["
                [Environment]::SetEnvironmentVariable("PATH", "$PATH;$premakePath", "User")
            ]] )
            file:close()
            
            os.execute( "@powershell -NoProfile -ExecutionPolicy ByPass -Command \"" .. cmd .. "\" && SET PATH=%PATH%;" .. dir )
        end
    
    elseif os.get() == "linux" then
    
        zpm.install.createSymLinks()
    
    elseif os.get() == "macosx" then
    
        zpm.install.createSymLinks()
    
    else
        zpm.assert( false, "Current platform '%s' not supported!", os.get() )
    end
end

function zpm.install.setup( checkLatest )

    checkLatest = checkLatest or true
    
    local folder = zpm.install.getInstallDir()

    local pattern = string.format( "premake-.*-%s.*", os.get() )
    local assets = zpm.GitHub.latestAssetMatches("premake", "premake-core", pattern )
    
    local isLatest = true
        
    for _, asset in pairs( assets ) do
    
        local premakeCmd = zpm.install.getPremakeCmd( "-" .. tostring( asset.version ) )
        
        local premakeFile = path.join( folder, premakeCmd )
        
        print(asset.version, zpm.install.minReqVersion)
        if not os.isfile( premakeFile ) and premake.checkVersion( asset.version, zpm.install.minReqVersion ) then
    
            printf( "- Installing premake version '%s'", tostring( asset.version ) )
            local file = zpm.util.downloadFromArchive( asset.url, "premake*" )[1]
            
            zpm.assert( os.rename( file, premakeFile ), "Failed to install premake '%s'!", file )
        
        end
        
        if checkLatest then
        
            local globalPremake = path.join( folder, zpm.install.getPremakeCmd( "5" ) )
            if ( isLatest and asset.version > zpm.semver( _PREMAKE_VERSION ) ) or not os.isfile( globalPremake ) then
                
                if os.isfile( globalPremake ) then
                    zpm.util.hideProtectedFile( globalPremake )
                end                

                if os.is( "windows" ) then
                    local zpmFile = path.join(folder, "zpm.exe" )
                    if os.isfile( zpmFile ) then
                        zpm.util.hideProtectedFile( zpmFile )
                    end
                    os.copyfile( premakeFile, zpmFile )
                end
                
                printf( "- Installing new default version '%s'", tostring( asset.version ) )
                os.copyfile( premakeFile, globalPremake )
            
            end
        end
    
        isLatest = false
    
    end

end

function zpm.install.getLatestPremakeVersion()
    
    local checkFile = path.join( zpm.cache, "PREMAKE-CHECK" )
    -- check once a day
    if os.isfile(checkFile) and os.difftime(os.time(), os.stat(checkFile).mtime) < (60 * 60 * 24) and zpm.semver(_PREMAKE_VERSION) == zpm.semver(zpm.util.readAll(checkFile))  then
        return true, nil
    end
    
    local pattern = string.format( "premake-.*-%s.*", os.get() )
    local ok, latest, version = pcall( zpm.GitHub.latestAssetMatch, "premake", "premake-core", pattern )   
    
    if ok then
        file = io.open(checkFile, "w")
        file:write( tostring( version ) )
        file:close()
    end

    return ok, latest, version
end

zpm.install.updatedPremake = false
function zpm.install.updatePremake( checkOnly, verbose )
    if zpm.install.updatedPremake then
        return nil
    end

    zpm.install.writePremakeSystem()

    verbose = verbose or false
    
    local ok, latest, version = zpm.install.getLatestPremakeVersion()
    
    if ok then
    
        if latest ~= nil and version > zpm.semver( _PREMAKE_VERSION ) then
        
            if checkOnly then
                printf( zpm.colors.green .. zpm.colors.bright .. "A new version '%s' of premake is available, current is '%s'\nPlease run 'premake5 self-update'", tostring( version ), _PREMAKE_VERSION )
            else
                printf( zpm.colors.green .. zpm.colors.bright .. "Updating premake to version '%s' from current version '%s'..." , tostring( version ), _PREMAKE_VERSION )
                
                local latestPremake = zpm.util.downloadFromArchive( latest.url, "premake*" )[1]
            
                local premakeFile = _PREMAKE_COMMAND
                
                if premakeFile == path.join(_PREMAKE_DIR, zpm.install.getPremakeCmd( "5" ) ) then
                
                    if os.isfile( premakeFile ) then
                        zpm.util.hideProtectedFile( premakeFile )
                    end
                    
                    zpm.assert( os.rename( latestPremake, premakeFile ), "Failed to install premake '%s'!", premakeFile )
                
                end

                if os.isdir( zpm.install.getInstallDir() ) then
            
                    zpm.install.setup( false )
                    
                end
        
                printf( zpm.colors.green .. zpm.colors.bright .. "Succesfully updated premake to version '%s'" , tostring( version ) )
                zpm.install.updatedPremake = true
            end
        
        else
            
            if verbose then
                printf( zpm.colors.green .. zpm.colors.bright .. "No new version found!" )
            end
        end
    else
    
        print( "Failed to check the premake version at this time" )        
    end
    
end