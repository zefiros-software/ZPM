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
       
zpm.build._currentBuildPath = nil
zpm.build._currentExportPath = nil
zpm.build._currentTargetPath = nil
zpm.build._currentObjPath = nil
zpm.build._currentDependency = nil
zpm.build._currentProjects = nil
zpm.build._currentBuild = nil

zpm.build._currentFilters = {}
zpm.build._previousFilters = {}

function zpm.build.buildPackage( package )

    if #package.dependencies > 0 then

        for _, dep in ipairs( package.dependencies ) do

            if dep.dependencies ~= nil then
                zpm.build.buildPackage( dep )
            end
        end

    end 
                    
    for _, dep in ipairs( package.dependencies ) do
    
        if dep.build ~= nil then
        
            zpm.build.setCursor( dep )
            
            for _, build in ipairs( dep.build ) do
                
                zpm.build._currentBuild = build
                zpm.build._currentBuild.exporting = false
                if zpm.build._currentBuild.export == nil then
                    zpm.build._currentBuild.export = {}
                end
                            
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

end

function zpm.build.getProjectName( project, name, version )

    wrkspc = zpm.build._currentWorkspace
    if wrkspc == nil then
        wrkspc = workspace().name
    end

    return string.format( "%s-%s", project, zpm.util.djb2( string.format( "%s/%s/%s", wrkspc, name, version ) ) )
    
end

function zpm.build.resetCursor()
            
    zpm.build._currentBuildPath = nil
    zpm.build._currentExportPath = nil
    zpm.build._currentTargetPath = nil
    zpm.build._currentObjPath = nil
    zpm.build._currentDependency = nil
    zpm.build._currentProjects = nil
    zpm.build._currentBuild = nil

end

function zpm.build.setCursor( dep )
            
    zpm.build._currentBuildPath = dep.buildPath
    zpm.build._currentExportPath = dep.exportPath
    zpm.build._currentTargetPath = path.join( zpm.build._currentExportPath, "extern/bin" )
    zpm.build._currentObjPath = path.join( zpm.build._currentExportPath, "extern/obj" )
    zpm.build._currentDependency = dep
    zpm.build._currentProjects = dep.build
end

function zpm.build.exportProjectBuild( build )

    if build.export ~= nil then
        for name, func in pairs( build.export ) do

            _G[name]( func() )

        end
    end

    return build
end

function zpm.build.exportReuseProjectBuild( build )

    for name, func in pairs( build.export ) do

        local expFunc = zpm.build._currentBuild.export[name]
        local hasPrev = expFunc == nil

        zpm.build._currentBuild.export[name] = function()
            if not hasPrev then
                expFunc()
            end
            if func ~= nil then
                func()
            end
        end

    end

    return build
end

function zpm.build.exportEasyCommand( func, value )

    local filters = table.arraycopy( zpm.build._currentFilters )
    local prevFilters = table.arraycopy( zpm.build._previousFilters )

    local export = zpm.build._currentBuild.export[func]
    local hasPrev = export == nil
    zpm.build._currentBuild.export[func] = function()
        if not hasPrev then
            export()
        end
        filter( filters )

        _G[func]( value )

        filter( prevFilters )
    end  
end

function zpm.build.reexportCommand( func, use )

    local filters = table.arraycopy( zpm.build._currentFilters )
    local prevFilters = table.arraycopy( zpm.build._previousFilters )

    local export = zpm.build._currentBuild.export[func]
    local hasPrev = export == nil
    zpm.build._currentBuild.export[func] = function()
        if not hasPrev then
            export()
        end

        filter( filters )

        if use[func] ~= nil then 

            use[func]()
        end

        filter( prevFilters )
    end  
end

function zpm.build.addEasyCommand( func )

    zpm.build.addCommand(
        { func },
        function( v )

            if zpm.build._currentBuild.exporting then
                zpm.build.exportEasyCommand( func, v[func] )
            end

            return function()   
                _G[func]( v[func] )
            end
        end)
end

function zpm.build.addPathCommand( func )

    zpm.build.addCommand(
        { func },
        function( v )                 
                
            if type( v[func] ) ~= "table" then
                v[func] = { v[func] }
            end  

            for i, dir in ipairs( v[func] ) do
                v[func][i] = path.join( zpm.build._currentExportPath, dir )
            end

            if zpm.build._currentBuild.exporting then
                zpm.build.exportEasyCommand( func, v[func] )
            end
            
            return function()   
                _G[func]( v[func] )
            end
        end)
end


