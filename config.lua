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
zpm.config = {}
zpm.config.fileName = ".config.json"
zpm.config.settings = {}

function zpm.config.scriptPath()
   local str = debug.getinfo(2, "S").source:sub(2)
   return str:match("(.*/)")
end

function zpm.config.initialise()
    
    -- inverse priority
    zpm.config.loadFile( path.join( _MAIN_SCRIPT_DIR, "../." .. zpm.config.fileName ) ) -- private

    zpm.config.loadFile( path.join( _MAIN_SCRIPT_DIR, "." .. zpm.config.fileName ) ) -- private

    zpm.config.loadFile( path.join( _MAIN_SCRIPT_DIR, zpm.config.fileName ) )

    zpm.config.loadFile( path.join( zpm.config.scriptPath(), zpm.config.fileName ) )
end

function zpm.config.loadFile( file )

    if not os.isfile( file ) then
        return nil
    end
    
    local config = zpm.JSON:decode( zpm.util.readAll( file ) )
    zpm.config = table.merge( config, zpm.config )
end

function zpm.config.addSettings( settings )

    if settings == nil then
        return nil
    end
    
    zpm.config.settings = table.merge( settings, zpm.config.settings )
end