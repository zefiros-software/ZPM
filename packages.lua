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
--zpm.packages.search = zpm.bktree:new()
--zpm.packages.searchMaxDist = 0.1

zpm.packages.package = {}

zpm.packages.root = {}

function zpm.packages.prepareDict( vendor, name, repository, shadowRepository, isShadow )
        
    if zpm.packages.package[ vendor ] == nil then
        zpm.packages.package[ vendor ] = {}
    end
    
    if zpm.packages.package[ vendor ][ name ] == nil then
        
        zpm.packages.package[ vendor ][ name ] = {}            
        zpm.packages.package[ vendor ][ name ].repository = repository    
        zpm.packages.package[ vendor ][ name ].shadowRepository = shadowRepository       
        zpm.packages.package[ vendor ][ name ].isShadow = isShadow            
        
        --disable for now
        --zpm.packages.search:insert( string.format( "%s/%s", vendor, name ) )
    end

end

function zpm.packages.suggestPackage( vendor, name ) 

    if zpm.packages.package[ vendor ] == nil or (zpm.packages.package[ vendor ] ~= nil and zpm.packages.package[ vendor ][ name ] == nil) then
    
        --local str = string.format( "%s/%s", vendor, name )
        --local suggest = zpm.packages.search:query( str, #str * ( 1 - zpm.packages.searchMaxDist ) )
    
        --if #suggest > 0 then
            
        --    printf( zpm.colors.error .. "Requiring package with vendor '%s' and name '%s' does not exist!", vendor, name )
            
        --    printf( zpm.colors.green .. zpm.colors.bright .. "Did you mean package '%s'?", suggest[1].str )

        --else
        
            zpm.assert( zpm.packages.package[ vendor ] ~= nil, "Requiring package with vendor '%s' does not exist!", vendor )
            zpm.assert( zpm.packages.package[ vendor ][ name ] ~= nil, "Requiring package with vendor '%s' and name '%s' does not exist!", vendor, name )

        --end
    end
   
end

zpm.packages._pullCache = {}
function zpm.packages.pullDependency( depPath, repository, vendor, name )

    if zpm.packages._pullCache[repository] ~= nil then
        return zpm.packages._pullCache[repository]
    end
    
    if vendor ~= nil and name ~= nil then
        printf( "\n- Pulling '%s/%s'", vendor, name )        
        verbosef( "   Switching to directory '%s'...", depPath )
    end

    local updated = zpm.git.cloneOrPull( depPath, repository )

    zpm.packages._pullCache[repository] = updated

    return updated
end

function zpm.packages.loadDependency( dependency, module, basedir )

    local p = path.getabsolute(path.join(basedir, dependency.path))
    
    if dependency.path ~= nil and os.isdir(p) then
        return path.getabsolute(p), path.getabsolute(p), true
    end

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
        
    local updated = zpm.packages.pullDependency( depPath, repository, vendor, name )
    
    local buildPath = depPath
    
    if zpm.packages.package[vendor][name].isShadow then 
        local buildRep = zpm.packages.package[vendor][name].repository
        
        buildPath = path.join( dependencyPath, zpm.util.getRepoDir( vendor .. "/" .. name, buildRep ) )
        
        --printf( "Switching to directory '%s'...", buildPath )
            
        updated = zpm.packages.pullDependency( buildPath, buildRep ) or updated
    end
    
    return depPath, buildPath, updated
        
end

function zpm.packages.load()

    --print( "\nLoading packages..." )
    

    local package = path.join( _MAIN_SCRIPT_DIR, zpm.install.packages.fileName )
    
    if os.isfile( package ) then    
        
        local externDir = zpm.install.getExternDirectory()

        if not os.isdir( externDir ) then    
                
            verbosef( "Creating extern directory..." )         
        
            assert( os.mkdir( externDir ) )    
                
            local file = io.open( externDir .. "/.gitignore", "w" )
            file:write([[*]])
            file:close()    
        end
        
        local ok, root = pcall( zpm.packages.loadFile, package, true, "LOCAL", nil, zpm.packages.root, false ) 
        
        if ok then
            zpm.packages.root = root
            if not _OPTIONS["ignore-updates"] then
                zpm.packages.postExtract( zpm.packages.root, true )
            end
        else
            printf( zpm.colors.error .. "Failed to load package '%s' possibly due to an invalid '.package.json':\n%s", package, root )
        
        end
        
    end
end

function zpm.packages.install()

    zpm.packages.installPackage( zpm.packages.root, ".", zpm.packages.root.name )
end

function zpm.packages.installPackage( package, folder, name )

    if type( package.install ) ~= "table" then
        package.install = { package.install }
    end

    if package.dependencies ~= nil and #package.dependencies > 0 then

        for i, dep in ipairs( package.dependencies ) do

            zpm.packages.installPackage( dep, dep.exportPath, dep.fullName )
        end

    end    

    if package.alreadyInstalled == false then

        if package.modules ~= nil and #package.modules > 0 then

            zpm.modules.installOrUpdateModules( package.modules )

        end

        -- make sure modules exist
        if #package.install > 0 then
            zpm.util.askInstallConfirmation( string.format( "Package '%s' asks to run an install script, do you want to accept this?\n(Please note that this may be a security risk!)", name ),
            function()
                
                for _, inst in ipairs( package.install ) do
                        printf( "\n- Installing '%s'", name )
                        dofile( string.format( "%s/%s", folder, inst ) )
                end
            end, 
            function()
                printf( "Installation declined, we can not guarantee this package works!" )
            end )
        end
    
    end
end

function zpm.packages.postExtract( package, isRoot )

    if type( package.postextract ) ~= "table" then
        package.postextract = { package.postextract }
    end

    if package.dependencies ~= nil and #package.dependencies > 0 then

        for i, dep in ipairs( package.dependencies ) do

            zpm.packages.postExtract( dep, false )
        end

    end

    if isRoot == false and package.alreadyInstalled == false and #package.postextract > 0 then         
        zpm.git.checkoutVersion( package.buildPath, package.version ) 
        
        zpm.util.askInstallConfirmation( string.format( "Package '%s' asks to run an extract script, do you want to accept this?\n(Please note that this may be a security risk!)", package.name ),
        function()    
            printf( "\n- Extracting '%s'", package.name )

            for _, inst in ipairs( package.postextract ) do
                zpm.build.setCursor( package )
            
                dofile( string.format( "%s/%s", package.buildPath, inst ) )       

                zpm.build.resetCursor()
            end
        end, 
        function()
            printf( "Installation declined, we can not guarantee this package works!" )
        end )
    end
end

function zpm.packages.resolveDependencies( lpackage, vendor, name, basedir )

    if lpackage == nil then
        return lpackage
    end
    
    if  lpackage.assets ~= nil then
        zpm.assets.resolveAssets( lpackage.assets, vendor, name )
    end
    
    if lpackage.requires ~= nil then

        for i, dependency in ipairs( lpackage.requires  ) do
        
            local depMod = bootstrap.getModule( dependency.name )
            local ok, depPath, buildPath, updated = pcall( zpm.packages.loadDependency, dependency, depMod, basedir )

            if ok then

                local loaded, version, expDir, dependencies = zpm.packages.loadPackage( depPath, buildPath, dependency, depMod[1], depMod[2], lpackage.dependencies )
                

                if loaded then                               
    
                    local isShadow = zpm.packages.package[depMod[1]][depMod[2]].isShadow
                    dependencies = table.merge( dependencies, {
                        fullName = dependency.name,
                        version = version,
                        dependencyPath = depPath,
                        buildPath = isShadow and buildPath or expDir,
                        exportPath = expDir,
                        module = depMod,
                        isShadow = isShadow,
                        overrides = dependency.overrides,
                        options = dependency.options,
                        updated = updated
                    })
                    lpackage.dependencies[i] = dependencies
                    
                else
                    printf( zpm.colors.error .. "Failed to load package '%s' with version '%s':\n%s", dependency.name, version, dependencies )
                end
            else
                printf( zpm.colors.error .. "Failed to load package '%s':\n%s", dependency.name, depPath )
            end
        end
        
    end
   
    return lpackage
end

function zpm.packages.loadPackage( depPath, buildPath, dependency, vendor, name, root )

    local ok, expDir, version, alreadyInstalled
    if dependency.path == nil then
        local externDir = zpm.install.getExternDirectory()
        local depDir = path.join( externDir, dependency.name )
        ok, version, expDir, alreadyInstalled = zpm.packages.extract( externDir, depPath, dependency.version, depDir )

        zpm.assert( ok, zpm.colors.error .. "Package '%s/%s'; cannot satisfy version '%s' for dependency '%s'!", 
                        vendor, name, dependency.version, dependency.name )
    else
        version = "LOCAL"
        expDir = buildPath
        alreadyInstalled = false

        -- make sure it exists in dictionary
        zpm.packages.prepareDict( vendor, name, dependency.repository, dependency.shadowRepository, dependency.isShadow )
    end

    local depPak = path.join( buildPath, zpm.install.packages.fileName )
    local loaded, pack = pcall( zpm.packages.loadFile, depPak, false, version, string.format( "%s/%s", vendor, name ), root, alreadyInstalled )

    root = pack
    
    return loaded, version, expDir, root
end

function zpm.packages.loadFile( packageFile, isRoot, version, pname, root, alreadyInstalled )
    
    zpm.assert( os.isfile( packageFile ), "No '.package.json' found on path '%s'", packageFile )    
    
    local file = zpm.util.readAll( packageFile )
    local lpackage = zpm.JSON:decode( file )
    
    if pname == nil then
        if lpackage.name == nil and root then
            lpackage.name = "root/root"
        end
        zpm.assert( lpackage.name ~= nil, "No 'name' supplied in '.package.json'!" )
        pname = lpackage.name
    end
        
    zpm.packages.checkValidity( lpackage, isRoot, pname )
    
    --zpm.modules.requestModules( lpackage.modules )
    
    local pak = bootstrap.getModule( pname )
    local name = pak[2]
    local vendor = pak[1]
    
    --printf( "Loading package '%s/%s'...", vendor, name )

    local mods = lpackage.modules ~= nil and lpackage.modules or {}

    if lpackage.dev ~= nil and lpackage.dev.modules ~= nil then
        mods = zpm.util.concat( mods, lpackage.dev.modules )
    end

    zpm.packages.loadModules( mods )

    lpackage = zpm.packages.preProcess(lpackage)
    root = zpm.packages.storePackage( isRoot, vendor, name, version, lpackage, alreadyInstalled )
    root = zpm.packages.postProcess(root)

    root = zpm.packages.resolveDependencies( root, vendor, name, path.getdirectory( packageFile ) )
    --printf( "Resolved package dependencies '%s/%s'...", vendor, name )

    return root
end

function zpm.packages.preProcess( lpackage )
    return lpackage
end

function zpm.packages.postProcess( lpackage )
    return lpackage
end

function zpm.packages.extendDev( dev )
    return dev
end

function zpm.packages.loadModules( modules )
    if modules == nil then
        return nil
    end

    for _, m in ipairs(modules) do
        if type(m) == "table" then
            for n, v in pairs(m) do
                require( n, v )
            end
        end
    end
end

function zpm.packages.storePackage( isRoot, vendor, name, version, lpackage, alreadyInstalled )

    if isRoot then            
        if lpackage.dev ~= nil then
            local move = zpm.packages.extendDev( {"assets", "settings", "options", "requires", "modules", "install",} )
            for _, m in ipairs(move) do

                if lpackage.dev[m] ~= nil then

                    if lpackage[m] == nil then
                        lpackage[m] = {}
                    end

                    lpackage[m] = zpm.util.concat( lpackage[m], lpackage.dev[m] )
                end

            end
        end
        
    else    
    
        zpm.assert( (zpm.packages.package[vendor] ~= nil and zpm.packages.package[vendor][name] ~= nil) or isRoot or version == "LOCAL", "Package '%s/%s' does not exist!", vendor, name )
        
    end   

    lpackage.dependencies = {}
    lpackage.alreadyInstalled = alreadyInstalled
    
    zpm.config.addSettings( lpackage.settings )

    return lpackage
end


zpm.packages._extractCache = {}
function zpm.packages.extract( vendorPath, repo, versions, dest )

    local zipFile = path.join( vendorPath, "archive.zip" )
    local continue = true
    local version = versions
    local folder = string.format( "%s-%s", dest, version )
    local alreadyInstalled = os.isdir( folder )

    if os.isfile( zipFile ) then
        os.remove( zipFile )
    end
    
    -- head of the master branch
    if versions == "@head" then

        local hashFile = path.join( folder, ".HASH-HEAD" )
    
        if not _OPTIONS["ignore-updates"] and not 
            (os.isfile(hashFile) and zpm.git.getHeadHash(repo) == zpm.util.readAll(hashFile)) and 
            (zpm.packages._extractCache[repo] == nil or (zpm.packages._extractCache[repo] ~= nil and zpm.packages._extractCache[repo][versions] == nil)) then
    
            zpm.packages._extractCache[repo] = {}
            zpm.packages._extractCache[repo][versions] = {}
            
            if alreadyInstalled then
            
                --print( "Removing existing head..." )
                zpm.util.rmdir( folder )

                -- continue installation
                alreadyInstalled = false

                zpm.assert( os.isdir( folder ) == false, "Failed to remove existing head!" )
            
            end
        
            --zpm.git.checkout( repo, "master" )
            zpm.git.archive( repo, zipFile, "master" )
    
            file = io.open(hashFile, "w")
            file:write( zpm.git.getHeadHash(repo) )
        end
    
    -- git commit hash
    elseif versions:gsub("#", "") ~= versions then
            
        if not alreadyInstalled and 
            (zpm.packages._extractCache[repo] == nil or (zpm.packages._extractCache[repo] ~= nil and zpm.packages._extractCache[repo][versions] == nil)) then

            zpm.packages._extractCache[repo] = {}
            zpm.packages._extractCache[repo][versions] = {}
            
            --zpm.git.checkout( repo, versions:gsub("#", "") )
            zpm.git.archive( repo, zipFile, versions:gsub("#", "") )
        end
    
    -- normal resolve
    else
    
        continue, version, folder, alreadyInstalled = zpm.packages.getBestVersion( repo, versions, zipFile, dest )

        if not alreadyInstalled and 
            (zpm.packages._extractCache[repo] == nil or (zpm.packages._extractCache[repo] ~= nil and zpm.packages._extractCache[repo][version] == nil)) then

            zpm.packages._extractCache[repo] = {}
            zpm.packages._extractCache[repo][version] = {}
            
            --zpm.git.checkout( repo, "tags/" .. version )
            zpm.git.archive( repo, zipFile, version )
        end      
        
    end
    
    if continue and not alreadyInstalled then

        zpm.assert( os.isfile( zipFile ), "Repository '%s' failed to archive!", repo )

        assert( os.mkdir( folder ) )

        zip.extract( zipFile, folder )

        os.remove( zipFile )
        zpm.assert( os.isfile( zipFile ) == false, "Zipfile '%s' failed to remove!", zipFile )
        zpm.assert( os.isdir( folder ), "Folder '%s' failed to install!", folder )
    end
    
    return continue, version, folder, alreadyInstalled
end

function zpm.packages.getBestVersion( repo, versions, zipFile, dest )

    local tags = zpm.git.getTags( repo )
    for _, gTag in ipairs( tags ) do
    
        if premake.checkVersion( gTag.version, versions ) then
        
            local folder = string.format( "%s-%s", dest, gTag.version )
            
            local alreadyInstalled = os.isdir( folder )  
            
            return true, gTag.version, folder, alreadyInstalled
        end
    end

    zpm.assert( false, "Versions '%s' could not by satisfied on repo '%s'!", versions, repo )
    
    return false
end


function zpm.packages.checkValidity( package, isRoot, pname )
        
    local man = bootstrap.getModule( pname )
    local name = man[2]
    local vendor = man[1]
        
    zpm.assert( vendor ~= nil, "No 'vendor' supplied in '.package.json'!" )
    zpm.assert( name ~= nil, "No 'name' supplied in '.package.json'!" )
    
    zpm.assert( zpm.util.isAlphaNumeric( vendor ), "The 'vendor' supplied in '.package.json' must be alpha numeric!" )
    zpm.assert( zpm.util.isAlphaNumeric( name ), "The 'name' supplied in '.package.json' must be alpha numeric!" )
    
    if package.authors ~= nil then
        zpm.assert(  package.description:len() <= 500, "The 'description' supplied in '.package.json'field exceeds maximum size of 500 characters!" )
    end

    if package.license ~= nil then    
        zpm.assert(  package.license:len() <= 60, "The 'license' supplied in '.package.json' field exceeds maximum size of 60 characters!" )        
    end

    if package.website ~= nil then    
        zpm.assert(  package.website:len() <= 120, "The 'website' supplied in '.package.json' field exceeds maximum size of 120 characters!" )        
    end

    if package.authors ~= nil then
    
        for _, author in ipairs( package.authors ) do
            zpm.assert( author.name ~= nil, "No 'name' supplied in '.package.json' author field!" )
            zpm.assert( author.email ~= nil, "No 'email' supplied in '.package.json' author field!" )
            zpm.assert( author.website ~= nil, "No 'website' supplied in '.package.json' author field!" )
        
            zpm.assert( author.email ~= nil and zpm.util.isEmail( author.email ), "The 'email' supplied in '.package.json' author field is not valid!" )
        end
        
    end

    if package.keywords ~= nil then
    
        for _, keyword in ipairs( package.keywords ) do
            zpm.assert( type(keyword) == "string", "The 'keyword' supplied in '.package.json' 'keywords' field is not a string!" )
            zpm.assert( keyword:len() <= 50, "The 'keyword' supplied in '.package.json' 'keywords' field exceeds maximum size of 50 characters" )
        end
        
        zpm.assert( #package.keywords <= 20, "The 'keywords' supplied in '.package.json' 'keywords' field exceeds the maximum amount of 20!" )
        
    end
    
    zpm.packages.checkDependencyValidity( package, isRoot )
    
    if package.dev ~= nil then
    
        zpm.packages.checkDependencyValidity( package.dev, isRoot )
        
    end
    
end

function zpm.packages.checkDependencyValidity( package, isRoot )

    if package.install ~= nil then
        
        zpm.assert( type(package.install) == "string", "The 'install' supplied in '.package.json' is not a string!" )
    end

    if package.options ~= nil then
    
        for name, value in pairs( package.options ) do
        
            zpm.assert( zpm.util.isAlphaNumeric( name ), "The 'name' supplied in '.package.json' 'options' field must be alpha numeric!" )
            --zpm.assert( type(value) == "boolean", "The 'options' value supplied in '.package.json' is not a boolean!" )
        end
    end

    if package.settings ~= nil then
    
        for name, value in pairs( package.settings ) do
        
            zpm.assert( zpm.util.isAlphaNumeric( name ), "The 'name' supplied in '.package.json' 'settings' field must be alpha numeric!" )
            --zpm.assert( type(value) == "boolean", "The 'options' value supplied in '.package.json' is not a boolean!" )
        end
    end

    if package.settings ~= nil then
    
        for name, value in pairs( package.settings ) do        
            zpm.assert( zpm.util.isAlphaNumeric( name ), "The 'name' supplied in '.package.json' 'settings' field must be alpha numeric!" )
        end
    end

    if package.modules ~= nil then
    
        for _, mod in ipairs( package.modules ) do
        
            if type(mod) ~= "table" then
                zpm.assert( type(mod) == "string", "The 'module' supplied in '.package.json' 'modules' field is not a string!" )
                
                local mman = bootstrap.getModule( mod )
                local mname = mman[2]
                local mvendor = mman[1]
                
                zpm.assert( mvendor ~= nil, "No 'vendor' supplied in '.package.json' 'modules' field!" )
                zpm.assert( mname ~= nil, "No 'name' supplied in '.package.json' 'modules' field!" )

                zpm.assert( mvendor:len() <= 50, "'vendor' supplied in '.package.json' 'modules' field exceeds maximum size of 50 characters!" )
                zpm.assert( mname:len() <= 50, "'name' supplied in '.package.json' 'modules' field exceeds maximum size of 50 characters!" )
                    
                zpm.assert( mvendor:len() >= 2, "'vendor' supplied in '.package.json' 'modules' field must at least be 2 characters!" )
                zpm.assert( mname:len() >= 2, "'name' supplied in '.package.json' 'modules' field must at least be 2 characters!" )
                                        
                zpm.assert( zpm.util.isAlphaNumeric( mvendor ), "The 'vendor' supplied in '.package.json' 'modules' field must be alpha numeric!" )
                zpm.assert( zpm.util.isAlphaNumeric( mname ), "The 'name' supplied in '.package.json' 'modules' field must be alpha numeric!" )
            end
        end
        
    end

    if package.assets ~= nil then
    
        for _, ass in ipairs( package.assets ) do
        
            zpm.assert( type(ass.name) == "string", "The 'assets' supplied in '.package.json' 'assets' field is not a string!" )
            
            local mman = bootstrap.getModule( ass.name )
            local mname = mman[2]
            local mvendor = mman[1]
            
            zpm.assert( mvendor ~= nil, "No 'vendor' supplied in '.package.json' 'assets' field!" )
            zpm.assert( mname ~= nil, "No 'name' supplied in '.package.json' 'assets' field!" )

            zpm.assert( mvendor:len() <= 50, "'vendor' supplied in '.package.json' 'assets' field exceeds maximum size of 50 characters!" )
            zpm.assert( mname:len() <= 50, "'name' supplied in '.package.json' 'assets' field exceeds maximum size of 50 characters!" )
                
            zpm.assert( mvendor:len() >= 2, "'vendor' supplied in '.package.json' 'assets' field must at least be 2 characters!" )
            zpm.assert( mname:len() >= 2, "'name' supplied in '.package.json' 'assets' field must at least be 2 characters!" )
                                      
            zpm.assert( zpm.util.isAlphaNumeric( mvendor ), "The 'vendor' supplied in '.package.json' 'assets' field must be alpha numeric!" )
            zpm.assert( zpm.util.isAlphaNumeric( mname ), "The 'name' supplied in '.package.json' 'assets' field must be alpha numeric!" )

        end
        
    end

    if package.requires ~= nil then
    
        for _, require in ipairs( package.requires ) do
            
            local rman = bootstrap.getModule( require.name )
            local rname = rman[2]
            local rvendor = rman[1]
            
            zpm.assert( rvendor ~= nil, "No 'vendor' supplied in '.package.json' 'require' field!" )
            zpm.assert( rname ~= nil, "No 'name' supplied in '.package.json' 'require' field!" )
            
            zpm.assert( rvendor:len() <= 50, "'vendor' supplied in '.package.json' 'require' field exceeds maximum size of 50 characters!" )
            zpm.assert( rname:len() <= 50, "'name' supplied in '.package.json' 'require' field exceeds maximum size of 50 characters!" )
                
            zpm.assert( rvendor:len() >= 2, "'vendor' supplied in '.package.json' 'require' field must at least be 2 characters!" )
            zpm.assert( rvendor:len() >= 2, "'name' supplied in '.package.json' 'require' field must at least be 2 characters!" )

            zpm.assert( zpm.util.isAlphaNumeric( rvendor ), "The 'vendor' supplied in '.package.json' 'require' field must be alpha numeric!" )
            zpm.assert( zpm.util.isAlphaNumeric( rname ), "The 'name' supplied in '.package.json' 'require' field must be alpha numeric!" )

            assert( require.version ~= nil or require.path ~= nil, "No 'version' or 'path' supplied in '.package.json'!" )
        end
        
    end

end