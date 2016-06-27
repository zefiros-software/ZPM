# Special Commands
ZPM introduces new commands, or slightly modified commands.

## Available Commands

* [`headeronly`]()
* [`uses`]()
* [`reuses`]()
* [`dependson`]()
* [`configmap`]()
* [`vpaths`]()

### `headeronly` Command
When your project should **not** be linked against,
you should set `headeronly` on true. This way ZPM knows
there are no lib files to **link** against.

** Example **
```
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
    By default ZPM links projects when used.

----

### `uses` Command

----

### `reuses` Command

----

### `dependson` Command

----

### `configmap` Command

----

### `vpaths` Command

----

## Related Pages
The following **build** commands are available:  

* [Premake5](premake5) commands
* [Build](build) commands
* [Export](export) commands
* [Reexport](reexport) commands
* [Filters](filters) commands
* [Path](path) commands
* [Special](special) commands