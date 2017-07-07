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

Builder = newclass "Builder"

function Builder:init(loader, solution)

    self.loader = loader
    self.solution = solution
    self.cursor = self.solution
    self.settings = {}
end

function Builder:walkDependencies()
    
    zpm.meta.exporting = true
    self:_walkDependency(self.solution)
end

function Builder:_walkDependency(cursor)

    for _, access in ipairs({"private", "public"}) do
        for _, type in ipairs(self.loader.manifests:getLoadOrder()) do
            local pkgs = zpm.util.indexTable(cursor,{access, type})
            if pkgs then
                for _, pkg in ipairs(pkgs) do
                    self:_walkDependency(pkg)
                end
            end
        end
    end

    filter {}
    if cursor.projects then
        for name, proj in pairs(cursor.projects) do
            if proj.workspaces then
                for _, wrkspace in ipairs(proj.workspaces) do
           
                    workspace(wrkspace)
                    project(name)
                
                    if proj.uses then
                        for uname, uproj in pairs(proj.uses) do     
                            if uproj.package then
                                if uproj.package.projects then
                                    for iproj, ipackage in pairs(uproj.package.projects) do
                                        self:_importPackage(iproj, ipackage)
                                    end
                                end
                            else
                                if cursor.aliases and cursor.aliases[uname] then
                                    local iproj = cursor.aliases[uname]
                                    if cursor and cursor.projects and cursor.projects[iproj] then
                                        self:_importPackage(iproj, cursor.projects[iproj])
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function Builder:_importPackage(name, package)
           
    if package.kind == "StaticLib" then
        links(name)
    end
    if package.exportFunction then
        package.exportFunction()
    end
end

function Builder:build(package, type)

    local extractDir = self.loader[type]:getExtractDirectory()
    local prev = self.cursor
    local found = nil
    for _, access in ipairs({"private", "public"}) do
        local pkgs = zpm.util.indexTable(self.solution,{access, type})
        if pkgs then
            for _, pkg in ipairs(pkgs) do
                if pkg.name == package and not zpm.util.indexTable(self.settings, {zpm.meta.workspace, type, package}) then
                    zpm.util.setTable(self.settings, {zpm.meta.workspace, type, package}, true)
                    
                    if pkg.export then
                        local prevGroup = zpm.meta.group
                        local prevProject = zpm.meta.project
                        local prevFilter = zpm.meta.filter

                        filter {}
                        group(("Extern/%s"):format(pkg.name))
                        
                        zpm.meta.package = pkg

                        self.cursor = pkg
                        self.cursor.bindir = path.join(extractDir, "@bin")
                        self.cursor.objdir = path.join(extractDir, "@obj", pkg.name, pkg.hash)
                        
                        found = self.cursor

                        zpm.sandbox.run(pkg.export, { env = self:getEnv(type), quota = false })
                        
                        zpm.meta.building = true
                        filter(prevFilter)
                        project(prevProject)
                        group(prevGroup)
                        zpm.meta.building = false

                        break
                    end
                end
            end
        end
        if found then
            break
        end
    end
    self.cursor = prev

    return found
end

function Builder:getEnv(type, cursor)

    local cursor = iif(cursor == nil, self.cursor, cursor)
    return zpm.api.load(type, cursor)
end
