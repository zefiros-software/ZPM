# Using ZPM Premake5
Whilst ZPM by default makes sure all dependencies are **downloaded**, you 
yourself are responsible for **using** them. However this is made as 
**simple** as possible!

# `premake5.lua` File
By default ZPM is loaded in the `zpm` global variable. There is only *two* commands you should remember:

* [`zpm.uses`](#zpmuses)
* [`require`](#require)

----

# `zpm.uses`
This command is used to **link**, and **use** all **exported** settings from the given packages.

```lua
zpm.uses( <libraries> )
```

Where  

* `libraries` is a string or a list of strings with "`<vendor-name>/<package-name>`"
  as described in your `.package.json`.


** Example **
```lua
project "Example"
    zpm.uses "Zefiros-Software/GoogleTest"
```

!!! alert-warning "Warning"
    This command is used on a per project level.

----

# `require`
ZPM can be used to load and install premake5 [modules](https://github.com/premake/premake-core/wiki/Modules). It can also
be used to download general lua modules.

** Example **
```
//.package.json
"modules": [
    "Zefiros-Software/Zefiros-Defaults"
]
```
**with**
```lua
//premake5.lua
local zefiros = require( "Zefiros-Software/Zefiros-Defaults", "@head" )
```

----

# Large Example

```lua
workspace "Example"

    configurations { "Debug", "Release" }

    platforms { "x86_64", "x86" }
        
    filter "*Debug"
        targetsuffix "d"
        defines "DEBUG"

        flags "Symbols"
        optimize "Off"

    filter "*Release"
        optimize "Speed"
			
	project "test"
				
		kind "ConsoleApp"
		flags "WinMain"
		
		location "test/"
        
        zpm.uses {
			"Zefiros-Software/GoogleTest"
		}

		files { 
			"test/**.h",
			"test/**.cpp"
			}

	project "lib"	 
		kind "StaticLib"
        
		files { 
			"include/**.h",
			"src/**.cpp",
			}
```