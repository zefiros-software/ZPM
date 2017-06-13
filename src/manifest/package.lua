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

zpm.package = {}

function zpm.package.splitName(name)

    local mod = bootstrap.getModule(name)
    return mod[1], mod[2]
end


Package = newclass "Package"

Package:virtual("install")
Package:virtual("update")
Package:virtual("uninstall")
Package:virtual("install")
Package:virtual("isInstalled")
Package:virtual("getRepository")
Package:virtual("getDefinition")
Package:virtual("pullRepository")
Package:virtual("pullDefinition")

function Package:init(loader, manifest, settings)

    self.manifest = manifest
    self.loader = loader
    self.fullName = settings.fullName
    self.name = settings.name
    self.vendor = settings.vendor

    self.repository = settings.repository
    self.definition = iif(settings.definition == nil, self.repository, settings.definition)
    self.isRoot = settings.isRoot
    self.pulled = false
    self.loaded = false

    self.versions = { }
end

function Package:__eq(package)
    
    return package:getHash() == self:getHash()
end

function Package:getHash()

    return package.fullName
end

function Package:getVersions(requirement)

    local result = {}
    for _, v in ipairs(self.versions) do
        local version = iif(v.version ~= nil, v.version, v.tag)
        if premake.checkVersion(version, requirement) then
            table.insert(result, v)
        end
    end

    return result
end

function Package:load()

    if self.loaded then
        return
    end

    self:pull()

    if self.definition ~= self.repository then

    end

    self.loaded = true
end

function Package:getRepository()

    if self:isRepositoryRepo() then
        return self:_getRepositoryPkgDir()
    end

    return self.repository
end

function Package:getDefinition()

    if self:isDefinitionRepo() then
        return self:_getDefinitionPkgDir()
    end

    return self.definition
end

function Package:isDefinitionRepo()

    return zpm.util.isGitUrl(self.definition)
end

function Package:isRepositoryRepo()

    return zpm.util.isGitUrl(self.repository)
end

function Package:findPackageDefinition(tag)

    local package = { }
    if not self:isDefinitionRepo() then

        for _, p in ipairs( { "package.yml", ".package.yml" }) do

            if not tag then
                local file = path.join(self:getDefinition(), p)
                if os.isfile(file) then

                    package = self:_processPackageFile(zpm.ser.loadFile(file))
                    break
                end
            else
                -- @todo implement package from tags
            end
        end
    else

        -- @todo implement
    end

    return package
end

function Package:_processPackageFile(package)

    if self.isRoot then
        package = table.merge(package, package.dev)
        package.dev = nil
    end

    if not package.private then
        package.private = {}
    end

    if not package.public then
        package.public = {}
    end    
    
    -- add private modules as public that may not be private
    for _, type in ipairs(self.loader.manifests:getLoadOrder()) do

        local maybePrivate = self.loader.config({"install", "manifests", type, "allowPrivate"})
        if not maybePrivate and package[type] then

            if not package.public[type] then
                package.public[type] = {}
            end
            
            package.public[type] = zpm.util.concat(package.public[type], package[type])
            package[type] = nil
        end
    end

    -- remove private types from root and insert in .private
    for _, type in ipairs(self.loader.manifests:getLoadOrder()) do

        if package[type] then

            if not package.private[type] then
                package.private[type] = {}
            end

            package.private[type] = zpm.util.concat(package.private[type], package[type])
            package[type] = nil
        end
    end

    return package
end

function Package:pullRepository()

    zpm.git.cloneOrPull(self:getRepository(), self.repository)

end

function Package:pullDefinition()

    zpm.git.cloneOrPull(self:getDefinition(), self.definition)
end

function Package:pull()

    if not self:isRepositoryRepo() then
        return
    end

    if self:_mayPull() then

        printf("- '%s' pulling '%s'", self.name, self.repository)
        self:pullRepository()

        if self.repository ~= self.definition then
            printf("- Pulling defintion '%s'", self.definition)
            self:pullDefinition()
        end
    end

    self.versions = zpm.util.concat(zpm.git.getBranches(self:getRepository()),zpm.git.getTags(self:getRepository()))

    self.pulled = true
end

function Package:_getRepositoryPkgDir()

    return path.join(zpm.env.getPackageDirectory(), self.manifest.name, self.vendor, self.name, string.sha1(self.repository):sub(0, 6))
end

function Package:_getDefinitionPkgDir()

    return path.join(zpm.env.getPackageDirectory(), self.manifest.name, self.vendor, self.name, string.sha1(self.definition):sub(0, 6))
end

function Package:_mayPull()

    return self.manifest:mayPull() and
            ((not self.pulled and zpm.cli.update()) or
            not os.isdir(self:getRepository()) or
            (self.repository ~= self.definition and not os.isdir(self:getDefinition())))
end