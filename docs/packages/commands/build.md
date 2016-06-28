#Build Commands
Some premake5 commands require access to **shell** scripts.
Due to security concerns ZPM asks **permission** to use these.


!!! alert-success "Note"
    You can by default accept this access by enabling the [`--allow-shell`](../../basics/commands/flags#allow-shell).


## Example
```json
//_build.json
[
    {
        "project": "Example",
        "do": [
            {"buildcommands": "'luac -o '%{cfg.objdir}/%{file.basename}.out' '%{file.relpath}'"}
        ]
    }
]
```

## Available Commands
* [`buildcommands`](https://github.com/premake/premake-core/wiki/buildcommands)
* [`debugcommand`](https://github.com/premake/premake-core/wiki/debugcommand)
* [`debugconnectcommands`](https://github.com/premake/premake-core/wiki/debugconnectcommands)
* [`debugstartupcommands`](https://github.com/premake/premake-core/wiki/debugstartupcommands)
* [`postbuildcommands`](https://github.com/premake/premake-core/wiki/postbuildcommands)
* [`prebuildcommands`](https://github.com/premake/premake-core/wiki/prebuildcommands)

----

## Related Pages
These **build** commands are available:  

* [Premake5](premake5) commands
* [Special](special) commands
* [Path](path) commands

These **region** commands are available:  

* [Export](../regions/export) regions
* [Reexport](../regions/reexport) regions
* [Filters](../regions/filters) regions
* [Options](../regions/options) regions