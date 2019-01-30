
%ifndef _LD_GEOMETRY_3D_64_ASM
%define _LD_GEOMETRY_3D_64_ASM

%include "LDM_MACROS.asm" ; Compile with -i 

args_reset ;<--Sets arguments definitions to normal, as it's definitions can change.

section .text

global TRI3DCENTROID; void TRI3DCENTROID(void * Destiny, void * Source)
;************************
;Given a triangle Triangle described by and array of 3 3D points (3 floats per point)
;this algorithm calculates its barycenter and returns and array of a 3D point in Result
;************************
TRI3DCENTROID:
    ;enter 0,0    
    movups XMM0,[arg2]
    add arg2,(4*3) ;<- It jumps three times the size of a float (4 bytes)
    movups XMM1,[arg2]
    add arg2,(4*2) ;<- It jumps two times the size of a float because of memory boundaries
    movups XMM2,[arg2] 

    _fillimm32_ xmm3,01000000010000000000000000000000b,rax

    ;xmm0 [Bx][Az][Ay][Ax]
    ;xmm1 [Cx][Bz][By][Bx]
    ;xmm2 [Cz][Cy][Cx][Bz]  ;<- It needs some alingment
    ;xmm3 [?][3.0f][3.0f][3.0f]

    psrldq XMM2,4    

    ;xmm0 [Bx][Az][Ay][Ax]
    ;xmm1 [Cx][Bz][By][Bx]
    ;xmm2 [??][Cz][Cy][Cx] :<- it's aligned now
    
    addps xmm0,xmm1
    addps xmm1,xmm2
    divps xmm0,xmm3
    movhlps xmm1,xmm0
    ;xmm0 [??][Rz][Ry][Rx]
    ;xmm1 [??][??][??][Rz]
    movsd [arg1],xmm0
    add arg2,(4*2)
    movss [arg1],xmm1
    ;leave
    ret

%endif