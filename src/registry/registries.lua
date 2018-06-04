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

Registries = newclass "Registries"

function Registries:init(loader, mayCheck)

    self.loader = loader
    self.cacheTime = self.loader.config("cache.registry.cacheTime")
    self.registries = { }
    self.isRoot = false

    self.__cacheMayCheck = mayCheck
end

function Registries:load()

    self:_loadRoot()
    self:loadRegistries()
end

function Registries:loadRegistries(force)

    for _, r in ipairs(self.registries) do

        r:load(force)
    end
end

function Registries:addRepository(repo)

    table.insert(self.registries, self:_newRegistry(nil, repo, nil))
end

function Registries:getDirectories()

    local dirs = {}

    for _, r in ipairs(self.registries) do

        table.insert(dirs, r.directory)
    end

    for _, r in ipairs(self.registries) do        

        dirs = zpm.util.concat(dirs, r.registries:getDirectories())
    end

    return dirs
end

function Registries:_loadRoot()

    if self.isRoot then

        table.insert(self.registries, self:_getMainRegistry())

        for _, p in ripairs(zpm.util.traversePath(_MAIN_SCRIPT_DIR)) do

            table.insert(self.registries, self:_newRegistry(p, nil, nil, true))
        end

        for _, r in ripairs(self.loader.config("registries")) do

            self:addRepository(r)
        end
    end
end

function Registries:_mayCheck()

    if self.__cacheMayCheck ~= nil then
        return self.__cacheMayCheck
    end    

    self.__cacheMayCheck = false

    local checkTime = self.loader.config("cache.registry.checkTime")
    if not checkTime or os.difftime(os.time(), checkTime) > self.cacheTime then

        self.loader.config:set("cache.registry.checkTime", os.time(), true)

        self.__cacheMayCheck = true
    end

    return self.__cacheMayCheck
end

function Registries:_getDirectory()

    return zpm.util.getRelativeOrAbsoluteDir(zpm.env.getDataDirectory(), self.loader.config("install.registry.directory"))
end

function Registries:_getMainRegistry()

    return self:_newRegistry(self:_getDirectory(), self.loader.config("install.registry.repository"), self.loader.config("install.registry.branch"), true)
end

function Registries:_newRegistry(dir, repo, branch, mayLoadRegistries)

    zpm.assert(not repo or zpm.util.isGitUrl(repo), "Registry '%s' is not a git url!", repo)

    if not dir then
        dir = path.join(self:_getDirectory(), string.sha1(repo):sub(0,5))
    end
    
    return Registry(self.loader, dir, repo, branch, self:_mayCheck(), isRoot)
end