function zpm.build.addBuildCommand( func )

    zpm.build.addCommand(
        { func },
        function( v )          
        return zpm.util.askShellConfirmation( string.format( "Allow usage of command '%s'", v[func] ), 
        function()
            return function()
                _G[func]( v[func] )
            end
        end, 
        function()
            return function()
                warningf( "Command not accepted, build may not work properly!" )
            end
        end )
    end)
end

function zpm.build.addEasyCommands( funcs )

    for _, func in ipairs( funcs ) do
        zpm.build.addEasyCommand( func )
    end
end

function zpm.build.loadCommands()

    zpm.build.addEasyCommands( { 
        "architecture",
        "atl",
        "defines",
        "builddependencies",
        "buildoptions",
        "buildoutputs",
        "callingconvention",
        "characterset",
        "clr",
        "debugargs",
        "debugenvs",
        "debugextendedprotocol",
        "debugformat",
        "debugport",
        "debugremotehost",  
        "kind",
        "configurations",
        "flags",
        "optimize",
        "disablewarnings",
        "editandcontinue",
        "editorintegration",
        "enablewarnings",
        "endian",
        "entrypoint",
        "exceptionhandling",
        "externalrule",
        "fatalwarnings",
        "fileextension",
        "floatingpoint",
        "fpu",
        "gccprefix",
        "ignoredefaultlibraries",
        "implibdir",
        "implibextension",
        "implibname",
        "implibprefix",
        "implibsuffix",
        "inlining",
        "language",
        "linkoptions",
        "links",
        "locale",
        "makesettings",
        "nativewchar",
        "pic",
        "rtti",
        "rule",
        "rules",
        "runtime",
        "strictaliasing",
        "targetprefix",
        "targetsuffix",
        "targetextension",
        "toolset",
        "undefines",
        "vectorextensions",
        "warnings"
    } )

    zpm.build.addBuildCommand( "buildcommands" )
    zpm.build.addBuildCommand( "debugcommand" )
    zpm.build.addBuildCommand( "debugconnectcommands" )
    zpm.build.addBuildCommand( "debugstartupcommands" )
    zpm.build.addBuildCommand( "postbuildcommands" )
    zpm.build.addBuildCommand( "prebuildcommands" )
    zpm.build.addBuildCommand( "prelinkcommands" )
        
    zpm.build.addPathCommand( "includedirs" )
    zpm.build.addPathCommand( "libdirs" )
    zpm.build.addPathCommand( "sysincludedirs" )
    zpm.build.addPathCommand( "syslibdirs" )
    zpm.build.addPathCommand( "files" )
    zpm.build.addPathCommand( "forceincludes" )

    zpm.build.addCommand(
        { "export" },
        function( v )    

            zpm.build._currentBuild.exporting = true

            local commands = zpm.build.getCommands( v.export )

            zpm.build._currentBuild.exporting = false

            return commands
        end)

    zpm.build.addCommand(
        { "reexport" },
        function( v )    
            
            for _, reexport in ipairs( v.reexport ) do
            
                for command, project in pairs( reexport ) do
        
                    local use = zpm.build.findSubProject( project, zpm.build._currentProjects )

                    if use.export ~= nil then
                        zpm.build.reexportCommand( command, use.export )
                    end
                end

            end

            return commands
        end)

    zpm.build.addCommand(
        { "headeronly" },
        function( v )
                    
            zpm.build._currentBuild.getMayLink = function()
                return v.headeronly ~= true
            end
            
            return function()
            end
        end)
            

    zpm.build.addCommand(
        { "uses" },
        function( v )                          
                
            if type( v.uses ) ~= "table" then
                v.uses = { v.uses }
            end  

            local projects = {}
            local uses = {}
            local dep = zpm.build._currentDependency
            for _, use in ipairs( v.uses ) do

                if use:contains( "/" ) then
                        
                    table.insert( projects, zpm.build.findProject( use, dep.dependencies ) )
                    
                else
                    local obj = zpm.build.findSubProject( use, zpm.build._currentProjects )
                    table.insert( uses, { name = use, uses = obj } )

                end
                
            end            

            local dep = zpm.build._currentDependency
            return function()

                for _, use in ipairs( uses ) do
                    local name = use.name
                    local use = use.uses
                    if use.getMayLink == nil or use.getMayLink() then
                        links( zpm.build.getProjectName( name, dep.fullName, dep.version ) )             
                    end  
                
                    zpm.build.exportProjectBuild( use )
                end

                for _, project in ipairs( projects ) do                    
                    zpm.useProject( project )
                end
            end
        end)
            

    zpm.build.addCommand(
        { "reuses" },
        function( v )                   
                
            if type( v.reuses ) ~= "table" then
                v.reuses = { v.reuses }
            end  

            local projects = {}
            local dep = zpm.build._currentDependency
            
            for _, use in ipairs( v.reuses ) do

                table.insert( projects, zpm.build.findProject( use, dep.dependencies ) )

                for _, project in ipairs( projects ) do
            
                    if project.build ~= nil then
                        for _, build in ipairs( project.build ) do

                            build = zpm.build.exportReuseProjectBuild( build )

                        end    
                    end
                end    

            end

            return function()
                for _, project in ipairs( projects ) do                    
                    zpm.useProject( project )
                end
            end
        end)

    zpm.build.addCommand(
        { "dependson" },
        function( v )
        
            local dep = zpm.build._currentDependency
            
            return function()
                dependson( zpm.build.getProjectName( v.uses, dep.fullName, dep.version ) )
            end
            
        end)

    zpm.build.addCommand(
        { "configmap" },
        function( v )
            
            local map = {}
            
            for _, config in ipairs( v.configmap ) do   
                    
                table.insert( map, {
                    [config.workspace] = config.project
                })
            
            end
            
            return function()
                configmap( map )
            end
        end)

    zpm.build.addCommand(
        { "vpaths" },
        function( v )
            
            local map = {}
            
            for _, vpath in ipairs( v.vpaths ) do   
                    
                table.insert( map, {
                    [config.name] = config.vpaths
                })
            
            end
            
            return function()
                vpaths( map )
            end
        end)

    zpm.build.addCommand(
        { "filter", "do" },
        function( v )    

            local prevFilter = table.arraycopy( zpm.build._currentFilters )
            local prevprevFilter = table.arraycopy( zpm.build._previousFilters )
            zpm.build._previousFilters = zpm.build._currentFilters
            table.insert( zpm.build._currentFilters, v.filter )

            local commands = zpm.build.getCommands( v["do"] )
            local filters = {
                function()
                    filter( v.filter )
                end
            }
            table.insert( filters, commands )
            table.insert( filters, {
                function()
                    filter {}
                end
            } )            

            zpm.build._currentFilters = prevFilter   
            zpm.build._previousFilters = prevprevFilter
                
            return filters
        end)

    zpm.build.addCommand(
        { "filter-options", "do" },
        function( v )    
        
            if v["filter-options"] ~= nil and zpm.build._currentBuild.options ~= nil then
                for option, value in pairs( v["filter-options"] ) do
          
                    for boption, bvalue in pairs( zpm.build._currentBuild.options ) do 
                        
                        if boption == option and value ~= bvalue then                 
                            return {}     
                        end      
                    end
                        
                end    
            end
            return zpm.build.getCommands( v["do"] )   
        end)

    zpm.build.addCommand(
        { "filter-options", "do", "otherwise" },
        function( v )    
        
            if v["filter-options"] ~= nil and zpm.build._currentBuild.options ~= nil then
                for option, value in pairs( v["filter-options"] ) do
          
                    for boption, bvalue in pairs( zpm.build._currentBuild.options ) do
                        
                        if boption == option and value ~= bvalue then
                            if v.otherwise ~= nil then
                                return zpm.build.getCommands( v.otherwise ) 
                            end
                            
                            return {}
                        end
                    
                    end
                        
                end    
            end
            
            return zpm.build.getCommands( v["do"] )   
        end)
    
