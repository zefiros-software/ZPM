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

Packages = newclass("Packages")

function Packages:init(loader, settings, name, nameSingle)

    self.loader = loader

    settings = iif(settings, settings, {})
    self.mayInstall = iif(settings.install ~= nil, settings.install, false)
    self.mayUpdate = iif(settings.update ~= nil, settings.update, false)
    self.mayUninstall = iif(settings.uninstall ~= nil, settings.uninstall, false)
    self.maySearch = iif(settings.search ~= nil, settings.search, true)
    self.mayShow = iif(settings.show ~= nil, settings.show, false)
    self.extract = iif(settings.extract ~= nil, settings.extract, '{extern}/{name}')

    self.name = iif(name, name, "package")
    self.nameSingle = iif(nameSingle, nameSingle, "packages")

    if _ACTION == self:getNameSingle() then
        zpm.util.disableMainScript()
        
        newoption {
            trigger = "public",
            description = "Mark this package as public"
        }
        
        newoption {
            trigger = "private",
            description = "Mark this package as private"
        }
        
        newoption {
            trigger = "development",
            description = "Mark this package as development"
        }
        
        newoption {
            trigger = "versions",
            description = "Mark this package to use these versions",
            default = "*"
        }
        
        newoption {
            trigger = "preload",
            description = "Mark this package to be preloaded"
        }
    end

    newaction {
        trigger = self:getNameSingle(),
        description = ("Interacts with the ZPM %s"):format(self:getName()),
        execute = function()
            self:CLI()
        end
    }
end

function Packages:getExtractDirectory()

    if not self.extract then
        return nil
    end

    return zpm.util.getRelativeOrAbsoluteDir(_MAIN_SCRIPT_DIR, self.extract:gsub('{name}', self.name):gsub('{extern}', self.loader.config("install.extern.directory")) )
end

function Packages:getName()
    
    return self.name
end

function Packages:getNameSingle()
    
    return self.nameSingle
end

function Packages:CLI()
    local help = false

    if #_ARGS > 0 then
        if self.mayInstall and _ARGS[1] == "install" and #_ARGS > 1 then
                
            self:install(_ARGS[2], _ARGS[3])
        elseif self.mayUpdate and _ARGS[1] == "update" and #_ARGS > 1  then
                
            self:update(_ARGS[2], _ARGS[3])
        elseif self.mayUninstall and _ARGS[1] == "uninstall" and #_ARGS > 1 then
                
            self:uninstall(_ARGS[2], _ARGS[3])
        elseif self.mayUpdate and _ARGS[1] == "update" and #_ARGS == 1 then
                
            self:update("*/*")
        elseif self.maySearch and _ARGS[1] == "search" and #_ARGS > 1 then
                
            self:search(_ARGS[2], _ARGS[3])
        elseif self.mayShow and _ARGS[1] == "show" then
                
            self:showInstalled()
        else
            help = true
        end
    else
        help = true
    end

    if help or zpm.cli.showHelp() then
        noticef("Action must be one of the following commands:")
        cnoticef(self.mayInstall, " - install   [vendor] [name]\tInstalls modules with given vendor and name")
        cnoticef(self.mayUninstall, " - uninstall [vendor] [name]\tUninstalls modules with given vendor and name")
        cnoticef(self.maySearch, " - search    [vendor] [name]\tSearches modules with given vendor and name")
        cnoticef(self.mayUpdate, " - update    [vendor] [name]\tUpdates modules with given vendor and name")
        cnoticef(self.mayUpdate, " - update \t\t\tUpdates all modules that are installed")
        cnoticef(self.mayShow, " - show \t\t\tShow all installed modules")
    end
end

function Packages:getSettings()
    
    return {
        install = false,
        update = false,
        uninstall = false,
        search = true,
        show = false
    }
end

