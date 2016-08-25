# Publishing Packages
To publish a ZPM package you should have the following directory structure:

* [`/.package.json`](general/.package): Package configuration.
* [`/.build.lua`](.build): The build configuration.
* `/*`: Other files and directories.

## .package.json
In the `.package.json` you describe what **dependencies** (packages, modules, and  
assets) your own package uses, and should be available from the root project.

## .build.lua
In the `.build.lua` we define how the projects should be **built** and **linked** against.