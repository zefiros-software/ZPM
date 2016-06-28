# Option Regions
When you want to deliver your package with several options that are decided compile time, you can 
use the `filter-options` region.

## Usage
The `filter-option` region is used in three parts.

### _build.json Options
The `_build.json` file has a region to specify which options are **defined** in the project.
This is in the form
```json
"options": {
    <options>
}
```

Where `options` is an object of key-value pairs that define the options **available**, and their **default** value.


### _build.json Command
In the `filter-option` region in `_build.json` files we
can **filter** on the option values.
```json
{"filter-options": {<options>},
 "do": [
     <do-commands>
 ]}
```
** or ** 
```json
{"filter-options": {<options>},
 "do": [
     <do-commands>
 ],
 "otherwise": [
     <otherwise-commands>
]}
```

Where  

* `options` is an object with **key-value** pairs which we all test.
* `do-commands` when **every** value in the condition is **true**, this is executed.
* `otherwise-commands` when **one** value in the condition is **false**, this is executed.

!!! alert-success "Note"
    ZPM stops executing when the conditions are not met, thus these regions are **safe** to 
    **export** and **re-export**.

    
### _package.json
When we want to change the value of the options, we have to do this project wide in the
`_package.json`. In the package that uses it you **override** the options from the `_build.json` in
the [`require`]() field. This is in the form:

```
"options":[
    {"project": "<name>",
     "options": {
        <options>
    }}    
]
```
Where 

* `name` is the project name we want to set the option on.
* `options` are **key-value** pairs that override the default options.


## Example
```json
//_build.json
[
    {
        "project": "UseOtherLibProject",
        "options": {
            "UseOtherLib": true
        },
        "do":
        [
            {
                "filter-options": {
                    "UseOtherLib": true
                },
                "do":
                [
                    {"reuses": "Zefiros-Software/OtherLib"},
                ],
                "otherwise":
                [                    
                    {"defines": "NO_OTHER_LIB"}
                ]
            }
        ]
    }
]
```

In the project that uses it
```json
//_package.json
{
    ...
    "requires": [
        {
            "name": "Zefiros-Software/UseOtherLibProject",
            "version": "@head",
            "options": [
                {"project": "UseOtherLibProject",
                 "options": {
                    "UseOtherLib": false
                }}
            ],
        }
    ]
}
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
* [Filters](filters) regions