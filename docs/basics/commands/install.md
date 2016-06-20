
# Installing

* [`install-module`](#install-module)
* [`install-package`](#install-package)
* [`install-zpm`](#install-zpm)

----

## `install-module`
**Installs** the given module, and writes
all **version** directories so they can be loaded.

** Example **

 * `premake5 install-module <vendor>/<name>`
 * `premake5 install-module <vendor> <name>`

!!! alert-warning "Note"
    If the module already exists, it gets updated in stead.

----

## `install-package`
Run all the installer scripts of the current package, and its dependencies.

** Example **

 ```
 premake5 install-package
 ```

!!! alert-danger "Note"
    Since this executes third-party lua scripts, your permissions is asked.
    To avoid this you can enable the [`--allow-install`](flags#allow-install) flag to accept all installs.

----

## `install-zpm`
Installs ZPM and premake5 in your path.

** Example **

 ```
 premake5 install-zpm
 ```

!!! alert-danger "Note"
    This command should not be called manually.

----

## Related Pages

* [Commands](../commands)
* [Flags](flags)
* [Update](update)