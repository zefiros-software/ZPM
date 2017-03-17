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

newaction {
    trigger = "module",
    description = "Interacts with the ZPM modules",
    execute = function()
        local help = false

        if #_ARGS > 0 then
            if _ARGS[1] == "install" and #_ARGS > 1 then
                
                zpm.loader.modules:install(_ARGS[2], _ARGS[3])
            elseif _ARGS[1] == "update" and #_ARGS > 1  then
                
                zpm.loader.modules:update(_ARGS[2], _ARGS[3])
            elseif _ARGS[1] == "uninstall" and #_ARGS > 1  then
                
                zpm.loader.modules:uninstall(_ARGS[2], _ARGS[3])
            elseif _ARGS[1] == "update" and #_ARGS == 1  then
                
                zpm.loader.modules:update("*/*")
            elseif _ARGS[1] == "show" then
                
                zpm.loader.modules:showInstalled()
            else
                help = true
            end
        else
            help = true
        end

        if help or _OPTIONS["help"] then
            printf("%%{yellow}Modules action must be one of the following commands:\n" ..
            " - install   [vendor] [name]\tInstalls modules with given vendor and name\n" ..
            " - uninstall [vendor] [name]\tUninstalls modules with given vendor and name\n" ..
            " - update    [vendor] [name]\tUpdates modules with given vendor and name\n" ..
            " - update \t\t\tUpdates all modules that are installed\n" ..
            " - show \t\t\tShow all installed modules")
        end
    end
}
