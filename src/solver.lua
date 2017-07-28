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


function Solver:solve(lock)

    local cost, heuristic, succeeded = math.huge, nil, false
    local hasInitial = false
    if lock ~= nil then
        heuristic = self:getRootSolution()
        if heuristic:loadFromLock(lock) then
            cost = heuristic:getCost()    
            hasInitial = true
        else
            noticef("Current lockfile is invalid, generating a fresh one")
        end
    end
    if not hasInitial then
        -- do an initial DFS biased pass to get an upper bound
        local rootSolution = self:getRootSolution()

        local stack = Stack()
        stack:put(rootSolution,rootSolution:getCost())
        cost, heuristic, succeeded = self:_branchAndBound(stack, math.huge, nil, 10, false, true)
    end
    
    if (zpm.cli.update() or not lock) and (succeeded or hasInitial) then
    
        noticef("Optimising dependencies")
        -- use a BFS method to optimise
        local queue = Queue()
        local rootSolution = self:getRootSolution()
        queue:put(rootSolution,rootSolution:getCost())
        cost, heuristic, succeeded = self:_branchAndBound(queue, cost, heuristic, 50)
    end

    return cost, heuristic, succeeded
end

function Solver:_branchAndBound(container, b, best, beam, useCompleteSpace, returnFirst)

    if useCompleteSpace == nil then
        useCompleteSpace = true
    end
    if returnFirst == nil then
        returnFirst = false
    end

    --local rejected = 0
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

                if returnFirst then
                    break
                end
            end
        else
            --print(cost, b)
            --rejected = rejected + 1
        end

        if container:getSize() == 0 and openSolutions:getSize() > 0 then
            if useCompleteSpace or not best:isComplete() then
                local nextSolution, cost = openSolutions:pop()
                container:put(nextSolution, cost)
            else
                -- we found a complete solution and only search our beam
                -- not the complete space
                break
            end
        end
    end

    --print(rejected)
    return b, best, (best and best:isComplete())
end

function Solver:getRootSolution()

    return Solution(self, nil, nil)
end
