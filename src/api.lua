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

zpm.api = {}

function zpm.uses(libraries)

    local found = true
    if type(libraries) ~= "table" then
        libraries = {libraries}
    end

    for _, library in ipairs(libraries) do
    
        local package, access = zpm.loader.project.builder:build(library, "libraries")
        --print(zpm.meta.project, library, package, "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
        zpm.util.setTable(zpm.loader.project.builder.cursor, {"projects", zpm.meta.project, "uses", library}, {
            package = package
        } )

        found = found and package
    end

    return found
end

function zpm.has(library)

    for _, access in ipairs({"public", "private"}) do
        if zpm.loader.project.builder.cursor[access] and zpm.loader.project.builder.cursor[access]["libraries"] then
            for _, pkg in ipairs(zpm.loader.project.builder.cursor[access]["libraries"]) do
                if pkg.name == library then
                    return true
                end
            end
        end
    end

    return zpm.loader.project.builder.solution.tree.closed.public["libraries"][library]
end

function zpm.export(commands)

    local cursor = zpm.loader.project.builder.cursor
    local index = {"projects", zpm.meta.project, "exportFunctions"}

    local func = function()

        zpm.loader.project.from = cursor
        --print(commands)
        zpm.sandbox.run(commands, {env = zpm.loader.project.builder:getEnv("libraries", cursor)})  

        zpm.loader.project.from = nil
    end

    zpm.util.insertTable(zpm.loader.project.builder.cursor, index, func)    
    
    local fltr = table.deepcopy(zpm.meta.filter)
    filter {}
    
    zpm.sandbox.run(commands, {env = zpm.loader.project.builder:getEnv("libraries")})  
        
    filter(fltr)
end

function zpm.setting(setting)
    
    local cursor = iif(zpm.loader.project.from, zpm.loader.project.from, zpm.loader.project.cursor)
    
    local tab = zpm.loader.settings({cursor.package.manifest.name, cursor.name, cursor.tag, setting})

    if not tab then
        warningf("Setting '%s' does not exist on package '%s'", setting, zpm.loader.project.cursor.name)

        return nil
    end
    
    local values = tab.values
    if not values then
        return tab.default
    end
    values = zpm.util.reverse(values)

    if tab.reduce then
        if zpm.settings.reduce[tab.reduce] then
            zpm.settings.reduce[tab.reduce](values)
        else
            -- @todo
        end
    end

    return values
end

function zpm.configuration(setting, default)
    
    local config = zpm.loader.config({"configuration", setting})
    
    return iif(config, config, default)
end