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

dofile( "action/install-module.lua" )
dofile( "action/update-module.lua" )
dofile( "action/update-modules.lua" )

-- Modules
zpm.modules = {}
zpm.modules.modules = {}
zpm.modules.search = zpm.bktree:new()
zpm.modules.searchMaxDist = 0.6

function zpm.modules.suggestModule( vendor, name ) 

    if zpm.modules.modules[ vendor ] == nil or zpm.modules.modules[ vendor ][ name ] == nil then
    
        local str = string.format( "%s/%s", vendor, name )
        local suggest = zpm.modules.search:query( str, #str * ( 1 - zpm.modules.searchMaxDist ) )
        
        if #suggest > 0 then
        
            if not zpm.modules.isModuleInstalled( suggest[1].str ) then
            
                printf( zpm.colors.error .. "Requiring module with vendor '%s' and name '%s' does not exist!", vendor, name )
                
                printf( zpm.colors.green .. zpm.colors.bright .. "Did you mean module '%s' (y/N [enter])?", suggest[1].str )
            
                local answer = io.read()
                if answer == "Y" or answer == "y" then
                    return true, bootstrap.getModule( suggest[1].str )
                end
                
            end
        else
        
            zpm.assert( zpm.modules.modules[ vendor ] ~= nil, "Requiring module with vendor '%s' does not exist!", vendor )
            zpm.assert( zpm.modules.modules[ vendor ][ name ] ~= nil, "Requiring module with vendor '%s' and name '%s' does not exist!", vendor, name )

        end
        
        return false, { vendor, name }
    end
   
    return true, { vendor, name }
end

function zpm.modules.isModuleInstalled( vendor, name )

    if name ~= nil then
        
        return os.isdir( path.join( bootstrap.directories[1], path.join( vendor, name ) ) )
    
    end
        
    return os.isdir( path.join( bootstrap.directories[1], vendor ) )
    
end

function zpm.modules.requestModules( modules ) 

    if modules == nil then
        return nil
    end

    for _, module in ipairs( modules ) do
    
        local pak = bootstrap.getModule( module )
        local name = pak[2]
        local vendor = pak[1] 
        
        local ok, result, suggest = pcall( zpm.modules.suggestModule, vendor, name )
        if ok and result then
        
            vendor = suggest[1]
            name = suggest[2]                          
  
            local modPath = path.join( bootstrap.directories[1], path.join( vendor, name ) )

            if not os.isdir( modPath ) then
                
                printf("Install package '%s/%s' (Y [enter]/n)?", vendor, name )
                local answer = io.read()
                if answer == "Y" or answer == "y" or answer == "" then
                
                    local head = path.join( modPath, "head" )
                    
                    zpm.modules.update( head, modPath, {vendor, name} )
                end
            
            end
        end
    end 

end

function zpm.modules.installOrUpdateModule()

    zpm.install.updatePremake( true )
    
    zpm.assert( #_ARGS > 0, "No module specified to install or update!" )

    local module = {}

    if #_ARGS > 1 then
        module = { _ARGS[1], _ARGS[2] }
    else
        module = bootstrap.getModule( _ARGS[1] )
    end

    local ok, suggest = zpm.modules.suggestModule( module[1], module[2] )

    if ok then
    
        module = suggest

        local modPath = path.join( bootstrap.directories[1], path.join( module[1], module[2] ) )
        
        local head = path.join( modPath, "head" )
    
        printf( "Installing or updating module '%s/%s'...", module[1], module[2] ) 
        
        zpm.modules.update( head, modPath, module )
    
    end

end

function zpm.modules.update( head, modPath, module )

    zpm.git.cloneOrPull( head, zpm.modules.modules[ module[1] ][ module[2] ].repository )

    local tags = zpm.git.getTags( head )

    for _, tag in ipairs( tags ) do
    
        local verPath = path.join( modPath, tag.version )
        
        if not os.isdir( verPath ) then
        
            printf( "Installing version '%s'...", tag.version ) 

            local zipFile = path.join( modPath, "archive.zip" )
            zpm.git.archive( head, zipFile, tag.tag )
                        
            assert( os.mkdir( verPath ) )
            zip.extract( zipFile, verPath )

            os.remove( zipFile )
        end
    end 
    
end

function zpm.modules.setSearchDir()

    -- override default location
    bootstrap.directories = table.insertflat( { path.join( zpm.cache, "modules" ) }, bootstrap.directories )

end

function zpm.modules.load()

    --print( "\nLoading modules ..." )
        
    for _, dir in ipairs( table.insertflat( { _MAIN_SCRIPT_DIR }, zpm.registry.dirs ) ) do
        local localModFile = path.join( dir, zpm.install.modules.fileName ) 
    
        if os.isfile( localModFile ) then    
            local manok, err = pcall( zpm.modules.loadFile, localModFile ) 
            if not manok then
                printf( zpm.colors.error .. "Failed to load modules '%s':\n%s", dir, err ) 
            end
        end
    end
    
end

function zpm.modules.loadFile( file )

    if not os.isfile( file ) then
        return nil
    end
    
    --print( string.format( "Loading modules '%s'...", file ) )
        
    local modules = zpm.JSON:decode( zpm.util.readAll( file ) )
    
    for _, module in ipairs( modules ) do
    
        local man = bootstrap.getModule( module.name )
        local name = man[2]
        local vendor = man[1]

        zpm.assert( name ~= nil, "No 'name' supplied in module definition!" )
        zpm.assert( vendor ~= nil, "No 'vendor' supplied in module definition!" )
        zpm.assert( module.repository ~= nil, "No 'repository' supplied in module definition!" )
        
        zpm.assert( zpm.util.isAlphaNumeric( name ), "'name' supplied in module defintion must be alpha numeric!" )
        zpm.assert( name:len() <= 50, "'name' supplied in module defintion exceeds maximum size of 50 characters!" )
        
        zpm.assert( zpm.util.isAlphaNumeric( vendor ), "'vendor' supplied in module defintion must be alpha numeric!" )
        zpm.assert( vendor:len() <= 50, "'vendor' supplied in module defintion exceeds maximum size of 50 characters!" )
        
        zpm.assert( zpm.util.isGitUrl( module.repository ), "'repository' supplied in module defintion is not a valid https git url!" )
        
        if zpm.modules.modules[ vendor ] == nil then
            zpm.modules.modules[ vendor ] = {}
        end
        
        if zpm.modules.modules[ vendor ][ name ] == nil then
        
            zpm.modules.search:insert( string.format( "%s/%s", vendor, name ) )
        
            zpm.modules.modules[ vendor ][ name ] = {}
            zpm.modules.modules[ vendor ][ name ].includedirs = {}
            
            zpm.modules.modules[ vendor ][ name ].repository = module.repository
            
        end
    
    end    
    
end

function zpm.modules.listModules()
    
    return os.matchdirs( path.join( zpm.install.getModulesDir(), "*/*/" ) )
        
end

function zpm.modules.updateModules()
    
    local matches = zpm.modules.listModules()
    
    for _, match in ipairs( matches ) do
    
        local vendor, name = match:match( ".*/(.*)/(.*)" )
        local module = { vendor, name }
        printf( "Updating module '%s/%s'...", module[1], module[2] ) 
        zpm.modules.update( path.join( match, "head" ), match, module )
    end
    
end