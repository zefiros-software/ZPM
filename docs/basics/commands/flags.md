# Flags
ZPM also introduces some new flags:

* [`allow-install`](#allow-install)
* [`allow-shell`](#allow-shell)
* [`allow-module`](#allow-module)
* [`github-token`](#github-token)

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

## `allow-module`
When a module is required to install or update, ZPM asks confirmation of this action.
By turning on this flag we always accept the changes.

** Example **

 ```
 premake5 install-package --allow-shell
 ```

----

## `github-token`
Since we use the GitHub api for a number of action, we can run into their
rate limiting. By adding a GitHub token to the commandline, we can login
into your account and circumvent this. See [this](../config/#github_token) 
for a more permanent solution.

** Example **

 ```
 premake5 gmake --github-token=<token>
 ```

----

## Related Pages

* [Commands](../commands)
* [Install](install)
* [Update](update)