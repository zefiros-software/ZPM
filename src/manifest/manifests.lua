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

Manifests = newclass "Manifests"

function Manifests:init(loader, registries)

    self.loader = loader
    self.registries = registries
    self.manifests = {}
end

function Manifests:load()

    for name, ext in pairs(self.loader.config("install.manifests")) do

        local ok, validOrMessage = pcall(zpm.validate.manifests, ext)
        if ok and validOrMessage == true then 
            
            self.loader[name] = self:_createPackages(name, ext)
            self.manifests[name] = Manifest(self.loader, self.loader[name], name, ext)

            for _, dir in ipairs(self.registries:getDirectories()) do

                self.manifests[name]:load(dir)
            end      
        else
            warningf("Failed to load manifest definition '%s':\n%s\n^~~~~~~~\n\n%s", name, zpm.json.encode(ext, {pretty=true}), validOrMessage)
        end
    end
end

function Manifests:getLoadOrder()

    local result = {}
    local dependencyTypes = zpm.util.toArray(self.loader.config("install.manifests"))
    table.sort(dependencyTypes, function(t1, t2) 
        return iif(t1[next(t1)].order ~= nil, t1[next(t1)].order, -1) > iif(t2[next(t2)].order ~= nil, t2[next(t2)].order, -1)
    end)

    for _, name in ipairs(dependencyTypes) do
        if name[next(name)].order then
            result = zpm.util.concat(result, next(name))
        end
    end
    return result
end

function Manifests:__call(tpe, vendorPattern, namePattern, pred)

    if not self.manifests[tpe] then
        return {}
    end

    return self.manifests[tpe]:search(vendorPattern, namePattern, pred)
end

function Manifests:_createPackages(name, ext)

    local factory = Packages
    if ext.class  and _G[ext.class] then
        factory = _G[ext.class]
    end
    
    return factory(self.loader, ext, name, ext.name)
end