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

Solution = newclass "Solution"

function Solution:init(solver, tree, cursor, cursorPtr)
       
    self.solver = solver
    if not self.root then
        self.root = self
    end
    
    if not tree then
        self.tree = {
            package = self.solver.root,
            public = {},
            private = {},
            open = {
                public = {{}},
                private = {}
            },
            closed = {
                public = {},
                all = {}
            }
        }
    else
        self.tree = tree
    end

    self.cursor = self.tree
    self.cursorPtr = {}

    self.indices = nil
end

function Solution:loadFromLock(lock)
     
    return self:_loadNodeFromLock(self.tree, self.tree, lock)
end

function Solution:_loadNodeFromLock(tree, node, lock)

    if not lock then
        return
    end
    
    local dpkgs = {}
    for _, access in ipairs({"public", "private"}) do
        node[access] = {}
        if lock[access] then
            for type, pkgs in pairs(lock[access]) do
                for _, pkg in pairs(pkgs) do

                    local vendor, name = zpm.package.splitName(pkg.name)
                    local package = self.solver.loader[type]:get(vendor, name)
                    package:load(pkg.hash)

                    local lnode = {                
                        package = package,
                        type = type,
                        name = pkg.name,
                        tag = pkg.tag,
                        version = pkg.version,
                        versionRequirement = pkg.versionRequirement,
                        hash = pkg.hash
                    }
                    table.insert(node[access], lnode)
                    zpm.util.insertTable(dpkgs, {access, type, pkg.name}, iif(pkg.version == nil, pkg.tag, pkg.version))

                    if not self:_loadNodeFromLock(tree, lnode, pkg) then
                        return false
                    end

                    local index = {type, package:getHash(), pkg.tag}
                    local semver = nil
                    if pkg.version then
                        semver = zpm.semver(pkg.version)
                    end
                    zpm.util.setTable(self.tree.closed.all, index, package:getCost({
                        tag = pkg.tag,
                        version = pkg.version,
                        semver = semver,
                        hash = pkg.hash                    
                    }))
                end      
            end
        end
    end

    
    for _, access in ipairs({"public", "private"}) do
        -- check whether the lockfile version is a complete solution
        local definition = node.package:findPackageDefinition(lock.hash)
        if definition and definition[access] then
            for ptype, pubs in pairs(definition[access]) do
                for _, pub in ipairs(pubs) do
                    if zpm.util.indexTable(dpkgs, {access, ptype, pub.name}) then  
                        local vcheckFailed = false
                        local lversion
                        for _, version in ipairs(dpkgs[access][ptype][pub.name]) do
                            lversion = version
                            if pub.version and not premake.checkVersion(version, pub.version) then
                                vcheckFailed = true
                            end
                        end

                        if vcheckFailed then
                            warningf("Package '%s' by '%s' locked on version '%s' does not match '%s'", pub.name, node.package.name, lversion, pub.version)
                            return false
                        end
                    else
                        warningf("Package '%s' required by '%s' missing in lockfile", pub.name, node.name)
                        return false
                    end
                end
            end
        end
    end
    return true
end

function Solution:isOpen()

    return self.indices ~= nil
end

