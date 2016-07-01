# Using ZPM Premake5
Whilst ZPM by default makes sure all dependencies are **downloaded**, you 
yourself are responsible for **using** them. However this is made as 
**simple** as possible!

# `premake5.lua` File
By default ZPM is loaded in the `zpm` global variable.  
There are only **two** command you should remember:

* [`zpm.uses`](#zpmuses)
* [`zpm.buildLibraries`](#zpmbuildlibraries)

----

# `zpm.uses`
This command is used to **link**, and **use** all **exported** settings from the given packages.

```lua
zpm.uses( <libraries> )
```

Where  

* `libraries` is a string or a list of strings with "`<vendor-name>/<package-name>`"
  as described in your `_package.json`.


** Example **
```lua
project "Example"
    zpm.uses "Zefiros-Software/GoogleTest"
```

!!! alert-warning "Warning"
    This command is used on a per project level.

----

# `zpm.buildLibraries`
This command is used to define all project the dependencies **require**.

** Example **
```lua
workspace "Example"
    zpm.buildLibraries()
```

!!! alert-warning "Warning"
    This command should be called in the workspace configuration **before** any project is defined.

!!! alert-success "Note"
    All projects made with this command will **share** the workspace settings **you **defined!
----

# Example


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
        
    zpm.buildLibraries()
			
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