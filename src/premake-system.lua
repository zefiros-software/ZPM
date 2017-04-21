
local function _updateRepo(destination, url, name, branch)
    local current = os.getcwd()

    if os.isdir(destination) then

        printf(" - Updating '%s'", name)
        os.chdir(destination)
        if branch then        
            os.executef("git checkout %s", branch)
        else
            os.execute("git checkout .")
        end

        if url and branch then
            os.executef("git pull %s %s", url, branch)
        else
            os.execute("git pull")
        end

        os.chdir(current)

    else
        printf(" - Creating '%s'", name)
        if branch then
            os.executef("git clone -v -b %s --recurse --progress \"%s\" \"%s\"", branch, url, destination)
        else
            os.executef("git clone -v --recurse --progress \"%s\" \"%s\"", url, destination)
        end
    end
end
        
newaction {
    trigger = "update-bootstrap",
    shortname = "Update module loader",
    description = "Updates the module loader bootstrapping process",
    execute = function()

        local destination = path.join(CMD, BOOTSTRAP_DIR)
        _updateRepo(destination, BOOTSTRAP_REPO, "bootstrap loader", BOOTSTRAP_BRANCH)
    end
}

newaction {
    trigger = "update-zpm",
    shortname = "Update zpm",
    description = "Updates the zpm module",
    execute = function()

        local destination = path.join(CMD, ZPM_DIR)
        _updateRepo(destination, ZPM_REPO, "zpm", ZPM_BRANCH)
    end
}

newaction {
    trigger = "update-registry",
    shortname = "Update the registry",
    description = "Updates the zpm library definitions",
    execute = function()

        local destination = path.join(CMD, REGISTRY_DIR)
        _updateRepo(destination, REGISTRY_REPO, "registry", REGISTRY_BRANCH)
    end
}

newaction {
    trigger = "repair",
    shortname = "Repairs ZPM",
    description = "Repairs the current installation",
    execute = function()

        premake.action.call("update-bootstrap")
        premake.action.call("update-zpm")
        premake.action.call("update-registry")
    end
}
 
if not (_ACTION and (_ACTION:contains("update-") or _ACTION == "repair")) then

    if not zpm or (zpm and not zpm.__isLoaded) then
            
        bootstrap = dofile(path.join(_PREMAKE_DIR, "../bootstrap/bootstrap.lua"))

        zpm = dofile(path.join(_PREMAKE_DIR, "../zpm/zpm.lua"))
        zpm.onLoad()
        zpm.__isLoaded = true
    end
else
    zpm.util.disableMainScript()
end