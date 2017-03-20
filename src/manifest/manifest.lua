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

Manifest = newclass "Manifest"

function Manifest:init(loader, name, settings)

    self.loader = loader
    self.name = name
    self.settings = settings
    self.packages = {}
end

function Manifest:load(directory)

    for _, file in ipairs(self:_getFileNames()) do

        local manifestFile = path.join(directory, file)
        if os.isfile(manifestFile) then
            local ok, err = pcall(self._loadFile, self, manifestFile)
            if not ok then
                warningf( "Failed to load manifest '%s':\n%s", directory, err)
            end
        end
    end
end

function Manifest:search(vendorPattern, namePattern, pred)
    
    pred = iif(pred ~= nil, pred, function(m) return true end)

    local results = {}
    for vendor, v in pairs(self.packages) do

        if zpm.util.patternMatch(vendor,vendorPattern) then

            for name, n in pairs(v) do
                if zpm.util.patternMatch(name,namePattern) and pred(n) then
                    table.insert(results, n)
                end
            end
        end
    end

    return results
end

function Manifest:_getFileNames()
    return {
        "." .. self.settings.manifest,
        self.settings.manifest
    }
end

function Manifest:_loadFile(file)
    
    local manifests = zpm.json:decode(zpm.util.readAll(file))

    for _, package in ipairs(manifests) do

        local mod = bootstrap.getModule(package.name)
        vendor, name = mod[1], mod[2]

        local ok, validOrMessage = pcall(zpm.validate.manifest, package, name, vendor)
        if ok and validOrMessage == true then
            self:_savePackage(package.name, name, vendor, package)
        else
            warningf("Failed to load manifest file '%s':\n%s\n^~~~~~~~\n\n%s", file, zpm.json:encode_pretty(package), validOrMessage)
        end
    end
end

function Manifest:_savePackage(fullName, name, vendor, package)

    if not self.packages[vendor] then
        self.packages[vendor] = {}
    end

    local factory = self:_getFactory()

    self.packages[vendor][name] = factory:new(self.loader, {
        fullName = fullName,
        name = name,
        vendor = vendor, 
        repository = package.repository,
        build = package.build
    })
end


function Manifest:_getFactory()

    local factory = Package
    if zpm.packageFactory[self.name] then
        factory = zpm.packageFactory[self.name]
    end
    return factory
end

zpm.packageFactory = {
    libraries = Package,
    modules = Module
}