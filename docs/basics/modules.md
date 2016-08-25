# Adding Modules
A module manifest is a collection of repository names and repository locations.

We have **three** types of manifests:

* **Local** Module Manifest
* **Root** Module Manifest
* **Normal** Module Manifest

Module Manifests are loaded in that **order**, wherein duplicate names will be ignored.

!!! alert-success "Note"
    Since duplicate names are ignored, the local module manifests can be used to override other manifests.

## Definition
The manifest definition consists of a listing of a name and a repository, and are listed in a `.manifest.json`:

```json
//_modules.json
[
    {
        "name": "<vendor-name>/<module-name>",
        "repository": "https://<repository>.git"
    }
]
```
Where   

 * `vendor-name` is **alpha-numeric** and may contain '**-**' and '**_**'.
 * `module-name` is **alpha-numeric** and may contain '**-**' and '**_**'.
 * `repository` is a git url (may be **private**).

----

## Local Module Manifest
Local Manifests are added on a per **project** basis.
By defining a `.module.json` file in the root of your project we can add
new modules available to **that** project only.

## Root Module Manifest
The root manifest contains modules that are defined by the root registry.

## Normal Module Manifest
The normal manifests are modules defined by normal registries.

!!! alert-success "Note"
    To get your **own** modules included in the root or normal manifest, you can setup a **pull request** to get it validated!