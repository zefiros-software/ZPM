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

zpm.package = { }

function zpm.package.splitName(name)

    local mod = bootstrap.getModule(name)
    return mod[1], mod[2]
end


function zpm.package.semverDist(v1, v2)

    return(v1.major * 100000 + v1.minor * 1000 + v1.patch) -
    (v2.major * 100000 + v2.minor * 1000 + v2.patch)
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

Package:virtual("onInstall")
Package:virtual("onUninstall")
Package:virtual("onUpdate")
Package:virtual("onLoad")

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

    self.costTranslation = 0

    self.costCache = {}
    self.versions = { }
    self.newest = nil
    self.oldest = nil
end


function Package:onInstall(version, tag)
    -- @todo: add this hook
end

function Package:onUninstall(version, tag)
    -- @todo: add this hook
end

function Package:onUpdate(oldVersion, newVersion, oldTag, newTag)
    -- @todo: add this hook
end

function Package:onLoad(version, tag)
    -- @todo: add this hook
end

function Package:isGitRepo()
    
    return not os.isdir(self.repository)
end

function Package:isTrusted(ask)

    ask = iif(ask == nil, true, ask)
    local index = {"trustStore", self.vendor, self.name}
    local trustStore = self.loader.config(index)
    if not trustStore then
        trustStore = {}
    end
    local trusted = false
    local changed = false
    if (not table.contains(trustStore, self.repository) and zpm.util.hasUrl(self.repository)) and (not table.contains(trustStore, self.definition) and zpm.util.hasUrl(self.definition)) then

        if self.definition ~= self.repository then
            if zpm.util.hasUrl(self.definition) then
                zpm.cli.askTrustStoreConfirmation(("Package '%s' wants to execute code from '%s' and '%s',\ndo you trust this repository?"):format(self.fullName, self.repository, self.definition), function()
                    table.insert(trustStore, self.repository)
                    table.insert(trustStore, self.definition)
                    changed = true
                end, function()
                    warningf("Package repositories are not trusted!")
                end)
            end
        else
            zpm.cli.askTrustStoreConfirmation(("Package '%s' wants to execute code from '%s',\ndo you trust this repository?"):format(self.fullName, self.repository), function()
                table.insert(trustStore, self.repository)
                changed = true
            end, function()
                warningf("Package repository is not trusted, and execution is skipped!")
            end)
        end
    else
        trusted = true
    end

    if changed then
        self.loader.config:set(index, trustStore, true)
    end

    return trustStore
end

function Package:__eq(package)

    return package:getHash() == self:getHash()
end

function Package:getExtractDirectory(dir, node)

    if self:isGitRepo() then
        local version = iif(node.version == nil, node.tag, node.version)
        return path.join(dir, self.fullName, string.format("%s-%s", version, node.hash:sub(0,5)))
    else
        return self.repository
    end
end

function Package:needsExtraction(dir, node)

    if not os.isdir(self:getExtractDirectory(dir, node)) or zpm.cli.force() then
        return true
    end
    return false
end

function Package:extract(dir, node)

    local location = self:getExtractDirectory(dir, node)
    local updated = false

    if self:needsExtraction(location, node) then

        if os.isdir(location) then
            noticef(" * Cleaning existing '%s'", self:getExtractDirectory("", node))
            zpm.util.rmdir(location)
        end
        zpm.util.recurseMkdir(location)
        noticef(" * Extracting %s to %s", self.manifest.manager.nameSingle, self:getExtractDirectory("", node))

        local version = iif(node.version == nil, node.tag, node.version)
        local extract = self:findPackageExtract(version)
        if extract then

            if self:isGitRepo() then
                noticef("   Checking out directory, this may take a while...")
                zpm.git.checkout(self:getRepository(), node.hash)
            end

            local current = os.getcwd()
            os.chdir(self:getRepository())

            self.loader.project.cursor = node

            if self:isTrusted() then
                zpm.sandbox.run(extract, { env = zpm.api.load("extract", node), quota = false })
            end

            self.loader.project.cursor = nil
            os.chdir(current)
        else
        
            if self:isGitRepo() then
                if zpm.git.hasSubmodules(self:getRepository()) then
                    noticef("   We detected submodules, this may take a little longer")
                end
                zpm.git.export(self:getRepository(), location, node.hash)
            end
        end

        updated = true
    end
    return location, updated
end

function Package:getHash()

    return self.fullName
end

function Package:getVersions(requirement)

    local result = { }

    --print(self:isGitRepo(), self.name, requirement)
    if not self:isGitRepo() then
        table.insert(result, {
            hash = "LOCAL",
            tag = "DIR",
            cost = 0
        })
    else
        for _, v in ipairs(self.versions) do
            local version = iif(v.version ~= nil, v.version, v.tag)
            if premake.checkVersion(version, requirement) then
                v.cost = self:getCost(v)
                table.insert(result, v)
            end
        end
    end

    return result
end

