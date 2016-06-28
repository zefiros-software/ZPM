# Dev Section
The `dev` section allow you to use ZPM packages for the development of libraries. 
Commands in this section are **only** executed when the current package is **root**, 
these settings are **not** exported when the package is used by **another** project.

## Example
Inside the `_package.json` we can add a `dev` section like so:
```json
// _package.json
"dev": {
        "requires": [
            {
                "name": "Zefiros-Software/GoogleTest",
                "version": "@head"
            }
        ]
    }
```
When we now run `premake5` commands on this directory,  
we have `Zefiros-Software/GoogleTest` **available** for usage.

----

## Related Pages

* [_package.json](_package)
* [Overrides](overrides)
* [Versions](versions)