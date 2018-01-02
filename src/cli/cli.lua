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

function zpm.cli.verbose()

    return _OPTIONS["verbose"] ~= nil
end


function zpm.cli.showVersion()

    return _OPTIONS["version"] ~= nil
end


function zpm.cli.showHelp()

    return _OPTIONS["help"] ~= nil
end

function zpm.cli.ci()

    return _OPTIONS["ci"] or os.getenv("TRAVIS") or os.getenv("APPVEYOR") or os.getenv("CI")
end

newoption {
    trigger = "ci",
    description = "Mark this as an CI build"
}

if zpm.cli.showHelp() then
    zpm.util.disableMainScript()
end

newoption {
    trigger = "ignore-lock",
    description = "Act as if there is no lock file available"
}
newoption {
    trigger = "skip-lock",
    description = "Alias for --ignore-lock"
}

function zpm.cli.force()

    return _OPTIONS["force"]
end

newoption {
    trigger = "force",
    description = "Force installation of already extracted dependencies"
}

function zpm.cli.ignoreLock()

    return _OPTIONS["ignore-lock"] or _OPTIONS["skip-lock"]
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

    return _OPTIONS["update"] ~= nil
end

function zpm.cli.profile()

    if (_OPTIONS["profile"] ~= "none" or _ACTION == "profile") then
        return _OPTIONS["profile"]
    end
    return false
end

newoption {
    trigger = "profile",
    description = "Profiles the given commands",
    value = "pepper_fish",
    default = "none",
    allowed = {
        {"none", "no profiling"},
        {"pepper_fish", "the default profiler"},
        {"ProFi", ""}
    }
}

if zpm.cli.profile() then

    newaction {
        trigger = "profile",
        description = "Profiles"
    }
end

newoption {
    trigger = "always-trust",
    description = "Allow trust execution of new repository code"
}

function zpm.cli.askTrustStoreConfirmation(question, yesFunc, noFunc)

    interactf("%s Use '--always-trust' to always accept (Y [enter]/n)?", question)
    local answer = not zpm.cli.n() and (zpm.cli.y() or zpm.cli.noInteractive() or _OPTIONS["allow-trust"] or io.read())
    print(answer, type(answer), "@@@@@@@@@@@@@@@")
    if answer == "Y" or
        answer == "y" or
        answer == "" or
        answer == true or
        answer == "true" or
        answer == "True" then
        return yesFunc()
    else
        return noFunc()
    end

end

newoption {
    trigger = "allow-module",
    description = "Allow modules to install"
}

function zpm.cli.askModuleConfirmation(question, yesFunc, noFunc)

    interactf("%s, use '--allow-module' to always accept (Y [enter]/n)?", question)
    local answer = not zpm.cli.n() and (zpm.cli.y() or zpm.cli.noInteractive() or _OPTIONS["allow-module"] or io.read())
    interactf(answer)
    if answer == "Y" or
        answer == "y" or
        answer == "" or
        answer == true or
        answer == "true" or
        answer == "True" then
        return yesFunc()
    else
        return noFunc()
    end

end

newoption {
    trigger = "y",
    description = "Always use 'y' to accept CLI interactions"
}

function zpm.cli.y()

    return _OPTIONS["y"] or zpm.cli.ci()
end

newoption {
    trigger = "n",
    description = "Always use 'n' to decline CLI interactions"
}

function zpm.cli.n()

    return _OPTIONS["n"]
end

newoption {
    trigger = "no-interactive",
    description = "Use this option if you can't interact with zpm"
}

function zpm.cli.noInteractive()

    return _OPTIONS["no-interactive"] or zpm.cli.ci()
end

function zpm.cli.askConfirmation(question, yesFunc, noFunc, pred)

    pred = iif(pred ~= nil, pred, function() return false end)

    if not (zpm.cli.y() or zpm.cli.n() or zpm.cli.noInteractive()) then
        interactf("\n%s (Y [enter]/n)\nUse '--y' or '--no-interactive' to always accept or '--n' to decline.", question)
    end

    local answer = not zpm.cli.n() and (zpm.cli.y() or zpm.cli.noInteractive() or pred() or io.read())
    interactf(answer)
    if answer == true or
        answer == "true" or
        answer == "True" or
        answer == "Y" or
        answer == "y" or
        answer == "" then
        return yesFunc()
    else
        return noFunc()
    end

end
