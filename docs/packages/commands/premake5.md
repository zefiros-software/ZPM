# Premake5 Commands
These type of build command translate **directly** to premake5.

## Example
```
//_build.json
[
    {
        "project": "Example",
        "do": [
            {"architecture": "x86_64"},
            {"endian": "Little" },
            {"links": [
                "mpi",
                "pthreads"
            ]}
        ]
    }
]
```

## Available Commands

 * [architecture](https://github.com/premake/premake-core/wiki/architecture)
 * [atl](https://github.com/premake/premake-core/wiki/atl)
 * [defines](https://github.com/premake/premake-core/wiki/defines)
 * [builddependencies](https://github.com/premake/premake-core/wiki/builddependencies)
 * [buildoptions](https://github.com/premake/premake-core/wiki/buildoptions)
 * [buildoutputs](https://github.com/premake/premake-core/wiki/buildoutputs)
 * [callingconvention](https://github.com/premake/premake-core/wiki/callingconvention)
 * [characterset](https://github.com/premake/premake-core/wiki/characterset)
 * [clr](https://github.com/premake/premake-core/wiki/clr)
 * [debugargs](https://github.com/premake/premake-core/wiki/debugargs)
 * [debugenvs](https://github.com/premake/premake-core/wiki/debugenvs)
 * [debugextendedprotocol](https://github.com/premake/premake-core/wiki/debugextendedprotocol)
 * [debugformat](https://github.com/premake/premake-core/wiki/debugformat)
 * [debugport](https://github.com/premake/premake-core/wiki/debugport)
 * [debugremotehost](https://github.com/premake/premake-core/wiki/debugremotehost)  
 * [kind](https://github.com/premake/premake-core/wiki/kind)
 * [configurations](https://github.com/premake/premake-core/wiki/configurations)
 * [flags](https://github.com/premake/premake-core/wiki/flags)
 * [optimize](https://github.com/premake/premake-core/wiki/optimize)
 * [disablewarnings](https://github.com/premake/premake-core/wiki/disablewarnings)
 * [editandcontinue](https://github.com/premake/premake-core/wiki/editandcontinue)
 * [editorintegration](https://github.com/premake/premake-core/wiki/editorintegration)
 * [enablewarnings](https://github.com/premake/premake-core/wiki/enablewarnings)
 * [endian](https://github.com/premake/premake-core/wiki/endian)
 * [entrypoint](https://github.com/premake/premake-core/wiki/entrypoint)
 * [exceptionhandling](https://github.com/premake/premake-core/wiki/exceptionhandling)
 * [externalrule](https://github.com/premake/premake-core/wiki/externalRule)
 * [fatalwarnings](https://github.com/premake/premake-core/wiki/fatalwarnings)
 * [fileextension](https://github.com/premake/premake-core/wiki/fileextension)
 * [floatingpoint](https://github.com/premake/premake-core/wiki/floatingpoint)
 * [fpu](https://github.com/premake/premake-core/wiki/fpu)
 * [gccprefix](https://github.com/premake/premake-core/wiki/gccprefix)
 * [ignoredefaultlibraries](https://github.com/premake/premake-core/wiki/ignoredefaultlibraries)
 * [implibdir](https://github.com/premake/premake-core/wiki/implibdir)
 * [implibextension](https://github.com/premake/premake-core/wiki/implibextension)
 * [implibname](https://github.com/premake/premake-core/wiki/implibname)
 * [implibprefix](https://github.com/premake/premake-core/wiki/implibprefix)
 * [implibsuffix](https://github.com/premake/premake-core/wiki/implibsuffix)
 * [inlining](https://github.com/premake/premake-core/wiki/inlining)
 * [language](https://github.com/premake/premake-core/wiki/language)
 * [linkoptions](https://github.com/premake/premake-core/wiki/linkoptions)
 * [links](https://github.com/premake/premake-core/wiki/links)
 * [locale](https://github.com/premake/premake-core/wiki/locale)
 * [makesettings](https://github.com/premake/premake-core/wiki/makesettings)
 * [nativewchar](https://github.com/premake/premake-core/wiki/nativewchar)
 * [pic](https://github.com/premake/premake-core/wiki/pic)
 * [rtti](https://github.com/premake/premake-core/wiki/rtti)
 * [rule](https://github.com/premake/premake-core/wiki/rule)
 * [rules](https://github.com/premake/premake-core/wiki/rules)
 * [runtime](https://github.com/premake/premake-core/wiki/runtime)
 * [strictaliasing](https://github.com/premake/premake-core/wiki/strictaliasing)
 * [targetprefix](https://github.com/premake/premake-core/wiki/targetprefix)
 * [targetsuffix](https://github.com/premake/premake-core/wiki/targetsuffix)
 * [targetextension](https://github.com/premake/premake-core/wiki/targetextension)
 * [toolset](https://github.com/premake/premake-core/wiki/toolset)
 * [undefines](https://github.com/premake/premake-core/wiki/undefines)
 * [vectorextensions](https://github.com/premake/premake-core/wiki/vectorextensions)
 * [warnings](https://github.com/premake/premake-core/wiki/warnings)
 * [buildmessage](https://github.com/premake/premake-core/wiki/buildmessage)
 * [postbuildmessage](https://github.com/premake/premake-core/wiki/postbuildmessage)
 * [prebuildmessage](https://github.com/premake/premake-core/wiki/prebuildmessage)
 * [prelinkmessage](https://github.com/premake/premake-core/wiki/prelinkmessage)

----

## Related Pages
The following **build** commands are available:  

* [Premake5](premake5) commands
* [Build](build) commands
* [Export](export) commands
* [Reexport](reexport) commands
* [Filters](filters) commands
* [Path](path) commands
* [Special](special) commands