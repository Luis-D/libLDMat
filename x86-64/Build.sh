#libLDMat
#Luis Delgado. 2019.

#!/bin/bash

mkdir tmp

echo "ELF64"
nasm -f ELF64 Algebra64.asm -o tmp/Al64.o
nasm -f ELF64 Geometry2D64.asm -o tmp/G2D64.o

ar rcs libLDM.a tmp/Al64.o
mv libLDM.a GCC/libLDM.a

gcc -s -shared -fPIC -o libLDM.so tmp/G2D64.o tmp/Al64.o
mv libLDM.so GCC/libLDM.so

gcc main.c GCC/libLDM.so



echo "WIN64 (MinGW)"
nasm -f win64 Algebra64.asm -o tmp/Alg64.obj
nasm -f win64 Geometry2D64.asm -o tmp/G2D64.obj

x86_64-w64-mingw32-ar rcs libLDM.a tmp/Alg64.obj
mv libLDM.a MINGW/libLDM.a

x86_64-w64-mingw32-gcc -s -shared -fPIC -o libLDM.dll tmp/Alg64.obj
cp libLDM.dll MINGW/libLDM.dll


x86_64-w64-mingw32-gcc-7.3-posix main.c MINGW/libLDM.a tmp/G2D64.obj -static