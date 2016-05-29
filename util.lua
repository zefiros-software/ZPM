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

-- Util
zpm.util = {}

function zpm.util.askShellConfirmation( question, yesFunc, noFunc )

    printf( "%s, use '--allow-shell' to always accept (Y [enter]/n)?", question )
    local answer = io.read()
    if answer == "Y" or 
       answer == "y" or 
       answer == "" or 
       _OPTIONS["allow-shell"] ~= nil then
        return yesFunc()
    else
        return noFunc()
    end
    
end

function zpm.util.isAlphaNumeric( str )
    return str == str:gsub( "[^[%w-_]]*", "" )
end

function zpm.util.getAlphaNumeric( str )
    str = str:gsub( "[^[%w-_]]*", "" )
    return str
end

function zpm.util.concat( t1,t2 )
    for i=1,#t2 do
        t1[#t1+1] = t2[i]
    end
    return t1
end

function zpm.util.compare( t1, t2 )
    table.sort( t1 )
    table.sort( t2 )
    if #t1 ~= #t2 then 
        return false 
    end
    for i=1,#t1 do
        if t1[i] ~= t2[i] then 
            return false 
        end
    end
    return true
end

function zpm.util.isEmail( str )
    return str:match( "[A-Za-z0-9%.%%%+%-]+@[A-Za-z0-9%.%%%+%-]+%.%w%w%w?%w?" )
end

function zpm.util.getGitUrlName( str )

    local str2 = zpm.util.getGitUrl( str )
    
    str2 = str2:match( ".*/(.*)\.git" )
    
    return getAlphaNumeric( str2 )
end

function zpm.util.getGitUrl( str )
    local str2 = str:match( "(https://.*\.git).*" )
    if str2 == nil then
        return str:match( "(ssh://git@.*\.git).*" )
    end
    
    return str2
end

function zpm.util.isGitUrl( str )
    return str == zpm.util.getGitUrl( str )
end

function zpm.util.hasGitUrl( str )
    return zpm.util.getGitUrl( str ) ~= nil    
end

function zpm.util.hasUrl( str )
    return str:match( ".*(https?://).*" ) ~= nil
end


function zpm.util.getRepoDir( name, repository )
    return name .. "-" .. string.hash( repository )
end

function zpm.util.readAll( file )

    zpm.assert( os.isfile( file ), "'%s' does not exist", file )

    local f = io.open(file, "rb")
    local content = f:read("*all")
    f:close()
    
    return content
end

function zpm.util.downloadFromArchive( url, pattern )
    if url:gsub( ".tar.gz", "" ) == url then
        return zpm.util.downloadFromZip( url, pattern )
    end
    return zpm.util.downloadFromTarGz( url, pattern )
end

function zpm.util.downloadFromZip( url, pattern )

    local hash = os.uuid()
    local zipFile = path.join( zpm.temp, hash .. ".zip" )
    
    zpm.wget.download( zipFile, url )
                    
    local zipTemp = path.join( zpm.temp, hash )
    zpm.assert( os.mkdir( zipTemp ), "The archive directory could not be made!" )

    zip.extract( zipFile, zipTemp )
    
    local fullPattern = path.join( zipTemp, pattern )
    
    return os.matchfiles( fullPattern )
    
end

function zpm.util.downloadFromTarGz( url, pattern )

    local hash = os.uuid()
    local zipFile = path.join( zpm.temp, hash .. ".tar.gz" )
    
    zpm.wget.download( zipFile, url )
                    
    local zipTemp = path.join( zpm.temp, hash )
    zpm.assert( os.mkdir( zipTemp ), "The archive directory could not be made!" )

    os.execute( "tar xzvf " .. zipFile .. " -C " .. zipTemp )
    
    local fullPattern = path.join( zipTemp, pattern )
    
    return os.matchfiles( fullPattern )
    
end

function zpm.util.hideProtectedFile( file )

    local hash = os.uuid()
    local dir = path.join( zpm.temp, hash )
    local fileh = path.join( dir, hash )
    
    zpm.assert( os.mkdir( dir ), "The archive directory could not be made!" )
    zpm.assert( os.rename( file, fileh ) )
    
end