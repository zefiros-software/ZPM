# _build.json File
The `_build.json` file describes how packages are **built**.  
The file is in the form:

```json
[
    {
        "project": "<name>",
        "options": {
            <options>
        },
        "do":
        [
            <commands>
        ]
    }
]
```

Where  

* `name` The name of the project.
* `options` What [options](regions/options) the project has, and their default values.
* `commands` The commands we want to execute.

## Commands
These **build** commands are available:  

* [Premake5](commands/premake5) commands
* [Build](commands/build) commands
* [Export](commands/export) commands
* [Reexport](commands/reexport) commands

These **region** commands are available:  

* [Filters](filters) commands
* [Path](path) commands
* [Special](special) commands