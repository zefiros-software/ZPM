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
    self.cursor = self.solution.tree
    self.settings = {}

    -- provide missing information
    -- which is not in our solution yet
    self.cursor.location = _WORKING_DIR
    zpm.meta.package = self.cursor
end

function Builder:walkDependencies()


    for _, type in ipairs(self.loader.manifests:getLoadOrder()) do
        local lazyLoading = self.loader.config({"install", "manifests", type, "lazyLoading"})
        if self:isEager(type) then
            self:_eagerLoad(type)
        end
    end
    
    zpm.meta.exporting = true

    self.solution:iterateDFS(function(node, type)

        if node.projects then
            for name, proj in pairs(node.projects) do
                if proj.workspaces then
            
                    for _, wrkspace in ipairs(proj.workspaces) do
           
                        filter {}
                        workspace(wrkspace)
                        project(name)
                
                        if proj.uses then
                    
                            local useNames = table.keys(proj.uses)
                            -- sort for deterministic anwsers
                            table.sort(useNames)

                            for _, uname in ipairs(useNames) do
                                local uproj = proj.uses[uname]
                                if uproj.package then
                                    if uproj.package.projects then
                                
                                        local iprojs = table.keys(uproj.package.projects)
                                        -- sort for deterministic anwsers
                                        table.sort(iprojs)
                                        for _, iproj in ipairs(iprojs) do
                                            self:_importPackage(iproj, uproj.package.projects[iproj])
                                        end
                                    end
                                else
                                    if node.aliases and node.aliases[uname] then
                                        local iproj = node.aliases[uname]
                                        if node.projects and node.projects[iproj] then
                                            self:_importPackage(iproj, node.projects[iproj])
                                        end
                                    end
                                end
                            end
                        end
                    end
                end    
            end
        end
    end)
    
    zpm.meta.exporting = false
end

function Builder:build(package, type)

    local extractDir = self.loader[type]:getExtractDirectory()
    local prev = self.cursor
    local found = nil
    for _, access in ipairs({"private", "public"}) do
        local pkgs = zpm.util.indexTable(self.cursor,{access, type})
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

                        self.loader.project.cursor = pkg
                        self.cursor = pkg
                        self.cursor.bindir = path.join(extractDir, "@bin")
                        self.cursor.objdir = path.join(extractDir, "@obj", pkg.name, pkg.hash:sub(0,5))
                        
                        found = self.cursor

                        -- @todo: check if this is not too annoying
                        if pkg.package:isTrusted() then
                            zpm.sandbox.run(pkg.export, { env = self:getEnv(type), quota = false })
                        end

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
    zpm.meta.package = self.cursor

    return found
end

function Builder:isEager(type)

    local lazyLoading = self.loader.config({"install", "manifests", type, "lazyLoading"})
    return lazyLoading ~= nil and not lazyLoading
end

function Builder:_eagerLoad(type)

end


function Builder:getEnv(type, cursor)

    local cursor = iif(cursor == nil, self.cursor, cursor)
    return zpm.api.load(type, cursor)
end

function Builder:_importPackage(name, package)
           
    if package.kind == "StaticLib" then
        links(name)
    end
    if package.exportFunction then
        package.exportFunction()
    end
end