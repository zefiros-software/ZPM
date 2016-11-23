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


-- Git
zpm.git = {}

zpm.git.lfs = {}

function zpm.git.share( destination )
    
    local current = os.getcwd()
    
    os.chdir( destination )

    --os.execute( "git config core.sharedRepository 0777" ) 
    
    os.chdir( current )
end

function zpm.git.getHeadHash( destination )
    
    local current = os.getcwd()
    
    os.chdir( destination )

    local out = os.outputof( "git rev-parse HEAD" )
    
    os.chdir( current )

    return out
end

function zpm.git.checkout( destination, version )
    
    local current = os.getcwd()
    
    os.chdir( destination )

    local status, errorCode = os.outputof( "git status" )
    
    if status:contains(version) == false then
        printf( "Checkingout version %s", version )
        os.execute( "git checkout -q -f -B " .. version ) 
    end

    os.chdir( current )

end

function zpm.git.checkoutVersion( destination, version )
    
    if version == "@head" then
        zpm.git.checkout( destination, "master" )
    elseif version:gsub("#", "") ~= version then 
        zpm.git.checkout( destination, version:gsub("#", "") )
    else
        zpm.git.checkout( destination, "tags/" .. version )
    end
end

function zpm.git.pull( destination, url )

    --[[if url:contains( "https://github.com" ) then
        local vendor, name = url:match( "https://github.com/(.*)/(.*).git" )
        local ok, resp = pcall( zpm.GitHub.latestCommit, "https://api.github.com/repos/%s/%s/git/refs/heads/master", vendor, name )
        if ok and resp.object ~= nil then

            if zpm.git.getHeadHash(destination) == resp.object.sha then
                return false
            end

        end
    end]]
    
    local current = os.getcwd()
    
    os.chdir( destination )

    if url ~= nil then        
        os.execute( "git remote set-url origin " .. url  )
    end
    
    os.execute( "git fetch origin --tags -q -j 8" )

    if os.outputof( "git log HEAD..origin/master --oneline" ):len() > 0 then    

        os.execute( "git checkout -q ." )
        os.execute( "git reset --hard origin/HEAD" )
        os.execute( "git submodule update --init --recursive -j 8" )
        os.execute( "git gc --auto" )
    
        os.chdir( current )

        return true
    end
    
    os.chdir( current )
    
    return false
end

function zpm.git.clone( destination, url )
    
    os.execute( string.format( "git clone -b master -v --recurse -j8 --progress \"%s\" \"%s\"", url, destination ) )
    zpm.git.share( destination )
    
end

function zpm.git.getTags( destination )
    
    local current = os.getcwd()
    
    os.chdir( destination )
    
    local tagStr, errorCode = os.outputof( "git tag" )
    local tags = {}
    
    for _, s in ipairs( tagStr:explode( "\n" ) ) do
    
        if s:len() > 0 then
        
            local version = s:match( "[.-]*([%d+%.]+.*)" )
            if pcall( zpm.semver, version ) then
                table.insert( tags, {
                    version = version,
                    tag = s
                } )
            else
                
                version = s:gsub("_", "%."):match( "[.-]*([%d+%.]+.*)" )

                if pcall( zpm.semver, version ) then
                    table.insert( tags, {
                        version = version,
                        tag = s
                    } )
                end
            end
        end
	end   
    
    
    table.sort( tags, function( t1, t2 )         
        return bootstrap.semver( t1.version ) > bootstrap.semver( t2.version )
    end )
    
    os.chdir( current )  
      
    return tags
end

function zpm.git.archive( destination, output, tag )
    
    local current = os.getcwd()
    
    os.chdir( destination )
    
    os.execute( "git archive --format=zip --output=" .. output .. " " .. tag )
    
    os.chdir( current )
end

function zpm.git.cloneOrPull( destination, url )

    if os.isdir( destination ) then
        
        if not _OPTIONS["ignore-updates"] then
            
            return zpm.git.pull( destination, url )
        else
            return false
        end
    else
        zpm.git.clone( destination, url )
    end

    return true
end


function zpm.git.lfs.checkout( destination, checkout )
    
    local current = os.getcwd()
    
    os.chdir( destination )
    
    os.execute( "git checkout -q -f -B " .. checkout )
    os.execute( "git lfs checkout" )
    os.execute( "git submodule update --init --recursive -j 8" )
    
    os.chdir( current )

end

function zpm.git.lfs.checkoutVersion( destination, version )
    
    if version == "@head" then
        zpm.git.lfs.checkout( destination, "master" )
    elseif version:gsub("#", "") ~= version then 
        zpm.git.lfs.checkout( destination, version:gsub("#", "") )
    else
        zpm.git.lfs.checkout( destination, "tags/" .. version )
    end
end

function zpm.git.lfs.pull( destination, url )
    
    local current = os.getcwd()
    
    os.chdir( destination )

    if url ~= nil then        
        os.execute( "git remote set-url origin " .. url  )
    end
    
    os.execute( "git fetch origin --tags -q -j 8" )

    if os.outputof( "git log HEAD..origin/master --oneline" ):len() > 0 then    
        os.execute( "git checkout -q ." )
        os.execute( "git reset --hard origin/HEAD" )
        os.execute( "git lfs pull origin master -q" )
        os.execute( "git submodule update --init --recursive -j 8" )
    end
    
    os.chdir( current )
    
end

function zpm.git.lfs.clone( destination, url )
    
    os.execute( string.format( "git lfs clone \"%s\" \"%s\"", url, destination ) )
    zpm.git.share( destination )
    
end

function zpm.git.lfs.cloneOrPull( destination, url )

    if os.isdir( destination ) then
        zpm.git.lfs.pull( destination, url )
    
    else
        zpm.git.lfs.clone( destination, url )
    end
end