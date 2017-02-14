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

Manifest = newclass( "Manifest" )

function Manifest:init()
    self.defaultType = "library"
end

function Manifest:load()

    for _, dir in ipairs(table.insertflat( { _MAIN_SCRIPT_DIR }, zpm.registry.dirs)) do

        for name, ext in pairs(zpm.install.manifests) do
            self.loadType(path.join(dir, ext.manifest), name )
        end
        
    end
end

function Manifest:loadType( localManFile, tpe )

    if os.isfile(localManFile) then
        local manok, err = pcall(Manifest.loadFile, self, localManFile, tpe)
        if not manok then
            printf(zpm.colors.error .. "Failed to load manifest '%s':\n%s", dir, err)
        end
    end

end

function Manifest:loadFile(file, tpe)

    if not os.isfile(file) then
        return nil
    end

    local manifests = zpm.JSON:decode(zpm.util.readAll(file))

    for _, manifest in ipairs(manifests) do

        local man = bootstrap.getModule(manifest.name)
        local name = man[2]
        local vendor = man[1]

        local isShadow = false

        zpm.assert(name ~= nil, "No 'name' supplied in manifest definition!")
        zpm.assert(vendor ~= nil, "No 'vendor' supplied in manifest definition!")
        zpm.assert(manifest.repository ~= nil, "No 'repository' supplied in manifest definition!")

        zpm.assert(zpm.util.isAlphaNumeric(name), "'name' supplied in manifest definition must be alpha numeric!")
        zpm.assert(name:len() <= 50, "'name' supplied in manifest definition exceeds maximum size of 50 characters!")
        zpm.assert(name:len() >= 2, "'name' supplied in manifest definition must at least be 2 characters!")

        zpm.assert(zpm.util.isAlphaNumeric(vendor), "'vendor' supplied in manifest definition must be alpha numeric!")
        zpm.assert(vendor:len() <= 50, "'vendor' supplied in manifest definition exceeds maximum size of 50 characters!")
        zpm.assert(vendor:len() >= 2, "'vendor' supplied in manifest definition must at least be 2 characters!")

        zpm.assert(zpm.util.isGitUrl(manifest.repository), "'repository' supplied in manifest definition is not a valid https git url!")

        if manifest.shadowRepository ~= nil then
            zpm.assert(zpm.util.isGitUrl(manifest.shadowRepository), "'shadow-repository' supplied in manifest definition is not a valid https git url!")
            isShadow = true
        end

        zpm.packages.prepareDict(tpe, vendor, name, manifest.repository, manifest.shadowRepository, isShadow)

    end

end

zpm.manifest = Manifest:new()