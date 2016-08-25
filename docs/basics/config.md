# Configuration
For **customisation** of ZPM we load in a configuration file.

In **order** we look for the following configuration files:  

1. `<zpm-install-directory>/config.json`
2. `<premake5.lua-directory>/config.json`
3. `<premake5.lua-directory>/.config.json` - should be **private** and in .gitignore
4. `<premake5.lua-directory>/../.config.json`

Wherein each configuration node **overrides** the previous values. An example of 
the default configuration can be found in the ZPM repository.

## GitHub token
You may notice that sometimes you are **restricted** by the GitHub api access rate.
To prevent this from happening you may add a **GitHub token** in a configuration file 
in the paths described above to **authenticate** yourself.

** Example **
The following settings may be overriden:

````json
//.config.json
{
    "GitHub": {
        "token": "<token>"
    },
    "install": {
        "registry": {
            "directory": "registry",
            "directories": "registries",
            "fileName": ".registries.json",
            "assets": ".assets.json",
            "modules": ".modules.json",
            "manifest": ".manifest.json",
            "registries": ".registries.json",
            "build": ".build.json"
        },        
        "manifests": {
            "fileName": ".manifest.json"
        },
        "modules": {
            "fileName": ".modules.json",
            "directory": "modules"
        },
        "packages": {
            "fileName": ".package.json"
        },
        "assets": {
            "fileName": ".assets.lua",
            "directory": "assets"
        },
        "build": {
            "fileName": ".build.lua"
        },
        "extern": {
            "directory": "extern"  
        }
    }
}
````

!!! alert-success "Note"
    Absolute filepaths are supported!