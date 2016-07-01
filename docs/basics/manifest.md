# Adding Packages
A package manifest is a collection of repository names and repository locations.

We have **three** types of manifests:

* **Local** Manifest
* **Root** Manifest
* **Normal** Manifest

Manifests are loaded in that **order**, wherein duplicate names will be ignored.

!!! alert-success "Note"
    Since duplicate names are ignored, the local manifests can be used to override other manifests.

## Definition
The manifest definition consists of a listing of a name and a repository, and are listed in a `_manifest.json`:

```json
//_manifest.json
[
    {
        "name": "<vendor-name>/<package-name>",
        "repository": "https://<repository>.git"
    }
]
```
Where   

 * `vendor-name` is **alpha-numeric** and may contain '**-**' and '**_**'.
 * `package-name` is **alpha-numeric** and may contain '**-**' and '**_**'.
 * `repository` is a git url (may be **private**).

----

## Local Manifest
Local Manifests are added on a per **project** basis.
By defining a `._manifest.json` file in the root of your project we can add
new packages available to **that** project only.

## Root Manifest
The root manifest contains packages that are defined by the root registry.

## Normal Manifest
The normal manifests are packages defined by normal registries.

!!! alert-success "Note"
    To get your **own** packages included in the root or normal manifest, you can setup a **pull request** to get it validated!