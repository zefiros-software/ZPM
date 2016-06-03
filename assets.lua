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

zpm.assets = {}
zpm.assets.assets = {}

zpm.assets.search = zpm.bktree:new()
zpm.assets.searchMaxDist = 0.6


function zpm.assets.load()

    --print( "\nLoading assets..." )
    local assetsDir = zpm.install.getAssetsDir()

    if not os.isdir( assetsDir ) then    
            
        print( "Creating assets directory..." )         
    
        assert( os.mkdir( assetsDir ) )    
            
        local file = io.open( assetsDir .. "/.gitignore", "w" )
        file:write([[**]])
        file:close()    
    end
    
    for _, dir in ipairs( table.insertflat( { _MAIN_SCRIPT_DIR }, zpm.registry.dirs ) ) do
        local localAssetsFile = path.join( dir, zpm.install.assets.fileName ) 
    
        if os.isfile( localAssetsFile ) then    
            local manok, err = pcall( zpm.assets.loadFile, localAssetsFile ) 
            if not manok then
                printf( zpm.colors.error .. "Failed to load assets '%s':\n%s", dir, err ) 
            end
        end
    end
    
end


function zpm.assets.loadFile( file )

    if not os.isfile( file ) then
        return nil
    end
    
    --print( string.format( "Loading assets '%s'...", file ) )
     
    local assets = zpm.JSON:decode( zpm.util.readAll( file ) )
    
    for _, asset in ipairs( assets ) do
    
        local man = bootstrap.getModule( asset.name )
        local name = man[2]
        local vendor = man[1]
        local isShadow = false

        zpm.assert( name ~= nil, "No 'name' supplied in asset definition!" )
        zpm.assert( vendor ~= nil, "No 'vendor' supplied in asset definition!" )
        zpm.assert( asset.repository ~= nil, "No 'repository' supplied in asset definition!" )
        
        zpm.assert( zpm.util.isAlphaNumeric( name ), "'name' supplied in asset defintion must be alpha numeric!" )
        zpm.assert( name:len() <= 50, "'name' supplied in asset defintion exceeds maximum size of 50 characters!" )
        
        zpm.assert( zpm.util.isAlphaNumeric( vendor ), "'vendor' supplied in asset defintion must be alpha numeric!" )
        zpm.assert( vendor:len() <= 50, "'vendor' supplied in asset defintion exceeds maximum size of 50 characters!" )
        
        zpm.assert( zpm.util.isGitUrl( asset.repository ), "'repository' supplied in asset defintion is not a valid https git url!" )
                
        if asset.shadowRepository ~= nil then
            zpm.assert( zpm.util.isGitUrl( asset.shadowRepository ), "'shadow-repository' supplied in manifest defintion is not a valid https git url!" )
            isShadow = true
        end
        
        if zpm.assets.assets[ vendor ] == nil then
            zpm.assets.assets[ vendor ] = {}
        end
        
        if zpm.assets.assets[ vendor ][ name ] == nil then
        
            zpm.assets.search:insert( string.format( "%s/%s", vendor, name ) )
        
            zpm.assets.assets[ vendor ][ name ] = {}        
            zpm.assets.assets[ vendor ][ name ].repository = asset.repository    
            zpm.assets.assets[ vendor ][ name ].shadowRepository = asset.shadowRepository       
            zpm.assets.assets[ vendor ][ name ].isShadow = isShadow            
            
            
        end
    
    end    
    
end

