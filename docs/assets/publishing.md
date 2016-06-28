# Publishing Assets
When publishing an asset you should consider a few things. Inside a (shadow) assets directory we find a `_assets.json` in the root. This file
describes how the asset should download files from its repository

## Normal Repository
Usually the Git LFS repository and `_assets.json` are combined in the same repository.

### Directory Layout
Assets have the following *directory layout*:

 * [`/_assets.json`](_assets) describes how the asset is **used**.
 * `/*` **files** and **directories** of the asset.

Where  

* `_assets.json` is of the format `[<commands>]`.


** Example **
```
//_assets.json
[
    {"system": "windows",
     "do": [
        {"files": [
            "*.exe"
        ]}
    ]}
]
```

----

## Shadow Repository
In this type the Git LFS repository and `_assets.json` are separated in **different** repositories.
This means our `_assets.json` has to be adjusted likewise, and thus we have to specify how
each **version** of the asset should be used. All commands are executed as if they
were done from the shadow repository.

### Directory Layout
Assets have the following *directory layout*:

 * [`/_assets.json`](_assets) describes how the asset is **used**.

This `_assets.json` is of the format:

```
[
    {"version": <version>,
     "do" [
        <commands>
    ]}
]
```
Where  

* `<version>` is [checked](../packages/general/versions) against the required version.
* `do` is the asset build section we execute, we hit **first** when our `<version>` **matches**.

And in the shadow repository:

 * `/*` **files** and **directories** of the asset.

** Example **
```json
//_assets.json
[
    {
        "version": ">1.0.0 || @head",
        "do" [
            {"system": "windows",
             "do": [
                {"files": [
                    "*.exe"
                ]}
            ]}
        ]
    }
]
```

!!! alert-warning "Note"
    The build file will always use the **head** of the repository in a shadow repository setting.
