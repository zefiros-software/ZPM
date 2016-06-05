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

-- Packages
zpm.packages = {}
zpm.packages.search = zpm.bktree:new()
zpm.packages.searchMaxDist = 0.1

zpm.packages.package = {}

zpm.packages.root = {}
zpm.packages.root.isLoaded = false

function zpm.packages.suggestPackage( vendor, name ) 

    if zpm.packages.package[ vendor ] == nil or zpm.packages.package[ vendor ][ name ] == nil then
    
        local str = string.format( "%s/%s", vendor, name )
        local suggest = zpm.packages.search:query( str, #str * ( 1 - zpm.packages.searchMaxDist ) )
    
        if #suggest > 0 then
            
            printf( zpm.colors.error .. "Requiring package with vendor '%s' and name '%s' does not exist!", vendor, name )
            
            printf( zpm.colors.green .. zpm.colors.bright .. "Did you mean package '%s'?", suggest[1].str )

        else
        
            zpm.assert( zpm.packages.package[ vendor ] ~= nil, "Requiring package with vendor '%s' does not exist!", vendor )
            zpm.assert( zpm.packages.package[ vendor ][ name ] ~= nil, "Requiring package with vendor '%s' and name '%s' does not exist!", vendor, name )

        end
    end
   
end

function zpm.packages.loadDependency( dependency, module )

    local name = module[2]
    local vendor = module[1]
            
    local dependencyPath = path.join( zpm.cache, "libs" )
    
    if not os.isdir( dependencyPath ) then 
        os.mkdir( dependencyPath )
    end
    
    zpm.packages.suggestPackage( vendor, name ) 
    
    local repository = zpm.packages.package[vendor][name].repository
    
    if zpm.packages.package[vendor][name].isShadow then 
        repository = zpm.packages.package[vendor][name].shadowRepository
    end
    
    local depPath = path.join( dependencyPath, zpm.util.getRepoDir( vendor .. "/" .. name, repository ) )
    
    printf( "Switching to directory '%s'...", depPath )
        
    zpm.git.cloneOrPull( depPath, repository )
    
    local buildPath = depPath
    
    if zpm.packages.package[vendor][name].isShadow then 
        local buildRep = zpm.packages.package[vendor][name].repository
        
        buildPath = path.join( dependencyPath, zpm.util.getRepoDir( vendor .. "/" .. name, buildRep ) )
        
        printf( "Switching to directory '%s'...", buildPath )
            
        zpm.git.cloneOrPull( buildPath, buildRep )
    end
    
    return depPath, buildPath
        
end

function zpm.packages.load()

    --print( "\nLoading packages..." )
    

    local package = path.join( _MAIN_SCRIPT_DIR, zpm.install.packages.fileName )
    
    if os.isfile( package ) then    
        
        local externDir = zpm.install.getExternDirectory()

        if not os.isdir( externDir ) then    
                
            print( "Creating extern directory..." )         
        
            assert( os.mkdir( externDir ) )    
                
            local file = io.open( externDir .. "/.gitignore", "w" )
            file:write([[**]])
            file:close()    
        end
        
    end
    
    local ok, err = pcall( zpm.packages.loadFile, package, true ) 
    
    if not ok then
    
        printf( zpm.colors.error .. "Failed to load package '%s' possibly due to and invalid '_package.json':\n%s", package, err )
    
    end
    
end

function zpm.packages.resolveDependencies( lpackage, vendor, name, isRoot )
    
    if lpackage.assets ~= nil then
        zpm.assets.resolveAssets( lpackage.assets, vendor, name, isRoot  )
    end
    
    if lpackage.requires ~= nil then

        for _, dependency in ipairs( lpackage.requires  ) do
        
            local depMod = bootstrap.getModule( dependency.name )            
            local ok, depPath, buildPath = pcall( zpm.packages.loadDependency, dependency, depMod )
        
            if ok then

                local loaded, version, expDir, err = zpm.packages.loadPackage( depPath, buildPath, dependency, depMod[1], depMod[2] )
                
                if loaded then
                               
    
                    local isShadow = zpm.packages.package[depMod[1]][depMod[2]].isShadow
                
                    local package = {
                        fullName = dependency.name,
                        version = version,
                        dependencyPath = depPath,
                        buildPath = isShadow and buildPath or expDir,
                        exportPath = expDir,
                        module = depMod,
                        isShadow = isShadow,
                        overrides = dependency.overrides
                    }
                    
                    zpm.packages.addDependency( package, isRoot, vendor, name, version )
                    
                else
                    printf( zpm.colors.error .. "Failed to load package '%s' with version '%s':\n%s", dependency.name, version, err )
                end
            else
                printf( zpm.colors.error .. "Failed to load package '%s':\n%s", dependency.name, depPath )
            end
        end
        
    end
   
end

function zpm.packages.addDependency( package, isRoot, depMod, vendor, name, version )

    if isRoot then
    
        table.insert( zpm.packages.root.dependencies, package )
        
    else
    
        table.insert( zpm.packages.package[vendor][name][version].dependencies, package )
    
    end
    
end

function zpm.packages.loadPackage( depPath, buildPath, dependency, vendor, name )

    local externDir = zpm.install.getExternDirectory()
    local depDir = path.join( externDir, dependency.name )
    
    local ok, version, expDir = zpm.packages.extract( externDir, depPath, dependency.version, depDir )
    zpm.assert( ok, zpm.colors.error .. "Package '%s/%s'; cannot satisfy version '%s' for dependency '%s'!", 
                    vendor, name, dependency.version, dependency.name )

    local depPak = path.join( buildPath, zpm.install.packages.fileName )
    local loaded, err = pcall( zpm.packages.loadFile, depPak, false, version, string.format( "%s/%s", vendor, name ) )
    
    return loaded, version, expDir, err
end

function zpm.packages.loadFile( packageFile, isRoot, version, pname )
    
    zpm.assert( os.isfile( packageFile ), "No '_package.json' found" )    
    
    local file = zpm.util.readAll( packageFile )
    local lpackage = zpm.JSON:decode( file )
    
    if pname == nil then
        zpm.assert( lpackage.name ~= nil, "No 'name' supplied in '_package.json'!" )
        pname = lpackage.name
    end
        
    zpm.packages.checkValidity( lpackage, isRoot, pname )
    
    zpm.modules.requestModules( lpackage.modules )
    
    local pak = bootstrap.getModule( pname )
    local name = pak[2]
    local vendor = pak[1]
    
    printf( "Loading package '%s/%s'...", vendor, name )

    zpm.packages.storePackage( isRoot, vendor, name, version, lpackage )    
    
    zpm.packages.resolveDependencies( lpackage, vendor, name, isRoot )
        
end

function zpm.packages.storePackage( isRoot, vendor, name, version, lpackage )

    if isRoot then
                    
        if not zpm.packages.root.isLoaded then
        
            zpm.packages.root = lpackage
            zpm.packages.root.isLoaded = true
            zpm.packages.root.dependencies = {}
            
            if lpackage.dev ~= nil then
                if lpackage.assets == nil then
                    zpm.packages.root.assets = {}
                end
                
                if lpackage.dev.assets ~= nil then
                    zpm.packages.root.assets = zpm.util.concat( zpm.packages.root.assets, lpackage.dev.assets )
                end
            
                if lpackage.requires == nil then
                    zpm.packages.root.requires = {}
                end
                
                if lpackage.dev.requires ~= nil then
                    zpm.packages.root.requires = zpm.util.concat( zpm.packages.root.requires, lpackage.dev.requires )
                end
                
                if lpackage.modules == nil then
                    zpm.packages.root.modules = {}
                end
                
                if lpackage.dev.modules ~= nil then
                    zpm.packages.root.modules = zpm.util.concat( zpm.packages.root.modules, lpackage.dev.modules )
                end
            end
        end
        
    else    
    
        zpm.assert( zpm.packages.package[vendor][name] ~= nil, "Package '%s/%s' does not exist!", vendor, name )
        
        if zpm.packages.package[vendor][name][version] == nil then
        
            zpm.packages.package[vendor][name][version] = lpackage
            zpm.packages.package[vendor][name][version].dependencies = {}
        end
    end
end

function zpm.packages.extract( vendorPath, repo, versions, dest )

    local zipFile = path.join( vendorPath, "archive.zip" )
    local continue = true
    local version = versions
    local folder = string.format( "%s-%s", dest, version )
    local alreadyInstalled = os.isdir( folder )
    
    -- head of the master branch
    if versions == "@head" then
    
        if not alreadyInstalled then
            os.rmdir( folder )
        end
        
        zpm.git.archive( repo, zipFile, "master", dest )
    
    -- git commit hash
    elseif versions:gsub("#", "") ~= versions then
    
        if not alreadyInstalled then
            zpm.git.archive( repo, zipFile, versions:gsub("#", ""), dest )
        end
    
    -- normal resolve
    else
    
        continue, version, folder, alreadyInstalled = zpm.packages.archiveBestVersion( repo, versions, zipFile, dest )
        
    end
    
    if continue and not alreadyInstalled then
        zip.extract( zipFile, folder  )

        os.remove( zipFile )
    end
    
    return continue, version, folder
end

function zpm.packages.archiveBestVersion( repo, versions, zipFile, dest )

    local tags = zpm.git.getTags( repo )
    
    for _, gTag in ipairs( tags ) do
    
        if premake.checkVersion( gTag.version, versions ) then
        
            local folder = string.format( "%s-%s", dest, gTag.version )
            
            local alreadyInstalled = os.isdir( folder )
            if not alreadyInstalled then
                zpm.git.archive( repo, zipFile, gTag.tag )
            end        
            
            return true, gTag.version, folder, alreadyInstalled
        end
    end
    
    return false
end


function zpm.packages.checkValidity( package, isRoot, pname )
        
    local man = bootstrap.getModule( pname )
    local name = man[2]
    local vendor = man[1]
        
    zpm.assert( vendor ~= nil, "No 'vendor' supplied in '_package.json'!" )
    zpm.assert( name ~= nil, "No 'name' supplied in '_package.json'!" )
    
    zpm.assert( zpm.util.isAlphaNumeric( vendor ), "The 'vendor' supplied in '_package.json' must be alpha numeric!" )
    zpm.assert( zpm.util.isAlphaNumeric( name ), "The 'name' supplied in '_package.json' must be alpha numeric!" )
    
    if package.authors ~= nil then
        zpm.assert(  package.description:len() <= 500, "The 'description' supplied in '_package.json'field exceeds maximum size of 500 characters!" )
    end

    if package.license ~= nil then    
        zpm.assert(  package.license:len() <= 30, "The 'license' supplied in '_package.json'field exceeds maximum size of 30 characters!" )        
    end

    if package.website ~= nil then    
        zpm.assert(  package.website:len() <= 120, "The 'website' supplied in '_package.json'field exceeds maximum size of 120 characters!" )        
    end

    if package.authors ~= nil then
    
        for _, author in ipairs( package.authors ) do
            zpm.assert( author.name ~= nil, "No 'name' supplied in '_package.json' author field!" )
            zpm.assert( author.email ~= nil, "No 'email' supplied in '_package.json' author field!" )
            zpm.assert( author.website ~= nil, "No 'website' supplied in '_package.json' author field!" )
        
            zpm.assert( author.email ~= nil and zpm.util.isEmail( author.email ), "The 'email' supplied in '_package.json' author field is not valid!" )
        end
        
    end

    if package.keywords ~= nil then
    
        for _, keyword in ipairs( package.keywords ) do
            zpm.assert( type(keyword) == "string", "The 'keyword' supplied in '_package.json' 'keywords' field is not a string!" )
            zpm.assert( keyword:len() <= 50, "The 'keyword' supplied in '_package.json' 'keywords' field exceeds maximum size of 50 characters" )
        end
        
        zpm.assert( #package.keywords <= 20, "The 'keywords' supplied in '_package.json' 'keywords' field exceeds the maximum amount of 20!" )
        
    end
    
    zpm.packages.checkDependencyValidity( package )
    
    if package.dev ~= nil then
    
        zpm.packages.checkDependencyValidity( package.dev )
        
    end
    
end

function zpm.packages.checkDependencyValidity( package )


    if package.modules ~= nil then
    
        for _, mod in ipairs( package.modules ) do
        
            zpm.assert( type(mod) == "string", "The 'module' supplied in '_package.json' 'modules' field is not a string!" )
            
            local mman = bootstrap.getModule( mod )
            local mname = mman[2]
            local mvendor = mman[1]
            
            zpm.assert( mvendor ~= nil, "No 'vendor' supplied in '_package.json' 'modules' field!" )
            zpm.assert( mname ~= nil, "No 'name' supplied in '_package.json' 'modules' field!" )

            zpm.assert( mvendor:len() <= 50, "'vendor' supplied in '_package.json' 'modules' field exceeds maximum size of 50 characters!" )
            zpm.assert( mname:len() <= 50, "'name' supplied in '_package.json' 'modules' field exceeds maximum size of 50 characters!" )
                                      
            zpm.assert( zpm.util.isAlphaNumeric( mvendor ), "The 'vendor' supplied in '_package.json' 'modules' field must be alpha numeric!" )
            zpm.assert( zpm.util.isAlphaNumeric( mname ), "The 'name' supplied in '_package.json' 'modules' field must be alpha numeric!" )

        end
        
    end

    if package.assets ~= nil then
    
        for _, ass in ipairs( package.assets ) do
        
            zpm.assert( type(ass.name) == "string", "The 'assets' supplied in '_package.json' 'assets' field is not a string!" )
            
            local mman = bootstrap.getModule( ass.name )
            local mname = mman[2]
            local mvendor = mman[1]
            
            zpm.assert( mvendor ~= nil, "No 'vendor' supplied in '_package.json' 'assets' field!" )
            zpm.assert( mname ~= nil, "No 'name' supplied in '_package.json' 'assets' field!" )

            zpm.assert( mvendor:len() <= 50, "'vendor' supplied in '_package.json' 'assets' field exceeds maximum size of 50 characters!" )
            zpm.assert( mname:len() <= 50, "'name' supplied in '_package.json' 'assets' field exceeds maximum size of 50 characters!" )
                                      
            zpm.assert( zpm.util.isAlphaNumeric( mvendor ), "The 'vendor' supplied in '_package.json' 'assets' field must be alpha numeric!" )
            zpm.assert( zpm.util.isAlphaNumeric( mname ), "The 'name' supplied in '_package.json' 'assets' field must be alpha numeric!" )

        end
        
    end

    if package.requires ~= nil then
    
        for _, require in ipairs( package.requires ) do
            
            local rman = bootstrap.getModule( require.name )
            local rname = rman[2]
            local rvendor = rman[1]
            
            zpm.assert( rvendor ~= nil, "No 'vendor' supplied in '_package.json' 'require' field!" )
            zpm.assert( rname ~= nil, "No 'name' supplied in '_package.json' 'require' field!" )
            
            zpm.assert( rvendor:len() <= 50, "'vendor' supplied in '_package.json' 'require' field exceeds maximum size of 50 characters!" )
            zpm.assert( rname:len() <= 50, "'name' supplied in '_package.json' 'require' field exceeds maximum size of 50 characters!" )
                                      
            zpm.assert( zpm.util.isAlphaNumeric( rvendor ), "The 'vendor' supplied in '_package.json' 'require' field must be alpha numeric!" )
            zpm.assert( zpm.util.isAlphaNumeric( rname ), "The 'name' supplied in '_package.json' 'require' field must be alpha numeric!" )

            --assert( require.version ~= nil and isEmail( author.email ), "TheNo 'email' supplied in '_package.json' author field is not valid!" )
        end
        
    end

end