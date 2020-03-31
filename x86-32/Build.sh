 #libLDMat
 #Luis Delgado. 2019.
 
 #!/bin/bash

mkdir BUILD
mkdir BUILD/tmp
mkdir BUILD/GCC
mkdir BUILD/MINGW

AS="as --32"
AR="ar"
GCC="gcc -m32"
OUTF="GCC"
FORMAT="so"

COMPILE () {
    $AS Algebra32.s -o BUILD/tmp/Al.o
    $AR rsc libLDM.a BUILD/tmp/Al.o
    mv libLDM.a BUILD/$OUTF/libLDMat.a

    $GCC -shared -fPIC -o libLDM.$FORMAT BUILD/tmp/Al.o
    mv libLDM.$FORMAT BUILD/$OUTF/libLDMat.$FORMAT
}

echo "ELF32"
COMPILE 

echo "WIN32 (MINGW) (CDECL)"
AS="i686-w64-mingw32-as --defsym USEUNDESCORE=1"
AR="i686-w64-mingw32-ar"
GCC="i686-w64-mingw32-gcc"
OUTF="MINGW"
FORMAT="dll"
COMPILE 
