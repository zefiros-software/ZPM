# Export Commands
Sometimes you define commands in your project that you also want
to **export** to other projects using it. The `export` region allows you
to do exactly this.

## Usage
In the export region
```
{"export": [
    <commands>
]}
```
you define commands as usual. However these commands are **both** 
executed in the current project, and the projects that use it.

## Example
```
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
The following **build** commands are available:  

* [Premake5](premake5) commands
* [Build](build) commands
* [Export](export) commands
* [Reexport](reexport) commands
* [Filters](filters) commands
* [Path](path) commands
* [Special](special) commands