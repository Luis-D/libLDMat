#libLDM
#Luis Delgado. 2019.

#!/bin/bash

mkdir tmp
mkdir GCC
mkdir MINGW

echo "ELF64"
nasm -f ELF64 Algebra64.asm -o tmp/LDMAlg64.o

ar rcs libLDM.a tmp/LDMAlg64.o
mv libLDM.a GCC/libLDM.a

gcc -s -shared -fPIC -o libLDM.so tmp/LDMAlg64.o
mv libLDM.so GCC/libLDM.so

#gcc main.c GCC/libLDM.so



echo "WIN64 (MinGW)"
nasm -f win64 Algebra64.asm -o tmp/LDMAlg64.obj

x86_64-w64-mingw32-ar rcs libLDM.a tmp/LDMAlg64.obj
mv libLDM.a MINGW/libLDM.a

x86_64-w64-mingw32-gcc -s -shared -fPIC -o libLDM.dll tmp/LDMAlg64.obj
mv libLDM.dll MINGW/libLDM.dll


#x86_64-w64-mingw32-gcc-7.3-posix main.c MINGW/libLDM.a -static