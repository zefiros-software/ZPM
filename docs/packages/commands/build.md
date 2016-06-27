#Build Commands
Some premake5 commands require access to **shell** scripts.
Due to security concerns ZPM asks **permission** to use these.


!!! alert-success "Note"
    You can by default accept this access by enabling the [`--allow-shell`](../../basics/commands/flags#allow-shell).


## Example
```
//_build.json
[
    {
        "project": "Example",
        "do": [
            {"buildcommands": '"luac -o "%{cfg.objdir}/%{file.basename}.out" "%{file.relpath}"'}
        ]
    }
]
```

## Available Commands
* [buildcommands](https://github.com/premake/premake-core/wiki/buildcommands)
* [debugcommand](https://github.com/premake/premake-core/wiki/debugcommand)
* [debugconnectcommands](https://github.com/premake/premake-core/wiki/debugconnectcommands)
* [debugstartupcommands](https://github.com/premake/premake-core/wiki/debugstartupcommands)
* [postbuildcommands](https://github.com/premake/premake-core/wiki/postbuildcommands)
* [prebuildcommands](https://github.com/premake/premake-core/wiki/prebuildcommands)

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