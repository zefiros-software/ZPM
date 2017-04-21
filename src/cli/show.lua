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
    trigger = "show",
    description = "Shows various ZPM settings",
    execute = function()
        local help = false
        zpm.util.disableMainScript()

        if #_ARGS == 1 then
            if _ARGS[1] == "cache" then
                print(zpm.env.getCacheDirectory())
            elseif _ARGS[1] == "install" then
                print(zpm.env.getDataDirectory())
            else
                help = true
            end
        else
            help = true
        end

        if help or zpm.cli.showHelp() then
            printf("%%{yellow}Show action must be one of the following commands:\n" ..
            " - cache \tSets the key on a specified value\n" ..
            " - install \tAdds a value to the array on the given key")
        end
    end
}

function zpm.cli.show()

    return _ACTION == "show"
end