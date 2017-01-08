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

zpm.build.commands = {}
zpm.build.rcommands = {}

function zpm.build.commands.extractdir( targets, prefix )

    if _OPTIONS["ignore-updates"] then
        return nil
    end

    prefix = prefix or "./"

    if type(targets) ~= "table" then
        targets = {targets}
    end
    
    for i, target in ipairs(targets) do
        local zipFile = path.join( zpm.temp, "submodule.zip" )
        local targetPath = path.join( zpm.build._currentExportPath, prefix, target )
        local depPath = path.join( zpm.build._currentDependency.dependencyPath, target )

        if path.getabsolute(depPath):contains( path.getabsolute(zpm.build._currentDependency.dependencyPath) ) then
        
            for _, file in ipairs( os.matchfiles( path.join( depPath, "**" ) ) ) do

                local ftarget = path.join( targetPath, path.getrelative( depPath, file ) )

                if ftarget:contains( ".git" ) == false  then
                    local ftargetDir = path.getdirectory( ftarget )            
                    
                    if not os.isdir( ftargetDir ) then
                        zpm.assert( os.mkdir( ftargetDir ), "Could not create directory '%s'!", ftargetDir )
                    end
                    
                    if ftarget:len() <= 255 then
                        if os.isfile( ftarget ) == false or zpm.util.isNewer( file, ftarget ) then
                            os.copyfile( file, ftarget )
                        end

                        zpm.assert( os.isfile(ftarget), "Could not make file '%s'!", ftarget )
                    else
                        warningf( "Failed to copy '%s' due to long path length!", ftarget )
                    end
                end
            end 
        end
    end

end

function zpm.build.commands.export( commands )

    local name = project().name
        
    local parent = zpm.build._currentDependency.projects[name].export
    local currExp = zpm.build._currentExportPath 
    local currDep = zpm.build._currentDependency
    zpm.build._currentDependency.projects[name].export = function()

        if parent ~= nil then
            parent()
        end

        local old = zpm.build._currentExportPath
        local oldDep = zpm.build._currentDependency
        zpm.build._currentExportPath = currExp
        zpm.build._currentDependency = currDep
        
        zpm.sandbox.run( commands, {env = zpm.build.getEnv()})  

        zpm.build._currentExportPath = old
        zpm.build._currentDependency = oldDep
    end

    zpm.sandbox.run( commands, {env = zpm.build.getEnv()})     
end

function zpm.build.commands.uses( proj )

    if type(proj) ~= "table" then
        proj = {proj}
    end

    local cname = project().name
    
    if zpm.build._currentDependency.projects[cname] == nil then
        zpm.build._currentDependency.projects[cname]  = {}
    end

    if zpm.build._currentDependency.projects[cname].uses == nil then
        zpm.build._currentDependency.projects[cname].uses  = {}
    end

    if zpm.build._currentDependency.projects[cname].packages == nil then
        zpm.build._currentDependency.projects[cname].packages  = {}
    end

    for _, p in ipairs(proj) do

        if p:contains( "/" ) then

            local package = zpm.build.findProject( p )

            if table.contains( zpm.build._currentDependency.projects[cname].packages, package ) == false then
                table.insert( zpm.build._currentDependency.projects[cname].packages, package )
            end
        else
            local name = zpm.build.getProjectName( p, zpm.build._currentDependency.version, zpm.build._currentDependency.options )

            if table.contains( zpm.build._currentDependency.projects[cname].uses, name ) == false then
                table.insert( zpm.build._currentDependency.projects[cname].uses, name )
            end
        end
    end
end

function zpm.build.commands.isDev()
    return zpm.isDev()
end

function zpm.build.rcommands.project( proj )

    local name = zpm.build.getProjectName( proj, zpm.build._currentDependency.version, zpm.build._currentDependency.options )

    project( name )

    -- always touch just in case
    --if _ACTION and _ACTION:contains( "vs" ) then
        dummyFile = path.join( zpm.install.getExternDirectory(), "dummy.cpp" )

        file = io.open( dummyFile, "w")
        file:write( string.format("void Dummy%s(){  return; }", string.sha1(dummyFile) ) )

        files(dummyFile)
    --end

    location( zpm.build._currentExportPath )
    targetdir( zpm.build._currentTargetPath )
    objdir( zpm.build._currentObjPath )
    warnings "Off"

    if zpm.build._currentDependency.projects == nil then
        zpm.build._currentDependency.projects = {}
    end

    if zpm.build._currentDependency.projects[name] == nil then
        zpm.build._currentDependency.projects[name] = {}
    end
end


function zpm.build.rcommands.dependson( depdson )

    if type(depdson) ~= "table" then
        depdson = {depdson}
    end

    for _, p in ipairs(depdson) do
            
        local dep = zpm.build._currentDependency
        dependson( zpm.build.getProjectName( p, dep.version, dep.options ) )
    end
end


function zpm.build.rcommands.kind( knd )

    local name = project().name

    zpm.build._currentDependency.projects[name].kind = knd

    kind( knd )
end

function zpm.build.rcommands.filter( ... )
        
    filter( ... )
end