# Using Assets
To use an asset, just place an `assets` section in your [`_package.json`]() in the form:

```
"assets": [
    {
        "name": "<vendor>/<name>",
        "version": "<version>
    }
]
```

Where

* `name` is the **asset** we want to download.
* `<version>` specifies the **version** we want to use.

When you or another project uses an asset, it will be **available** under
your [`assets/`](../basics/basics/#assets_folder) folder.

** Example **
The following snippet:
```
// _package.json
{
    "name": "I/MyProject",
    "assets": [
        {
            "name": "Zefiros-Software/Anaconda",
            "version": ">=4.0.0"
        }
    ]
}
```
Will download the Anaconda installer **into** the `assets/I/MyProject/Zefiros-Software/Anaconda/` folder.


!!! alert-success "Note"
    Assets may also be added to the [`dev`]() section of the [`_package.json`]().