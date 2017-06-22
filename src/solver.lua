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

Solver = newclass "Solver"

function Solver:init(loader, root)

    self.loader = loader
    self.root = root
end

function Solver:solve()

    local rootSolution = self:getRootSolution(self.root)
    local stack = Stack()
    stack:put(rootSolution,rootSolution:getCost())

    local c, heuristic = self:_branchAndBound(stack, math.huge, nil, 50)
    
    -- solve again given the previous upperbound
    --local queue = PriorityQueue()
    --queue:put(rootSolution,rootSolution:getCost())
    --local b, best = self:_branchAndBound(stack, c, heuristic)

    
    print(table.tostring(heuristic:extract(), 10))

    os.writefile_ifnotequal(json.encode_pretty(heuristic:extract()), path.join(_WORKING_DIR,"zpm.lock"))
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
        --print(cost, "@@@@@@@@@@@@@")

        --print(table.tostring(nextSolution.tree.closed,5))
        if cost < b then            
            local expanded = nextSolution:expand(b, beam)
            if #expanded > 0 then
                for _, n in ripairs(expanded) do
                    local ncost = n:getCost()
                    if ncost <= b then
                        container:put(n, ncost)
                    end
                end
            end

            if nextSolution:isOpen() then
                openSolutions:put(nextSolution, cost)
            end

            if nextSolution:isComplete() then
                b = cost
                best = nextSolution
            end
        end

        if container:getSize() == 0 and openSolutions:getSize() > 0 then
            local nextSolution, cost = openSolutions:pop()
            container:put(nextSolution, cost)
        end
    end

    return b, best
end

function Solver:getRootSolution(package)

    local solution = Solution(self, nil, nil)
    --solution:load()
    return solution
end
