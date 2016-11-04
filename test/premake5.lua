

workspace "local"

    configurations { "test" }

    project "local"
        kind "ConsoleApp"        
        files "main.cpp"
        
        zpm.uses "root/local2"