function Solution:expand(best, beam)
    
    local solutions = {}

    while true do
        
        if not self:isOpen() then
            self:nextCursor()
            self:load()
        end

        local versions = self:_enumerateVersions()
        
        local l = self:_carthesian(table.deepcopy(versions), beam)
        for _, solved in ipairs(l) do
    
            for i=1,#self.cursor.private do
                self.cursor.private[i].tag = solved[i].tag
                self.cursor.private[i].version = solved[i].version
                self.cursor.private[i].hash = solved[i].hash
            end
    
            for i=1,#self.cursor.public do
                self.cursor.public[i].tag = solved[#self.cursor.private + i].tag
                self.cursor.public[i].version = solved[#self.cursor.private + i].version
                self.cursor.public[i].hash = solved[#self.cursor.private + i].hash
            end

            local tree = self:_copyTree()
            local solution = Solution(self.solver, tree)
    
            for i=1,#self.cursor.private do

                local index = {
                    self.cursor.private[i].type,
                    self.cursor.private[i].package:getHash(),
                    self.cursor.private[i].tag
                }

                zpm.util.setTable(solution.tree.closed.all, index, solved[i].cost)
            end
    
            for i=1,#self.cursor.public do

                local index = {
                    self.cursor.public[i].type,
                    self.cursor.public[i].package:getHash(),
                    self.cursor.public[i].tag
                }
                zpm.util.setTable(solution.tree.closed.all, index, solved[#self.cursor.private + i].cost)
                zpm.util.setTable(solution.tree.closed.public, index, solved[#self.cursor.private + i].cost)

            end
    

            table.insert(solutions, solution)
        end

        if #solutions ~= 0 or not self.cursorPtr then
            return solutions
        end
    end
end

function Solution:nextCursor()

    local ptr = nil
    if #self.tree.open.public > 0 then
        self.cursorPtr = table.remove(self.tree.open.public,1)
    elseif #self.tree.open.private > 0 then  
        self.cursorPtr = table.remove(self.tree.open.private,1)
    else
        self.cursorPtr = nil
    end

    if self.cursorPtr then
        self.cursor = zpm.util.indexTable(self.tree, self.cursorPtr)
        self.indices = nil
    end
end

function Solution:_copyTree()

    local root = self:_copyNode(self.tree)
    root.open = table.deepcopy(self.tree.open)
    root.closed = table.deepcopy(self.tree.closed)

    return root
end

function Solution:_copyNode(node)

    local public = {}
    local private = {}
    
    if node.public then
        for _, n in ipairs(node.public) do
            table.insert(public, self:_copyNode(n))
        end
    end
    if node.private then 
        for _, n in ipairs(node.private) do
            table.insert(private, self:_copyNode(n))
        end
    end

    return {
        package = node.package,
        public = public,
        private = private,
        type = node.type,
        name = node.name,
        version = node.version,
        versionRequirement = node.versionRequirement,
        tag = node.tag,
        hash = node.hash
    }
end

function Solution:extract(isLock)
    if isLock == nil then
        isLock = isLock
    end
    return self:_extractNode(self.tree, isLock)
end

function Solution:isComplete()

    return (#self.tree.open.public + #self.tree.open.private) == 0
end

function Solution:getCost()

    local cost = 0
    for type, libs in pairs(self.tree.closed.all) do
        for _, lib  in pairs(libs) do
            for _, v in pairs(lib) do
                cost = cost + v
            end
        end
    end
    return cost
end

function Solution:load()


    self.cursor.definition = self.cursor.package:findPackageDefinition(self.cursor.tag)

    for _, type in ipairs(self.solver.loader.manifests:getLoadOrder()) do

        if self.cursor.definition.private and self.cursor.definition.private[type] then
            
            if not self.cursor.private then
                self.cursor.private = {}
            end
            local ptr = zpm.util.concat(table.deepcopy(self.cursorPtr), {"private"})
            for i, d in ipairs(self.cursor.definition.private[type]) do
                self:_loadDependency(self.cursor.private, d, type, self.solver.loader[type])

                table.insert(self.tree.open.private, zpm.util.concat(table.deepcopy(ptr), {i}))
            end
        end
    
        if self.cursor.definition.public and self.cursor.definition.public[type] then
        
            if not self.cursor.public then
                self.cursor.public = {}
            end
            local ptr = zpm.util.concat(table.deepcopy(self.cursorPtr), {"public"})
            for i, d in ipairs(self.cursor.definition.public[type]) do
                self:_loadDependency(self.cursor.public, d, type, self.solver.loader[type])

                table.insert(self.tree.open.public, zpm.util.concat(table.deepcopy(ptr), {i}))
            end
        end
    end            
    if not self.cursor.private then
        self.cursor.private = {}
    end
    if not self.cursor.public then
        self.cursor.public = {}
    end
end

function Solution:_loadDependency(cursor, d, type, loader)

    local vendor, name = zpm.package.splitName(d.name)
    local dependency = {
        name = d.name,
        versionRequirement = d.version,
        package = loader:get(vendor, name),
        type = type
    }

    dependency.package:load()

    table.insert(cursor, dependency)

    return dependency
end

function Solution:_enumerateVersions()

    local pubVersions = self:_enumeratePublicVersions()
    if pubVersions then
        return zpm.util.concat(self:_enumeratePrivateVersions(), pubVersions)
    end

    return nil
end

function Solution:_enumeratePublicVersions()

    local pubVersions = {}
    for _, d in ipairs(self.cursor.public) do
    
        --print(table.tostring(self.tree.closed,10), "@")
        for _, c in ipairs(self.tree.closed.public) do
            c = zpm.util.indexTable(self.tree, c)
            if d.package == c.package then
                if premake.checkVersion(c.version, d.versionRequirement) then
                    table.insert(pubVersions, {c.version})
                else
                    return nil
                end
            end
        end 

        local vs = d.package:getVersions(d.versionRequirement)
        if table.isempty(vs) then
            return nil
        else
            table.insert(pubVersions, vs)
        end
    end

    return pubVersions
end

function Solution:_enumeratePrivateVersions()

    local privVersions = {}
    for _, d in ipairs(self.cursor.private) do
        local vs = d.package:getVersions(d.versionRequirement)
        if table.isempty(vs) then
            return {}
        else
            table.insert(privVersions, vs)
        end
    end

    return privVersions
end


function Solution:_extractNode(node, isLock)

    local result = {
        public = {},
        private = {}        
    }
    self:_extractDependencies(node.private, result.private, isLock)
    self:_extractDependencies(node.public, result.public, isLock)

    if table.isempty(result.public) then
        result.public = nil
    end
    if table.isempty(result.private) then
        result.private = nil
    end

    return result
end

function Solution:_extractDependencies(dependencies, result, isLock)

    if not dependencies then
        return
    end

    for _, d in ipairs(dependencies) do
        local c = result
        if d.type then
            if not result[d.type] then
                result[d.type] = {}
            end
            c = result[d.type]
        end
        
        local extract = self:_extractNode(d, isLock)
        local t = {
            name = d.package.fullName,
            versionRequirement = d.versionRequirement,
            version = d.version,
            hash = d.hash,
            tag = d.tag,
            public =  extract.public,
            private = extract.private
        }
        if not isLock then
            t.package = d.package
        end
        table.insert(c, t)
    end
end

function Solution:_carthesian(lists, amount)

    if #lists == 0 then
        return {}
    end

    if not self.indices or table.isempty(self.indices) then
        indices = {}
        for i=1,#lists do 
            table.insert(indices, 1)
        end        
    else
        indices = table.deepcopy(self.indices)
    end

    local abort = false
    local result = {}
    while #result < amount and not abort do
        local l = {}
        for list,i in zpm.util.zip(lists, indices) do
            table.insert(l, list[i])
        end

        table.insert(result,l)

        local j = #indices
        while true do
            indices[j] = indices[j] + 1
            if indices[j] <= #lists[j] then
                break
            end

            indices[j] = 1
            j = j - 1

            if j <= 0 then
                abort = true
                indices = nil
                j = 1
                break
            end

        end
    end
    self.indices = indices

    return result
end