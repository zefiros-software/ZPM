# Filter Regions
Just like premake5 allows you to use **filters** for system **configurations**,
ZPM also allows you to do this. For a more in-depth explanation of
filters, please look [here](https://github.com/premake/premake-core/wiki/filter).


## Usage
In the filter region
```json
{"filter": "<filter>",
 "do": [
     <commands>
 ]}
```

Where  

* `commands` are the commands executed when the filter is active.

!!! alert-success "Note"
    Filters are **obeyed** in [export](export) regions and are also re-exported.

!!! alert-danger "Note"
    Filters can **only** be used for commands used by premake5. Otherwise
    you should look at [options](options).

## Example
```json
//_build.json
[
    {
        "project": "ThreadingExample",
        "do": [
            {"filter": "system:not windows",
                "do": [
                {"links": [
                    "pthread"
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

* [Export](export) regions
* [Reexport](reexport) regions
* [Options](options) regions