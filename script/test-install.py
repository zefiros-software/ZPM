import subprocess
import sys
import os

output = str(subprocess.check_output( ["premake5", "install-package"], universal_newlines=True ))

if ("Zefiros Package Manager - (c) Zefiros Software" not in output or
    "Loading The Zefiros Bootstrap version" not in output or
    "Loading The Zefiros Package Manager version" not in output or
    "Resolved package dependencies 'Zefiros-Software/ZPM'" not in output):

    print( "ZPM failed to load correctly!" )
    exit(-1)
else:
    print( "ZPM successfully installed" )