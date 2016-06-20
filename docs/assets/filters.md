# Filters
ZPM allows assets to filter different settings for target systems:

* [`system`](#system) filters the target operating system.
* [`is64bit`](#is64bit) filters the architecture.

## `system`
Filters the target **operating system**.

```json
{"system": "<system>",
 "do": [
    <commands>
]}
```

Where  

* `systems` is passed to [os.is](https://github.com/premake/premake-core/wiki/os.is).
* `do` is **executed** when `os.is( <systems> )` passes.
* `<commands>` is a list of **command** objects.

** Example **
```
//_assets.json
[
    {"system": "windows",
     "do": [
        {"files": [
            "*.exe"
        ]}
    ]}
]
```

----

## `is64bit`
We can also filter on **architecture** in two ways:
```json
{"is64bit": <is64bit>,
 "do": [
    <commands>
]}
```

And also:
```json
{"is64bit":<is64bit>,
 "do": [
    <commands>
],
 "otherwise": [
    <commands>
]}
```
Where

* `is64bit` is a boolean that functions as **conditional**.
* `do` is executed when `is64bit` **matches** the current system.
* `otherwise` is executed when `is64bit` does **not** match the current system.

** Example **
```
//_assets.json
[
    {"is64bit": true,
     "do": [
        {"files": [
            "foo/x64*.exe"
        ]}
    ]},
    {"is64bit": false,
     "do": [
        {"files": [
            "bar/x86*.exe"
        ]}
    ],
     "otherwise": [
        {"files": [
            "bar/x64*.exe"
        ]}
    ]},
]
```