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
Packages:virtual("getSettings")
Packages:virtual("getName")
Packages:virtual("getNameSingle")

function Packages:init(loader)

    self.loader = loader

    local settings = self:getSettings()
    self.mayInstall = settings.install
    self.mayUpdate = settings.update
    self.mayUninstall = settings.uninstall
    self.maySearch = settings.search
    self.mayShow = settings.show
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
        noticef("Modules action must be one of the following commands:")
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

function Packages:getName()
    
    return "packages"
end

function Packages:getNameSingle()
    
    return "package"
end

function Packages:install(vendor, name)

    local modules = self:_search(vendor, name, "install")
    local install = function()

        printf("\nInstalling %s...", self:getName())
        for _, mod in ipairs(modules) do
            mod:install()
        end
    end
    local no = function()
        warningf("You chose to abort the installation!")
    end
    zpm.cli.askConfirmation(("Do you want to install these %s?"):format(self:getName()), install, no)
end

function Packages:update(vendor, name)

    local modules = self:_search(vendor, name, "update", function(m) return m:isInstalled() end)
    local update = function()

        printf("\nUpdating modules...")
        for _, mod in ipairs(modules) do
            mod:update()
        end
    end
    local no = function()
        warningf("You chose not to update the modules!")
    end
    zpm.cli.askConfirmation(("Do you want to update these %s?"):format(self:getName()), update, no)
end

function Packages:uninstall(vendor, name)

    local modules = self:_search(vendor, name, "uninstall", function(m) return m:isInstalled() end)
    local uninstall = function()

        printf("\nUninstalling modules...")
        for _, mod in ipairs(modules) do
            mod:uninstall()
        end
    end
    local no = function()
        warningf("You chose to abort the uninstall process!")
    end
    zpm.cli.askConfirmation(("Do you want to uninstall these %s?"):format(self:getName()), uninstall, no)
end

function Packages:showInstalled()

    noticef("The following modules are installed:")

    local results = self.loader.manifests(self:getName(), "*", "*", function(m) return m:isInstalled() end)
    for _, r in ipairs(results) do
        noticef(" - %s", r.fullName)
    end
end

function Packages:search(vendor, name)

    vendor, name = self:_fixName(vendor, name)

    local results = self.loader.manifests(self:getName(), vendor, name)
    
    noticef("The following %s match '%s/%s':", self:getName(), vendor, name)
    for _, r in ipairs(results) do
        noticef(" - %s", r.fullName)
    end
end

function Packages:_search(vendor, name, action, pred)

    vendor, name = self:_fixName(vendor, name)
    local results = self.loader.manifests(self:getName(), vendor, name, pred)

    if #results > 0 then

        noticef("Are you sure you want to %s %s that match '%s/%s':", action, self:getName(), vendor, name)

        for _, r in ipairs(results) do
            noticef(" - %s", r.fullName)
        end

        return results
    else
        warningf("No %s found that matches with '%s %s'", self:getNameSingle(), vendor, name)
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