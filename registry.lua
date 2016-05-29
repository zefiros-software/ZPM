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

-- Registry
zpm.registry = {}
zpm.registry.dirs = {}
zpm.registry.registries = {}

function zpm.registry.loadPath( manifestPath )

    local registries = path.join( manifestPath, "_registries.json" )
    
    local list = zpm.JSON:decode( zpm.util.readAll( registries ) )
    
    for _, auth in ipairs(list) do
        
        zpm.registry.loadFile( auth )
        
    end
    

end

function zpm.registry.load()
   
    --print( "\nLoading registries..." )
            
    zpm.git.cloneOrPull( zpm.install.getMainRegistryDir(), zpm.install.registry.repository )
    
    zpm.assert( os.isfile( zpm.install.getMainRegistry() ), "The root registry is not found on path '%s'!", zpm.install.getMainRegistry() )
    
    local repos = zpm.JSON:decode( zpm.util.readAll( zpm.install.getMainRegistry() ) )
    zpm.registry.dirs = { zpm.install.getMainRegistryDir() }
    
    local localRegFile = path.join( _MAIN_SCRIPT_DIR, zpm.install.registry.fileName )
    
    if os.isfile( localRegFile ) then
    
        --print( "Loading local registries..." )
        
        local localRegistries = zpm.JSON:decode( zpm.util.readAll( localRegFile ) )
        repos = table.insertflat( localRegistries, repos )
    end
    
    for _, repo in ipairs( repos ) do
    
        local manok, registryPath = pcall( zpm.registry.loadFile, repo ) 
        if manok then
        
            if registryPath ~= nil then
               
                ok, err = pcall( zpm.registry.loadPath, registryPath )
                if not ok then  
                    printf( zpm.colors.error .. "Failed to load registry '%s' on '%s':\n%s", repo.name, repo.repository, err )
                end
                
            end
            
        else
            printf( zpm.colors.error .. "Failed to load registry '%s' on '%s':\n%s", repo.name, repo.repository, registryPath )
        end
        
    end

end

function zpm.registry.loadFile( registry )

    zpm.assert( registry.name ~= nil, "No 'name' supplied in registry definition!" )
    zpm.assert( registry.repository ~= nil, "No 'repository' supplied in registry definition!" )
    
    zpm.assert( zpm.util.isAlphaNumeric( registry.name ), "'name' supplied in registry defintion must be alpha numeric!" )
    zpm.assert( registry.name:len() <= 50, "'name' supplied in registry defintion exceeds maximum size of 50 characters!" )
    zpm.assert( zpm.util.isGitUrl( registry.repository ), "'repository' supplied in registry defintion is not a valid https git url!" )

    if zpm.registry.registries[registry.name] ~= nil then
        return nil
    end
    
    zpm.registry.registries[registry.name] = registry

    --printf( "Updating registry '%s' on '%s'...", registry.name, registry.repository )
    
    local registryPath = path.join( zpm.cache, zpm.install.registry.directories )
    
    if not os.isdir( registryPath ) then 
        os.mkdir( registryPath )
    end
    
    local regPath = path.join( registryPath, zpm.util.getRepoDir( registry.name, registry.repository ) )
    
    printf( "Switching to directory '%s'...", regPath )
        
    zpm.git.cloneOrPull( regPath, registry.repository )
    
    zpm.registry.dirs = table.insertflat( zpm.registry.dirs, regPath )
    
    return regPath

end