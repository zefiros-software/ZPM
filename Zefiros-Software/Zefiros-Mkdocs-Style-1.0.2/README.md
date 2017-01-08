# Default ZPM MkDocs Style
This is the style we use for our MkDocs documentation.

## Default mkdocs.yml
```yml
site_name: 
site_url: 
repo_url: 
site_description: 
theme: united
copyright: Copyright © 2016 Mick van Duijn, Koen Visscher and Paul Visscher
google_analytics: 

theme_dir: docs/style

pages: 
    - 'index.md'

extra_css:
    - 'style/docs.css'

extra_javascript:
    - 'style/mathjax-loader.js'
    - https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML

markdown_extensions:
    - toc:
        permalink: True
        separator: "_"
    - admonition
    - sane_lists
    - pymdownx.arithmatex
    - pymdownx.magiclink
    - markdown_checklist.extension
```