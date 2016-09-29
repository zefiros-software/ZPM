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

zpm.assets.commands = {}

function zpm.assets.commands.extract( repo, folder, files )

    if (type(files) ~= "table") then
        files = {files}
    end
        
    for _, pattern in ipairs( files ) do
        for _, file in ipairs( os.matchfiles( path.join( repo, pattern ) ) ) do

            local target = path.join( folder, path.getrelative( repo, file ) )
            local targetDir = path.getdirectory( target )            
            
            zpm.assert( path.getabsolute( targetDir ):contains( _MAIN_SCRIPT_DIR ), "Executing lua outside folder is not allowed!" )
            if not os.isdir( targetDir ) then
                zpm.assert( os.mkdir( targetDir ), "Could not create asset directory '%s'!", targetDir )
            end
            
            if os.isfile( target ) == false or zpm.util.isNewer( file, target ) then
                os.copyfile( file, target )
            end

            zpm.assert( os.isfile(target), "Could not make file '%s'!", target )
        end 
    end 

end

function zpm.assets.commands.extractto( repo, folder, files, to )

    if (type(files) ~= "table") then
        files = {files}
    end

    for _, pattern in ipairs( files ) do
        for _, file in ipairs( os.matchfiles( path.join( repo, pattern ) ) ) do

            local target = path.join( _MAIN_SCRIPT_DIR, to, path.getrelative( repo, file ) )
            local targetDir = path.getdirectory( target )
            
            zpm.assert( path.getabsolute( targetDir ):contains( _MAIN_SCRIPT_DIR ), "Executing lua outside folder is not allowed!" )
            if not os.isdir( targetDir ) then
                zpm.assert( os.mkdir( targetDir ), "Could not create asset directory '%s'!", targetDir )
            end
            
            if target:len() <= 255 then
            
                if os.isfile( target ) == false or zpm.util.isNewer( file, target ) then
                    os.copyfile( file, target )
                end
                zpm.assert( os.isfile(target), "Could not make file '%s'!", target )
            else
                warningf( "Failed to copy '%s' due to long path length!", target )
            end
        end 
    end 
    
end

function zpm.assets.commands.download( repo, folder, url, to )
    local targetDir = path.join( folder, to )
            
    zpm.assert( path.getabsolute( targetDir ):contains( _MAIN_SCRIPT_DIR ), "Executing lua outside assets folder is not allowed!" )

    if not os.isdir( targetDir ) then
        zpm.assert( os.mkdir( targetDir ), "Could not create asset directory '%s'!", targetDir )
    end
                    
    zpm.util.download( url, targetDir, "*" )
end