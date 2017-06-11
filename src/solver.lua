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

function Solution:init(solver, root, parent)
       
    self.solver = solver
    self.root = root
    self.parent = parent

    if not self.root then
        self.root = self
    end

    self.indices = nil

    self.privateDependencies = {}
    self.publicDependencies = {}

    self.openPrivate = {}
    self.openPublic = {}

    self.closedPublic = {}
end

function Solution:load(package)

    for _, type in ipairs(self.solver.loader.manifests:getLoadOrder()) do
    
        if package[type] then
            for _, d in ipairs(package[type]) do
                local dep = self:_loadDependency(self.privateDependencies, d, type, self.solver.loader[type])
                table.insert(self.openPrivate, dep)
            end
        end
    
        if package.public and package.public[type] then
            for _, d in ipairs(package.public[type]) do
                local dep = self:_loadDependency(self.publicDependencies, d, type, self.solver.loader[type])
                table.insert(self.openPublic, dep)
            end
        end
    end
end

function Solution:expandSolution(best, beam)

    local versions = self:_enumerateVersions()

    local l = self:_carthesian(versions, beam)

    local solutions = {}
    for _, solved in ipairs(l) do
    
        local public = self:_extractPublic(solved)
        local private = self:_extractPrivate(solved)        

        local solution = Solution(self.solver, self.root, self)
        
        print(table.tostring(private,1))        
        print(table.tostring(public,1))

        table.insert(solutions, solution)
    end

    
    return solutions
end

function Solution:_extractPublic(solution)

    local public = {}
    for i=1,#self.openPublic do
        local o = {
            type = self.openPublic[i].type,
            name = self.openPublic[i].name,
            package = self.openPublic[i].package,
            version = solution[i + #self.openPrivate].version,
            tag = solution[i + #self.openPrivate].tag,
            hash = solution[i + #self.openPrivate].hash
        }
        table.insert(public, o)
    end

    return public
end

function Solution:_extractPrivate(solution)

    local private = {}
    for i=1,#self.openPrivate do
        local o = {
            type = self.openPrivate[i].type,
            name = self.openPrivate[i].name,
            package = self.openPrivate[i].package,
            version = solution[i].version,
            tag = solution[i].tag,
            hash = solution[i].hash
        }
        table.insert(private, o)
    end

    return private
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
    for _, d in ipairs(self.openPublic) do

        for _, c in ipairs(self.closedPublic) do
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
    for _, d in ipairs(self.openPrivate) do
        local vs = d.package:getVersions(d.versionRequirement)
        if table.isempty(vs) then
            return {}
        else
            table.insert(privVersions, vs)
        end
    end

    return privVersions
end

function Solution:_loadDependency(tab, d, type, loader)

    local dependency = {
        name = d.name,
        versionRequirement = d.version
    }
    dependency.type = type

    local mod = bootstrap.getModule(dependency.name)
    local vendor, name = mod[1], mod[2]

    local package = loader:get(vendor, name)
    package:load()

    dependency.package = package

    table.insert(tab, dependency)

    return dependency
end

function Solution:getCost()

    return 0
end

function Solution:isComplete()
    
    return #self.openPrivate == 0 and #self.openPublic == 0
end

function Solution:isOpen()
    
    return self.indices ~= nil
end

function Solution:extract()

    return self:_extract(self.root)
end

function Solution:_extract(solution)

    local result = {
        private = {},
        public = {}
    }

    self:_extractDependencies(solution.privateDependencies, result.private)
    self:_extractDependencies(solution.publicDependencies, result.public)

    return {
        dependencies = result
    }
end

function Solution:_extractDependencies(dependencies, result)

    for _, d in ipairs(dependencies) do
        if not result[d.type] then
            result[d.type] = {}
        end
        
        table.insert(result[d.type], {
            name = d.package.fullName,
            package = d.package,
            --version = d.version,
            --dependencies = self:_extract(d)
        })
    end
end

function Solution:_carthesian(lists, amount)

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

Solver = newclass "Solver"

function Solver:init(loader, root)

    self.loader = loader
    self.root = root
end

function Solver:solve()

    local rootSolution = self:getRootSolution(self.root)
    local stack = Stack()
    stack:put(rootSolution,rootSolution:getCost())

    local c, heuristic = self:_branchAndBound(stack, math.huge, nil, 5)
    
    -- solve again given the previous upperbound
    --local queue = PriorityQueue()
    --queue:put(rootSolution,rootSolution:getCost())
    --local b, best = self:_branchAndBound(stack, c, heuristic)

    
    print(table.tostring(heuristic:extract(), 4))

    --[[
    for _, deps in ipairs(self.loader.manifests:getLoadOrder()) do
    
        if rootPackage[deps] and self.loader[deps] then

            for _, dep in pairs(rootPackage[deps]) do
                local mod = bootstrap.getModule(dep.name)
                local vendor, name = mod[1], mod[2]

                local package = self.loader[deps]:get(vendor, name)
                package:load()
            end
        end
    end]]
end

function Solver:_branchAndBound(container, b, best, beam)

    local openSolutions = Queue()
    while container:getSize() > 0 or openSolutions:getSize() > 0 do
        local nextSolution, cost = container:pop()
        if cost < b then
            if nextSolution:isComplete() then
                b = cost
                best = nextSolution
            else
                local expanded = nextSolution:expandSolution(b, beam)
                if #expanded > 0 then
                    for _, n in ipairs(expanded) do
                        local ncost = n:getCost()
                        if ncost <= b then
                            container:put(n, ncost)
                        end
                    end
                end

                if nextSolution:isOpen() then
                    openSolutions:put(nextSolution)
                end
            end
        end

        if container:getSize() == 0 and openSolutions:getSize() > 0 then
            container:put(nextSolution)
        end
    end

    return b, best
end

function Solver:getRootSolution(package)

    local rootPackage = nil

    if not package:isDefinitionRepo() then
        rootPackage = package:findPackage()
    end
    local solution = Solution(self, nil, nil)
    solution:load(rootPackage)
    return solution
end
