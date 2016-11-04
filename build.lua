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

zpm.build = {}
zpm.build.commands = {}

zpm.build.commandQueue = {}
       
zpm.build._currentExportPath = nil
zpm.build._currentTargetPath = nil
zpm.build._currentObjPath = nil
zpm.build._currentDependency = nil
zpm.build._currentProjects = nil
zpm.build._currentBuild = nil
zpm.build._isBuilding = false

function zpm.build.getEnv()

    local env = { 
        zpm = {
            build = {
            _currentExportPath = zpm.build._currentExportPath,
            _currentTargetPath = zpm.build._currentTargetPath,
            _currentObjPath = zpm.build._currentObjPath,
            _currentDependency = zpm.build._currentDependency,
            _currentProjects = zpm.build._currentProjects,
            _currentBuild = zpm.build._currentBuild 
            }
        },
        os = { 
            matchfiles = os.matchfiles,
            isdir = os.isdir,
            isfile = os.isfile,
            is = os.is,
            getenv = os.getenv
        },
        path = {
            join = path.join
        },
        table = table,
        print = print,
        _OS = _OS,
        _ARGS = _ARGS,
        _ACTION = _ACTION,
        _OPTIONS = _OPTIONS,	
        _PREMAKE_DIR = _PREMAKE_DIR,
        _MAIN_SCRIPT = _MAIN_SCRIPT,
        _PREMAKE_VERSION = _PREMAKE_VERSION,
        _PREMAKE_COMMAND = _PREMAKE_COMMAND,
        _MAIN_SCRIPT_DIR = _MAIN_SCRIPT_DIR
        
    }

    for name, func in pairs( zpm.build.commands ) do
        env.zpm[ name ] = function( ... )
            return func( ... )
        end
    end

    for name, func in pairs( zpm.build.rcommands ) do
        env[ name ] = function( ... )
            return func( ... )
        end
    end

    for name, func in pairs( premake.field._list ) do
        if env[name] == nil then 

            if name:contains( "command" ) then            
            
                env[ name ] = function( command )
                zpm.util.askShellConfirmation( string.format( "Allow usage of command '%s'", zpm.util.tostring( command ) ), 
                    function()
                        _G[name]( command )
                    end, 
                    function()
                        warningf( "Command not accepted, build may not work properly!" )
                    end)
                end
            else

                if func.kind == "list:directory" or func.kind == "list:file" then

                    env[ name ] = function( ... )             
                
                        local args = ...
                        if type( args ) ~= "table" then
                            args = { args }
                        end  

                        for i, dir in ipairs( args ) do
                            args[i] = path.join( zpm.build._currentExportPath, dir )
                        end
                        
                        _G[name](args)
                    end

                    if _G[ "remove" .. name ] ~= nil then
                        env[ "remove" .. name ] = function( ... )             
                    
                            local args = ...
                            if type( args ) ~= "table" then
                                args = { args }
                            end  

                            for i, dir in ipairs( args ) do
                                args[i] = path.join( zpm.build._currentExportPath, dir )
                            end
                            
                            _G[ "remove" .. name](args)
                        end
                    end

                else
                    env[ name ] = function( ... )
                        _G[ name](...)
                    end
                    if _G[ "remove" .. name ] ~= nil then
                        env[ "remove" .. name ] = function( ... )
                            _G[ "remove" .. name](...)
                        end
                    end
                end
            end
        end
    end

    return env
end

function zpm.build.buildPackage( package )

    if package.dependencies == nil then
        return nil
    end

    if  #package.dependencies > 0 then

        for _, dep in ipairs( package.dependencies ) do

            if dep.dependencies ~= nil then
                zpm.build.buildPackage( dep )    
            end
        end

    end 
                    
    for _, dep in ipairs( package.dependencies ) do
    
        if dep.build ~= nil then
        
            zpm.build.setCursor( dep )
            
            zpm.sandbox.run( dep.build, {env = zpm.build.getEnv(), quota = false})        

            zpm.build._currentDependency = dep
            zpm.build.resetCursor()

            for p, conf in pairs( dep.projects ) do

                if conf.uses ~= nil then
                    for _, uses in ipairs( conf.uses ) do
                        if conf.export ~= nil then
                            project( p )                                

                            if dep.projects[uses].kind == "StaticLib" then
                                links( uses )
                            end

                            dep.projects[uses].export()
                        end
                    end
                end

                if conf.packages ~= nil then
                    for _, package in ipairs( conf.packages ) do
                        zpm.useProject( package )
                    end
                end
            end
        end                
    end
