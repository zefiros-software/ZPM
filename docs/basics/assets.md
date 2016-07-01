# Assets Manifest
We have **three** different types of asset manifests:

* **Local** asset manifest
* **Root** asset manifests
* **Normal** asset manifests

Asset manifests are loaded in the **order** described above, and duplicate names will be ignored. 

!!! alert-success "Note"
    Since duplicate names are ignored, the local asset manifest can be used to override other asset manifests.

The asset manifests definition consists of a listing of a name and a repository, and are listed in a `_assets.json`:

```json
//_assets.json
[
    {
        "name": "<vendor-name>/<asset-name>",
        "repository": "https://<url-to-repo>.git"
    }
]
```
Where   

 * `vendor-name` is **alpha-numeric** and may contain '**-**' and '**_**'.
 * `asset-name` is **alpha-numeric** and may contain '**-**' and '**_**'.
 * `repository` is a git url (may be **private**).

 ----

## Local Asset Manifest
Local Manifests are added on a per **project** basis.
By defining a `._assets.json` file in the root of your project we can add
new packages available to **that** project only.

## Root Asset Manifest
The root manifest contains assets that are defined by the root registry.

## Normal Asset Manifest
The normal manifests are assets defined by normal registries.

!!! alert-success "Note"
    To get your **own** assets included in the root or normal manifest, you can setup a **pull request** to get it validated!