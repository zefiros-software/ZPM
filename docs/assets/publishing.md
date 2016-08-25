# Publishing Assets
When publishing an asset you should consider a few things. We have **two** type of repositories:

* **Normal**: The assets and `.assets.lua` are in the **same** repository.
* **Shadow**: The assets and asset definition are in **different** repositories.

## Normal Repository
In this case the Git LFS repository and `.assets.lua` are combined in the same repository.

### Directory Layout
Assets have the following *directory layout*:

 * [`/.assets.lua`](#available_commands) describes how the asset is **used**.
 * `/*` **files** and **directories** of the asset.

Where  

* `.assets.lua` is a sandboxed lua file.

----

## Shadow Repository
In this type the Git LFS repository and asset definition are separated in **different** repositories.
We have to specify how each **version** of the asset should be used. All commands are executed as if they
were done from the shadow repository.

### Directory Layout
Assets have the following *directory layout*:

 * `/.assets.json` describes what buildfile.
 * [`/<build-name>.lua`](#available_commands) describes how the asset is **used**.

This `.assets.json` is of the format:

```
[
    {
        "version": <version>,
        "file": <file>.lua
     }
]
```
Where  

* `<version>` is [checked](../packages/general/versions) against the required version.
* `<file>.lua` is the asset build file we execute, we hit **first** when our `<version>` **matches**.

And in the shadow repository:

 * `/*` **files** and **directories** of the asset.

----

** Example **
```json
//_assets.json
[
    {
        "version": ">1.0.0 || @head",
        "file": ".assets.2.lua"
    },
    {
        "version": "^0.0.0",
        "file": ".assets.1.lua"
    }
]
```

**with**
```lua
// .assets.1.lua
zpm.assets.extract( "*.exe" )
```
**and**
```lua
// .assets.2.lua
zpm.assets.extract( {
    "*.dll",
    "*.exe"
} )
```

!!! alert-warning "Note"
    The build file will always use the **head** of the repository in a shadow repository setting.

----

# Available commands 
By default ZPM does nothing with cloned assets, and thus we need to **move**
the files or **download** new ones.


!!! alert-warning "Warning"
    This lua file is sandboxed, and thus the function one can use are limited.

**Available special functions**

* [`download`](#zpmassetsdownload) downloads assets from an **url**.
* [`extract`](#zpmassetsextract) extracts files from a repository to the assets folder.
* [`extractto`](#zpmassetsextractto) extracts files from a repository to the given folder.

## `zpm.assets.download`
Downloads assets form a given archive or file url.

```lua
zpm.assets.download( <url>, <to> )
```

Where 

* `url` is an url to an **archive** (.zip or .tar.gz) or **file**.
* `to` is an alpha-numeric (with '-' and '_') name wherein we **place** the (extracted) files.
  This folder lies within the **project** `assets` folder.

----

## `zpm.assets.extract`
We also support files from our **Git** or **Git LFS** repository to be downloaded.

```lua
zpm.assets.extract( <patterns> )
```
* `<patterns>` is an array of strings that are passed to [os.matchfiles](https://github.com/premake/premake-core/wiki/os.matchfiles).  
  Matched files are copied and we leave the relative path intact. 

!!! alert-warning "Warning"
    Files extracted with this method get placed in the `assets` folder.

----

## `zpm.assets.extractto`
```lua
zpm.assets.extractto( <patterns>, <to> )
```

Where 

* `<patterns>` is an array of strings that are passed to [os.matchfiles](https://github.com/premake/premake-core/wiki/os.matchfiles).  
  Matched files are copied and we leave the relative path intact.
* `<to>` the directory to copy the files to, from the root of the repository. Relative paths are left intact.

** Examples **
```lua
//.assets.lua
zpm.assets.extract({
    "*.exe",
    "*.dll"
})

zpm.assets.extractto( "style/*", "docs"/)

if os.is( "windows" ) then
    zpm.assets.download("www.graphviz.org/pub/graphviz/stable/windows/graphviz-2.38.zip", "graphviz" )
end
```