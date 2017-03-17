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

Modules = newclass("Modules")

function Modules:init(loader)

    self.loader = loader
end

function Modules:getDirectory()
    return bootstrap.directories[1]
end

function Modules:install(vendor, name)

    local modules = self:_search(vendor, name, "install")
    local install = function()

        printf("\nInstalling modules...")
        for _, mod in ipairs(modules) do
            mod:install()
        end
    end
    local no = function()
        warningf("You chose to abort the installation!")
    end
    zpm.cli.askConfirmation("Do you want to install these modules?", install, no)
end

function Modules:update(vendor, name)

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
    zpm.cli.askConfirmation("Do you want to update these modules?", update, no)
end

function Modules:uninstall(vendor, name)

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
    zpm.cli.askConfirmation("Do you want to uninstall these modules?", uninstall, no)
end

function Modules:showInstalled()

    noticef("The following modules are installed:")

    local results = self.loader.manifests("modules", "*", "*", function(m) return m:isInstalled() end)
    for _, r in ipairs(results) do
        noticef(" - %s", r.fullName)
    end
end

function Modules:_search(vendor, name, action, pred)

    vendor, name = self:_fixName(vendor, name)
    local results = self.loader.manifests("modules", vendor, name, pred)

    if #results > 0 then

        noticef("Are you sure you want to %s modules that match '%s/%s':", action, vendor, name)

        for _, r in ipairs(results) do
            noticef(" - %s", r.fullName)
        end

        return results
    else
        warningf("No module found that matches with '%s %s'", vendor, name)
    end

    return {}
end

function Modules:_fixName(vendor, name)
    if not name then
        local mod = vendor:explode( "/" )
        vendor, name = mod[1], mod[2]
    end
    return vendor, name
end