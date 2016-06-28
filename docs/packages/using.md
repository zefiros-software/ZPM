# Using Packages
To use ZPM packages you should have the following directory structure:

* [`/_package.json`](general/_package): Package configuration.
* [`/extern/`](../basics/basics#extern_folder): Reserved for external packages.
* [`/assets/`](../basics/basics#assets_folder): Reserved for external assets.
* `/*`: Other files and directories.

## _package.json
In the `_package.json` you describe what **dependencies** (packages, modules, and  
assets) your own project uses.

## extern
In this folder the external **packages** downloaded by ZPM are stored.

## assets
In this folder the external **assets** downloaded by ZPM are stored.