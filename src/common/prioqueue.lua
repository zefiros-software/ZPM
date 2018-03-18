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

PriorityQueue = newclass "PriorityQueue"

function PriorityQueue:init()
    self.size = 0
    self.values = {}
end

function PriorityQueue:getSize()
    
    return self.size
end

function PriorityQueue:put(v, p)
    local q = self.values[p]
    if not q then
        q = {first = 1, last = 0}
        self.values[p] = q
    end
    q.last = q.last + 1
    q[q.last] = v

    self.size = self.size + 1
end

function PriorityQueue:pop()
    for p, q in pairs(self.values) do
        if q.first <= q.last then
            local v = q[q.first]
            q[q.first] = nil
            q.first = q.first + 1

            self.size = self.size - 1
            return v, p
        else

            self.values[p] = nil
        end
    end
end