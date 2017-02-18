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
    trigger = "config",
    description = "Interacts with the ZPM configuration",
    execute = function()
        local help = false
        if #_ARGS > 1 then
            if _ARGS[1] == "set" then
                zpm.assert(#_ARGS == 3, "No key and value specified")
                zpm.loader.config:set(_ARGS[2], _ARGS[3])
            elseif _ARGS[1] == "add" then
                zpm.assert(#_ARGS == 3, "No key and value specified")
                zpm.loader.config:add(_ARGS[2], _ARGS[3])
            elseif _ARGS[1] == "get" then
                zpm.assert(#_ARGS == 2, "No key specified")
                zpm.loader.config:get(_ARGS[2])
            else
                help = true
            end
        else
            help = true
        end

        if help or _OPTIONS["help"] then
            printf("%%{yellow}Config action must be one of the following commands:\n" ..
            " - set [key] [value]\tSets the key on a specified value\n" ..
            " - add [key] [value]\tAdds a value to the array on the given key\n" ..
            " - get [key]\t\tGets the value on a specified key\n\n" ..
            " --parents\tMake parent keys as needed")
        end
    end
}

if _ACTION == "config" then
    
    newoption {
        trigger = "parents",
        description = "Make parent keys as needed"
    }
end