function Package:getCost(v)

    if self.costCache[v.hash] then
        return self.costCache[v.hash]
    end

    if not self:isGitRepo() then

        return 0
    end

    if self.newest then
        if v.version then

            return zpm.package.semverDist(self.newest.semver, v.semver) + self.costTranslation
        else
            if not self.totalCommits then
                self.totalCommits = zpm.git.getCommitCountBetween(self:getRepository(), self.newest.tag, self.oldest.tag)
            end
            local ahead, behind = zpm.git.getCommitAheadBehind(self:getRepository(), self.newest.tag, v.hash)

            local totalDistance = zpm.package.semverDist(self.newest.semver, self.oldest.semver)
            local distancePerCommit = math.min(totalDistance / self.totalCommits, 1)
            local guessedDistance =(behind - ahead) * distancePerCommit

            self.costCache[v.hash] = guessedDistance + self.costTranslation
        end
    else
    
        if not self.totalCommits then
            self.totalCommits = zpm.git.getCommitCount(self:getRepository(), "HEAD")
        end
        local ahead, behind = zpm.git.getCommitAheadBehind(self:getRepository(), "HEAD", v.hash)

        local totalDistance = zpm.package.semverDist(zpm.semver(1, 0, 0), zpm.semver(0, 0, 0))
        local distancePerCommit = math.min(totalDistance / self.totalCommits, 1)
        local guessedDistance =(behind - ahead) * distancePerCommit
        self.costCache[v.hash] = guessedDistance + self.costTranslation
    end

    return self.costCache[v.hash]
end

function Package:load(hash)

    if self.loaded then
        return
    end

    self:pull(hash)

    self.loaded = true
end

function Package:getRepository()

    if self:isRepositoryRepo() then
        return self:_getRepositoryPkgDir()
    end

    return zpm.util.getRelativeOrAbsoluteDir(_MAIN_SCRIPT_DIR, self.repository)
end

function Package:getDefinition()

    
    if self:isDefinitionRepo() then
        return self:_getDefinitionPkgDir()
    end

    return zpm.util.getRelativeOrAbsoluteDir(_MAIN_SCRIPT_DIR, self.definition)
end

function Package:isDefinitionRepo()

    return zpm.util.isGitUrl(self.definition)
end

function Package:isRepositoryRepo()

    return zpm.util.isGitUrl(self.repository)
end


function Package:isDefinitionSeperate()

    return self.definition ~= self.repository
end

function Package:findPackageDefinition(hash, tag)

    local package = { }
    if not tag or self:isDefinitionSeperate() or not self:isDefinitionRepo() then

        for _, p in ipairs( { "package.yml", ".package.yml", "package.yaml", ".package.yaml" }) do

            local file = path.join(self:getDefinition(), p)
            if os.isfile(file) then
                package = self:_processPackageFile(zpm.ser.loadFile(file), hash, tag)
                break
            end
        end
    else

        for _, p in ipairs( { "package.yml", ".package.yml", "package.yaml", ".package.yaml" }) do

            local contents = zpm.git.getFileContent(self:getDefinition(), p, tag)
            if contents then

                package = self:_processPackageFile(zpm.ser.loadYaml(contents), hash, tag)
                break
            end
        end
    end
    return package
end

function Package:findPackageExport(tag)
    
    if self:isDefinitionSeperate() or not self:isDefinitionRepo() then
        return self:_findExportSeperated(tag)
    else
        return self:_findExport(tag)
    end
    return export
end

function Package:_findExport(tag)

    local export = nil
    for _, p in ipairs( { "export.lua", ".export.lua" }) do

        local contents = zpm.git.getFileContent(self:getDefinition(), p, tag)
        if contents then

            export = contents
            break
        end
    end
    return export
end

function Package:_findExportSeperated(tag)

    local export = nil
    for _, p in ipairs( { "export.yml", ".export.yml", "export.yaml", ".export.yaml" }) do

        local file = path.join(self:getDefinition(), p)
        if os.isfile(file) then
            local builds = zpm.ser.loadMultiYaml(file)
            for _, build in ipairs(builds) do
                if premake.checkVersion(tag, build.version) then
                    if build.export then
                        export = build.export
                    elseif build.file then
                        export = zpm.io.readfile(build.file)
                    end
                    break
                end
            end
            break
        end
    end

    if not export then
        for _, p in ipairs( { "export.lua", ".export.lua" }) do
            local file = path.join(self:getDefinition(), p)
            if os.isfile(file) then
                local fexport = io.readfile(file)
                if fexport then
                    export = fexport
                    break
                end
            end
        end
    end

    return export
end


function Package:findPackageExtract(tag)

    if self:isDefinitionSeperate() or not self:isDefinitionRepo() then
        return self:_findExtractSeperated(tag)
    else
        return self:_findExtract(tag)
    end
end

