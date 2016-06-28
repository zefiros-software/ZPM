# Publishing Packages
To publish a ZPM package you should have the following directory structure:

* [`/_package.json`](general/_package): Package configuration.
* [`/_build.json`](_build): The build configuration.
* `/*`: Other files and directories.

## _package.json
In the `_package.json` you describe what **dependencies** (packages, modules, and  
assets) your own package uses, and should be available from the root project.

## _build.json
In the `_build.json` we define how the projects should be **built** and **linked** against.