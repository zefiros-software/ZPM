# Special Commands
ZPM introduces new commands, or slightly modified commands.

## Available Commands

* [`headeronly`](#headeronly_command)
* [`uses`](#uses_command)
* [`reuses`](#reuses_command)
* [`dependson`](#dependon_command)
* [`configmap`](#configmap_command)
* [`vpaths`](#vpaths_command)

### `headeronly` Command
When your project should *not* be linked against, you should set `headeronly` on true. This way ZPM knows
there are no lib files to **link** against.

** Example **
```json
//_build.json
[
    {
        "project": "Example",
        "do": [
            {"includedirs": "include/"},
            {"headeronly": true}
        ]
    }
]
```


!!! alert-warning "Note"
    By default ZPM **links** projects when used.

----

### `uses` Command
Specifies you either want to use a project from the **current** [`_build.json`]() 
or a **dependency** from your [`_package.json`]() in this project.

** Example **
```json
//_build.json
[
    {
        "project": "Lib",
        "do": [
            {"files": "src/*.cpp"}
        ]
    },
    {
        "project": "Test",
        "do": [
            {"uses": "Zefiros-Software/GoogleTest"}
            {"uses": "Lib"}
            {"files": "test/*.cpp"}
        ]
    }
]
```

----

### `reuses` Command
Specifies you want to **use** and **re-export** a project from your [`_package.json`]().

** Example **
```json
//_build.json
[
    {
        "project": "MathLibrary",
        "do": [
            {"reuses": "Zefiros-Software/PlotLib"}
        ]
    }
]
```

----

### `dependson` Command
Specify one or more **non-linking** project build order dependencies. These projects are
from the same [`_build.json`]() and are converted to the correct project name.
Check [this](https://github.com/premake/premake-core/wiki/dependson) for more information.

** Example **
```json
//_build.json
[
    {
        "project": "HeaderLib",
        "do": [
            {"includedirs": "include/"}
        ]
    },
    {
        "project": "Test",
        "do": [
            {"uses": "Zefiros-Software/GoogleTest"}
            {"includedirs": "include/"}
            {"dependson": "HeaderLib"}
            {"files": "test/*.cpp"}
        ]
    }
]
```

----

### `configmap` Command
Map workspace level configuration and platforms to a different project configuration or platform.
Check [this](https://github.com/premake/premake-core/wiki/configmap) for more information.

**Usage**
```json
{"configmap": [
    {
        "workspace": <workspace>,
        "project": <project>
    }
]}
```
Where  

* <workspace> a *list* of *strings* or *string* with workspace configurations that are **mapped**.
* <project> a *list* of *strings* or *string* with project configurations we map **to** workspace.


** Example **
```json
//_build.json
[
    {
        "project": "Lib",
        "do": [
            {"configurations": ["WeirdDebug"]},
            {"includedirs": "include/"}
            {"files": [
                "src/",
                "src2/",
                "include/"
            ]}
            {"configmap": [                
                {
                    "workspace": "Debug",
                    "project": ["WeirdDebug", "WeirdDebug2"],
                }
            ]}
        ]
    }
]
```

----

### `vpaths` Command
Places files into **groups** or "virtual paths", rather than the default behavior of mirroring the filesystem in IDE-based projects.
Check [this](https://github.com/premake/premake-core/wiki/vpaths) for more information.

**Usage**
```json
{"vpaths": [
    {
        "name": <name>,
        "vpaths": <vpaths>
    }
]}
```
Where  

* <name> either *array* of *strings* or *string* to group **under**.
* <vpaths> either *array* of *paths* or *path* patterns we **group**.


** Example **
```json
//_build.json
[
    {
        "project": "Lib",
        "do": [
            {"includedirs": "include/"}
            {"files": [
                "src/",
                "src2/",
                "include/"
            ]}
            {"vpaths": [                
                {
                    "name": "Headers",
                    "vpaths": [ "**.h", "**.hxx", "**.hpp" ],
                },           
                {
                    "name": "Sources/*",
                    "vpaths": [ "**.c", "**.cpp" ],
                }
            ]}
        ]
    }
]
```

----

## Related Pages
These **build** commands are available:  

* [Premake5](premake5) commands
* [Build](build) commands
* [Path](path) commands

These **region** commands are available:  

* [Export](../regions/export) regions
* [Reexport](../regions/reexport) regions
* [Filters](../regions/filters) regions
* [Options](../regions/options) regions