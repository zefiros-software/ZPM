# Path Commands
All path commands are executed as if they were executed from the (shadow) repository **root**.

## Example
```json
//_build.json
[
    {
        "project": "Example",
        "do": [
            {"files": [
                "src/*.cpp",
                "include/*.h"
            ]}
        ]
    }
]
```

## Available Commands
* [`includedirs`](https://github.com/premake/premake-core/wiki/includedirs)
* [`libdirs`](https://github.com/premake/premake-core/wiki/libdirs)
* [`sysincludedirs`](https://github.com/premake/premake-core/wiki/sysincludedirs)
* [`syslibdirs`](https://github.com/premake/premake-core/wiki/syslibdirs)
* [`files`](https://github.com/premake/premake-core/wiki/files)
* [`forceincludes`](https://github.com/premake/premake-core/wiki/forceincludes)

----

## Related Pages
These **build** commands are available:  

* [Premake5](premake5) commands
* [Special](special) commands
* [Build](build) commands

These **region** commands are available:  

* [Export](../regions/export) regions
* [Reexport](../regions/reexport) regions
* [Filters](../regions/filters) regions
* [Options](../regions/options) regions