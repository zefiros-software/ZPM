# Download
By default ZPM does nothing with cloned assets, and thus we need to move the files.

* [`url`](#url_command) downloads assets from an **url**.
* [`files`](#files_command) downloads files from **Git LFS** to the assets folder.

## `url` Command
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

## `files` Command
We also support files from our **Git LFS** repository to be downloaded.

```json
{"files": [
    <patterns>
]}
```
** or **
```json
{"files": [
    <patterns>
 ],
 "to": "<directory>}
```

Where 

* `<patterns>` is an array of strings that are passed to [os.matchfiles](https://github.com/premake/premake-core/wiki/os.matchfiles).  
  Matched files are copied and we leave the relative path intact.
* `<directory>` to copy the files to, from the root of the repository.

** Example **
```json
//_assets.json
[
    {"files": [
        "*.exe",
        "*.dll"
    ]}
]
```