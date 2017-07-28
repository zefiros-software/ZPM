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

Registry = newclass "Registry"

function Registry:init(loader, directory, repository, branch, mayCheck, mayLoadRegistries)

    self.loader = loader
    self.directory = directory
    self.repository = repository
    self.mayCheck = mayCheck
    self.mayLoadRegistries = mayLoadRegistries
    self.branch = branch

    self.registries = Registries(loader, mayCheck)
end

function Registry:load()

    self:_update()

    self:_tryLoadRegistriesFile()

    self.registries:load()
end

function Registry:_update()

    if self:_mayUpdate() and self.repository then

        printf("%%{yellow}Hit: %s", self.repository)
        zpm.git.cloneOrFetch(self.directory, self.repository, self.branch)
        zpm.git.checkout(self.directory, "HEAD")
    end
end

function Registry:_getFileName()

    return self.loader.config("install.registry.manifest")
end

function Registry:_getRegistryFiles()
    
    if self.mayLoadRegistries then
        return {path.join(self.directory, "." .. self:_getFileName()), path.join(self.directory, self:_getFileName())}
    end
    return {}
end

function Registry:_mayUpdate()

    return not zpm.cli.cachedOnly() and zpm.cli.update() and self.mayCheck
end

function Registry:_tryLoadRegistriesFile()

    local ok, registries = pcall(self._loadRegistriesFile, self)
    if ok then
        if registries then

            for _, r in ipairs(registries) do

                self.registries:addRepository(r)
            end
        end
    else
        warningf("Failed to load registry '%s'", self:_getRegistryFiles()[1])
    end
end

function Registry:_loadRegistriesFile()

    local localRegFiles = self:_getRegistryFiles()

    for _, reg in ipairs(localRegFiles) do
        if os.isfile(reg) then

            return zpm.ser.loadFile(reg)
        end
    end

    return nil
end
