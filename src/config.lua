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
    self.mayStore = false
    self.storeFile = path.join(zpm.env.getDataDirectory(), "." .. self.configName)
    self.printf = printf

    self.__loadedFiles = {}
end

function Config:load()

    -- these config files are loaded in inverse priority
    -- since each new key will override the old ones
    self:_loadOverideFile(_PREMAKE_DIR, configName)

    self:_loadOverideFile(_MAIN_SCRIPT_DIR, configName)

    for _, p in ripairs(zpm.util.traversePath(zpm.env.getSrcDirectory())) do
        self:_loadOverideFile(p, configName)
    end

    self:_loadOverideFile(zpm.env.getScriptPath())
end

function Config:set(key, value, force)

    local ok, json = pcall(zpm.json.decode, zpm.json, value)
    if ok then
        value = json
    end

    local cursor = self:__call(key, value)
    if cursor then
        self:_store(key, value, false, force)
        if not force then
            return self:_print(key)
        end
    else
        errorf("Failed to find the complete key '%s', please run again with option '--parents' set to force creation", key)
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
        return self:_print(key)
    else
        errorf("Failed to find the complete key '%s', please run again with option '--parents' set to force creation", key)
    end
end

function Config:get(key)

    return self:_print(key)
end

function Config:_store(keys, value, add, force)

    if not self.mayStore and not force then
        return nil
    end

    add = iif(add ~= nil, add, false)
    local config = { }
    if os.isfile(self.storeFile) then
        local ok, json = pcall(zpm.json.decode, zpm.json, zpm.util.readAll(self.storeFile))
        if ok then
            config = json
        end
    end

    self:_findKey(config, keys, function(cursor, key)
        if add then
            table.insert(cursor[key], value)
        else
            if type(value) == "table" then
                cursor[key] = table.merge(cursor[key], value)
            else
                cursor[key] = value
            end
        end
        zpm.util.writeAll(self.storeFile, zpm.json:encode_pretty(config))
    end , true, true)

    -- reload to get the actual value  
    self.__loadedFiles = {}
    self:load()
end

function Config:_print(key)

    local str = ""
    local c = self:_findKey(self.values, key, function(cursor, k)
        local c = iif(cursor[k] ~= nil, cursor[k], "")
        if type(c) == "table" then
            c = table.tostring(c, 4)
        end
        str = string.format("\nValue '%s' is set to:\n%s", key, c)
    end )
    self.printf(str)
    return str
end

function Config:_loadFile(file)
    if not os.isfile(file) or table.contains(self.__loadedFiles, file) then
        return nil
    end

    local config = zpm.json:decode(zpm.util.readAll(file))
    self:_loadJSON(config)
    table.insert(self.__loadedFiles, file)
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

function Config:_findKey(tab, key, func, ensureTable, store)

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

        if (_OPTIONS["parents"] or store) and not cursor[key] then
            cursor[key] = { }
        end

        if cursor[key] then
            cursor = cursor[key]
        else
            return nil
        end
    end
end