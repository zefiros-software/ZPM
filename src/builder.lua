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

    self.cache = {}
end

function Builder:walkDependencies()


    for _, type in ipairs(self.loader.manifests:getLoadOrder()) do
        local lazyLoading = self.loader.config({"install", "manifests", type, "lazyLoading"})
        if self:isEager(type) then
            self:_eagerLoad(type)
        end
    end
    
    zpm.meta.exporting = true


    self.solution:iterateDFS(function(node, type, parent, index)

        if node.projects then
            for name, proj in pairs(node.projects) do

                --print(name,"##############")
                if proj.workspaces then
            
                    local workspaces = table.deepcopy(proj.workspaces)
                    table.sort(workspaces)

                    
                    for _, wrkspace in ipairs(workspaces) do
                        filter {}
                        workspace(wrkspace)
                        project(name)

                        local prev = self.cursor
                        self.cursor = node

                        local oldKeys = {}
                        local foundNew = true
                        while foundNew do 
                            foundNew = false
                            if proj.uses and not table.isempty(proj.uses) then
                                local newUses = {}
                                local currentKeys = table.keys(proj.uses)
                                table.foreachi(currentKeys, function(key)                                
                                    if not table.contains(oldKeys, key) then
                                        newUses[key] = proj.uses[key]
                                        foundNew = true
                                    end
                                end)

                                self:_importUses(newUses, proj, node, name, wrkspace, parent) 

                                oldKeys = currentKeys
                            end
                        end
                    
                        self:_links(proj.links, node.exportLinks, proj, node, name, wrkspace, parent)      
                        
                        self.cursor = prev          
                    end
                end    
            end
        end
    end, true)


    self.solution:iterateDFS(function(node)

        if node.projects then
            for name, proj in pairs(node.projects) do
                if proj.workspaces then
            
                    local workspaces = table.deepcopy(proj.workspaces)
                    table.sort(workspaces)
                    for _, wrkspace in ipairs(workspaces) do
                        filter {}
                        workspace(wrkspace)
                        project(name)
                        
                        if proj.uses then                    
                            local useNames = table.keys(proj)
                            table.sort(useNames)

                            for _, uname in ipairs(useNames) do

                                local index = {"publicExportFunctions", wrkspace, uname}
                                local exports = zpm.util.indexTable(node, index)
                                if exports then
                                    for _, func in ipairs(exports) do
                                        func()
                                    end
                                end
                            end
                        end
                    end
                end    
            end
        end
    end, true)
    

    local allDialects = {}
    self.solution:iterateDFS(function(node, type, parent, index)    

        if node.projects then
            for name, proj in pairs(node.projects) do
                if proj.workspaces then            
                    local workspaces = table.deepcopy(proj.workspaces)
                    for _, wrkspace in ipairs(workspaces) do
                        local dialects = iif(node['cppdialects'], node['cppdialects'], {})
                        dialects = zpm.util.concat(node['cppdialects'], iif(proj['cppdialects'], proj['cppdialects'], {}))
                        if #dialects > 0 then                        
                            table.sort(dialects, function(a,b)
                                return a:lower() > b:lower()
                            end)
                            table.insert(allDialects, dialects[1])
                        end           
                    end
                end    
            end
        end
    end, true)
    if #allDialects > 0 then                        
        table.sort(allDialects, function(a,b)
            return a:lower() > b:lower()
        end)
        self.solution:iterateDFS(function(node, type, parent, index)    

            if node.projects then
                for name, proj in pairs(node.projects) do
                    if proj.workspaces then            
                        local workspaces = table.deepcopy(proj.workspaces)
                        table.sort(workspaces)                    
                        for _, wrkspace in ipairs(workspaces) do
                            filter {}
                            workspace(wrkspace)
                            project(name)
                            zpm.cppdialect(allDialects[1])
                        end
                    end    
                end
            end
        end, true)
    end
    
    zpm.meta.exporting = false
end

function Builder:_importUses(uses, proj, node, name, wrkspace, parent)


    if uses and not table.isempty(uses) then

        local useNames = table.keys(uses)
        -- sort for deterministic anwsers
        table.sort(useNames)

        for _, uname in ipairs(useNames) do    

            local setParentExport = function(func)
                if parent then
                    local index = {"publicExportFunctions", wrkspace, node.name}
                    zpm.util.insertTable(parent, index, func)
                end
            end
        
            local uproj = uses[uname]
            --print(wrkspace, name, uname, uproj.package)
            if uproj.package then
                if uproj.package.projects then
                                
                    local iprojs = table.keys(uproj.package.projects)
                    -- sort for deterministic anwsers
                    table.sort(iprojs)
                    for _, iproj in ipairs(iprojs) do
                    
                        local func = self:_importPackage(iproj, uproj.package, uproj.package.projects[iproj], node, wrkspace)
                        setParentExport(func)
                    end
                end
            else
                if node.aliases and node.aliases[uname] then
                    local iproj = node.aliases[uname]
                    if node.projects and node.projects[iproj] then
                        local func = self:_importPackage(iproj, node, node.projects[iproj], node, wrkspace)
                        setParentExport(func)
                    end
                else
                    local wasOptional = false
                    if node.optionals and node.optionals["libraries"] then
                        for _, lib in ipairs(node.optionals["libraries"]) do
                            if lib.name == uname then
                                wasOptional = true
                                break
                            end
                        end
                    end

                    if not wasOptional then
                        if node.fullName then
                            warningf("%s is trying to use '%s' which is unknown to its definition.", node.fullName, uname)
                        else   
                            warningf("Trying to use '%s' which is unknown to its definition.", uname)
                        end
                    end
                end
            end
        end
    end