function Package:_findExtract(tag)

    local extract = nil
    for _, p in ipairs( { "extract.lua", ".extract.lua" }) do

        local contents = zpm.git.getFileContent(self:getDefinition(), p, tag)
        if contents then

            extract = contents
            break
        end
    end

    return extract
end

function Package:_findExtractSeperated(tag)

    local extract = nil
    for _, p in ipairs( { "extract.yml", ".extract.yml", "extract.yaml", ".extract.yaml" }) do

        local file = path.join(self:getDefinition(), p)
        if os.isfile(file) then
            local builds = zpm.ser.loadMultiYaml(file)
            for _, build in ipairs(builds) do

                if premake.checkVersion(tag, build.version) then
                    if build.extract then
                        extract = build.extract
                    elseif build.file then
                        extract = io.readfile(build.file)
                    end
                    break
                end
            end
            break
        end
    end

    if not extract then
        for _, p in ipairs( { "extract.lua", ".extract.lua" }) do
            local file = path.join(self:getDefinition(), p)
            if os.isfile(file) then
                local fextract = io.readfile(file)
                if fextract then
                    extract = fextract
                    break
                end
            end
        end
    end

    return extract
end

function Package:_processPackageFile(package, hash, tag)

    if not package then
        return { }
    end

    if not package.private then
        package.private = { }
    end

    if not package.public then
        package.public = { }
    end

    local mergeDefinition = function(package, dev)
        
        if not dev then
            return
        end

        if not package then
            package = dev
        else

            for type, pkgs in pairs(dev) do
                for _, pkg in ipairs(pkgs) do
                    if not package[type] then
                        package[type] = {}
                    end

                    local found = nil
                    local idx = 0
                    for i, fpkg in ipairs(package[type]) do
                        if fpkg.name == pkg.name then
                            found = fpkg
                            idx = i
                            break
                        end
                    end

                    if not found then
                        table.insert(package[type], pkg)
                    else
                        package[type][idx] = table.merge(found, pkg)
                    end
                end
            end

        end
        return package
    end
    

    if self.isRoot and package.dev then
        mergeDefinition(package, package.dev)
        mergeDefinition(package.public, package.dev.public)
        mergeDefinition(package.private, package.dev.private)
        package.dev = nil
    end

    -- remove private types from root and insert in .private
    for _, type in ipairs(self.loader.manifests:getLoadOrder()) do

        if package[type] then

            if not package.private[type] then
                package.private[type] = { }
            end

            package.private[type] = zpm.util.concat(package.private[type], package[type])
            package[type] = nil
        end
    end

    -- add private modules as public that may not be private
    for _, type in ipairs(self.loader.manifests:getLoadOrder()) do

        local maybePrivate = self.loader.config( { "install", "manifests", type, "allowPrivate" })
        if not maybePrivate and package[type] then

            if not package.public[type] then
                package.public[type] = { }
            end

            package.public[type] = zpm.util.concat(package.public[type], package[type])
            package[type] = nil
        end
    end
    
    -- load setting definitions
    self:_loadSettings(tag, package.settings)

    return package
end

function Package:pullRepository()

    zpm.git.cloneOrFetch(self:getRepository(), self.repository)
end

function Package:pullDefinition()

    zpm.git.cloneOrFetch(self:getDefinition(), self.definition)
    zpm.git.reset(self:getDefinition())
end

function Package:pull(hash)

    local hasHash = false
    local repo = self:getRepository()
    if hash and os.isdir(repo) then
        hasHash = zpm.git.hasHash(repo, hash)
    end

    if not self:isRepositoryRepo() or (self.pulled and not needsUpdate) then
        return
    end

    if self:_mayPull() or (hash and not hasHash) then

        noticef("- '%s' pulling '%s'", self.fullName, self.repository)
        self:pullRepository()

        if self.repository ~= self.definition and not os.isdir(self.definition) then
            noticef("   with definition '%s'", self.definition)
            self:pullDefinition()
        end

    end
    local tags = zpm.git.getTags(self:getRepository())
    self.newest = tags[1]
    self.oldest = tags[#tags]
    self.versions = zpm.util.concat(zpm.git.getBranches(self:getRepository()), tags)

    -- make sure all cost function values are positive
    for _, v in ipairs(self.versions) do
        local c = self:getCost(v)
        if c < self.costTranslation then
            self.costTranslation = c
        end
    end
    self.costTranslation = math.abs(self.costTranslation)

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
    ((not self.pulled and zpm.cli.update() and not zpm.cli.cachedOnly()) or not os.isdir(self:getRepository()) or
    (self.repository ~= self.definition and not os.isdir(self:getDefinition())))
end

function Package:_loadSettings(tag, settings)

    if self.fullName and tag then
        if settings then
            for name, setting in pairs(settings) do
                if type(setting) ~= "table" then
                    setting = {default = setting}
                end
                self.loader.settings:set( { self.manifest.name, self.fullName, tag, name }, {
                    default = setting.default,
                    reduce = setting.reduce
                }, true)
            end
        end
    end
end