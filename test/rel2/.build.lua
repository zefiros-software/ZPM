
project "rel2"
    kind "StaticLib"

    files "test2.cpp"

    zpm.uses "root/local"

    zpm.export [[
        includedirs "."
    ]]