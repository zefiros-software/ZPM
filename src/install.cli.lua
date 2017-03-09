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

local function _installZPM()

    printf("%%{greenbg white bright}Installing ZPM version '%s'!", zpm._VERSION)

    if not zpm.__isLoaded or zpm.__isLoaded == nil then
        zpm.onLoad()
        zpm.__isLoaded = true
    end
    
    zpm.loader.install:install()
end

newaction {
    trigger = "install",
    description = "Installs ZPM",
    execute = function()
        local help = false
        if #_ARGS == 0 or _ARGS[1] == "package" then
        elseif #_ARGS == 1 or _ARGS[1] == "zpm" then
            _installZPM()
        else
            help = true
        end

        if help or _OPTIONS["help"] then
            printf("%%{yellow}Show action must be one of the following commands:\n" ..
            " - package (default)\tSets the key on a specified value\n" ..
            " - zpm  \t\tInstalls ZPM")
        end
    end
}

newaction {
    trigger = "update",
    description = "Updates ZPM",
    execute = function()
        local help = false
        if #_ARGS == 1 or _ARGS[1] == "self" then
            zpm.loader.install:update()
            premake.action.call("update-modules")
        elseif #_ARGS == 1 or _ARGS[1] == "bootstrap" then
            premake.action.call("update-bootstrap")
        elseif #_ARGS == 1 or _ARGS[1] == "registry" then
            premake.action.call("update-registry")
        elseif #_ARGS == 1 or _ARGS[1] == "zpm" then
            premake.action.call("update-zpm")
        elseif #_ARGS == 1 or _ARGS[1] == "modules" then
            premake.action.call("update-modules")
        else
            help = true
        end

        if help or _OPTIONS["help"] then
            printf("%%{yellow}Show action must be one of the following commands:\n" ..
            " - self \tUpdates everything underneath\n" ..
            " - bootstrap \tUpdates the bootstrap module loader\n" ..
            " - registry \tUpdates the ZPM library registry\n" ..
            " - zpm \t\tUpdates ZPM itself\n" ..
            " - modules \tUpdates the installed modules")
        end
    end
}