# Registries
A registry is a collection of **modules**, **packages**, **assets**, and sometimes **other** registries.

We have **three** different types of registries:

* **Local** Registries
* **Root** Registries
* **Normal** Registries

Registries are loaded in the **order** described above, and duplicate names will be ignored. 

!!! alert-success "Note"
    Since duplicate names are ignored, the local registries can be used to override other registries.

## Definition
The registry definition consists of a listing of a name and a repository, and are listed in a `_registries.json`:

```json
//_registries.json
[
    {
        "name": "<name>",
        "repository": "https://<repository>.git"
    }
]
```
Where   

 * `name` is alpha-numeric and may contain '-' and '_'.
 * `repository` is a git url (may be **private**).

 ----

## Local Registries
Local registries are registries that are added on a per **project** base override.
By defining a `._registries.json` file in the root of a project, we can add
new registries that contain registries **specific** for that project.
These registries may define [assets](../../assets/assets), [packages]() and [modules]().

!!! alert-warning "Warning"
    `_registries.json` from these registries will not be loaded.

## Root Registries
Root registries are registries that may define new registries to load. Since their `_registries.json` files
will be parsed and added. 
These registries may define [assets](../../assets/assets), [packages]() and [modules]().

## Normal Registries 
These registries may define [assets](../../assets/assets), [packages]() and [modules]().

!!! alert-warning "Warning"
    `_registries.json` from these registries will not be loaded.

----

## Related Pages

* [Basics](basics)
* [Commands](commands)