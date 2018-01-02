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

-- Handy little helper
function os.outputoff(...)
    return os.outputof(string.format(...))
end

function os.fexecutef(...)
    local result, f, code = os.executef(...)
    if code ~= 0 then
        printf("Failed to execute command!")
        os.exit(1)
    end
end

premake.override(os, "execute", function(base, exec)

    if _OPTIONS["verbose"] then
        print(os.getcwd() .. "\t" .. exec)
    end
    return base(exec)
end )

premake.override(os, "outputof", function(base, exec)

    if _OPTIONS["verbose"] then
        print(os.getcwd() .. "\t" .. exec)
    end
    return base(exec)
end )

-- Unfortunately premake normalises most paths,
-- which results in some links like http:// to be 
-- reduced to http:/ which of course is incorrect
premake.override(path, "normalize", function(base, p)

    if not zpm.util.hasGitUrl(p) and not zpm.util.hasUrl(p) and not p:contains("\\\"") then
        return base(p)
    end

    return p
end )

premake.override(premake.main, "preAction", function()
    local action = premake.action.current()
end )


-- this was taken from 
-- https://github.com/premake/premake-core/blob/785671fad5946a129300ffcd0f61561f690bddb4/src/_premake_main.lua
premake.override(premake.main, "processCommandLine", function()
    -- Process special options
    if (_OPTIONS["version"]) then
        printf("ZPM (Zefiros Package Manager) %s", zpm._VERSION)
        printf("premake5 (Premake Build Script Generator) %s", _PREMAKE_VERSION)
        os.exit(0)
    end

    if (_OPTIONS["help"] and _ACTION ~= "run") then
        premake.showhelp()
        os.exit(1)
    end

    -- Validate the command-line arguments. This has to happen after the
    -- script has run to allow for project-specific options
    local ok, err = premake.option.validate(_OPTIONS)
    if not ok then
        printf("Error: %s", err)
        os.exit(1)
    end

    -- If no further action is possible, show a short help message
    if not _OPTIONS.interactive then
        if not _ACTION then
            print("Type 'zpm --help' for help")
            os.exit(1)
        end

        local action = premake.action.current()
        if not action then
            printf("Error: no such action '%s'", _ACTION)
            os.exit(1)
        end

        if premake.action.isConfigurable() and not os.isfile(_MAIN_SCRIPT) then
            printf("No zpm script (%s) found!", path.getname(_MAIN_SCRIPT))
            os.exit(1)
        end
    end
	end)

 premake.override(premake.main, "postAction", function(base)

    if zpm.cli.profile() then
    
        if profiler then
            profiler:stop()
            profiler:report(io.open(path.join(_MAIN_SCRIPT_DIR, "profile.txt"), 'w'))
        elseif ProFi then
            ProFi:stop()
            ProFi:writeReport(path.join(_MAIN_SCRIPT_DIR, "profile.txt"))
        end
    end

    base()
	end)

 premake.override(premake.main, "locateUserScript", function()
    local defaults = { "zpm.lua", "premake5.lua", "premake4.lua" }
    for _, default in ipairs(defaults) do
        if os.isfile(default) then
            _MAIN_SCRIPT = default
            break
        end
    end

    if not _MAIN_SCRIPT then
        _MAIN_SCRIPT = defaults[1]
    end

    if _OPTIONS.file then
        _MAIN_SCRIPT = _OPTIONS.file
    end

    _MAIN_SCRIPT = path.getabsolute(_MAIN_SCRIPT)
    _MAIN_SCRIPT_DIR = path.getdirectory(_MAIN_SCRIPT)
	end)

 
premake.override(_G, "workspace", function(base, name)
    if name and not zpm.meta.exporting then
        zpm.meta.workspace = name
    end
    return base(name)
end)

premake.override(_G, "project", function(base, name)
    if name and not zpm.meta.exporting then
        zpm.meta.project = name
        
        if not zpm.meta.building then
            zpm.util.insertTable(zpm.loader.project.builder.cursor, {"projects", name, "workspaces"}, zpm.meta.workspace)
        end
    end

    return base(name)
end)

premake.override(_G, "group", function(base, name)
    if (name or name == "") and not zpm.meta.exporting  then
        zpm.meta.group = name
    end
    return base(name)
end)

premake.override(_G, "filter", function(base, fltr)
    if (fltr or fltr == "") and not zpm.meta.exporting  then
        zpm.meta.filter = fltr
    end
    return base(fltr)
end)

premake.override(_G, "kind", function(base, knd)
    if kind and not zpm.meta.exporting then
        zpm.meta.kind = knd
        if not zpm.meta.building then
            zpm.util.setTable(zpm.loader.project.builder.cursor, {"projects", zpm.meta.project, "kind"}, knd)
        end
    end
    return base(knd)
end)

premake.override(premake.main, "preBake", function(base)

    if zpm.loader and not zpm.util.isMainScriptDisabled() then

        zpm.loader.project.builder:walkDependencies()
    end
    return base()
end)