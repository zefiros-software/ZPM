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
 
function printf(...)
    print(zpm.colors(string.format(...)), zpm.colors("%{reset}"))
end
 
function warningf(...)
    print(zpm.colors("%{magenta bright}" .. string.format(...)), zpm.colors("%{reset}"))
end
 
function errorf(...)
    error(zpm.colors("%{red bright}" .. string.format(...)) .. zpm.colors("%{reset}"))
end

function zpm.assert(pred, str, ...)
    if next( { ...}) then
        assert(pred, zpm.colors("%{bright red}" .. string.format(str, ...) .. "\n" .. debug.traceback() .. "%{reset}"))
    else
        if str ~= nil then
            assert(pred, zpm.colors("%{bright red}" .. str .. "\n" .. debug.traceback() .. "%{reset}"))
        else
            assert(pred)
        end
    end
end

function ripairs(t)
    local function ripairs_it(t, i)
        i = i - 1
        local v = t[i]
        if v == nil then return v end
        return i, v
    end
    return ripairs_it, t, #t + 1
end


zpm.util = { }

function zpm.util.readAll(file)

    zpm.assert(os.isfile(file), "'%s' does not exist", file)

    local f = io.open(file, "rb")
    local content = f:read("*all")
    f:close()

    return content
end

function zpm.util.writeAll(file, str)

    local f = io.open(file, "wb")
    f:write(str)
    f:close()

    zpm.assert(os.isfile(file), "'%s' failed to write", file)
end

function zpm.util.traversePath(dir)
    local bases = { }
    local p = path.normalize(path.join(dir, traverse))
    while p ~= "" do
        table.insert(bases, p)
        p = path.normalize(path.join(p, "../"))
    end
    return bases
end

function zpm.util.isArray(tab)
    local i = 0
    for _ in pairs(t) do
        i = i + 1
        if t[i] == nil then 
            return false
        end
    end
    return true
end 

function zpm.util.getGitUrl(str)
    local str2 = str:match("(https://.*\.git).*")
    if str2 == nil then
        return str:match("(ssh://git@.*\.git).*")
    end

    return str2
end

function zpm.util.isGitUrl(str)
    return str == zpm.util.getGitUrl(str)
end

function zpm.util.hasGitUrl(str)
    return zpm.util.getGitUrl(str) ~= nil
end

function zpm.util.hasUrl(str)
    return str:match(".*(https?://).*") ~= nil
end