function zpm.assets.suggestAssets( vendor, name ) 

    if zpm.assets.assets[ vendor ] == nil or zpm.assets.assets[ vendor ][ name ] == nil then
    
        local str = string.format( "%s/%s", vendor, name )
        local suggest = zpm.assets.search:query( str, #str * ( 1 - zpm.assets.searchMaxDist ) )
    
        if #suggest > 0 then
            
            printf( zpm.colors.error .. "Requiring assets with vendor '%s' and name '%s' does not exist!", vendor, name )
            
            printf( zpm.colors.green .. zpm.colors.bright .. "Did you mean assets '%s'?", suggest[1].str )

        else
        
            zpm.assert( zpm.assets.assets[ vendor ] ~= nil, "Requiring assets with vendor '%s' does not exist!", vendor )
            zpm.assert( zpm.assets.assets[ vendor ][ name ] ~= nil, "Requiring assets with vendor '%s' and name '%s' does not exist!", vendor, name )

        end
    end
   
end

function zpm.assets.resolveAssets( assets, vendor, name )
    
    for _, asset in ipairs( assets ) do
        
        local assetM = bootstrap.getModule( asset.name )
        local avendor = assetM[1]
        local aname = assetM[2]
    
        local lassets = zpm.assets.assets[avendor][aname]
        local assPath, defPath = zpm.assets.loadAssets( asset, lassets, vendor, name, avendor, aname )
        
        local assetPackDir = path.join( zpm.install.getAssetsDir(), vendor, name, avendor, aname )

        if os.isdir( assetPackDir ) then 
            os.rmdir( assetPackDir )
        end
        os.mkdir( assetPackDir )
        
        lassets = zpm.assets.loadAssetsFile( path.join( defPath, zpm.install.assets.fileName ), avendor, aname )

        zpm.assets.extract( assPath, asset.version, assetPackDir, avendor, aname )
    
    
    end    

end

function zpm.assets.assetCacheDir( vendor, name, repository ) 
            
    local assetsPath = path.join( zpm.cache, "assets" )

    return path.join( assetsPath, zpm.util.getRepoDir( vendor .. "/" .. name, repository ) )
    
end

function zpm.assets.loadAssetsFile( assetsFile, vendor, name ) 
     
    zpm.assert( os.isfile( assetsFile ), "No '_assets.json' found" )  
    
    local file = zpm.util.readAll( assetsFile )
    local lasset = zpm.JSON:decode( file )

    zpm.assets.checkValidity( lasset )
    zpm.assets.storeAssets( lasset, vendor, name  )
    
    return lasset
end

function zpm.assets.storeAssets( lassets, vendor, name )

    zpm.assert( zpm.assets.assets[vendor][name] ~= nil, "Assets '%s/%s' does not exist!", vendor, name )
    zpm.assets.assets[vendor][name] = lassets
    
    return lassets
end

function zpm.assets.checkValidity( assetsFile )

end

function zpm.assets.loadAssets( asset, lasset, vendor, name, avendor, aname )
            
    local assetsPath = path.join( zpm.cache, "assets" )
    
    if not os.isdir( assetsPath ) then 
        os.mkdir( assetsPath )
    end
    
    zpm.assets.suggestAssets( avendor, aname )
    
    local repository = lasset.repository
    
    if lasset.isShadow then 
        repository = lasset.shadowRepository
    end
    
    local assPath = zpm.assets.assetCacheDir( avendor, aname, repository )
    
    printf( "Switching to directory '%s'...", assPath )
        
    zpm.git.lfs.cloneOrPull( assPath, repository )
    
    local defPath = assPath
    if lasset.isShadow then 
        local defRep = lasset.repository
        
        defPath = path.join( dependencyPath, zpm.util.getRepoDir( avendor .. "/" .. aname, defRep ) )
        
        printf( "Switching to directory '%s'...", defPath )
            
        zpm.git.cloneOrPull( defPath, defRep )
    end
    
    return assPath, defPath
end

function zpm.assets.extract( repo, versions, folder, vendor, name )

    local continue = true
    local version = versions
    local alreadyInstalled = os.isdir( folder )
    
    if alreadyInstalled then
        os.rmdir( folder )
        os.mkdir( folder )
    end
    
    -- head of the master branch
    if versions == "@head" then
    
        version = "master"
    
    -- git commit hash
    elseif versions:gsub("#", "") ~= versions then
    
        version =  versions:gsub("#", "")
    
    -- normal resolve
    else
    
        continue, version = zpm.assets.getBestVersion( repo, versions, dest )
        
    end
   
    if continue then
           
        zpm.git.lfs.checkout( repo, version )
        
        local filePatterns = zpm.assets.assets[ vendor ][ name ].files
        
        if filePatterns ~= nil then
            for _, pattern in ipairs( filePatterns ) do
                for _, file in ipairs( os.matchfiles( path.join( repo, pattern ) ) ) do
                    local target = path.join( folder, path.getrelative( repo, file) )
                    local targetDir = path.getdirectory( target )
                    if not os.isdir( targetDir ) then
                        zpm.assert( os.mkdir( targetDir ), "Could not create asset directory '%s'!", targetDir )
                    end
                    
                    os.copyfile( file, target )
                end 
            end 
        end
      
        local urls = zpm.assets.assets[ vendor ][ name ].urls
        
        if urls ~= nil then
            for _, url in ipairs( urls ) do
                local targetDir = path.join( folder, url.to )
                if not os.isdir( targetDir ) then
                    zpm.assert( os.mkdir( targetDir ), "Could not create asset directory '%s'!", targetDir )
                end
                
                local zipFile = path.join( zpm.temp, "assets.zip" )
                zpm.wget.download( zipFile, url.url )
                zip.extract( zipFile, targetDir )
                os.remove( zipFile )
                    
            end 
        end
    end
    
    return continue, version, folder
end

function zpm.assets.getBestVersion( repo, versions )

    local tags = zpm.git.getTags( repo )
    
    for _, gTag in ipairs( tags ) do
    
        if premake.checkVersion( gTag.version, versions ) then
        
            return true, gTag.version
        end
    end
    
    return false
end