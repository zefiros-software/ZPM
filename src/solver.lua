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

Node = newclass "Node"

function Node:init(root, parent, package)
       
    self.root = root
    self.parent = parent
    self.package = package
end

function Node:getCost()

    return 0
end

function Node:isComplete()
    
    return false
end

function Node:isOpen()
    
    return false
end

Solver = newclass "Solver"

function Solver:init(loader, root)

    self.loader = loader
    self.root = root
end

function Solver:solve()

    local rootPackage = self:getPackage(self.root)
    local rootNode = Node(rootPackage, nil, rootPackage)
    local stack = Stack()
    stack:put(rootNode,rootNode:getCost())

    local c, heuristic = self:_branchAndBound(stack, math.huge, nil, 1)
    
    -- solve again given the previous upperbound
    local queue = PriorityQueue()
    queue:put(rootNode,rootNode:getCost())
    self:_branchAndBound(stack, c, heuristic)

    
    print(table.tostring(rootPackage,3))
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

function Solver:expandNode(node, best, beam)

    return {}
end

function Solver:_branchAndBound(container, b, best, beam)

    local openNodes = Queue()

    while container:getSize() > 0 and openNodes:getSize() > 0 do
        local nextNode, cost = container:pop()

        if cost < b then
            if nextNode:isComplete() then
                b = cost
                best = nextNode
            else
                local expanded = self:expandNode(nextNode, b, beam)
                if #expanded > 0 then
                    for _, n in ipairs(expanded) do
                        local ncost = n:getCost()
                        if ncost <= b then
                            container:put(n, ncost)
                        end
                    end
                end

                if nextNode:isOpen() then
                    openNodes:put(nextNode)
                end
            end
        end

        if container:getSize() == 0 and openNodes:getSize() > 0 then
            container:put(nextNode)
        end
    end

    return b, best
end

function Solver:getPackage(package)

    if not package:isDefinitionRepo() then
        return package:findPackage()
    end
end
