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

premake.override(path, "normalize", function(base, p)

    if not zpm.util.hasGitUrl(p) and not zpm.util.hasUrl(p) then
        return base(p)
    end

    return p
end )


premake.override(premake.tools.gcc, "getcxxflags", function(base, cfg)
   
    local cxx = base(cfg)
    if table.contains(cxx, "-std=c++14" ) then
        local i = table.indexof(cxx, "-std=c++11" )
        if i then
            cxx[i] = nil
        end
    end
    return table.filterempty(cxx)

end)

premake.override(premake.tools.clang, "getcxxflags", function(base, cfg)
   
    local cxx = base(cfg)
    if table.contains(cxx, "-std=c++14" ) then
        local i = table.indexof(cxx, "-std=c++11" )
        if i then
            cxx[i] = nil
        end
    end
    return table.filterempty(cxx)

end)

local builtWorkspaces = { }

zpm._workspaceCache = nil
premake.override(_G, "workspace", function(base, ...)

    local wkspc = base(...)
    if select("#", ...) > 0 then

        local name = select(1, ...)
        zpm._workspaceCache = name

        if table.contains(builtWorkspaces, name) then
            return wkspc
        end

        table.insert(builtWorkspaces, name)
        zpm.buildLibraries()
    end

    -- return to workspace
    base()

    return wkspc
end )
    
-- small hack so the first user defined project is the startup project
zpm._projectFirstCache = { }
premake.override(_G, "project", function(base, proj)

    zpm.__currentProject = proj
    local val = base(proj)

    if proj ~= nil and zpm.build._isBuilding == false and zpm._workspaceCache ~= nil and zpm._projectFirstCache[zpm._workspaceCache] == nil then
        zpm._projectFirstCache[zpm._workspaceCache] = { }
        workspace()
        startproject(proj)
        base(val.name)
    end

    if proj ~= nil and zpm.build._isRoot then
        if zpm.packages.root.projects == nil then
            zpm.packages.root.projects = { }
        end

        if zpm.packages.root.projects[val.name] == nil then
            zpm.packages.root.projects[val.name] = { }
        end
    end

    return val
end )

premake.override(_G, "kind", function(base, knd)

    base(knd)
    if zpm.build._isRoot then
        zpm.packages.root.projects[zpm.__currentProject].kind = knd
    end
end )

premake.override(os, "execute", function(base, exec)

    if _OPTIONS["verbose"] then
        print(exec)
    end
    base(exec)
end )