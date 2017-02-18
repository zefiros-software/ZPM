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

Config = newclass "Config"

function Config:init(loader)
    self.loader = loader
    self.values = { }
    self.configName = "config.json"
    self.globalConfig = path.join(_PREMAKE_DIR, "." .. self.configName)
end

function Config:load()

    -- these config files are loaded in inverse priority
    -- since each new key will override the old ones
    self:_loadOverideFile(_PREMAKE_DIR, configName)

    for _, p in ripairs(zpm.util.traversePath(_MAIN_SCRIPT_DIR)) do
        self:_loadOverideFile(p, configName)
    end

    self:_loadOverideFile(zpm.env.scriptPath())
end

function Config:set(key, value)

    local ok, json = pcall(zpm.json.decode, zpm.json, value)
    if ok then
        value = json
    end

    local cursor = self:__call(key, value)
    if cursor then
        self:_store(key, value)
        self:_print(key)
    else
        errorf( "Failed to find the complete key '%s', please run again with option '--parents' set to force creation", key )
    end
end

function Config:add(key, value)

    local ok, json = pcall(zpm.json.decode, zpm.json, value)
    if ok then
        value = json
    end

    local cursor = self:_findKey(self.values, key, function(cursor, key)
        table.insert(cursor[key], value)
        return cursor[key]
    end , true)

    if cursor then
        self:_store(key, value, true)
        self:_print(key)
    else
        errorf( "Failed to find the complete key '%s', please run again with option '--parents' set to force creation", key )
    end
end

function Config:get(key)

    self:_print(key)
end

function Config:_store(keys, value, add)

    add = iif(add ~= nil, add, false)
    -- we store in the user config
    local file = path.join(_PREMAKE_DIR, "." .. self.configName)

    local config = { }
    if os.isfile(file) then
        local ok, json = pcall(zpm.json.decode, zpm.json, zpm.util.readAll(file))
        if ok then
            config = json
        end
    end

    self:_findKey(config, keys, function(cursor, key)
        if add then
            table.insert(cursor[key], value)
        else
            cursor[key] = value
        end

        zpm.util.writeAll(self.globalConfig, zpm.json:encode_pretty(config))
    end , true)
end

function Config:_print(key)

    local c = self:_findKey(self.values, key, function(cursor, key)
        local c = iif(cursor[key] ~= nil, cursor[key], "")
        if type(c) == "table" then
            c = table.tostring(c, 4)
        end
        printf("\nValue '%s' is set to:\n%%{bright cyan}%s", key, c)
    end )
end

function Config:_loadFile(file)

    if not os.isfile(file) then
        return nil
    end

    local config = zpm.json:decode(zpm.util.readAll(file))
    self:_loadJSON(config)
end

function Config:_loadJSON(json)

    self.values = table.merge(json, self.values)
end

function Config:_loadOverideFile(directory)

    self:_loadFile(path.join(directory, self.configName))
    self:_loadFile(path.join(directory, "." .. self.configName))
end

function Config:__call(key, value)

    return self:_findKey(self.values, key, function(cursor, key)
        if value ~= nil then
            cursor[key] = value
        end
        return cursor[key]
    end )
end

function Config:_findKey(tab, key, func, ensureTable)

    ensureTable = iif(ensureTable ~= nil, ensureTable, false)
    local sep = key:explode("%.")
    local cursor = tab
    for i, key in ipairs(sep) do
        if i == #sep then
            if ensureTable then
                if not cursor[key] then
                    cursor[key] = { }
                elseif type(cursor[key]) ~= "table" then
                    cursor[key] = { cursor[key] }
                end
            end
            
            return func(cursor, key)
        end

        if _OPTIONS["parents"] and not cursor[key] then
            cursor[key] = {}
        end

        if cursor[key] then
            if i == #sep then
                return cursor[key]
            else
                cursor = cursor[key]
            end
        else
            return nil
        end
    end

    return nil
end