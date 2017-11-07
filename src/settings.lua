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

zpm.settings = {
    reduce={}
}

function zpm.settings.reduce.first(conflicts)

    return conflicts[1]
end

function zpm.settings.reduce.last(conflicts)

    return conflicts[#conflicts]
end

function zpm.settings.reduce.anyTrue(conflicts)

    for _, c in ipairs(conflicts) do
        if c then
            return true
        end
    end
    return false 
end

function zpm.settings.reduce.anyFalse(conflicts)

    for _, c in ipairs(conflicts) do
        if not c then
            return true
        end
    end
    return false
end

function zpm.settings.reduce.allTrue(conflicts)
    
    local all = true
    for _, c in ipairs(conflicts) do
        all = all and c
    end
    return all
end

function zpm.settings.reduce.allFalse(conflicts)

    local all = true
    for _, c in ipairs(conflicts) do
        all = all and not c
    end
    return all
end