end

function zpm.build.findSubProject( name, projects )

    if projects ~= nil then
        for _, project in ipairs( projects ) do
        
            if project.project == name then
            
                return project
            
            end
        
        end
    end

    printf( zpm.colors.error .. "Could not find sub project '%s', did you load it correctly as a dependency?", name )
    
    return nil

end

function zpm.build.findProject( name, projects )

    if projects ~= nil then
        for _, project in ipairs( projects ) do
        
            if project.fullName == name then
            
                return project
            
            end
        
        end
    end

    printf( zpm.colors.error .. "Could not find project '%s', did you load it correctly as a dependency?", name )
    
    return nil

end

function zpm.build.findRootProject( name )

    for _, project in ipairs( zpm.packages.root.dependencies ) do
    
        if project.fullName == name then
        
            return project
        
        end
    
    end
    
    printf( zpm.colors.error .. "Could not find root project '%s', did you load it correctly as a dependency?", name )
    
    return nil

end

function zpm.build.getCommand( value )

    local keywords = {}
    
    for kw, _ in pairs( value ) do
        table.insert( keywords, kw )
    end

    for i, command in ipairs( zpm.build.commands ) do
    
        if zpm.util.compare( command.keywords, keywords ) then
    
            return zpm.build.commands[i].execute( value )
            
        end
    end
    
    printf( zpm.colors.error .. "Unknown build command '%s':\n", table.tostring( value, 20 ) )
