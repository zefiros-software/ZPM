# Overrides
Useful when you want to add extra build commands to the default `_build.json` file.
This allows you to **append** new commands at the **bottom** of the project build configuration.

## Example
Inside the `_package.json` we can add a `overrides` section like so:
```json
// _package.json
"requires": [
    {
        "name": "Zefiros-Software/ArmadilloExt",
        "version": ">=1.2.0",
        "overrides": [
            {"project": "Armadillo",
             "do": [
                {"defines": "DEBUG"}
            ]}
        ]
    }
]
```
Now we have added the `DEBUG` symbol to the project in every configuration.

----

## Related Pages

* [_package.json](_package)
* [Dev](dev)
* [Versions](versions)