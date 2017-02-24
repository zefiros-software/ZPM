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


local function _updateRepo(destination, url, name, branch)
    local current = os.getcwd()

    if os.isdir(destination) then

        printf("Updating %s...", name)

        os.chdir(destination)
        branch = iif(branch ~= nil,("%s"):format(branch), ".")
        os.executef("git checkout %s", branch)
        os.execute("git pull")

        os.chdir(current)

    else

        print("Creating " .. name .. "...")
        branch = iif(branch ~= nil,("-b %s"):format(branch), "")
        os.executef("git clone -v %s --recurse --progress \"%s\" \"%s\"", branch, url, destination)
    end
end
        
newaction {
    trigger = "update-bootstrap",
    shortname = "Update module loader",
    description = "Updates the module loader bootstrapping process",
    execute = function()

        local destination = path.join(CMD, BOOTSTRAP_DIR)
        _updateRepo(destination, BOOTSTRAP_REPO, "bootstrap loader")
    end
}

newaction {
    trigger = "update-zpm",
    shortname = "Update zpm",
    description = "Updates the zpm module",
    execute = function()

        local destination = path.join(CMD, INSTALL_DIR)
        _updateRepo(destination, INSTALL_REPO, "zpm", ZPM_BRANCH)
    end
}

newaction {
    trigger = "update-registry",
    shortname = "Update the registry",
    description = "Updates the zpm library definitions",
    execute = function()

        local destination = path.join(CMD, REGISTRY_DIR)
        _updateRepo(destination, REGISTRY_REPO, "registry")

        if os.isdir(REGISTRY_DIR) then
            assert(os.mkdir(REGISTRY_DIR))
        end
    end
}

if _ACTION ~= "update-bootstrap" and
    _ACTION ~= "update-zpm" and
    _ACTION ~= "update-registry" then

    if _ACTION ~= "install-zpm" then
        bootstrap = dofile(path.join(_PREMAKE_DIR, "../bootstrap/bootstrap.lua"))
    end

    zpm = dofile(path.join(_PREMAKE_DIR, "../zpm/zpm.lua"))
    zpm.onLoad()
    zpm.__isLoaded = true
else
    _MAIN_SCRIPT = "."
end