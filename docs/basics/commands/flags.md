# Flags
ZPM also introduces some new flags:

* [`allow-install`](#allow-install)
* [`allow-shell`](#allow-shell)

----

## `allow-install`
When ZPM comes across an installer script that wants to run lua code,
it asks for your **permission**. You can **accept** all installer scripts
by turning on this flag.

** Example **

 ```
 premake5 install-package --allow-install
 ```

----

## `allow-shell`
Sometimes a build command is used by a library that uses **shell** code.
By default ZPM asks your **permission** to execute these snippets.
Turning on this flag **allows** all snippets to be run by default.

** Example **

 ```
 premake5 gmake --allow-shell
 ```

----

## Related Pages

* [Commands](../commands)
* [Install](install)
* [Update](update)