
project "rel1"
    kind "StaticLib"

    files "test.cpp"

    zpm.export [[
        includedirs "."
    ]]