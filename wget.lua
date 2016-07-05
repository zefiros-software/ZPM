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

-- WGet 
zpm.wget = {}
zpm.wget.downloadUrl = zpm.config.wget.downloadUrl
zpm.wget.dependenciesUrl = zpm.config.wget.dependenciesUrl
 

function zpm.wget.downloadWget( destination )

    local zipFile = path.join( zpm.temp, "wget.zip" )
    
    if not os.isfile( zipFile ) then
        print( "wget not detected - start downloading" )   
        http.download( zpm.wget.downloadUrl, zipFile )
    else
        print( "wget archive detected - start exctracting" )
    end
    
    local zipTemp = path.join( zpm.temp, "wget-zip" )
    zpm.assert( os.mkdir( zipTemp ), "The archive directory could not be made!" )
    
    zip.extract( zipFile, zipTemp )
                
    os.rename(  path.join( zipTemp, "bin/wget.exe" ), destination )

    zpm.assert( os.isfile( path.join( zipTemp, "bin/wget.exe" ) ), "Wget is not installed!" )
    
    print( "wget succesfully installed" )
    
end


function zpm.wget.downloadDependencies()

    local eay32 = path.join( zpm.cache, "libeay32.dll" )
    local iconv2 = path.join( zpm.cache, "libiconv2.dll" )
    local intl3 = path.join( zpm.cache, "libintl3.dll" )
    local ssl32 = path.join( zpm.cache, "libssl32.dll" )
    
    local zipFile = path.join( zpm.temp, "dependencies.zip" )
    
    if not ( os.isfile( eay32 )  and 
             os.isfile( iconv2 ) and 
             os.isfile( intl3 )  and 
             os.isfile( ssl32 ) ) then
        print( "wget dependencies not detected - start downloading" )
        http.download( zpm.wget.dependenciesUrl, zipFile )
    else
        print( "wget dependencies archive detected - start exctracting" )
    end
    
    local zipTemp = path.join( zpm.temp, "dependencies-zip" )
    zpm.assert( os.mkdir( zipTemp ), "The archive directory could not be made!" )
    
    zip.extract( zipFile, zipTemp )
    os.rename( path.join( zipTemp, "bin/libeay32.dll" ), eay32 )
    os.rename( path.join( zipTemp, "bin/libiconv2.dll" ), iconv2 )
    os.rename( path.join( zipTemp, "bin/libintl3.dll" ), intl3 )
    os.rename( path.join( zipTemp, "bin/libssl32.dll" ), ssl32 )
    
    print( "wget dependencies succesfully installed" )

end

function zpm.wget.initialise()

    local dest = path.join( zpm.cache, "wget.exe" )
    
    if os.get() == "windows" then
        if not os.isfile( dest ) then
    
            print( "\nLoading wget..." )

            zpm.wget.downloadWget( dest )
            zpm.wget.downloadDependencies()
           
        end
        
        zpm.wget.location = dest
    else
    
        zpm.wget.location = "wget"
        
    end     
end

function zpm.wget.get( url, header )

    if header == nil or not header then
        return os.outputof( zpm.wget.location .. " -nv -qO- " .. url .. " --no-check-certificate 2> nul" )
    end
    
    return os.outputof( zpm.wget.location .. " -nv -qO- " .. url .. " --no-check-certificate --header \"" .. header .. "\" 2> nul" )

end

function zpm.wget.download( destination, url, header )

    if header == nil or not header then
        os.execute( zpm.wget.location .. " -N " .. url .. " -O " .. destination .. " --no-check-certificate" )
    else    
        os.execute( zpm.wget.location .. " -N " .. url .. " -O " .. destination .. " --no-check-certificate --header \"" .. header .. "\"" )
    end
end

function zpm.wget.downloadFile( destination, url, header )

    if header == nil or not header then
        os.execute( zpm.wget.location .. " -N " .. url .. " -P " .. destination .. " --no-check-certificate" )
    else    
        os.execute( zpm.wget.location .. " -N " .. url .. " -P " .. destination .. " --no-check-certificate --header \"" .. header .. "\"" )
    end
end