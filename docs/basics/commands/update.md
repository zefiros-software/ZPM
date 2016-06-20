# Updating
* [`self-update`](#self-update)
* [`update-bootstrap`](#update-bootstrap)
* [`update-module`](#update-module)
* [`update-modules`](#update-modules)
* [`update-registry`](#update-registry)
* [`update-zpm`](#update-zpm)

----

## `self-update`
This action updates premake5 to the **newest** version, and makes all older versions available from the command line.
After this we update everything ZPM uses and we **call** in order:

* [`update-bootstrap`](#update-bootstrap)
* [`update-registry`](#update-registry)
* [`update-zpm`](#update-zpm)
* [`update-modules`](#update-modules)

** Example **

 ```
 premake5 self-update
 ```

!!! alert-warning "Note"
    We do not support versions under premake-5.0.0-alpha6.

----

## `update-bootstrap`
This pulls the latest version from the master branch to the [bootstrap]() directory.

** Example **

 ```
 premake5 update-bootstrap
 ```

----

## `update-module`
Updates the given module to **head** of the master branch, and writes
all other **version** directories so they can be loaded.

** Example **

 * `premake5 update-module <vendor>/<name>`
 * `premake5 update-module <vendor> <name>`

----

## `update-modules`
Updates all installed modules using [`update-module`](#update-module).

** Example **

 ```
 premake5 update-modules
 ```

----

## `update-registry`
This pulls the latest version from the master branch to the [registry](../registries) directory.

** Example **

 ```
 premake5 update-registry
 ```

!!! alert-success "Note"
    This is also done when you normally use ZPM.

----

## `update-zpm`
This pulls the latest version from the master branch to the ZPM directory.

** Example **

 ```
 premake5 update-zpm
 ```

!!! alert-warning "Note"
    Please note that this only updates the ZPM code.

----

## Related Pages

* [Commands](../commands)
* [Flags](flags)
* [Install](install)