--[[ @cond ___LICENSE___
-- Copyright (c) 2017 Zefiros Software.
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

Installer = newclass "Installer"

local function _scriptPath()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
end

function Installer:init(loader)
    self.loader = loader
end

function Installer:install()
    self:_createDirectory()
    self:_writePremakeSystem()

    local system = self:_getPremakeSystem()
    if os.isfile( system ) then
        dofile( system  )
    
        premake.action.call( "update-bootstrap" )    
        premake.action.call( "update-zpm" )
        premake.action.call( "update-registry" )
    end
end

function Installer:_getPremakeSystem()

    return path.join(_PREMAKE_DIR, "premake-system.lua")
end

function Installer:_createDirectory()
    local folder = zpm.env.getDataDirectory()

    if not os.isdir(folder) then

        zpm.assert(os.mkdir(folder), "Cannot create instalation folder '%s'!", folder)
    end
end

function Installer:_writePremakeSystem()

    local folder = zpm.env.getDataDirectory()
    local file = io.open(self:_getPremakeSystem(), "w")
    file:write(("local CMD = \"%s\"\n"):format(folder) .. 
               ("local BOOTSTRAP_DIR = \"%s\"\n"):format(self.loader.config("install.bootstrap.directory")) .. 
               ("local BOOTSTRAP_REPO = \"%s\"\n"):format(self.loader.config("install.bootstrap.repository")) .. 
               ("local INSTALL_DIR = \"%s\"\n"):format(self.loader.config("install.directory")) .. 
               ("local INSTALL_REPO = \"%s\"\n"):format(self.loader.config("install.repository")) .. 
               ("local REGISTRY_DIR = \"%s\"\n"):format(self.loader.config("install.registry.directory")) .. 
               ("local REGISTRY_REPO = \"%s\"\n"):format(self.loader.config("install.registry.repository")) .. 
               ("local ZPM_BRANCH = \"%s\"\n"):format(self.loader.config("install.branch")))
    file:write(zpm.util.readAll(path.join(_scriptPath(), "premake-system.lua")))
    file:close()
end