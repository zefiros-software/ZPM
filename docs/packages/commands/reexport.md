# Reexport Commands
When you want to **export** commands, and use exported commands from another project,
you can use the **reexport** region.

## Usage
In the reexport region
```
{"reexport": [
    {"<command>": "<project>"}
]}
```
you define which command from which project you want to reexport. However these commands are **both** 
executed in the current project, and the projects that use it.

Where:

* `command`: The command to reexport.
* `project`: The project to reexport from.

## Example
```
//_build.json
[
    {
        "project": "ExportProject",
        "do": [
            {"export": [
                {"includedirs": [
                    "include/"
                ]}
            ]}
        ]
    },
    {
        "project": "Example",
        "do": [
            {"reexport": [
                {"includedirs": "ExportProject"}
            ]}
        ]
    }
]
```

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