end

function Builder:_links(llinks, exportLinks, proj, node, name, wrkspace, parent)


    --print(name, table.tostring(llinks,2))

    if llinks and llinks then
        local linkNames = table.keys(llinks)
        -- sort for deterministic anwsers
        table.sort(linkNames)

        for _, lname in ipairs(linkNames) do

            
            local prevFilter = zpm.meta.filter
            filter(llinks[lname])

            if node.aliases and node.aliases[lname] then
                links(node.aliases[lname])
            else
                links(lname)
            end

            filter(prevFilter)
        end
    end

    
    if exportLinks and exportLinks[wrkspace] then
            
        local prevFilter = zpm.meta.filter
        filter {}

        local keys = table.keys(exportLinks[wrkspace])
        keys = table.difference(keys, {name})
        table.sort(keys)
        links(keys)

        --print(name, table.tostring(keys,2))

        filter(prevFilter)
    end
end

function Builder:build(package, type)

    local prev = self.cursor
    local extractDir = self.loader[type]:getExtractDirectory()
    local found = nil
    
    if not found then
        local faccess = nil
        for _, access in ipairs({"private"}) do
            local pkgs = zpm.util.indexTable(self.cursor,{access, type})
            if pkgs then
                for _, pkg in ipairs(pkgs) do
                    if pkg.name == package then          
                        found = self:buildPackage(pkg, package, type)
                        if found then
                            faccess = access
                            break
                        end
                    end
                end
            end
            if found then
                break
            end
        end
    end

    -- now search in the global package lists
    if not found and self.solution.tree.closed.public[type] and self.solution.tree.closed.public[type][package] then
        local node = self.solution.tree.closed.public[type][package]
        if node then
            found = self:buildPackage(node.node, package, type)
            faccess = "public"
        end
    end
    
    self.cursor = prev
    zpm.meta.package = self.cursor
    return found, faccess
end

function Builder:buildPackage(package, name, type)

    local found = package
    --print(zpm.meta.workspace, table.tostring(package.name), zpm.util.indexTable(self.settings, {zpm.meta.workspace, type, name}), "@")
    if not zpm.util.indexTable(self.settings, {zpm.meta.workspace, type, name}) then
        zpm.util.setTable(self.settings, {zpm.meta.workspace, type, name}, true)

        local prevGroup = zpm.meta.group
        local prevProject = zpm.meta.project
        local prevFilter = zpm.meta.filter
        local extractDir = self.loader[type]:getExtractDirectory()

        filter {}
        group(("Extern/%s"):format(package.name))
                        
        zpm.meta.package = package
            
        self.loader.project.cursor = package
        self.cursor = package
        self.cursor.bindir = path.join(extractDir, ".bin")
        self.cursor.objdir = path.join(extractDir, ".obj", package.hash:sub(0,5))
                   
        -- @todo: check if this is not too annoying
        if package.export and package.package:isTrusted() then
            zpm.sandbox.run(package.export, { env = self:getEnv(type), quota = false })
        else
            warningOncef("Package '%s' has no export defined, please check if has a correct .export.lua", package.name)
        end

        zpm.meta.building = true
        filter(prevFilter)
        project(prevProject)
        group(prevGroup)
        zpm.meta.building = false
    end

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

function Builder:_importPackage(name, package, proj, node, wrkspace)
           
    local pname = name
    local kind = proj.kind
    
    --[[
    -- this caching strategy is still buggy,
    -- for now just accept duplicates
    -- @todo
    if tostring(package) then
        local idx = {wrkspace, "uses", pname, tostring(node)}
        if zpm.util.indexTable(self.cache, idx) then
            return function() end
        end
        zpm.util.setTable(self.cache, idx, true)
    end
    --]]

    local childExports = table.deepcopy(zpm.util.indexTable(package.exportLinks, {wrkspace}))
    childExports = iif(childExports ~= nil, childExports, {})
    
    node.exportLinks = iif(node.exportLinks ~= nil, node.exportLinks, {})
    
    local localExports = table.deepcopy(zpm.util.indexTable(node.exportLinks, {wrskpace}))
    localExports = iif(localExports ~= nil, localExports, {})
    
    zpm.util.setTable(node.exportLinks, {wrkspace}, table.merge(localExports, childExports))
    zpm.util.setTable(node.exportLinks, {wrkspace, pname}, true)
    
    local funcs = table.deepcopy(proj.exportFunctions)
    
    if funcs then

        local export = function()
            if kind == "StaticLib" then        
                filter {}
                
                links(pname)
            end
            for _, func in ipairs(funcs) do
                filter {}
                
                func()
            end
        end

        export()
        return export
    end

    return function() end
end