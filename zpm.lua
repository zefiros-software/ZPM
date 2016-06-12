--[[ @cond ___LICENSE___
-- Copyright (c) 2016 Koen Visscher, Paul Visscher and individual contributors.
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

-- Module initialisation
zpm = {}
zpm._VERSION = "0.1.0-alpha"

-- Dependencies
zpm.JSON = (loadfile "json.lua")()
zpm.semver = require "semver"
zpm.bktree = require "bk-tree"

zpm.cachevar = "ZPM_CACHE"

-- Libs
zpm.libs = {}

dofile( "config.lua" )
dofile( "printf.lua" )
dofile( "assert.lua" )
dofile( "util.lua" )

-- we need to do this before the rest
zpm.config.initialise()
    
dofile( "wget.lua" )
dofile( "git.lua" )
dofile( "registry.lua" )
dofile( "manifest.lua" )
dofile( "modules.lua" )
dofile( "assets.lua" )
dofile( "packages.lua" )
dofile( "build.lua" )
dofile( "github.lua" )
dofile( "install.lua" )
    
premake.override(path, "normalize", function(base, p )

    if not zpm.util.hasGitUrl( p ) and not zpm.util.hasUrl( p ) then
        return base( p )
    end
    
    return p
end)

function zpm.uses( projects, options )

    if type( projects ) ~= "table" then
        projects = { projects }
    end
    
    for _, project in ipairs( projects ) do
    
        local project = zpm.build.findRootProject( project )
        
        if project ~= nil then
            
            for _, build in ipairs( project.build ) do
            
                local name = zpm.build.getProjectName( build.project, project.fullName, project.version )
            
            
                if build.getMayLink == nil or build.getMayLink() then
                    links( name )             
                end    
            
                if build.getExportLinks == nil then
                    links( build.getExportLinks() )             
                end    
                
                if build.getExportDefines ~= nil then 
                    defines( build.getExportDefines() )
                end
                
                if build.getExportIncludeDirs ~= nil then 
                    includedirs( build.getExportIncludeDirs() )
                end
            end                
        
        end
    end
end

function zpm.buildLibraries()

    local curFlter = premake.configset.getFilter(premake.api.scope.current)
    zpm.build._currentWorkspace = workspace().name

    filter {}
    group( string.format( "Extern/%s", zpm.build._currentWorkspace ) )    
    
    zpm.build._currentRoot = zpm.packages.root.dependencies
                    
    for _, dep in ipairs( zpm.packages.root.dependencies ) do
    
        if dep.build ~= nil then
        
            zpm.build.setCursor( dep )
            
            for _, build in ipairs( dep.build ) do
                
                zpm.build._currentBuild = build
                            
                zpm.build.queueCommand( function()
                
                    project( zpm.build.getProjectName( build.project, dep.fullName, dep.version ) )
                    location( zpm.install.getExternDirectory() )
                    targetdir( zpm.build._currentTargetPath )
                    objdir( zpm.build._currentObjPath )
                
                end)
                
                zpm.build.queueCommands( build["do"] )
                
            end    
            
            zpm.build.resetCursor()
        end                
    end
    
    zpm.build.executeCommands()
    
    zpm.build._currentRoot = nil
    
    group ""
    
    premake.configset.setFilter(premake.api.scope.current, curFlter)
--[[
    for vendor, vendorTab in pairs( zpm.packages.package ) do

        for name, nameTab in pairs( vendorTab ) do

            if nameTab.dependencies ~= nil then
                for i, dep in ipairs( nameTab.dependencies ) do
                
                    local buildFile = path.join( dep.buildPath, zpm.install.build.fileName )
                
                    local ok, buildFile = pcall( zpm.build.loadBuildFile, buildFile, dep )
                    if ok then
                    
                        buildFile = zpm.build.pathBuildFile( buildFile, dep.overrides )
                        zpm.packages.package[vendor][name].dependencies[i].build = buildFile
                    
                    else
                    
                        printf( zpm.colors.error .. "Failed to load package build '%s':\n%s", dep.fullName, buildFile )
                    
                    end                
                end
            end
        
        end
    
    end
]]

end


local function getCacheLocation()
	local folder = os.getenv(zpm.cachevar)
    
	if folder then
		return folder
    end
    
    if os.get() == "windows" then
        local temp = os.getenv("TEMP")
        zpm.assert( temp, "The temp directory could not be found!" )
        return path.join(temp, "zpm-cache")
    end
    
    return "/var/tmp/zpm-cache"
end


local function initialiseCacheFolder()

    -- cache the cache location
    zpm.cache = getCacheLocation()
    zpm.temp = path.join( zpm.cache, "temp" )
    
    if os.isdir( zpm.temp ) then
        os.rmdir( zpm.temp )
    end
    
    if not os.isdir( zpm.cache ) then
        print( "Creating cache folder" )   
        zpm.assert( os.mkdir( zpm.cache ), "The cache directory could not be made!" )
    end
    
    --print( "Cache location:", zpm.cache )   
    
    if not os.isdir( zpm.temp ) then
        print( "Creating temp folder" )   
        zpm.assert( os.mkdir( zpm.temp ), "The temp directory could not be made!" )
    end
    
    --print( "Temp location:", zpm.temp )  
    
end


function zpm.onLoad()

    print( string.format( "Loading The Zefiros Package Manager version '%s'...\nZefiros Package Manager - (c) Zefiros Software 2016", zpm._VERSION ) )
    
    initialiseCacheFolder()
    zpm.wget.initialise()
        
    if _ACTION ~= "self-update" and _ACTION ~= "install-zpm" then        
        
        zpm.modules.setSearchDir()
        
        zpm.install.updatePremake( true )
    
        zpm.registry.load()
        zpm.manifest.load()
        zpm.modules.load()
        
        if _ACTION ~= "install-module" and
           _ACTION ~= "update-module" and
           _ACTION ~= "update-modules" then
            
            zpm.assets.load()
            zpm.packages.load()
            zpm.build.load()
                    
        end
    end
end 

newoption {
    trigger     = "allow-shell",
    shortname   = "as",
    description = "Allows the usage of shell commands without confirmation"
}
newoption {
    trigger     = "allow-install",
    shortname   = "ai",
    description = "Allows the usage of install scripts without confirmation"
}

newaction {
    trigger     = "self-update",
    description = "Updates the premake executable to the latest version",
    execute = function ()

        zpm.install.updatePremake( false, true )
                       
        premake.action.call( "update-bootstrap" )
        premake.action.call( "update-registry" )
        premake.action.call( "update-zpm" )
   
        zpm.install.createSymLinks()     
    end
}

if _ACTION == "self-update" or
   _ACTION == "install-module" or
   _ACTION == "install-zpm" or
   _ACTION == "install-package" or
   _ACTION == "update-module" or
   _ACTION == "update-modules" or
   _ACTION == "update-bootstrap" or
   _ACTION == "update-registry" or
   _ACTION == "update-zpm" then
    -- disable main script
    _MAIN_SCRIPT = "."
        
end

newaction {
    trigger     = "install-zpm",
    description = "Installs zpm-premake in path",
    execute = function ()

        printf( zpm.colors.green .. zpm.colors.bright .. "Installing zpm-premake!" )
        
        if zpm.__isLoaded ~= true or zpm.__isLoaded == nil then
            zpm.onLoad()
            zpm.__isLoaded = true
        end

        zpm.install.initialise()
        zpm.install.setup()
        zpm.install.installInPath()
        zpm.install.setupSystem()
        
    end
}

newaction {
    trigger     = "install-package",
    description = "Installs all package dependencies",
    execute     = function()

        zpm.packages.install()

    end
}

return zpm