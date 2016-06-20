# Download
By default ZPM does nothing with cloned assets, and thus we need to move the files.

* [`url`](#url) downloads assets from an **url**.
* [`files`](#files) downloads files from **Git LFS** to the assets folder.

## `url`
Downloads assets form a given archive or file url.

```json
{"url": "https://<url-to-archive>.zip",
 "to": "<folder-name>"}
```

Where 

* `url` is an url to an **archive** (.zip or .tar.gz) or **file**.
* `to` is an alpha-numeric (with '-' and '_') name wherein we **place** the (extracted) files.
  This folder lies within the **project** `assets` folder.

----

## `files`
We also support files from our **Git LFS** repository to be downloaded.

```json
{"files": [
    <patterns>
]}
```

Where 

* `<patterns>` is an array of strings that are passed to [os.matchfiles](https://github.com/premake/premake-core/wiki/os.matchfiles).  
  Matched files are copied and we leave the relative path intact.

** Example **
```
//_assets.json
[
    {"files": [
        "*.exe",
        "*.dll"
    ]}
]
```