# Reexport Region
When you want to **export** commands, and use exported commands from another project,
you can use the `reexport` region.

## Usage
In the re-export region
```json
{"reexport": [
    {"<command>": "<project>"}
]}
```
you define which command from which project you want to re-export. However these commands are **both** 
executed in the current project, and the projects that use it.

Where:

* `command`: The command to re-export.
* `project`: The project to re-export from.

## Example
```json
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
These **build** commands are available:  

* [Premake5](../commands/premake5) commands
* [Special](../commands/special) commands
* [Build](../commands/build) commands
* [Path](../commands/path) commands

These **region** commands are available:  

* [Export](export) regions
* [Filters](filters) regions
* [Options](options) regions