end

function zpm.build.getCommands( values )

    if values == nil or type( values ) ~= "table" then
        return {}
    end
    
    local commands = {}
    
    for _, com in ipairs( values ) do
        local func = zpm.build.getCommand( com )  
        
        if type( func ) == "function" or "table" then
        
            table.insertflat( commands, func )
        
        end
    end

    return commands
end

function zpm.build.queueCommands( values )

    if values == nil or type( values ) ~= "table" then
        return nil
    end
    zpm.build.queueCommand( zpm.build.getCommands( values ) )        

end

function zpm.build.queueCommand( command )

    table.insertflat( zpm.build.commandQueue, command )        

end

function zpm.build.executeCommands()    

    for _, command in ipairs( zpm.build.commandQueue ) do  
        command()
    end

    zpm.build.commandQueue = {}

    zpm.assert( #zpm.build._currentFilters == 0, "Filters did not reset properly!" )
    zpm.assert( #zpm.build._previousFilters == 0, "Filters did not reset properly!" )
end

function zpm.build.addCommand( keywords, func )

    table.insert( zpm.build.commands, {
        keywords = keywords,
        execute = func   
    })

end

function zpm.build.overrideCommand( keywords, func )

    for i, command in ipairs( zpm.build.commands ) do
    
        if zpm.util.compare( command.keywords, keywords ) then
    
            local oldFunc = zpm.build.commands[i].execute
        
            zpm.build.commands[i] = {
                keywords = keywords,
                execute = function( value )
                
                    func( oldFunc, value )
                    
                end
            }
            
        end
    end

end

function zpm.build.load()

    zpm.packages.root = zpm.build.loadPackages( zpm.packages.root )
    
    zpm.build.loadCommands()
end

function zpm.build.loadPackages( packages )

    if packages.dependencies == nil then
        return packages
    end
                
    for i, dep in ipairs( packages.dependencies ) do
    
        local buildFile = path.join( dep.buildPath, zpm.install.build.fileName )
    
        local ok, buildFile = pcall( zpm.build.loadBuildFile, buildFile, dep )
        if ok then
        
            buildFile = zpm.build.patchBuildFile( buildFile, dep.overrides )
            buildFile = zpm.build.patchOptions( buildFile, dep.options )
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

function zpm.build.patchOptions( buildFile, overrides )

    if overrides == nil then
        return buildFile
    end
    
    for _, override in pairs(overrides) do
        
        for i, build in pairs(buildFile) do
                    
            if override.project == build.project then
            
                for option, value in pairs(override.options) do
                        
                        zpm.assert( buildFile[i].options[ option ] ~= nil, "Option '%s' does not exist!", option )
                        buildFile[i].options[ option ] = value
                    
                end
                
            end
            
        end
    
    end

    return buildFile
end

function zpm.build.patchBuildFile( buildFile, overrides )

    if overrides == nil then
        return buildFile
    end
    
    for _, override in pairs(overrides) do
    
        for i, build in pairs(buildFile) do
            
            if override.project == build.project then
                
                local emptyFilter = {
                    filter = ""
                } 
                emptyFilter["do"] = ""
                                
                buildFile[i]["do"] = zpm.util.concat( buildFile[i]["do"], { emptyFilter } )   
                buildFile[i]["do"] = zpm.util.concat( buildFile[i]["do"], override["do"] )
            
            end
            
        end
    
    end

    return buildFile
end

function zpm.build.loadBuildFile( file, dep )
    
    zpm.assert( os.isfile( file ), "No build file found for dependency '%s' version '%s'\non location '%s'!", dep.fullName, dep.version, file )

    
    local fileStr = zpm.util.readAll( file )
    local buildStr = zpm.JSON:decode( fileStr )
    local buildFile = buildStr
    
    if dep.isShadow then
        
        buildFile = zpm.build.getShadowBuildVersion( buildStr, dep.version )
        
    end

    return buildFile
end

function zpm.build.getShadowBuildVersion( build, version )
    
    for _, bversion in pairs( build ) do
        if premake.checkVersion( version, bversion.version ) then
            return bversion.projects
        end    
    end    
    
    error( string.format( "The version '%s' could not be satisfied with the build file!", version ) )
end