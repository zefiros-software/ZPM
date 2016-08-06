
zpm.build.commands = {}
zpm.build.rcommands = {}

function zpm.build.commands.option( opt )

    zpm.assert(zpm.build._currentDependency.options[opt] ~= nil, "Option '%s' does not exist!", opt)
    return zpm.build._currentDependency.options[opt] == true
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

    for _, p in ipairs(proj) do
        local name = zpm.build.getProjectName( p, zpm.build._currentDependency.fullName, zpm.build._currentDependency.version )

        if table.contains( zpm.build._currentDependency.projects[cname].uses, name ) == false then
            table.insert( zpm.build._currentDependency.projects[cname].uses, name )

            local dep = zpm.build._currentDependency

        end
    end
end

function zpm.build.rcommands.project( proj )

    local name = zpm.build.getProjectName( proj, zpm.build._currentDependency.fullName, zpm.build._currentDependency.version )
    project( name )
    location( zpm.install.getExternDirectory() )
    targetdir( zpm.build._currentTargetPath )
    objdir( zpm.build._currentObjPath )

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
        dependson( zpm.build.getProjectName( p, dep.fullName, dep.version ) )
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