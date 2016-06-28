# Versions
We follow the rules of [semantic versioning](http://semver.org/) with the version strings. 
We compare the given version string against the **git tags** used the repository.
Thus we have:

Given a version number `<major>.<minor>.<patch>*`, increment the:

* `major` version when you make incompatible API changes,
* `minor` version when you add functionality in a backwards-compatible way, and
* `patch` version when you make backwards-compatible bug fixes.
* `*` additional information for builds etc.

Using these rules we can check for version **requirements**.

## Equality &amp; Comparison
```lua
<true version> ~ <check>
"1.2.3" ~ "1.2.3"           -- true
"1.2.3" ~ "<4.5.6"          -- true
"1.2.3-alpha" ~ "<1.2.3"    -- true
"1.2.3" ~ "<1.2.3+build.1"  -- false, builds are ignored when comparing versions
```

## Pessimistic Upgrade
`a ^ b` returns **true** if it is **safe** to update from a to b.
```lua
<true version> ~ <check>
"2.0.1" ~ "^2.5.1" -- true  - it is safe to upgrade from 2.0.1 to 2.5.1
"1.0.0" ~ "^2.0.0" -- false - 2.0.0 is not supposed to be backwards-compatible
"2.5.1" ~ "^2.0.1" -- false - 2.5.1 is more modern than 2.0.1
```

## Composite

** Or **

For **or** we use a `||` operator:
```lua
<true version> ~ <check>
"1.2.3" ~ ">1.2.1 || >=1.2.0" -- true - >=1.2.0 is satisfied
```

** And **

For **and** we use a ` ` (space) operator:
```lua
<true version> ~ <check>
"1.2.3" ~ ">1.2.1  <1.2.4" -- true
"1.2.3" ~ ">1.2.1  <1.2.2" -- false
```

## `@head`
When you want the `head` of the **master** of a repository you should use the `@head` version.

## Non Semantic
When a **non semantic** version tag is used we try to fix it by appending extra `.0`.
```lua
<true version> ~ <check>
"1.2" ~ ">1.2.1  <1.2.4" -- false - 1.2 is read as 1.2.0
"1"   ~ ">1.2.1  <1.2.2" -- false - 1 is read as 1.0.0
```

## Example
```json
// _package.json
"requires": [
    {
        "name": "Zefiros-Software/ArmadilloExt",
        "version": ">1.1.0"
    },
    {
        "name": "Zefiros-Software/PlotLib",
        "version": "@head"
    }
],
"assets": [
    {
        "name": "Zefiros-Software/Anaconda",
        "version": ">=4.0.0"
    }
]
```
----

## Related Pages

* [_package.json](_package)
* [Dev](dev)
* [Overrides](overrides)