end

function zpm.build.getProjectName( project, name, version )

    return string.gsub( string.format( "%s-%s", project, version ), "@", "" )
    
end

function zpm.build.findRootProject( name )

    if zpm.packages.root.dependencies == nil then
        return nil
    end

    for _, project in ipairs( zpm.packages.root.dependencies ) do
    
        if project.fullName == name then
        
            return project
        
        end
    
    end

    printf( zpm.colors.error .. "Could not find root project '%s', did you load it correctly as a dependency?", name )
    
    return nil

end

function zpm.build.findProject( name )

    for _, project in pairs( zpm.build._currentDependency.dependencies ) do
    
        if project.fullName == name then
        
            return project
        
        end
    
    end
    
    printf( zpm.colors.error .. "Could not find project '%s', did you load it correctly as a dependency?", name )
    
    return nil

end

function zpm.build.resetCursor()

    if zpm.build._oldPath ~= nil then
        os.chdir( zpm.build._oldPath )
    end

    zpm.build._oldPath = nil
    zpm.build._currentExportPath = nil
    zpm.build._currentTargetPath = nil
    zpm.build._currentObjPath = nil
    zpm.build._currentDependency = nil
    zpm.build._currentProjects = nil
end

function zpm.build.setCursor( dep )
       
    zpm.build._oldPath = os.getcwd() 
    zpm.build._currentExportPath = dep.exportPath
    zpm.build._currentTargetPath = path.join( zpm.build._currentExportPath, "extern/bin" )
    zpm.build._currentObjPath = path.join( zpm.build._currentExportPath, "extern/obj" )
    zpm.build._currentDependency = dep
    zpm.build._currentProjects = dep.build

    os.chdir( dep.exportPath )
end

function zpm.build.load()

    zpm.packages.root = zpm.build.loadPackages( zpm.packages.root )

end

function zpm.build.loadPackages( packages )

    if packages.dependencies == nil then
        return packages
    end
                
    for i, dep in ipairs( packages.dependencies ) do
    
        local buildFile = path.join( dep.buildPath, zpm.install.build.fileName )

        if dep.isShadow then
            buildFile = path.join( dep.buildPath, zpm.install.registry.build )
        end
    
        local ok, buildFile = pcall( zpm.build.loadBuildFile,  dep.buildPath, buildFile, dep )
        if ok then

            packages.dependencies[i].build = buildFile
        
        else
        
            printf( zpm.colors.error .. "Failed to load package build '%s':\n%s", dep.fullName, buildFile )
        
        end                
    end 

    for i, dep in ipairs( packages.dependencies ) do
                
        packages.dependencies[i] = zpm.build.loadPackages( dep )
    end

    return packages
end


function zpm.build.loadBuildFile( dir, file, dep )
    
    zpm.assert( os.isfile( file ), "No build file found for dependency '%s' version '%s'\non location '%s'!", dep.fullName, dep.version, file )

    local fileStr = zpm.util.readAll( file )
    
    if dep.isShadow then
        
        local buildStr = zpm.JSON:decode( fileStr )
        fileStr = zpm.util.readAll( zpm.build.getShadowBuildVersion( dir, buildStr, dep.version ) )     
    end

    return fileStr
end

function zpm.build.getShadowBuildVersion( dir, build, version )
    
    for _, bversion in pairs( build ) do
        if premake.checkVersion( version, bversion.version ) then
            local file = path.join( dir, bversion.file )
            zpm.assert( path.getabsolute( file ):contains( path.getabsolute( dir ) ), "Executing lua outside build folder is not allowed!" )
        
            return file
        end    
    end    
    
    error( string.format( "The version '%s' could not be satisfied with the build file!", version ) )
end
