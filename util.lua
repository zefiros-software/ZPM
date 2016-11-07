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

function zpm.util.sleep( n )
  if n > 0 then 
    os.execute("ping -n " .. tonumber(n+1) .. " localhost > NUL") 
  end
end

function zpm.util.djb2( str )
    -- works better
    return string.sha1( str ):sub( -4 )
end

function zpm.util.rmdir( folder )

    if os.get() == "windows" then
        os.execute( string.format( "move /Y \"%s\" \"%s-delete\" > nul", folder, folder ) )
        os.execute( string.format( "@start \"Deleting...\" cmd /c el /f/s/q \"%s-delete\" > nul && rmdir /Q /S \"%s-delete\" > nul && exit", folder, folder ) )
    else
        os.execute( string.format( "rm -rf \"%s\"", folder ) )
    end

end

function zpm.util.askModuleConfirmation( question, yesFunc, noFunc )

    printf( zpm.colors.cyan .. zpm.colors.bright .. "\n%s, use '--allow-module' to always accept (Y [enter]/n)?", question )
    local answer = _OPTIONS["allow-module"] or io.read()
    if answer == "Y" or 
       answer == "y" or 
       answer == "" or 
       _OPTIONS["allow-module"] then
        return yesFunc()
    else
        return noFunc()
    end
    
end

function zpm.util.askShellConfirmation( question, yesFunc, noFunc )

    printf( zpm.colors.cyan .. zpm.colors.bright .. "\n%s, use '--allow-shell' to always accept (Y [enter]/n)?", question )
    local answer = _OPTIONS["allow-shell"] or io.read()
    if answer == "Y" or 
       answer == "y" or 
       answer == "" or 
       _OPTIONS["allow-shell"] then
        return yesFunc()
    else
        return noFunc()
    end
    
end

function zpm.util.askInstallConfirmation( question, yesFunc, noFunc )

    printf( zpm.colors.cyan .. zpm.colors.bright .. "\n%s, use '--allow-install' to always accept (Y [enter]/n)?", question )
    local answer = _OPTIONS["allow-install"] or io.read()
    if answer == "Y" or 
       answer == "y" or 
       answer == "" or 
       _OPTIONS["allow-install"] ~= nil then
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

function zpm.util.hashTable( tab )
    return zpm.util.djb2( zpm.util.tostring( zpm.util.sortTable(tab) ) )
end

function zpm.util.sortTable( tab ) 
    local sort = function(a,b)
        local atab = type(a) == "table"
        local btab = type(b) == "table"
        if atab and btab then
            return true
        elseif atab then
            return false

        elseif btab then
            return false
        else       
            return a < b
        end
    end

    if type(tab) ~= "table" then
        return tab
    elseif tab[1] ~= nil then
        local arr = {}
        for i, v in ipairs(tab) do 
            arr[i] = zpm.util.sortTable( v )
        end
        table.sort(arr, sort)
        return arr
    else
        local arr = {}
        for k, v in pairs(tab) do 
            arr[k] = zpm.util.sortTable( v )
        end
        table.sort(arr, sort)
        return arr
    end
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
    repository = repository or ""
    return name .. "-" .. string.sha1( repository ):sub( -5 )
end

function zpm.util.readAll( file )

    zpm.assert( os.isfile( file ), "'%s' does not exist", file )

    local f = io.open(file, "rb")
    local content = f:read("*all")
    f:close()
    
    return content
end

function zpm.util.download( url, destination, pattern )
    if url:endswith( ".tar.gz" ) then
        return zpm.util.downloadFromTarGzTo( url, destination, pattern )
    elseif url:endswith( ".zip" ) then
        return zpm.util.downloadFromZipTo( url, destination, pattern )
    end
    
    -- it is a file
    zpm.wget.downloadFile( destination, url )
end

function zpm.util.downloadFromArchive( url, pattern )
    if url:gsub( ".tar.gz", "" ) == url then
        return zpm.util.downloadFromZip( url, pattern )
    end
    return zpm.util.downloadFromTarGz( url, pattern )
end

function zpm.util.downloadFromZipTo( url, destination, pattern )

    local hash = os.uuid()
    local zipFile = path.join( zpm.temp, hash .. ".zip" )
    
    zpm.wget.download( zipFile, url )

    zip.extract( zipFile, destination )
    
    local fullPattern = path.join( destination, pattern )
    
    return os.matchfiles( fullPattern )
    
end

function zpm.util.downloadFromTarGzTo( url, destination, pattern )

    local hash = os.uuid()
    local zipFile = path.join( zpm.temp, hash .. ".tar.gz" )
    
    zpm.wget.download( zipFile, url )

    os.execute( "tar xzvf " .. zipFile .. " -C " .. destination )
    
    local fullPattern = path.join( destination, pattern )
    
    return os.matchfiles( fullPattern )
    
end


function zpm.util.downloadFromZip( url, pattern )

    local zipTemp = path.join( zpm.temp, hash )
    zpm.assert( os.mkdir( zipTemp ), "The archive directory could not be made!" )

    return zpm.util.downloadFromZipTo( url, zipTemp, pattern )
    
end

function zpm.util.downloadFromTarGz( url, pattern )

    local zipTemp = path.join( zpm.temp, hash )
    zpm.assert( os.mkdir( zipTemp ), "The archive directory could not be made!" )

    return zpm.util.downloadFromTarGzTo( url, zipTemp, pattern )
    
end

function zpm.util.hideProtectedFile( file )

    local hash = os.uuid()
    local dir = path.join( zpm.temp, hash )
    local fileh = path.join( dir, hash )
    
    zpm.assert( os.mkdir( dir ), "The archive directory could not be made!" )
    zpm.assert( os.rename( file, fileh ) )
    
end

function zpm.util.isNewer( file1, file2 )

    info1 = os.stat(file1)
    info2 = os.stat(file2)

    return info1.mtime > info2.mtime
end

function zpm.util.tostring(tab, recurse, indent)
    local res = ''

    if not indent then
        indent = 0
    end

    local format_value = function(k, v, i)
        formatting = ""
        for j=0, i, 1 do
            formatting = formatting .. "\t"
        end

        if k then
            if type(k) == "table" then
                k = '[table]'
            end
            formatting = formatting .. k .. ": "
        end

        if not v then
            return formatting .. '(nil)'
        elseif type(v) == "table" then
            if recurse and recurse > 0 then
                return formatting .. '\n' .. zpm.util.tostring(v, recurse-1, i+1)
            else
                return formatting .. "<table>"
            end
        elseif type(v) == "function" then
            return formatting .. tostring(v)
        elseif type(v) == "userdata" then
            return formatting .. "<userdata>"
        elseif type(v) == "boolean" then
            if v then
                return formatting .. 'true'
            else
                return formatting .. 'false'
            end
        else
            return formatting .. v
        end
    end

    if type(tab) == "table" then
        local first = true

        -- add the meta table.
        local mt = getmetatable(tab)
        if mt then
            res = res .. format_value('__mt', mt, indent)
            first = false
        end

        -- add all values.
        for k, v in pairs(tab) do
            if not first then
                res = res .. '\n'
            end

            res = res .. format_value(k, v, indent)
            first = false
        end
    else
        res = res .. format_value(nil, tab, indent)
    end

    return res
end
