# Publishing Modules
To publish your own module, you should make sure your module is **supported** by the
**bootstrap loader**.

# Entry Scripts
The loader script should either be:

* `<manifest-name>.lua` (no vendor)
* `init.lua`

# Extending ZPM
ZPM can be **extended** to add new commands to `.build.lua` and `.assets.json` files.