function Packages:install(vendor, name)

    local packages = self:_search(vendor, name, "install")
    local install = function()

        printf("\nInstalling %s...", self:getName())
        for _, mod in ipairs(packages) do
            --print(table.tostring(mod,2))
            mod:install()
            self:addTodefinition(mod.vendor, mod.name)
        end
        return true
    end
    local no = function()
        warningf("You chose to abort the installation!")
        return false
    end
    if #packages > 0 then
        return zpm.cli.askConfirmation(("Do you want to install these %s?"):format(self:getName()), install, no)
    else
        warningf("No %s were found.", self:getName())
        return false
    end
end

function Packages:addTodefinition(vendor, name)
    self.loader.definition:add(("%s/%s"):format(vendor, name), self.name, {
        development = _OPTIONS['development'],
        public = _OPTIONS['public'],
        private = _OPTIONS['private'],
        version = _OPTIONS['versions'],
        preload = _OPTIONS['preload']
    })
end

function Packages:update(vendor, name)

    local packages = self:_search(vendor, name, "update", function(m) return m:isInstalled() end)
    local update = function()

        printf("\nUpdating %s...", self:getName())
        for _, p in ipairs(packages) do
            p:update()
        end
    end
    local no = function()
        warningf("You chose not to update the %s!", self:getName())
    end
    if #packages > 0 then
        zpm.cli.askConfirmation(("Do you want to update these %s?"):format(self:getName()), update, no)
    end
end

function Packages:uninstall(vendor, name)

    local packages = self:_search(vendor, name, "uninstall", function(m) return m:isInstalled() end)
    local uninstall = function()

        printf("\nUninstalling %s...", self:getName())
        for _, p in ipairs(packages) do
            p:uninstall()
        end
    end
    local no = function()
        warningf("You chose to abort the uninstall process!")
    end
    if #packages > 0 then
        zpm.cli.askConfirmation(("Do you want to uninstall these %s?"):format(self:getName()), uninstall, no)
    end
end

function Packages:showInstalled()

    local packages = self.loader.manifests(self:getName(), "*", "*", function(m) return m:isInstalled() end)
    if #packages > 0 then
        noticef("The following %s are installed:", self:getName())

        for _, r in ipairs(packages) do
            noticef(" - %s", r.fullName)
        end
    else
        noticef("No %s are installed.", self:getName())
    end
end

function Packages:search(vendor, name)

    vendor, name = self:_fixName(vendor, name)

    local packages = self.loader.manifests(self:getName(), vendor, name)
    
    if #packages > 0 then
        noticef("The following %s match '%s/%s':", self:getName(), vendor, name)
        for _, r in ipairs(packages) do
            noticef(" - %s", r.fullName)
        end
    else
        noticef("No %s were found.", self:getName())
    end
end

function Packages:get(vendor, name)

    return self.loader.manifests(self:getName(), vendor, name, function(n) return n.vendor == vendor and n.name == name end)[1]
end

function Packages:getOrStore(vendor, name, settings)

    local result = self.loader.manifests(self:getName(), vendor, name, function(n) return n.vendor == vendor and n.name == name end)[1]

    if not result and settings.repository then
        result = self.loader.manifests.manifests[self:getName()]:addPackage(string.format("%s/%s", vendor, name), vendor, name, settings)
    end

    return result
end

function Packages:_search(vendor, name, action, pred)

    vendor, name = self:_fixName(vendor, name)
    local packages = self.loader.manifests(self:getName(), vendor, name, pred)

    if #packages > 0 then

        noticef("Are you sure you want to %s %s that match '%s/%s':", action, self:getName(), vendor, name)

        for _, r in ipairs(packages) do
            noticef(" - %s", r.fullName)
        end

        return packages
    end

    return {}
end

function Packages:_fixName(vendor, name)

    if not vendor then
        vendor = "*"
    end

    if not name then
        local mod = vendor:explode( "/" )
        vendor, name = mod[1], mod[2]

        if not name then
            name = "*"
        end
    end

    return vendor, name
end