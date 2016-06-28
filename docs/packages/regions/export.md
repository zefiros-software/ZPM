# Export Region
Sometimes you define commands in your project that you also want
to **export** to other projects using it. The `export` region allows you
to do exactly this.

## Usage
In the export region
```json
{"export": [
    <commands>
]}
```
you define commands as usual. However these commands are **both** 
executed in the current project, and the projects that use it.

## Example
```json
//_build.json
[
    {
        "project": "Example",
        "do": [
            {"export": [
                {"includedirs": [
                    "include/"
                ]}
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

* [Reexport](reexport) regions
* [Filters](filters) regions
* [Options](options) regions