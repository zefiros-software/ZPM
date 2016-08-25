# Using Assets
To use an asset, just place an `assets` section in your [`.package.json`](../packages/_package) in the form:

```
"assets": [
    {
        "name": "<vendor>/<name>",
        "version": "<version>
    }
]
```

Where  

* `<name>` is the **asset** we want to download.
* `<version>` specifies the [version](../packages/general/versions) we want to use.

When you or another project uses an asset, it will be **available** under
your [`assets/`](../basics/basics/#assets_folder) folder.

## Example
The following snippet:
```
// .package.json
{
    "name": "Test/MyProject",
    "assets": [
        {
            "name": "Zefiros-Software/Doxygen",
            "version": "@head"
        }
    ]
}
```
Will download Doxygen **into** the `assets/Test/MyProject/Zefiros-Software/Doxygen/` folder.

!!! alert-success "Note"
    More specialised assets can download assets outside your `assets` folder.

!!! alert-success "Note"
    For more information on how to use the **version** string, you should check [this](../packages/versions).

!!! alert-success "Note"
    Assets may also be added to the [`dev`](../packages/_package#dev) section of the [`.package.json`](../packages/.package).