# Using Packages
To use ZPM packages you should have the following directory structure:

* [`/_package.json`](general/_package): Package **configuration**.
* [`/extern/`](../basics/basics#extern_folder): Reserved for external **packages**.
* [`/assets/`](../basics/basics#assets_folder): Reserved for external **assets**.
* [`/premake5.lua`](../premake5/using): Describing how your project should be **built**.
* `/*`: Other **files** and **directories**.

** Optionally **

* [`._registries.json`](../basics/registries.md): Adding your own **registries**.
* [`._manifest.json`](../basics/manifest.md): Adding your own **packages**.
* [`._assets.json`](../basics/assets.md): Adding your own **assets**.
* [`._modules.json`](../basics/modules.md): Adding your own **modules**.

## _package.json
In the `_package.json` you describe what **dependencies** (packages, modules, and  
assets) your own project uses.

## extern
In this folder the external **packages** downloaded by ZPM are stored.

## assets
In this folder the external **assets** downloaded by ZPM are stored.

# Premake5 Usage
Since ZPM only download dependencies for you, you should define how to [use](../premake5/using) them.