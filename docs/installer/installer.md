# Installer
ZPM can be used to **install** external dependencies (modules, assets, packages, installer scripts) that are used
by packages, such as scipy, from command line.

## Calling 
To call the installer you should open the current directory from shell and use
as described [here](../basics/commands/install#install-package):

```
premake5 install-package
```

## Creating
To create an installer for your package, you should add an `install` environment in your
[`_package.json`](../packages/general/_package#install).

** Example **
```json
// _package.json
"install": "install/dev.lua",
```

This lua file wil be executed, when the install command is run. And so will the 
installer of the dependencies of dependencies.

For example to install `mkdocs` using an installer script:
```lua
-- install/dev.lua
os.execute( "pip install mkdocs -U" )
os.execute( "pip install mkdocs-bootswatch -U" )
```