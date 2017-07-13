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
 
function interactf(...)
    print(zpm.colors("%{cyan bright}" .. string.format(...)), zpm.colors("%{reset}"))
end
 
function noticef(...)
    print(zpm.colors("%{yellow}" .. string.format(...)), zpm.colors("%{reset}"))
end
 
function errorf(...)
    error(zpm.colors("%{red bright}" .. string.format(...)) .. zpm.colors("%{reset}"))
end
 
function cprintf(cond, ...)
    if cond then
        print(zpm.colors(string.format(...)), zpm.colors("%{reset}"))
    end
end
 
function cwarningf(cond, ...)
    if cond then
        print(zpm.colors("%{magenta bright}" .. string.format(...)), zpm.colors("%{reset}"))
    end
end
 
function cinteractf(cond, ...)
    if cond then
        print(zpm.colors("%{cyan bright}" .. string.format(...)), zpm.colors("%{reset}"))
    end
end
 
function cnoticef(cond, ...)
    if cond then
        print(zpm.colors("%{yellow}" .. string.format(...)), zpm.colors("%{reset}"))
    end
end
 
function cerrorf(cond, ...)
    if cond then
        error(zpm.colors("%{red bright}" .. string.format(...)) .. zpm.colors("%{reset}"))
    end
end

function zpm.sassert(pred, str, ...)
    if not pred then
        if zpm.cli.verbose() then
            assert(pred, string.format(str, ...) .. "\n" .. debug.traceback())
        else
            assert(pred, string.format(str, ...))
        end
    end
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

function zpm.util.indexTable(tab, arr)

    local cursor = tab
    for i=1,#arr do
        if cursor then
            cursor = cursor[arr[i]]
        else
            return nil
        end
    end
    return cursor
end

function zpm.util.disableMainScript()

    _MAIN_SCRIPT = ""
end

function zpm.util.isMainScriptDisabled()

    return _MAIN_SCRIPT == ""
end

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

function zpm.util.isArray(t)

    if not t or type(t) ~= "table" then
        return false
    end

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
    local str2 = str:match("(https://.*%.git).*")
    if str2 == nil then
        return str:match("(git@.*%.git).*")
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

function zpm.util.hideProtectedFile(file)

    local hash = os.uuid()
    local dir = path.join(zpm.loader.temp, hash)
    local fileh = path.join(dir, hash)

    zpm.assert(os.mkdir(dir), "The archive directory could not be made!")
    zpm.assert(os.rename(file, fileh))

    return fileh
end

function zpm.util.getRelativeOrAbsoluteDir( root, dir )

    if dir and path.getabsolute(dir) == dir then
        return dir
    end

    return path.join(root, dir)
end

function zpm.util.isAlphaNumeric(str)
    return str == str:gsub("[^[%w-_]]*", "")
end

function zpm.util.reverse(tbl)

	local len = #tbl
	local ret = {}

	for i = len, 1, -1 do
		ret[ len - i + 1 ] = tbl[ i ]
	end

	return ret

end

function zpm.util.concat(t1, t2)
    if type(t1) ~= "table" then
        t1 = {t1}
    end

    if type(t2) ~= "table" then
        t2 = {t2}
    end
    for i = 1, #t2 do
        t1[#t1 + 1] = t2[i]
    end
    return t1
end

function zpm.util.patternMatch(str, pattern)
    return str:match(path.wildcards(pattern))
end

function zpm.util.split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

function zpm.util.rmdir(folder)

    if os.ishost("windows") then
        os.executef("del /f/s/q \"%s\" > NUL", folder)
        os.executef("rmdir /s/q \"%s\" > NUL", folder)
    else
        os.executef("rm -rf \"%s\"", folder)
    end

end

function zpm.util.getExecutable(file)

    return iif(os.is("windows"), file .. ".exe", file)
end

function zpm.util.mergeAppend(...)
		  local result = {}
		  local arg = {...}
		  for _,t in ipairs(arg) do

			     if type(t) == "table" then
				        for k,v in pairs(t) do
					           if zpm.util.isArray(result[k]) and zpm.util.isArray(v) then
                    result[k] = zpm.util.concat(result[k], v)
                elseif type(result[k]) == "table" and type(v) == "table" then
						              result[k] = table.merge(result[k], v)
					           else
						              result[k] = v
					           end
            end
			     else
				        error("invalid value")
			     end
		  end

		  return result
	end

function zpm.util.toArray(t1)

		  local result = {}
    for name, ext in pairs(t1) do
        local obj = {}
        obj[name] = ext
        table.insert(result, obj)
    end

    return result
end

function zpm.util.setTable(tab, index, value)

    local cursor = tab
    for i=1,#index do
        if cursor[index[i]] then
            cursor = cursor[index[i]]
        elseif i == #index then
            cursor[index[i]] = value
        else
            cursor[index[i]] = {}
            cursor = cursor[index[i]]
        end
    end
    return cursor
end

function zpm.util.insertTable(tab, index, value)

    local cursor = tab
    for i=1,#index do
        if cursor[index[i]] then
            cursor = cursor[index[i]]
        elseif i == #index then
            if not cursor[index[i]] then
                cursor[index[i]] = {}
            end
            table.insert(cursor[index[i]], value)
        else
            cursor[index[i]] = {}
            cursor = cursor[index[i]]
        end
    end
    return cursor
end

function zpm.util.zip(...)
  local arrays, ans = {...}, {}
  local index = 0
  return
    function()
      index = index + 1
      for i,t in ipairs(arrays) do
        if type(t) == 'function' then ans[i] = t() else ans[i] = t[index] end
        if ans[i] == nil then return end
      end
      return table.unpack(ans)
    end
end

function zpm.util.shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function zpm.util.recurseMkdir(p)

    local dir = iif(p:startswith("/"), "/", "")
    for part in p:gmatch("[^/]+") do
        dir = dir .. part

        if part ~= "" and not path.isabsolute(part) and not os.isdir(dir) then
            local ok, err = os.mkdir(dir)
            if not ok then
				            return nil, err
            end
        end

        dir = dir .. "/"
    end

    return true
end

function zpm.util.trim(s)
  return s:match'^%s*(.*%S)' or ''
end


function zpm.util.tostring(tab, recurse, indent)
    local res = ''

    if not indent then
        indent = 0
    end

    local format_value = function(k, v, i)
        formatting = ""
        for j = 0, i, 1 do
            formatting = formatting .. "\t"
        end

        if k then
            if type(k) == "table" then
                k = '[table]'
            end
            formatting = formatting .. k .. ": "
        end

        if not v then
            return formatting .. '(nil)'
        elseif type(v) == "table" then
            if recurse and recurse > 0 then
                return formatting .. '\n' .. zpm.util.tostring(v, recurse - 1, i + 1)
            else
                return formatting .. "<table>"
            end
        elseif type(v) == "function" then
            return formatting .. tostring(v)
        elseif type(v) == "userdata" then
            return formatting .. "<userdata>"
        elseif type(v) == "boolean" then
            if v then
                return formatting .. 'true'
            else
                return formatting .. 'false'
            end
        else
            return formatting .. v
        end
    end

    if type(tab) == "table" then
        local first = true

        -- add the meta table.
        local mt = getmetatable(tab)
        if mt then
            res = res .. format_value('__mt', mt, indent)
            first = false
        end

        -- add all values.
        for k, v in pairs(tab) do
            if not first then
                res = res .. '\n'
            end

            res = res .. format_value(k, v, indent)
            first = false
        end
    else
        res = res .. format_value(nil, tab, indent)
    end

    return res
end