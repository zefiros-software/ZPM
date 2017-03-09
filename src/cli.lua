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

zpm.cli = {}

function zpm.cli.showVersion()

    return _OPTIONS["version"]
end


function zpm.cli.showHelp()

    return _OPTIONS["help"]
end


newoption {
    trigger = "cached-only",
    description = "Only use the cached repositories (usefull on slow connections)"
}

function zpm.cli.cachedOnly()

    return _OPTIONS["cached-only"]
end


newoption {
    trigger = "update",
    description = "Updates the dependencies to the newest version given the constraints"
}

function zpm.cli.update()

    return _OPTIONS["update"]
end


newoption {
    trigger = "profile",
    description = "Profiles the given commands"
}

newaction {
    trigger = "profile",
    description = "Profiles the given commands",
    onStart = function()
        ProFi = require("mindreframer/ProFi", "@head")
        ProFi:start()
    end,
    onEnd = function()
        ProFi:stop()
        ProFi:writeReport(path.join(_MAIN_SCRIPT_DIR, "profile.txt"))
    end
}










