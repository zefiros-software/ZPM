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
                private = {}
            }
        }

        --print(table.tostring(self.solver.root:findDefinition(),2))
    else
        self.tree = tree
    end

    self.cursor = self.tree
    self.cursorPtr = {}

    self.indices = nil
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
        
            solution.tree.open.public = table.deepcopy(self.tree.open.public)
            solution.tree.open.private = table.deepcopy(self.tree.open.private)

            solution.tree.closed.public = table.deepcopy(self.tree.closed.public)
            solution.tree.closed.all = table.deepcopy(self.tree.closed.all)
    
            --local public = self:_extractPublicFromSolution(solved)
            --local private = self:_extractPrivateFromSolution(solved)        

            --local solution = Solution(self.solver, self.root, self)
        
            --print(table.tostring(private,1))        
            --print(table.tostring(public,1))

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
        table.insert(self.tree.closed.public, self.cursorPtr)
    elseif #self.tree.open.private > 0 then  
        self.cursorPtr = table.remove(self.tree.open.private,1)
        table.insert(self.tree.closed.private, self.cursorPtr)
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
    root.closed = {
        public = {},
        private = {}
    }

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
        tag = node.tag,
        hash = node.hash
    }
end

function Solution:extract()

    local result = {
        public = {},
        private = {}        
    }
    self:_extractDependencies(self.tree.private, result.private)
    self:_extractDependencies(self.tree.public, result.public)

    return result
end

function Solution:isComplete()

    return (#self.tree.open.public + #self.tree.open.private) == 0
end

function Solution:getCost()

    return 0
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
        
            if not self.cursor.private then
                self.cursor.public = {}
            end
            local ptr = zpm.util.concat(table.deepcopy(self.cursorPtr), {"public"})
            for i, d in ipairs(self.cursor.definition.public[type]) do
                self:_loadDependency(self.cursor.public, d, type, self.solver.loader[type])

                table.insert(self.tree.open.public, zpm.util.concat(table.deepcopy(ptr), {i}))
            end
        end
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

        for _, c in ipairs(self.tree.closed.public) do
            --print(table.tostring(self.tree,5))
            c = zpm.util.indexTable(self.tree, c)
            print(table.tostring(c,1), c, "2")
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


function Solution:_extractNode(node)

    local result = {
        public = {},
        private = {}        
    }
    self:_extractDependencies(node.private, result.private)
    self:_extractDependencies(node.public, result.public)

    return result
end

function Solution:_extractDependencies(dependencies, result)
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
        
        local extract = self:_extractNode(d)
        local t = {
            name = d.package.fullName,
            --package = d.package,
            versionRequirement = d.versionRequirement,
            version = d.version,
            hash = d.hash,
            tag = d.tag,
            public =  extract.public,
            private = extract.private
        }
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