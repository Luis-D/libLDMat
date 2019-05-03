#libLDMat
#Luis Delgado. 2019.

#!/bin/bash

mkdir BUILD
mkdir BUILD/tmp
mkdir BUILD/GCC
mkdir BUILD/MINGW

echo "ELF64"
nasm -f ELF64 Algebra64.asm -o BUILD/tmp/Al64.o
nasm -f ELF64 Geometry2D64.asm -o BUILD/tmp/G2D64.o

ar rcs libLDM.a BUILD/tmp/Al64.o BUILD/tmp/G2D64.o
mv libLDM.a BUILD/GCC/libLDMat.a

gcc -shared -fPIC -o libLDM.so BUILD/tmp/Al64.o BUILD/tmp/G2D64.o
mv libLDM.so BUILD/GCC/libLDMat.so

gcc Test.c BUILD/GCC/libLDMat.so -o BUILD/Test.out



echo "WIN64 (MinGW)"
nasm -f win64 Algebra64.asm -o BUILD/tmp/Alg64.obj
nasm -f win64 Geometry2D64.asm -o BUILD/tmp/G2D64.obj

x86_64-w64-mingw32-ar rcs libLDM.a BUILD/tmp/Alg64.obj BUILD/tmp/G2D64.obj
mv libLDM.a BUILD/MINGW/libLDMat.a

x86_64-w64-mingw32-gcc -shared -fPIC -o  BUILD/libLDMat.dll BUILD/tmp/Alg64.obj BUILD/tmp/G2D64.obj
cp BUILD/libLDMat.dll BUILD/MINGW/libLDMat.dll


x86_64-w64-mingw32-gcc-7.3-posix Test.c BUILD/MINGW/libLDMat.a -static -o BUILD/Test.exe
