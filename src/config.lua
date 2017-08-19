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

function Config:init()

    self.values = { }
    self.configNames = {"config.yaml", "config.yml", "config.json"}
    self.mayStore = false
    self.mayPrint = false
    self.storeFile = path.join(zpm.env.getDataDirectory(), ".config.json")
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

    value = table.deepcopy(value)
    local ok, ljson = pcall(json.decode, value)
    if ok and ljson then
        value = ljson
    end

    local cursor = self:__call(key, value, true)
    if cursor then
        self:_store(key, value, false, force)
        return self:print(key)
    else
        errorf("Failed to find the complete key '%s'.", key)
    end
end

function Config:add(key, value)

    value = table.deepcopy(value)
    local ok, ljson = pcall(json.decode, value)
    if ok and ljson then
        value = ljson
    end

    local cursor = self:_findKey(self.values, key, function(cursor, key)
        table.insert(cursor[key], value)
        return cursor[key]
    end, true, true)

    if cursor then
        self:_store(key, value, true)
        return self:print(key)
    else
        errorf("Failed to find the complete key '%s'.", key)
    end
end

function Config:get(key)

    return table.deepcopy(self:__call(key))
end

function Config:print(key)

    local str = ""
    local c = self:_findKey(self.values, key, function(cursor, k)
        local c = iif(cursor[k] ~= nil, cursor[k], "")
        if type(c) == "table" then
            c = table.tostring(c, 4)
        end
        str = string.format("\nValue '%s' is set to:\n%s", key, c)
    end )
    if self.mayPrint then
        self.printf(str)
    end
    return str
end

function Config:__call(key, value, createKeys)

    return self:_findKey(self.values, key, function(cursor, key)
        if value ~= nil then
            cursor[key] = value
        end
        return cursor[key]
    end, false, createKeys )
end

function Config:_store(keys, value, add, force)

    if not self.mayStore and not force then
        return nil
    end

    add = iif(add ~= nil, add, false)
    local config = { }
    if self.storeFile and os.isfile(self.storeFile) then
        local ok, ljson = pcall(json.decode, zpm.util.readAll(self.storeFile))
        if ok then
            config = ljson
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
        if self.storeFile then
            zpm.util.writeAll(self.storeFile, json.encode_pretty(config))
        end
    end, true, true)
end

function Config:_loadFile(file)

    if not os.isfile(file) or table.contains(self.__loadedFiles, file) then
        return nil
    end

    self:_loadJSON(zpm.ser.loadFile(file))
    table.insert(self.__loadedFiles, file)
end

function Config:_isYAML(file)
    
    return file:contains(".yml") or file:contains(".yaml")
end

function Config:_loadJSON(ljson)

    self.values = zpm.util.mergeAppend(self.values, ljson)
end

function Config:_loadOverideFile(directory)

    for _, name in ipairs(self.configNames) do
        self:_loadFile(path.join(directory, name))
        self:_loadFile(path.join(directory, "." .. name))
    end
end

function Config:_findKey(tab, key, func, ensureTable, createKeys)

    ensureTable = iif(ensureTable ~= nil, ensureTable, false)

    local sep = key
    if type(key) ~= "table" then
        sep = key:explode("%.")
    end

    local cursor = tab
    for i, key in ipairs(sep) do

        if createKeys and not cursor[key] then
            cursor[key] = { }
        end

        if i == #sep then
            if ensureTable then
                if type(cursor[key]) ~= "table" then
                    cursor[key] = { cursor[key] }
                end
            end
            
            return func(cursor, key)
        end

        if cursor[key] then
            cursor = cursor[key]
        else
            return nil
        end
    end
end