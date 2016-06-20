# Basics
ZPM is a [distributed](https://en.wikipedia.org/wiki/Distributed_networking) C++ package manager, focused mainly on **ease of use**!

## Overview
When a user uses ZPM, [bootstrap]() and ZPM are loaded and all [registries](registries) are updated. [Modules]() are
checked and loaded, [packages]() are cloned and updated, [assets](../../assets/assets) are cloned, downloaded and updated. After this the **user**
defines how premake5 should build his/her project.

## Architecture
<p align="center"><img src="/images/zpm-arch.png" alt="ZPM Architecture"></p>

ZPM keeps the list of available [packages](), [modules](), and [assets](../../assets/assets) in [registry](registries) repositories. Each
root registry may define **more** registries which will be loaded. These lists contain the vendor, name and (shadow) repository
from which we should clone. Since we do not always have full control over the libraries we want to include,
we support shadow repositories, which define their build files **separately** from the code.

## Directories
Of course ZPM uses a few directories to work properly.

### Extern Folder
In your project root a folder `extern/` and is ignored in git. 
This folder ZPM keeps the packages the **current** project uses.  

It is structured like `extern/<vendor>/<name>/<version>/`.

!!! alert-warning "Note"
    This folder can be removed without problems.

### Assets Folder
In your project root a folder `assets/` and again is ignored in git. 
It keeps the assets the **current** project uses.  

This folder is structured like `assets/<from-vendor>/<from-name>/<asset-vendor>/<asset-name>`.

!!! alert-warning "Note"
    This folder can be removed without problems.

### ZPM-Cache
The ZPM-Cache folder is used by ZPM to **cache** all used repositories in for **packages** and **assets**, to make reusing a lot *faster*. 
In this folder we also store installed **modules**, and **registries**.

!!! alert-warning "Note"
    This folder can be removed without problems.

### Install Folder
In the install folder we have the `premake-systems.lua` that **loads** the `bootstrap` and `ZPM` modules natively. Also
the ZPM and bootstrap **repositories** are stored. In the root of this folder all premake5 versions are installed.

!!! alert-danger "Note"
    This folder should be left untouched.

----

## Related Pages

* [Registries](registries)
* [Premake5](premake5)
* [Commands](commands)