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
    trigger = "run",
    description = "Run module and package cli command",
    execute = function()
        local help = false

        if #_ARGS >= 1 then
            if _ARGS[1] ~= "help" then
                _ACTION = _ARGS[1]
                _ARGS[1] = nil
                _ARGS = table.filterempty(_ARGS)

                premake.main.processCommandLine()
                premake.main.callAction()
            else
                help = true
            end
        else
            help = true
        end

        if help or zpm.cli.showHelp() then
            printf("%%{yellow}Run action must be one of the following commands:\n")

            printf("%%{yellow}\nOPTIONS\n")
            for i, action in ipairs(zpm.cli._options) do

                printf("%%{yellow}--%s\t\t%s", action.trigger, action.description)
            end

            printf("%%{yellow}\nACTIONS\n")
            for i, action in ipairs(zpm.cli._actions) do

                printf("%%{yellow}%s\t\t%s", action.trigger, action.description)
            end
        end
    end
}

zpm.cli._actions = {}
zpm.cli._options = {}

function zpm.cli.run()

    return _ACTION == "run"
end

function zpm.cli.newRunAction(action)

    table.insert(zpm.cli._actions, action)

    newaction(action)
end

function zpm.cli.newRunOption(option)

    table.insert(zpm.cli._options, option)

    newoption(option)
end

zpm.newaction = zpm.cli.newRunAction
zpm.newoption = zpm.cli.newRunOption

if _ACTION == "run" then
    zpm.util.disableMainScript()
end