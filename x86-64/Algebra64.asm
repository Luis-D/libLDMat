; Luis Delgado. 2019
; To be used with NASM-Compatible Assemblers
; For x86-64 architecture.

; System V AMD64 ABI Convention (*nix)
; Function parameters are passed this way:
; Interger values: RDI, RSI, RDX, RCX, R8, R9
; Floating Point values: XMM0, XMM1, XMM2, XMM3, XMM4, XMM5, XMM6, XMM7
; Extra arguments are pushed on the stack starting from the most left argument
; Function return value is returned this way:
; Integer value: RAX:RDX 
; Floating point value: XMM0:XMM1
; RAX, R10 and R11 are volatile

; Microsoft x64 calling convention (Windows)
; Function parameters are passed this way:
; Interger values: RCX, RDX, R8, R9
; Floating point values: XMM0, XMM1, XMM2, XMM3 
; Both kind of arguments are counted together
; e.g. if the second argument is a float, it will be in arg2f, if Interger, then RDX
; Extra arguments are pushed on the stack 
; Function return value is returned this way:
; Integer value: RAX
; Floating point value: XMM0
; XMM4, XMM5, RAX, R10 and R11 are volatile

; SSE, SSE2, SSE3, FPU

; Format =
; INSTRUCTION(Destiny, Operand1, Operand2, Operand3, ... , OperandN)

; Original Source code from Luis-D/Boring-NASM-Code.

; Collection of mathematical functions and MACROS, very useful for algebra.

;January 11, 2019: Code writing started.
;January 21, 2019: 2x2 Matrix Math added.
;February 05,2019: 2D Norm fixed
;February 28,2019: Projection and view matrix operations added.
;March   02, 2019: Many errors fixed.
;March	 14, 2019: Windows routines prologues fixed.
;April	 02, 2019: Quaternion Normalized LERP added.
;April	 14, 2019: MADSS and SSMAD Operations added.
;June	 03, 2019: Inversion instructions added. Absolute value instruction added.
;April	 01, 2020: Orthogonal projection redone.

;TODO:
;July	 27, 2020: Complete SLERP.
;July	 27, 2020: Interleave instructions to gain performance.
;July	 31, 2020: Rewrite in GAS


;Notes:
;   - Matrices are COLUMN MAJOR.
;   - "LEGACY MACROS" are pieces of code from Boring-NASM-Code
;   - V2ANGLE does not have a MACRO version. This routine uses FPU.
;   - V2V2ANGLE does not have a MACRO version. This routine uses FPU.
;   - ANGLEROTV2 does not have a MACRO version. This routine uses FPU.
;   - EULERTOQUAT does not have a MACRO version. This routine uses FPU.
;   - QUATTOM4 does not have a MACRO version. This routine uses FPU.
;   - None of the 4x4 matrices operations have MACROS versions due to their complexity.
;   - "AM4" stands for "Affine transformation of Mat4", refering to it's upper 3x3 submatrix.
;   - Some of the 2x2 matrices operations doesn't have MACROS versions due to their simplicity.

%ifndef _LD_Algebra_64_ASM_
%define _LD_Algebra_64_ASM_

%include "LDM_MACROS.asm" ; Compile with -i

;*****************************
;MACROS
;*****************************
args_reset ;<--Sets arguments definitions to normal, as it's definitions can change.



%macro TRANS44 0
; *** LEGACY MACRO ***
; Result in XMM0:XMM2:XMM4:XMM5
    movaps  xmm4,  xmm0
    movaps  xmm6,  xmm2

    punpckldq xmm0,xmm1
    punpckldq xmm2,xmm3
    punpckhdq xmm4,xmm1
    punpckhdq xmm6,xmm3

    movaps  xmm1,xmm0
    movaps  xmm5,xmm4

    punpcklqdq xmm0,xmm2
    punpckhqdq xmm1,xmm2
    punpcklqdq xmm4,xmm6
    punpckhqdq xmm5,xmm6
%endmacro

%macro MULVEC4VEC4 3
; *** LEGACY MACRO ***
;Multiplies XMM0:XMM1:XMM4:XMM5 by XMM2:XMM3:XMM6:XMM7
        movups arg3f,[%1+%3]
        movaps xmm7,arg3f

        mulps  arg3f,arg1f
        movshdup    arg4f, arg3f
        addps       arg3f, arg4f
        movaps xmm6,xmm7
        movhlps     arg4f, arg3f
        addss       arg3f, arg4f
        movss  [%2+%3], arg3f;//<--- Important

        mulps  xmm6,arg2f
        movshdup    arg4f, xmm6
        addps       xmm6, arg4f
        movaps arg3f,xmm7
        movhlps     arg4f, xmm6
        addss       xmm6, arg4f
        movss  [%2+4+%3], xmm6;//<--- Important

        mulps  arg3f,xmm4
        movshdup    arg4f, arg3f
        addps       arg3f, arg4f
        movaps xmm6,xmm7
        movhlps     arg4f, arg3f
        addss       arg3f, arg4f
        movss  [%2+8+%3], arg3f;<--- Important

        mulps  xmm6,xmm5
        movshdup    arg4f, xmm6
        addps       xmm6, arg4f
        movhlps     arg4f, xmm6
        addss       xmm6, arg4f
        movss  [%2+8+4+%3], xmm6;<--- Important
%endmacro



section .data
;***Constants loads***;

  ;***** Constants *****;
    fc_360f:                   equ 0x43b40000                         ;32-bits 360.f
    fc_2f:                     equ 01000000000000000000000000000000b  ;32-bits 2.f
    fc_m_1f:                   equ 0xbf800000                         ;32-bits -1.f
    fc_1f:                     equ 0x3f800000                         ;32-bits +1.f
    SignChange32bits:          equ 10000000000000000000000000000000b  ;It can change the sign if XOR'd
    fc_180f:                   equ 0x43340000                         ;32-bits 180.f
    fc_PIdiv180f:              equ 0x3c8efa35                         ;32-bits (PI/180.f)
    fc_180fdivPI:              equ 0x42652ee1                         ;32-bits (180.f/PI)



;*********************;

section .text

;*** Simple float MATH ***;
global SSABS; float ABSSS(float Operand);
    SSABS:
    _enter_
    pcmpeqw xmm4,xmm4
    psrld xmm4,1
    pand xmm0,xmm4
    _leave_
    ret

global SSCLAMP; float CLAMPSS(float Value,float Min, float Max)
    SSCLAMP:
    _enter_
    ucomiss xmm0,xmm1
    ja CLAMPSS_NO_MIN 
	movss xmm0,xmm1
    CLAMPSS_NO_MIN:
    ucomiss xmm0,xmm2
    jb CLAMPSS_END
	movss xmm0,xmm2
    CLAMPSS_END:
    _leave_
    ret


 ;***VECTOR 4 MATH***;

%macro _V4MATH_ARITHMETIC_ROUTINE 1
;%1 = operation
    movups xmm0,[arg2] ; <- Unaligned
    %1 xmm0,[arg3]
    movntps [arg1],xmm0
%endmacro

%macro _V4MATH_SCALAR_ROUTINE 1
;%1 = operation
    movups arg2f,[arg2]
    shufps arg1f,arg1f,0
    %1 arg2f,arg1f
    movntps [arg1],arg2f
%endmacro


global V4ADD; void V4ADD( void * Result, void * A, void * B)
;************************************
; V4 Result = (A.x + B.x , X.y + B.y, A.z + B.z , A.w + B.w)
;************************************
    V4ADD:
        _enter_
            _V4MATH_ARITHMETIC_ROUTINE addps
        _leave_
        ret

global V4SUB; void V4SUB(void * Result, void * A, void * B)
;************************************
; V4 Result = (A.x - B.x , X.y - B.y, A.z - B.z , A.w - B.w)
;************************************
    V4SUB:
        _enter_
            _V4MATH_ARITHMETIC_ROUTINE subps
        _leave_
        ret

global V4MUL; void V4MUL(void * Result, void * A, void * B)
;************************************
; V4 Result = (A.x * B.x , X.y * B.y, A.z * B.z , A.w * B.w)
;************************************
    V4MUL:
        _enter_
            _V4MATH_ARITHMETIC_ROUTINE mulps
        _leave_
        ret 

global V4DIV; void V4DIV(void * Result, void * A, void * B)
;************************************
; V4 Result = (A.x / B.x , X.y / B.y, A.z / B.z , A.w / B.w)
;************************************
    V4DIV:
        _enter_
            _V4MATH_ARITHMETIC_ROUTINE divps
        _leave_
        ret     

global V4MULSS; void V4MULSS (void * result, void * Vector, float FLOAT)
;************************************
; V4 Result = (A.x * FLOAT , X.y * FLOAT, A.z * FLOAT , A.w * FLOAT)
;************************************
    V4MULSS:
%ifidn __OUTPUT_FORMAT__, win64 
    %define arg1f XMM2
    %define arg2f XMM3
%endif
        _enter_
        _V4MATH_SCALAR_ROUTINE mulps
        _leave_
        ret
%ifidn __OUTPUT_FORMAT__, win64 
    args_reset
%endif

global V4DIVSS; void V4DIVSS (void * result, void * Vector, float FLOAT)
;************************************
; V2 Result = (A.x / FLOAT , X.y / FLOAT, A.z / FLOAT , A.w / FLOAT)
;************************************
    V4DIVSS:
%ifidn __OUTPUT_FORMAT__, win64 
    %define arg1f XMM2
    %define arg2f XMM3
%endif
        _enter_
        _V4MATH_SCALAR_ROUTINE divps
        _leave_
        ret
%ifidn __OUTPUT_FORMAT__, win64 
    args_reset
%endif

global V4MADSS
;void V4MADSS(void * Result, void * A, void * B, float C)
;************************************
;V4 Resul = (A + (B*C))
;************************************
    V4MADSS:
%ifidn __OUTPUT_FORMAT__, win64 
    %define arg1f XMM3
%endif
    _enter_
    
    movups xmm5,[arg3]
    pshufd arg1f,arg1f,0
    movups xmm4,[arg2]
    mulps xmm5,arg1f
    addps xmm4,xmm5
    movups [arg1],xmm4

%ifidn __OUTPUT_FORMAT__, win64 
    args_reset
%endif
    _leave_
    ret

    ;*** VECTOR 4 ALGEBRA***/



%macro _V4NORMALIZE_ 4
;%1 = Destination Operand
;%2 = Source Operand
;%3 = Temporal Operand (Trasheable)
;%4 = Temporal Operand (Trasheable)
    movaps %4,%2
    movaps %1,%2
    mulps %4,%4
    movshdup %3,%4
    addps    %4,%3
    movhlps  %3,%4
    addss    %4,%3
    sqrtss   %4,%4
    pshufd   %4,%4,0
    divps    %1,%4
%endmacro
global V4NORMALIZE; void V4NORMALIZE (void * result,void * Vector)
;***************************************************************************
; Given a vector (Vector), this algorithm returns a normalized version of it.
;***************************************************************************
    V4NORMALIZE:
        _enter_
        movups xmm1,[arg2]
        _V4NORMALIZE_ xmm0,xmm1,xmm2,xmm3
        movntps [arg1],xmm0
        _leave_
        ret 

%macro DotProductXMM 4
;%1 and %2 are registers to proccess
;%3 is the result ;Result stored in the first 32-bits
;%4 is a temporal register
	movaps %3, %1
	mulps  %3, %2
	movshdup %4,%3
	addps    %3,%4
	movhlps  %4,%3
	addss    %3,%4
%endmacro

%macro _V4DOT_ 4
;%1 is the Destiny Operand. The result is stored in the first 32-bits
;%2 and %3 are registers to proccess
;%4 is a temporal register
    DotProductXMM %2,%3,%1,%4
%endmacro
global V4DOT; float V4DOT(void * A, void * B)
;*******************************************************************************
; Given a vector (Vector), this algorithm returns the dot product version of it.
;*******************************************************************************
    V4DOT:
        movups xmm1,[arg1]
        pxor xmm0,xmm0
        movups xmm2,[arg2]
        _V4DOT_ xmm0,xmm1,xmm2,xmm3
    ret

%macro _V4Lerp_ 4
;%1 Is the First  Operand Vector (A)
;%2 Is the Second Operand Vector (B)
;%3 Is the Factor Operand Vector (t) (Previously pshufd' by itself with 0)
;%4 Is the Destiny Vector        (C)
;All operands must be different
    movaps %4,%2
    subps %4,%1  ;B-A
    mulps %4,%3  ;(B-A)*t
    addps %4,%1  ;C = A+((B-A)*t)
%endmacro


%macro _V4LERP_ 4
;%1 Is the Destiny Operand        
;%2 Is the First  Operand Vector 
;%3 Is the Second Operand Vector 
;%4 Is the Factor Operand Vector (Previously pshufd' by itself with 0)
;All operands must be different
    _V4Lerp_ %2, %3, %4, %1
%endmacro
global V4LERP; void V4LERP(void * Result, void * A, void * B, float factor)
;********************************************************
;Given two 4D vectors (A and B) and a scalar factor,
;this algorithm does a Linear Interpolation
;The result, a 4D vector, is stored in QR
;********************************************************
    V4LERP:
    %ifidn __OUTPUT_FORMAT__, win64 
        %define arg1f XMM3 ;The fourth argument is a float, Factor.
        %define argrf XMM0 ;The result will be stored here.
    %elifidn __OUTPUT_FORMAT__, elf64
        %define argrf XMM3 ;The result will be stored here.
    %endif
        _enter_
        movups XMM1,[arg2]
        pshufd arg1f,arg1f,0
        movups XMM2,[arg3]
        _V4Lerp_ XMM1,XMM2,arg1f,argrf
        movntps [arg1],argrf
        _leave_
        ret 
    %ifidn __OUTPUT_FORMAT__, win64 
        args_reset
    %endif

%macro _V4NORM_ 3
;%1 Is the Destiny Operand.
;%2 Is the Vector.
;%3 Is a temporal Operand (trasheable).
    movaps   %3,%2
    mulps    %3,%3
    movshdup %1,%3
	addps    %1,%3
	movhlps  %3,%1
	addss    %1,%3
    sqrtss   %1,%1
%endmacro
global V4NORM; float V4NORM(void * A)
    V4NORM:
    _enter_
    movups xmm1,[arg1]
    pxor xmm0,xmm0
    _V4NORM_ xmm0,xmm1,xmm2
    _leave_
    ret

%macro _V4DISTANCE_ 4
;%1 Is the Destiny Operand.
;%2 Is the Vector A.
;%3 Is the Vector B.
;%4 Is a temporal Operand (trasheable).
    movaps %4,%3
    subps %4,%2
    _V4NORM_ %1,%4,%3
%endmacro
global V4DISTANCE; float V4NORM(void * A, void * B)
;********************************************************************
;Given two vectors, this algorithm returns the distance between them.
;********************************************************************
    V4DISTANCE:
    _enter_
    movups xmm1,[arg1]
    pxor xmm0,xmm0
    movups xmm2,[arg2]
    _V4DISTANCE_ xmm0,xmm1,xmm2,xmm3
    _leave_
    ret

global V4INV; void V4INV(void * Result, void * Operand)
;*************************************
;V4 Result = -Operand
;************************************
    V4INV:
    _enter_
	movups xmm1,[arg2]
	pcmpeqw xmm0,xmm0
	pslld xmm0,31
	pxor xmm1,xmm0
	movups [arg1],xmm1
    _leave_
    ret

   ;***VECTOR 2 MATH***;

%macro _V2MATH_ARITHMETIC_ROUTINE 1
;%1 = operation
    movlps xmm0,[arg2]
    movlps xmm1,[arg3]
    %1 xmm0,xmm1
    movsd [arg1],xmm0
%endmacro

%macro _V2MATH_SCALAR_ROUTINE 1
;%1 = operation
    movlps arg2f,[arg2]
    shufps arg1f,arg1f,0
    %1 arg2f,arg1f
    movsd [arg1],arg2f
%endmacro

global V2ADD; 
;************************************
; V2 Result = (A.x + B.x , A.y + B.y)
;************************************
    V2ADD:
        _enter_
            _V2MATH_ARITHMETIC_ROUTINE addps
        _leave_
        ret

global V2SUB; 
;************************************
; V2 Result = (A.x - B.x , A.y - B.y)
;************************************
    V2SUB:
        _enter_
            _V2MATH_ARITHMETIC_ROUTINE subps
        _leave_
        ret

global V2MUL; 
;************************************
; V2 Result = (A.x * B.x , A.y * B.y)
;************************************
    V2MUL:
        _enter_
            _V2MATH_ARITHMETIC_ROUTINE mulps
        _leave_
        ret 

global V2DIV; 
;************************************
; V2 Result = (A.x / B.x , A.y / B.y)
;************************************
    V2DIV:
        _enter_
            _V2MATH_ARITHMETIC_ROUTINE divps
        _leave_
        ret     

global V2MULSS; 
;************************************
; V2 Result = (A.x * FLOAT , A.y * FLOAT)
;************************************
    V2MULSS:
%ifidn __OUTPUT_FORMAT__, win64 
    %define arg1f XMM2
    %define arg2f XMM3
%endif
        _enter_
        _V2MATH_SCALAR_ROUTINE mulps
        _leave_
        ret
%ifidn __OUTPUT_FORMAT__, win64 
    args_reset
%endif

global V2DIVSS; 
;************************************
; V2 Result = (A.x / FLOAT , A.y / FLOAT)
;************************************
    V2DIVSS:
 %ifidn __OUTPUT_FORMAT__, win64 
    %define arg1f XMM2
    %define arg2f XMM3
%endif
        _enter_
        _V2MATH_SCALAR_ROUTINE divps
        _leave_
        ret
%ifidn __OUTPUT_FORMAT__, win64 
    args_reset
%endif

global V2MADSS
;void V2MADSS(void * Result, void * A, void * B, float C)
;************************************
;V2 Result = (A + (B*C))
;************************************
V2MADSS:
%ifidn __OUTPUT_FORMAT__, win64 
%define arg1f XMM3
%endif
_enter_

movsd xmm5,[arg3]
pshufd arg1f,arg1f,0
movsd xmm4,[arg2]
mulps xmm5,arg1f
addps xmm4,xmm5
movsd [arg1],xmm4

%ifidn __OUTPUT_FORMAT__, win64 
args_reset
%endif
_leave_
ret

global V2INV; void V2INV(void * Result, void * Operand)
;*************************************
;V2 Result = -Operand
;************************************
    V2INV:
    _enter_
	movsd xmm1,[arg2]
	pcmpeqw xmm0,xmm0
	pslld xmm0,31
	pxor xmm1,xmm0
	movsd [arg1],xmm1
    _leave_
    ret



;***VECTOR 2 ALGEBRA***;

%macro DotProductXMMV2 4
;%1 and %2 are registers to proccess
;%3 is the result ;Result stored in the first 32-bits
;%4 is a temporal register
movsd %3, %1
mulps  %3, %2
movshdup %4,%3
addss    %3,%4
%endmacro
%macro _V2DOT_ 4
;%1 is the result ;Result stored in the first 32-bits
;%2 and %3 are registers to proccess
;%4 is a temporal register
DotProductXMMV2 %2, %3, %1, %4
%endmacro
global V2DOT; float V2DOT(void * A, void * B)
V2DOT:
_enter_
movlps xmm1,[arg1]
pxor xmm0,xmm0
movlps xmm2,[arg2]
_V2DOT_ xmm0,xmm1,xmm2,xmm3
_leave_
ret

%macro CROSSPRODUCTV2 4
;*** LEGACY MACRO ***;
;%1 and %2 Registers to operate with
;%3 Register where to store the result
;%4 Temporal register
;v = %1; w = %2
pshufd %4,%2,00000001b
movsd %3,%1
mulps %3,%4
movshdup %4, %3
subss %3,%4
%endmacro
%macro _V2CROSS_ 4
;%1 Destiny Operand
;%2 First Operand
;%3 Second Operand
;%4 Temporal Operand
;v = %2; w = %3
CROSSPRODUCTV2 %2,%3,%1,%4
%endmacro
global V2CROSS; float V2CROSS(void * A, void * B)
V2CROSS:
_enter_
movsd xmm2,[arg2]
movsd xmm3,[arg3]
_V2CROSS_ xmm1,xmm2,xmm3,xmm0
movss xmm0,xmm1
_leave_
ret

global V2TRANSPOSE; void V2TRANSPOSE(void * Result, void * Vector)
;***************************************
;Result = { Vector.Y , Vector.X } 
;***************************************
V2TRANSPOSE:
_enter_
movsd xmm0,[arg2]
pshufd xmm0,xmm0,1
movsd [arg1],xmm0
_leave_
ret

%macro _V2NORMALIZE_ 4
;%1 = Destination Operand
;%2 = Source Operand
;%3 = Temporal Operand (Trasheable)
;%4 = Temporal Operand (Trasheable)
movaps %4,%2
movaps %1,%2
mulps %4,%4
movshdup %3,%4
addss    %4,%3
sqrtss   %4,%4
movsldup   %4,%4,
	   divps    %1,%4
	   %endmacro
	   global V2NORMALIZE
	   V2NORMALIZE:
	   _enter_
	   movlps xmm1,[arg2] 
	   _V2NORMALIZE_ xmm0,xmm1,xmm2,xmm3
	   movsd [arg1],xmm0
	   _leave_
	   ret

	   %macro ____V2Lerp____ 4
	   ;%1 Is the First  Operand Vector (A)
	   ;%2 Is the Second Operand Vector (B)
	   ;%3 Is the Factor Operand Vector (t) (Previously pshufd' by itself with 0)
	   ;%4 Is the Destiny Vector        (C)
	   ;All operands must be different
	   movsd %4,%2
	   subps %4,%1  ;B-A
	   mulps %4,%3  ;(B-A)*t
	   addps %4,%1  ;C = A+((B-A)*t)
	   %endmacro
	   %macro _V2LERP_ 4
	   ;%1 Is the Destiny Vector        (C)
	   ;%2 Is the First  Operand Vector (A)
	   ;%3 Is the Second Operand Vector (B)
	   ;%4 Is the Factor Operand Vector (t) (Previously pshufd' by itself with 0)
	   ;All operands must be different
	   ____V2Lerp____ %2,%3,%1,%4
	   %endmacro

	   global V2LERP; void V2LERP(void * Result, void * vec2_A, void * vec2_B, float factor)
	   ;********************************************************
	   ;Given two 2D vectors and a scalar factor,
	   ;this algorithm does a Linear Interpolation
	   ;The result, a 2D vector, is stored in QR
	   ;********************************************************
	   V2LERP:
	   %ifidn __OUTPUT_FORMAT__, win64 
	   %define arg1f XMM3 ;The fourth argument is a float, Factor.
	   %define argrf XMM0 ;The result will be stored here.
	   %elifidn __OUTPUT_FORMAT__, elf64
	   %define argrf XMM3 ;The result will be stored here.
	   %endif
	   _enter_
	   movsd XMM3,[arg2]
	   pshufd arg1f,arg1f,0
	   movsd XMM1,[arg3]
	   ____V2Lerp____ XMM3,XMM1,arg1f,argrf
	   movsd [arg1],argrf
	   _leave_
	   ret 
	   %ifidn __OUTPUT_FORMAT__, win64 
	   args_reset
	   %endif

	   %macro _V2NORM_imm  2
	   ;%1 Destiny/Source Operand (float)
	   ;%2 Temporal Operand (2D vector of floats)
	   mulps %1,%1
	   movshdup %2,%1
	   addss   %1,%2
	   sqrtss  %1,%1
	   %endmacro
	   global V2NORM; float V2NORM(void * A)
	   ;************************************************************
	   ;Given a 2D vector, this algorithm returns its length (norm).
	   ;************************************************************
	   V2NORM:
	   _enter_
	   movsd xmm0,[arg1]
	   _V2NORM_imm xmm0,xmm1
	   _leave_
	   ret

	   global V2DISTANCE; float V2DISTANCE(void * A, void * B)
	   ;************************************************************
	   ;Given two 2D points, this algorithm returns the distance.
	   ;************************************************************
	   V2DISTANCE:
	   _enter_
	   movsd xmm1,[arg1]
	   movsd xmm0,[arg2]
	   subps xmm0,xmm1
	   _V2NORM_imm xmm0,xmm1
	   _leave_
	   ret


	   global V2ANGLE; (RADIANS) float V2ANGLE(void * Vector)
	   ;******************************************************************
	   ;Given a 2D Vector, this algorithm returns its angle (in radians).
	   ;******************************************************************
	   V2ANGLE:
	   _enter_
	   sub rsp, 8
	   fld dword [arg1+4]
	   fld dword [arg1]
	   fpatan
	   ;fchs
	   fstp dword [rsp]
	   movss xmm0, [rsp] 
	   add rsp, 8
	   _leave_
	   ret

	   global V2V2ANGLE; (RADIANS) float V2V2ANGLE(void * A, void * B)
	   ;******************************************************************
	   ;Given a line segment formed by the two 2D points A and B.
	   ;This algorimth calculates the angle of the line segment.
	   ;******************************************************************
	   V2V2ANGLE:
	   _enter_
	   sub rsp, 8
	   fld dword[arg1+4];A.y
	   fld dword[arg2+4];B.y
	   fsubp 
	   fld dword[arg1];A.x
	   fld dword[arg2];B.x
	   fsubp
	   fpatan
	   ;fchs
	   fstp dword[rsp] 
	   movss xmm0, [rsp] 
	   add rsp, 8
	   _leave_
	   ret

	   global ANGLEROTV2; (RADIANS) void ANGLEROTV2(void * Destiny, void * Source, float Radians)
	   ;******************************************************************
	   ;Given a 2D vector (Source) and an angle in Radians,
	   ;this algorithm transforms the 2D vector by the angle.
	   ;The result is stored in Destiny.
	   ;******************************************************************
	   %ifidn __OUTPUT_FORMAT__, win64 
	   %define arg1f XMM2
	   %define arg2f xmm0
	   %define arg3f xmm1
	   %define arg4f xmm3
	   %endif
	   ANGLEROTV2:
	   _enter_   
	   sub rsp,8

	   movss [rsp],arg1f

	   pxor xmm4,xmm4
	   pxor arg4f,arg4f

	   fld dword [rsp]
	   pxor xmm5,xmm5
	   pcmpeqd xmm4,xmm4
	   ;xmm4[0] = [11111111111111111111111111111111]

	   fld st0
	   fcos 
	   fstp dword [rsp]
	   psllq xmm4,31
	   ;xmm4[0] = [10000000000000000000000000000000]
	   fsin
	   fstp dword [rsp+4]
	   movss xmm5,xmm4

	   movsd arg1f,[rsp]
	   ;arg1f [][][sin][cos]
	   pshufd arg2f,arg1f,11_10_00_01b
	   ;arg2f [][][cos][sin]
	   movsd arg3f,[arg2]
	   movsldup xmm4,arg3f
	   ;xmm4 [][][x][x]
	   movshdup arg4f,arg3f
	   ;arg4f [][][y][y]
	   pxor arg4f,xmm5
	   ;arg4f [][][y][-y]

	   ;xmm4 [][] [x][x]
	   ;arg1f [][][sin][cos]

	   ;arg4f [][][y][-y]
	   ;arg2f [][][cos][sin]

	   mulps arg1f,xmm4
	   mulps arg2f,arg4f
	   addps arg1f,arg2f

	   movsd [arg1],arg1f

	   add rsp,8
	   _leave_ 
	   ret
	   %ifidn __OUTPUT_FORMAT__, win64 
	   args_reset
	   %endif



	   ;***VECTOR 3 MATH***;
	   ;(It is slow as it consist of Scalar and VECTOR 2 Math)

	   %macro _V3MATH_ARITHMETIC_ROUTINE 1
	   ;%1 = operation
	   _loadvec3_ xmm0,arg2,xmm2 
	   _loadvec3_ xmm1,arg3,xmm2 
	   %1 xmm0,xmm1
	   _storevec3_ arg1,xmm0,xmm2
	   %endmacro


	   %macro _loadvec3_ 3
	   ;%1 = Destiny Operand
	   ;%2 = Source Memory
	   ;%3 = temporal Operand (Trasheable)
	   movlps %1,[%2]
	   movss  %3,[%2+8]
	   movlhps %1,%3
	   %endmacro
	   %define _LOADVEC3_ _loadvec3_

	   %macro _storevec3_ 3
	   ;%1 = Destiny Memory 
	   ;%2 = Source Operand
	   ;%3 = temporal Operand (Trasheable)
	   movhlps %3,%2
	   movsd [%1],%2
	   movss [%1+8],%3
	   %endmacro
	   %define _STOREVEC3_ _storevec3_

	   %macro _V3MATH_SCALAR_ROUTINE 1
	   ;%1 = operation
	   _loadvec3_ arg2f,arg2,arg3f
	   shufps arg1f,arg1f,0
	   %1 arg2f,arg1f
	   _storevec3_ arg1,arg2f,arg3f
	   %endmacro

	   global V3ADD; void V3ADD(, void * Result, void * A, void * B)
	   ;************************************
	   ; V3 Result = (A.x + B.x , X.y + B.y, A.z + B.z)
	   ;************************************
	   V3ADD:
	   _enter_
	   _V3MATH_ARITHMETIC_ROUTINE addps
	   _leave_
	   ret

	   global V3SUB; void V3SUB(void * Result,void * A, void * B)
	   ;************************************
	   ; V3 Result = (A.x - B.x , X.y - B.y, A.z - B.z)
	   ;************************************
	   V3SUB:
	   _enter_
	   _V3MATH_ARITHMETIC_ROUTINE subps
	   _leave_
	   ret

	   global V3MUL; void V3MUL(void * Result, void * A, void * B)
	   ;************************************
	   ; V4 Result = (A.x * B.x , X.y * B.y, A.z * B.z)
	   ;************************************
	   V3MUL:
	   _enter_
	   _V3MATH_ARITHMETIC_ROUTINE mulps
	   _leave_
	   ret 

	   global V3DIV; void V3DIV(void * Result, void * A, void * B)
	   ;************************************
	   ; V3 Result = (A.x / B.x , X.y / B.y, A.z / B.z)
	   ;************************************
	   V3DIV:
	   _enter_
	   _V3MATH_ARITHMETIC_ROUTINE divps
	   _leave_
	   ret     

	   global V3MULSS; void V3MULSS (void * result, void * Vector, float FLOAT )
	   ;************************************
	   ; V3 Result = (A.x * FLOAT , X.y * FLOAT, A.z * FLOAT)
	   ;************************************
	   %ifidn __OUTPUT_FORMAT__, win64 
	   %define arg1f XMM2
	   %define arg2f XMM3
	   %define arg3f XMM4
	   %endif
	   V3MULSS:
	   _enter_
	   _V3MATH_SCALAR_ROUTINE mulps
	   _leave_
	   ret
	   %ifidn __OUTPUT_FORMAT__, win64 
	   args_reset
	   %endif

	   global V3DIVSS; void V3DIVSS (void * result, void * Vector, float FLOAT)
	   ;************************************
	   ; V2 Result = (A.x / FLOAT , X.y / FLOAT, A.z / FLOAT)
	   ;************************************
	   %ifidn __OUTPUT_FORMAT__, win64 
	   %define arg1f XMM2
	   %define arg2f XMM3
	   %define arg3f XMM4
	   %endif
	   V3DIVSS:
	   _enter_
	   _V3MATH_SCALAR_ROUTINE divps
	   _leave_
	   ret
	   %ifidn __OUTPUT_FORMAT__, win64 
	   args_reset
	   %endif

	   global V3MADSS
	   ;void V3MADSS(void * Result, void * A, void * B, float C)
	   ;************************************
	   ;V2 Resul = (A + (B*C))
	   ;************************************
	   V3MADSS:
%ifidn __OUTPUT_FORMAT__, win64 
    %define arg1f XMM3
    %define arg4f XMM0
%endif
    _enter_
    
    _loadvec3_ xmm5,arg3,arg4f
    pshufd arg1f,arg1f,0
    _loadvec3_ xmm4,arg2,arg4f
    mulps xmm5,arg1f
    addps xmm4,xmm5
    _storevec3_ arg1,xmm4,arg4f 

%ifidn __OUTPUT_FORMAT__, win64 
    args_reset
%endif
    _leave_
    ret

%macro DotProductXMMV3 4
;**LEGACY MACRO**
;%1 and %2 are registers to proccess
;%3 is the result ;Result stored in the first 32-bits
;%4 is a temporal register
	movaps %3, %1
	;%3[?][z1][y1][z1]
	mulps  %3, %2
	;%3[?][z1*z2][y1*y2][x1*x2]
	movshdup %4,%3
	;%4[?][?]    [y1*y2][y1*y2]
	addps    %4,%3
	;%4[?][?]    [?]    [(x1*x2)+(y1*y2)]
	movhlps  %3,%3
	;%3[?][z1*z2][?]    [z1*z2]
	addss    %3,%4
	;%3[?][?]    [?]    [(x1*x2)+(y1*y2)+(z1*z2)]
%endmacro
%macro _V3DOT_ 4
;%1 is the result Operand, the result stored in the first 32-bits
;%2 and %3 are registers to proccess
;%4 is a temporal register
    DotProductXMMV3 %2,%3,%1,%4
%endmacro
global V3DOT; float V3DOT(void * A, void * B)
    V3DOT:
        _enter_
        _loadvec3_ xmm1,arg1,xmm3
        _loadvec3_ xmm2,arg2,xmm3
        _V3DOT_ xmm0,xmm1,xmm2,xmm3
        _leave_
        ret

%macro NORMALIZEVEC3MACRO 4 
;%1 Register with the vector about to normalize
;%2, %3 y %4 temporal registers
    movaps %3,%1
    ;%3 [][z][y][x]
    mulps  %3,%1
    ;%3 [][z*z][y*y][x*x]	
	movhlps %2,%3
	;%2 [][][][z*z]
	pshufd %4,%3,1
	;%4 [][][][y*y]
	addss %3,%4
	addss %3,%2
	;%3 [][][][(x*x)+(y*y)+(z*z)]
	sqrtss %3,%3
	;%3 [][][][sqrt((x*x)+(y*y)+(z*z))]
    pshufd %3,%3,0
    divps %1,%3
%endmacro 
%define _V3NORMALIZE_imm NORMALIZEVEC3MACRO

global V3NORMALIZE; void V3NORMALIZE(void * Result, void * A)
    V3NORMALIZE:
    _enter_
    _loadvec3_ xmm0,arg2,xmm3
    _V3NORMALIZE_imm xmm0,xmm1,xmm2,xmm3
    _storevec3_ arg1,xmm0,xmm3
    _leave_
    ret

%macro CROSSPRODUCTMACRO 6
;**LEGACY MACROS**
;%1 First register to use
;%2 Second register to use
;%3 Register to store result
;%4, %5, %6 temporal registers
        movups %3,%1
        ;%3 [?][Az][Ay][Ax]
        movups %4,%2
        ;%4 [?][Bz][By][Bx]
        pshufd %5,%3,11010010b
        pshufd %6,%4,11001001b
        pshufd %3,%3,11001001b
        pshufd %4,%4,11010010b
        ;%3 [?][Ax][Az][Ay]
        ;%4 [?][By][Bx][Bz]
        ;%5 [?][Ay][Ax][Az]
        ;%6 [?][Bx][Bz][By]
        mulps %3,%4
        mulps %5,%6
        subps %3,%5
        ;%3 [?][Rz][Ry][Rx]
%endmacro

%macro _V3CROSS_ 5
;%1 = Destiny Operand
;%2 = First Operand     (A)
;%3 = Second Operand    (B)
;%4 = Temporal Operand (Trasheable)
;%5 = Temporal Operand (Trasheable)
    pshufd %5,%2,11010010b
    ;%5 [?][Ay][Ax][Az]
    pshufd %4,%3,11001001b
    ;%4 [?][Bx][Bz][By]

    mulps %5,%4

    pshufd %1,%2,11001001b
    ;%1 [?][Ax][Az][Ay]
    pshufd %4,%3,11010010b
    ;%4 [?][By][Bx][Bz]
    mulps %1,%4

    subps %1,%5
    ;%1 [?][Rz][Ry][Rx]
%endmacro
global V3CROSS; void V3CROSS (void * Result, void * A, void * B)
;*****************************
; V3 result = A x B
;*****************************
    V3CROSS:
    _enter_
    _loadvec3_ xmm0,arg2,xmm3
    _loadvec3_ xmm1,arg3,xmm3
    _V3CROSS_ xmm3,xmm0,xmm1,xmm2,xmm4
    _storevec3_ arg1,xmm3,xmm2
    _leave_
    ret

global V3LERP; void V3LERP(void * Result, void * vec3_A, void * vec3_B, float factor)
;********************************************************
;Given two 3D vectors and a scalar factor,
;this algorithm does a Linear Interpolation
;The result, a 3D vector, is stored in Result
;********************************************************
V3LERP:
%ifidn __OUTPUT_FORMAT__, win64 
    %define arg1f XMM3 ;The fourth argument is a float, Factor.
    %define argrf XMM0 ;The result will be stored here.
%elifidn __OUTPUT_FORMAT__, elf64
    %define argrf XMM3 ;The result will be stored here.
%endif
    _enter_
    _loadvec3_ xmm1,arg2,xmm4
    _loadvec3_ xmm2,arg3,xmm4
    pshufd arg1f,arg1f,0
    _V4Lerp_ XMM1,XMM2,arg1f,argrf
    _storevec3_ arg1,argrf,xmm4
    _leave_
    ret 
%ifidn __OUTPUT_FORMAT__, win64 
    args_reset
%endif

%macro _V3NORM_ 3
;%1 Destiny Operand (float)
;%2 Source Operand
;%3 Temporal Operand
    _V4NORM_ %1,%2,%3
%endmacro 
global V3NORM; float V3NORM(void * Vector)
    V3NORM:
        _enter_
        _loadvec3_ xmm1,arg1,xmm2
        pxor xmm0,xmm0
        _V3NORM_ xmm0,xmm1,xmm2
        _leave_
        ret

%macro _V3DISTANCE_ 4
;%1 Destiny Operand (float)
;%2 First Operand
;%3 Second Operand
;%4 Temporal Operand
    _V4DISTANCE_ %1,%2,%3,%4
%endmacro
global V3DISTANCE
    V3DISTANCE:
        _enter_
        _loadvec3_ xmm1,arg1,xmm3
        pxor xmm0,xmm0
        _loadvec3_ xmm2,arg2,xmm3
        _V3DISTANCE_ xmm0,xmm1,xmm2,xmm3
        _leave_
        ret

global V3INV; void V3INV(void * Result, void * Operand)
;*************************************
;V3 Result = -Operand
;************************************
    V3INV:
    _enter_
	_loadvec3_ xmm1,arg2,xmm2
	pcmpeqw xmm0,xmm0
	pslld xmm0,31
	pxor xmm1,xmm0
	_storevec3_ arg1,xmm1,xmm2
    _leave_
    ret

args_reset

global SSMAD; float SSMAD(float A,float B, float C);
;***********************
; It returns A + (B*C)
;***********************
    SSMAD:
    _enter_
	mulss arg2f,arg3f
	addss arg1f,arg2f
    _leave_
    ret


%macro _SSLERP_ 4
;%1 Is the Destiny    
;%2 Is the First  float     
;%3 Is the Second float     
;%4 Is the Factor float    
    movss %1,%3
    subss %1,%2  ;B-A
    mulss %1,%4  ;(B-A)*t
    addss %1,%2  ;C = A+((B-A)*t)
%endmacro
global SSLERP; float SSLERP(float A, float B,float Factor)
;******************************************************************************
;Given two single precision floats (both scalars, A and B) and a scalar factor,
;this algorithm does a Linear Interpolation
;The result is stored in Result
;******************************************************************************
    SSLERP:
    _enter_
        _SSLERP_ arg4f,arg1f,arg2f,arg3f
        movss arg1f,arg4f
    _leave_
    ret


global SDMAD; float SDMAD(float A,float B, float C);
;***********************
; It returns A + (B*C)
;***********************
    SDMAD:
    _enter_
	mulsd arg2f,arg3f
	addsd arg1f,arg2f
    _leave_
    ret

%macro _SDLERP_ 4
;%1 Is the Destiny    
;%2 Is the First  double     
;%3 Is the Second double      
;%4 Is the Factor double     
    movsd %1,%3
    subsd %1,%2  ;B-A
    mulsd %1,%4  ;(B-A)*t
    addsd %1,%2  ;C = A+((B-A)*t)
%endmacro
global SDLERP; double  SDLERP(double A, double B,double Factor)
;*************************************************************************************
;Given two double precision doubles (both scalars, A and B) and a double scalar factor,
;this algorithm does a Linear Interpolation
;The result is stored in Result
;*************************************************************************************
    SDLERP:
    _enter_
        _SDLERP_ arg4f,arg1f,arg2f,arg3f
        movsd arg1f,arg4f
    _leave_
    ret

%macro _ANGCONV_imm 4
;%1 Source and Destiny Operand
;%2 Conversion multiplier
;%3 Temporal Operand
;%4 Temporal Operand (Integer register)
    _loadimm32_ %3,%2,%4
    mulss %1,%3
%endmacro

%macro _RADTODEG_imm 3
;%1 Source and Destiny Operand
;%2 Temporal Operand
;%3 Temporal Operand (Integer register)
    _ANGCONV_imm %1,fc_180fdivPI,%2,%3
%endmacro

global RADTODEG; float RADTODEG(float Radian)
;***************************************************************
;Given a measure in radians, this algorithm returns the degrees
;***************************************************************
    RADTODEG:
    _enter_
        _RADTODEG_imm xmm0,xmm1,eax
    _leave_
    ret


%macro _DEGTORAD_imm 3
;%1 Source and Destiny Operand
;%2 Temporal Operand
;%3 Temporal Operand (Integer register)
    _ANGCONV_imm %1,fc_PIdiv180f,%2,%3
%endmacro
global DEGTORAD; float DEGTORAD(float Degrees)
;***************************************************************
;Given a measure in degrees, this algorithm returns the radians
;***************************************************************
    DEGTORAD:
    _enter_
        _DEGTORAD_imm xmm0,xmm1,eax
    _leave_
    ret

    ;/** QUATERNION MATH **/

%macro _QUATMUL_ 8
;%1 Destiny Operand         (C)
;%2 First Source Operand    (A)
;%3 Second Source Operand   (B)
;%4 Temporal Operand
;%5 Temporal Operand
;%6 Temporal Operand
;%7 Temporal Operand
;%8 Temporal Operand (Integer Register)
;All Operands must be different
    pshufd %1,%2,0
    ;%1 = [Ax][Ax][Ax][Ax]
    pxor %4,%4
    _loadimm32_ %4, SignChange32bits,%8
    ;%4 = [][][][SC]
    pshufd %5,%3,00_01_10_11b
    ;%5 = [Bx][By][Bz][Bw]
    pshufd %6,%3,01_00_11_10b
    ;%6 = [By][Bx][Bw][Bz]
    pshufd %7,%2,01_01_01_01b
    ;%7 = [Ay][Ay][Ay][Ay]
    pshufd %4,%4, 00_11_00_11b
    ;%4 = [SC][][SC][]
    mulps %1,%5
    ;%1 = [Ax*Bx][Ax*By][Ax*Bz][Ax*Bw]
    mulps %7,%6
    ;%7 = [Ay*By][Ay*Bx][Ay*Bw][Ay*Bz]
    pxor %1,%4
    ;%1 = [-Ax*Bx][Ax*By][-Ax*Bz][Ax*Bw]
    pshufd %5,%3,10_11_00_01b
    ;%5 = [Bz][Bw][Bx][By]
    pshufd %6,%2,10_10_10_10b
    ;%6 = [Az][Az][Az][Az]
    pshufd %4,%4, 11_11_00_00b
    ;%4 = [SC][SC][][]
    mulps %5,%6
    ;%5 = [Az*Bz][Az*Bw][Az*Bx][Az*By]
    pxor %7,%4
    ;%7 = [-Ay*By][-Ay*Bx][Ay*Bw][Ay*Bz]
    pshufd %6,%2,11_11_11_11b
    ;%6 = [Aw][Aw][Aw][Aw]
    pshufd %4,%4,11_00_01_11b
    ;%4 = [SC][][][SC]
    addps %1,%7
    ;%1 = [-(Ax*Bx)-(Ay*By)][(Ax*By)-(Ay*Bx)][-(Ax*Bz)+(Ay*Bw)][(Ax*Bw)+(Ay*Bz)]
    pxor %5,%4
    ;%5 = [-(Az*Bz)][(Az*Bw)][(Az*Bx)][-(Az*By)]
    mulps %6,%3
    ;%6 = [Aw*Bw][Aw*Bz][Aw*By][Aw*Bx]
    addps %1,%5
    ;%1 =   [-(Ax*Bx)-(Ay*By)-(Az*Bz)]
    ;       [(Ax*By)-(Ay*Bx)+(Az*Bw)]
    ;       [-(Ax*Bz)+(Ay*Bw)+(Az*Bx)]
    ;       [(Ax*Bw)+(Ay*Bz)-(Az*By)]
    addps %1,%6
    ;%1 =   [-(Ax*Bx)-(Ay*By)-(Az*Bz)+(Aw*Bw)]  qw
    ;       [(Ax*By)-(Ay*Bx)+(Az*Bw)+(Aw*Bz)]   qk
    ;       [-(Ax*Bz)+(Ay*Bw)+(Az*Bx)+(Aw*By)]  qj
    ;       [(Ax*Bw)+(Ay*Bz)-(Az*By)+(Aw*Bx)]   qi

    
%endmacro
global QUATMUL; void QUATMUL (float * Result, float * A, float * B);
;**********************************
; Given A and B (both Quaternions),
; Quaternion Result = A * B;
;**********************************
QUATMUL:
    _enter_
%ifidn __OUTPUT_FORMAT__, win64 
    sub rsp,16;
    movups [rsp], xmm6
    ;movups [rsp+(16)], xmm7
%endif
    movups xmm1,[arg2] ;<- Quaternion A
    movups xmm2,[arg3] ;<- Quaternion B

    _QUATMUL_ xmm0,xmm1,xmm2,xmm3,xmm4,xmm5,xmm6,eax
    
    ;movntps [arg1],xmm0
    movups [arg1],xmm0

%ifidn __OUTPUT_FORMAT__, win64 
    movups xmm6, [rsp]
    ;movups xmm7, [rsp+(16)]
    add rsp,16;
    args_reset
%endif
     _leave_
    ret


global QUATROTV3; void QUATROTV3(void * Result, void * V3, void * Quaternion )
;********************************************************************
;Given a Quaternion and a 3D Vector,
;this algoritm rotates the 3D vector around origin by the quaternion
;********************************************************************
QUATROTV3:
    _enter_
%ifidn __OUTPUT_FORMAT__, win64 
    sub rsp,16*2;
    movups [rsp], xmm6
    movups [rsp+(16)], xmm7
%endif


    movups xmm0, [arg2]	    ;<- xmm0 stores the imaginary part of the Quaternion
    movss xmm1,[arg2+4+4+4] ;<- xmm1 stores the real part of the Quaternion
    movsd xmm2,[arg3]    
    movss xmm3,[arg3+4+4]
    movlhps xmm2,xmm3	    ;<- xmm2 stores the 3D vector
    
    DotProductXMMV3 xmm0,xmm2,xmm3,xmm4; <-xmm3 stores xmm0 . xmm2
    addss xmm3,xmm3 ;<- xmm3 * 2.f
    movaps xmm6,xmm0
    DotProductXMMV3 xmm0,xmm6,xmm5,xmm4; <-xmm5 stores xmm0 . xmm0 
    movss xmm4,xmm1
    mulss xmm4,xmm4
    subss xmm4,xmm5 ;<- (xmm1*xmm1) - xmm5

    pshufd xmm3,xmm3,0
    mulps xmm3,xmm0

    pshufd xmm4,xmm4,0
    mulps xmm4,xmm2

    addps xmm4,xmm3

    CROSSPRODUCTMACRO xmm0,xmm2,xmm3,xmm5,xmm6,xmm7 ;<- xmm3 stores xmm0 x xmm2
    
    addss xmm1,xmm1 ;<- xmm1 * 2
    pshufd xmm1,xmm1,0
    mulps xmm1,xmm3
    
    addps xmm4,xmm1
    movhlps xmm1,xmm4

    movsd [arg1],xmm4
    movss [arg1+4+4],xmm1


%ifidn __OUTPUT_FORMAT__, win64 
    movups xmm6, [rsp]
    movups xmm7, [rsp+(16)]
    add rsp,16*2;
    args_reset
%endif
    _leave_
    ret

global QUATTOM4; void QUATTOM4(void * Matrix, void * Quaternion)
;********************************************
;Given a Quaternion, this function generates a 4x4 Matrix.
;This algorithm is an implementation of a method by Jay Ryness (2008)
;Source: https://sourceforge.net/p/mjbworld/discussion/122133/thread/c59339da/
;********************************************
QUATTOM4: 
    _enter_
%ifidn __OUTPUT_FORMAT__, win64 
    sub rsp,16*2
    movups [rsp],xmm6
    movups [rsp+16],xmm7
    %define arg1 rdx
    %define arg2 rcx
%elifidn __OUTPUT_FORMAT__, elf64
    %define arg1 rsi
    %define arg2 rdi
%endif
 
        _loadimm32_ xmm7,SignChange32bits,eax
        ;xmm7 [0][0][0][0x800000]
		movaps xmm6,xmm7
		;xmm6 [0][0][0][0x800000]
		pshufd xmm5,xmm7,01_00_01_01b
		;xmm5 [0][0x800000][0][0]
		pshufd xmm4,xmm7,01_01_00_01b
		;xmm4 [0][0][0x800000][0]

    sub rsp,16
                pshufd arg1f,xmm7,00_11_11_11b
                movups arg4f,[arg1]
                movups arg2f,arg4f
                ;xmm3 [w][z][y][x]
                movups [rsp],arg4f
                pshufd xmm7,xmm7,11000000b
                ;xmm7 [0][0x800000][0x800000][0x800000]
    mov arg3,rsp
    ;rsp=x  ;rsp+4=y	;rsp+8=z    ;rsp+12=w
                movups arg4f,arg2f
                ;xmm3 [w][z][y][x]
        fld dword[arg3]
    add arg3,4
        fld dword[arg3]
                pxor xmm7,arg4f
                ;xmm7 [w][-z][-y][-x]
    add arg3,4
        fld dword[arg3]
    add arg3,4
        fld dword[arg3]
        ;Stack: ST0= -w; ST1=z; ST2=y; ST3=x
        
	;xmm3= [w][z][y][x]
        ;xmm7= [w][-z][-y][-x]

        movups [arg2+16+16+16],xmm3

	pshufd xmm0,xmm3,00011011b
	pxor xmm0,xmm5
	;xmm0 = [x][-y][z][w]

	pshufd xmm1,xmm3,01001110b
	pxor xmm1,xmm6
	;xmm1 = [y][x][w][-z] 

    mov eax,fc_1f

	pshufd xmm2,xmm3,10110001b
	pxor xmm2,xmm4
	;xmm2 = [z][w][-x][y]

	movaps xmm3,xmm7
	;xmm3 = [w][-z][-y][-x]

	movups [arg2],xmm0
	movups [arg2+16],xmm1
	movups [arg2+16+16],xmm2
	movups [arg2+16+16+16],xmm3

        fstp dword [arg2+16+16+16+12]
        fchs
	fstp dword [arg2+16+16+16+12-16]
        fchs
	fstp dword [arg2+16+16+16+12-16-16]
        fchs
	fstp dword [arg2+16+16+16+12-16-16-16]

    TRANS44
    
    mov arg1,arg2
    xor arg3,arg3
    mov arg4,arg2
    Mmullabelqua:
        MULVEC4VEC4 arg1,arg4,arg3
        add arg3,16
        cmp arg3,64
        jne Mmullabelqua

    pxor xmm3,xmm3
    movups [arg2+16+16+16],xmm3
    mov [arg2+16+16+16+12],eax

    add rsp,16
%ifidn __OUTPUT_FORMAT__, win64 
    
    movups xmm6,[rsp]
    movups xmm7,[rsp+16]


    add rsp,16*2
    
%endif
    _leave_
    ret
args_reset


global EULERTOQUAT; void EULERTOQUAT( void * Quaternion,void * Axis, float Degree)
;*********************************************************************
;Given a 3D Vector describing an Axis and a angle given in Radians,
;This function calculates the respective quaternion.
;*********************************************************************
%ifidn __OUTPUT_FORMAT__, win64 
    %define arg1f XMM2
%endif
EULERTOQUAT:
    _enter_
	sub rsp,8
	movss [rsp],arg1f
        fld dword [rsp]
        fld1
    add rsp,8
        fld1

        faddp
        fdivp
        fld st0
            movups arg1f,[arg2]
        fcos
        fxch

        fsin
        fstp dword[arg1]
            movss XMM3,[arg1]
            pshufd XMM3,XMM3,0h
            mulps arg1f,XMM3
            movups [arg1],arg1f
        fstp dword[arg1+4+4+4]
    _leave_
    ret
%ifidn __OUTPUT_FORMAT__, win64 
    args_reset
%endif

%macro _UQUATINV_ 3
;%1 Destiny Operand
;%2 Source Operand
;%3 Temporal Operand
    _loadsignbit32_ %3
    ;xmm1 [sb][sb][sb][sb] 
    movaps %1,%2
    pslldq %3,4
    ;xmm1 [sb][sb][sb][0] 
    pxor %1,%2
%endmacro

global UQUATINV; void UQUATINV(void * Result, void * Unit_Quaternion);
;*********************************************************************
;Given an unit Quaternion, this algoritm return its inverse.
;*********************************************************************
UQUATINV:
    _enter_
	_loadsignbit32_ xmm0
	;xmm0 [sb][sb][sb][sb] 
    movups xmm1,[arg2]
	psrldq xmm0,4
	;xmm0 [0][sb][sb][sb]
	pxor xmm1,xmm0
	movups [arg1],xmm1
    _leave_
    ret


global UQUATNLERP; void UQUATNLERP(void * Result, void * UQuaternionA,void * UQuaternionB,float Factor)
;***************************************************************************************
;Given two quaternions, this algorithm returns the Normalized Linear Interpolation by a
;given factor.
;***************************************************************************************
UQUATNLERP:
    _enter_
%ifidn __OUTPUT_FORMAT__, win64
	movaps xmm0,xmm3
%endif
	movups xmm4,[arg2]
	pshufd xmm0,xmm0,0
	movups xmm5,[arg3]
	_V4Lerp_ xmm1,xmm4,xmm5,xmm0
	_V4NORMALIZE_ xmm2,xmm1,xmm3,xmm4
	movups [arg1],xmm2
    _leave_
    ret

global UQUATSLERP; void UQUATSLERP(void * Result, void * A, void * B, float Factor)
;***************************************************************************************
;Given two quaternions, this algorithm returns the Spherical Linear Interpolation by a
;given factor.
;***************************************************************************************
    UQUATSLERP:
%ifidn __OUTPUT_FORMAT__, win64
	movaps xmm0,xmm3
%endif
    _enter_
	movups xmm4,[arg2]
	pshufd xmm0,xmm0,0
	movups xmm5,[arg3]


    _leave_
    ret


global UQUATDIFF; void UQUATDIFF(void * Result, void * A, void * B);
;*********************************************************************
; Given Two Unit Quaternions A and B, 
; This algorithm returns the rotational difference.
;*********************************************************************
UQUATDIFF:
    _enter_
%ifidn __OUTPUT_FORMAT__, win64 
    sub rsp,16;
    movups [rsp], xmm6
%endif
	movups xmm2,[arg3]
	_loadsignbit32_ xmm1
	;xmm1 [sb][sb][sb][sb] 
    movups xmm0,[arg2]
	psrldq xmm1,4
	;xmm1 [0][sb][sb][sb] 
	pxor xmm1,xmm0
	;xmm1 = -A;

	;-- Calculate B * -A
	_QUATMUL_ xmm0,xmm2,xmm1,xmm3,xmm4,xmm5,xmm6,eax
	;xmm0 = B * -A = A - B

	movntps [arg1],xmm0
 
%ifidn __OUTPUT_FORMAT__, win64 
    movups xmm6, [rsp]
    add rsp,16;
    args_reset
%endif
    _leave_
    ret



;** 2x2 MATRIX MATH **;

global M2MAKE; void M2MAKE(void * Destiny, float Scale)
    M2MAKE:
	_enter_
%ifidn __OUTPUT_FORMAT__, win64 
    movaps arg1f,arg2f
%endif
	pshufd arg1f,arg1f,00_11_11_00b
	movups [arg1],arg1f
        _leave_
        ret
%ifidn __OUTPUT_FORMAT__, win64 
    args_reset
%endif

global ANGLETOM2; void ANGLETOM2(void * Destiny, float Radians);
	ANGLETOM2:
	_enter_
%ifidn __OUTPUT_FORMAT__, win64 
    movaps arg1f,arg2f
%endif
		sub rsp,8

		movss [rsp],arg1f
		
		fld dword [rsp]
		fld st0
		fcos 
		fst dword [arg1]
		fstp dword [arg1+4+4+4]
		fsin 
		fst dword [arg1+4]
		fchs
		fstp dword [arg1+8]
	

		add rsp,8
        _leave_
        ret
%ifidn __OUTPUT_FORMAT__, win64 
    args_reset
%endif

%macro _M2MUL_ 5
; %1 Destiny
; %2 First Operand
; %3 Second Operand
; %4 Temporal Operand
; %5 Temporal Operand
; All operands must be different
     movups %1,%2
     movlhps %1,%2
     movsldup %4,%3
     mulps %1,%4
     movups %5,%2
     movhlps %5,%2
     movshdup %4,%3
     mulps %4,%5
     addps %1,%4
 %endmacro
global M2MUL; void M2MUL(void * Destiny, void * A, void * B);
     M2MUL:
         _enter_
             movups xmm2,[arg2]
             movups xmm3,[arg3]
             _M2MUL_ xmm1,xmm2,xmm3,xmm4,xmm5
             movups [arg1],xmm1
         _leave_
         ret

%macro _M2MULV2_ 4
;%1 Destiny
;%2 Matrix Operand
;%3 Vector Operand
;%4 Temporal Operand
    pshufd %4,%3,01_01_00_00b
    mulps %4,%2
    movhlps %1,%4
    addps %1,%4
%endmacro
global M2MULV2; void M2MULV2(void * V2_Destiny, void * Matrix, void * Vector);
    M2MULV2:
	_enter_
	    movups xmm1,[arg2]
	    movsd xmm2,[arg3]
	    _M2MULV2_ xmm0,xmm1,xmm2,xmm3
	    movsd [arg1],xmm0
	_leave_
	ret

%macro _M2DET_ 3
 ; %1 Destiny
 ; %2 Operand
 ; %3 Temporal Operand
 ; All operands must be different
     pshufd %1,%2, 00_00_10_00b
     pshufd %3,%2, 00_00_01_11b
     mulps %1,%3
     movshdup %3,%1
     subss %1,%3
 %endmacro
 global M2DET; float M2DET(void * Matrix);
     M2DET:
	_enter_
             movups xmm1,[arg1]
             _M2DET_ xmm0,xmm1,xmm2
	_leave_
         ret

%macro _M2INV_ 3
;%1 Destiny Operand
;%2 Source Operand
;%3 Temporal Operand
     pcmpeqw %3,%3 
     pslld %3,31 
     ;%3 = [SB][SB][SB][SB] 
     pslldq %3,8 
     psrldq %3,4 
     ;%3 = [0][SB][SB][0] 
    pshufd %1,%2,00_10_01_11b
    pxor %1,%3
%endmacro 
global M2INV; void M2INV(void * Destiny, void * Matrix)
;************************************************************
;Given a 2x2 Matrix, this algorithm will compute its inverse,
;The Inverse will be stored in Destiny.
;************************************************************
    M2INV:
	_enter_
	    _M2INV_ xmm0,[arg2],xmm2
	    movntps [arg1],xmm0
	_leave_
	ret

global M2TRANSPOSE; void M2TRANSPOSE(void * Destiny, void * Origin)
    M2TRANSPOSE:
    _enter_
	movups xmm0,[arg2]
	pshufd xmm0,xmm0, 11011000b
	movups [arg1],xmm0
    _leave_
    ret







%if 0
;** 4x4 MATRIX MATH **;
global M4LERP; M4LERP(float * Result, float * MatrixA, float * MatrixB, float Factor)
;***************************************************************
;Given two 4x4 Matrices A and B and a scalar factor,
;This function will return a linear interpolation between them
;***************************************************************
M4LERP:
    %ifidn __OUTPUT_FORMAT__, win64 
        %define arg1f XMM3 ;The fourth argument is a float, Factor.
        %define argrf XMM0 ;The result will be stored here.
    %elifidn __OUTPUT_FORMAT__, elf64
        %define argrf XMM3 ;The result will be stored here.
    %endif

    _enter_
    ;XMM4 - XMM7 OUTPUT MATRIX (one at a time)
    ;XMM1	 MATRIX A COLUMNS (one at a time)
    ;XMM2	 MATRIX B COLUMNS (one at a time)

    ;XMM4
    movups XMM1,[arg2]
    pshufd arg1f,arg1f,0
    MOVUPS XMM2,[arg3]
    add arg2,4*4
    _V4Lerp_ XMM1, XMM2,arg1f,XMM4
    add arg3,4*4

    ;XMM5
    movups XMM1,[arg2]
    movups XMM2,[arg3]
    add arg2,4*4 ;UPDATING A MATRIX POINTER
    movups [arg1],XMM4 ;OUTPUTING FIRST COLUMN
    add arg3,4*4;UPDATING B MATRIX POINTER
    _V4Lerp_ XMM1, XMM2,arg1f, XMM5
    add arg1,4*4;UPDATING DESTINY POINTER

    ;XMM6
    movups XMM1,[arg2]
    movups XMM2,[arg3]
    add arg2,4*4 ;UPDATING A MATRIX POINTER
    movups [arg1],XMM5 ;OUTPUTING SECOND COLUMN
    add arg3,4*4 ;UPDATING B MATRIX POINTER
    _V4Lerp_ XMM1, XMM2,arg1f, XMM6
    add arg1,4*4 ;UPDATING DESTINY POINTER
    
    ;XMM7
    movups XMM1,[arg2]
    movups XMM2,[arg3]
    add arg2,4*4; UPDATING A MATRIX POINTER
    movups [arg1],XMM6 ;OUTPUTING THIRD COLUMN
    add arg3,4*4 ; UPDATING B MATRIX POINTER
    _V4Lerp_ XMM1, XMM2,arg1f, XMM7
    add arg1,4*4 ; UPDATING DESTINY POINTER
  
    movups [arg1],XMM7;OUTPUTING FOURTH COLUMN

    _leave_
    ret

    %ifidn __OUTPUT_FORMAT__, win64 
        args_reset
    %endif
%endif


%macro M4x4MULMACRO 2 ;When used, registers should be 0'd
;**LEGACY MACRO**;
    DotProductXMM arg4f,%1,xmm8,xmm9
    pshufd xmm10,xmm8,0
    DotProductXMM arg3f,%1,xmm8,xmm9
    movss xmm10,xmm8
    DotProductXMM arg2f,%1,xmm8,xmm9
    pshufd %2,xmm8,0
    DotProductXMM arg1f,%1,xmm8,xmm9
    movss %2,xmm8
    movlhps %2,xmm10
%endmacro

%if 0
global M4MULV4;M4MULV4(float * Result, float * MatrixA, float *VectorB);
;******************************************************
; Given a 4x4 Matrix MatrixA and a 4D Vector VectorB,
; 4D Vector Result = MatrixA * VectorB;
;******************************************************
M4MULV4: 
    _enter_
%ifidn __OUTPUT_FORMAT__, win64 
    sub rsp,16*2
    movups [rsp],xmm6
    movups [rsp+16],xmm7
    %define arg1 rdx
    %define arg2 r8
    %define arg3 rcx
%elifidn __OUTPUT_FORMAT__, elf64
    %define arg1 rsi
    %define arg2 rdx
    %define arg3 rdi
%endif

    sub rsp, 16*4
    movups [rsp],xmm8
    movups [rsp+16],xmm9
    movups [rsp+16+16],xmm10
    movups [rsp+16+16+16],xmm11

        movups  arg1f, [arg1]
        movups  arg2f, [arg1+16]
        movups  arg3f, [arg1+32]
        movups  arg4f, [arg1+16+32]
    TRANS44
    movups xmm7,[arg2]
	movaps arg3f,xmm4
	movaps arg4f,xmm5
    M4x4MULMACRO xmm7,xmm11
	movups [arg3],xmm11

    movups xmm8,[rsp]
    movups xmm9,[rsp+16]
    movups xmm10,[rsp+16+16]
    movups xmm11,[rsp+16+16+16]
    add rsp, 16*4

%ifidn __OUTPUT_FORMAT__, win64 
    movups xmm6,[rsp]
    movups xmm7,[rsp+16]
    add rsp, 16*2
%endif
    _leave_
    ret
args_reset
%endif


%if 0
global M4MUL ;void M4MUL (void * Result, float * A, float *B);
;**********************************************
;Given A and B (both 4x4 Matrices),
;4x4 Matrix Result = A * B;
;**********************************************
M4MUL:
    _enter_
%ifidn __OUTPUT_FORMAT__, win64 
    sub rsp,16*2
    movups [rsp],xmm6
    movups [rsp+16],xmm7
    %define arg1 rdx
    %define arg2 r8
    %define arg3 rcx
%elifidn __OUTPUT_FORMAT__, elf64
    %define arg1 rsi
    %define arg2 rdx
    %define arg3 rdi
%endif


    sub rsp, 16*8
    movups [rsp],xmm8
    movups [rsp+16],xmm9
    movups [rsp+16+16],xmm10
    movups [rsp+16+16+16],xmm11
    movups [rsp+16+16+16+16],xmm12
    movups [rsp+16+16+16+16+16],xmm13
    movups [rsp+16+16+16+16+16+16],xmm14
    movups [rsp+16+16+16+16+16+16+16],xmm15

        movups  arg1f, [arg1]
        movups  arg2f, [arg1+16]
        movups  arg3f, [arg1+32]
        movups  arg4f, [arg1+16+32]
    TRANS44; Matrix A (rows) in 0,1,4 and 5
	  movaps arg3f,xmm4
	  movaps arg4f,xmm5
    ;Matriz A (rows) in 0,1,2,3

        movups  xmm4, [arg2]
        movups  xmm5, [arg2+16]
        movups  xmm6, [arg2+32]
        movups  xmm7, [arg2+16+32]
    ;Matriz B (Columns) in 4,5,6,7

    M4x4MULMACRO xmm4,xmm12
    M4x4MULMACRO xmm5,xmm13
    M4x4MULMACRO xmm6,xmm14
    M4x4MULMACRO xmm7,xmm15

    movups [arg3],xmm12
    movups [arg3+16],xmm13
    movups [arg3+32],xmm14
    movups [arg3+16+32],xmm15

    movups xmm8,[rsp]
    movups xmm9,[rsp+16]
    movups xmm10,[rsp+16+16]
    movups xmm11,[rsp+16+16+16]
    movups xmm12,[rsp+16+16+16+16]
    movups xmm13,[rsp+16+16+16+16+16]
    movups xmm14,[rsp+16+16+16+16+16+16]
    movups xmm15,[rsp+16+16+16+16+16+16+16]
    add rsp, 16*8

%ifidn __OUTPUT_FORMAT__, win64 
    movups xmm6,[rsp]
    movups xmm7,[rsp+16]
    add rsp, 16*2
%endif
    _leave_
    ret
%endif
args_reset

%if 0
global M4MAKE; void M4MAKE(void * Destiny,float Scale) //FIXME
;**************************************************************
;This algorithm fills a matrix buffer with a scaling constant
;Using 1.0 as the constant is equal to the Identity
;**************************************************************
    M4MAKE:
        _enter_
%ifidn __OUTPUT_FORMAT__, win64 
    movaps arg1f,arg2f
%endif
        
        movups [arg1],arg1f
        pslldq arg1f,4
        add arg1,16
        movups [arg1],arg1f
        pslldq arg1f,4
        add arg1,16
        movups [arg1],arg1f
        pslldq arg1f,4
        add arg1,16
        movups [arg1],arg1f
        
        

        _leave_
        ret
%ifidn __OUTPUT_FORMAT__, win64 
    args_reset
%endif
%endif





%macro _M4INVERSE_Submatrices_L_ 3
;   %1 Destiny
;   %2 Low Source
;   %3 High Source
; All operands must be different
    movaps %1,%2
    movlhps %1,%3
%endmacro
%macro _M4INVERSE_Submatrices_H_ 3
;   %1 Destiny
;   %2 First Source
;   %3 Second Source
; All operands must be different
    movaps %1,%3
    movhlps %1,%2
%endmacro
%macro _M4INVERSE_ADJMULM2 5
;   %1  Destiny
;   %2  First Operand
;   %3  Second Operand
;   %4  Temporal Operand
;   %5  Temporal Operand
; All operands must be different
    pshufd %1,%2,00_11_00_11b
    mulps %1,%3
    pshufd %4,%2, 01_10_01_10b
    pshufd %5,%3, 10_11_00_01b
    mulps %4,%5
    subps %1,%4
%endmacro
%macro _M4INVERSE_M2MULADJ 5
;   %1  Destiny
;   %2  First Operand
;   %3  Second Operand
;   %4  Temporal Operand
;   %5  Temporal Operand
; All operands must be different
    pshufd %1,%3,00_00_11_11b
    mulps %1,%2
    pshufd %4,%3,10_10_01_01b
    pshufd %5,%2,01_00_11_10b
    mulps %4,%5
    subps %1,%4
%endmacro


%if 0 
global M4INV; void M4INV(void * Result, void * Matrix);
;****************************************************************************************
; This function returns the inverse of a given 4x4 Matrix (A).
; It is an implementation of Eric Zhang's Fast 4x4 Matrix Inverse.
; Source: 
; https://lxjk.github.io/2017/09/03/Fast-4x4-Matrix-Inverse-with-SSE-SIMD-Explained.html
;****************************************************************************************
M4INV:

    _enter_

%ifidn __OUTPUT_FORMAT__, win64 
    sub rsp,16*2
    movups [rsp],xmm6
    movups [rsp+16],xmm7
%endif
    sub rsp,16*6
    movups [rsp],xmm8
    movups [rsp+16],xmm9
    movups [rsp+16+16],xmm10
    movups [rsp+16+16+16],xmm15
    movups [rsp+16+16+16+16],xmm11
    movups [rsp+16+16+16+16+16],xmm12

    movups xmm4,[arg2]
    movups xmm5,[arg2+16]
    movups xmm6,[arg2+16+16]
    movups xmm7,[arg2+16+16+16]

    ;-- Get submatrices --;
    _M4INVERSE_Submatrices_L_ xmm0,xmm4,xmm5 ;A;            <-----
    _M4INVERSE_Submatrices_L_ xmm1,xmm6,xmm7 ;B;            <-----
    _M4INVERSE_Submatrices_H_ xmm2,xmm4,xmm5 ;C;            <-----
    _M4INVERSE_Submatrices_H_ xmm3,xmm6,xmm7 ;D;            <-----
    ;-- Submatrices OK--;
    

    ;-- Get D Determinant 
    _M2DET_ xmm5,xmm3,xmm6
    pshufd xmm5,xmm5,0
    ; xmm5 = |D|

    ;-- Get A Determinant --;
    _M2DET_ xmm15,xmm0,xmm6
    pshufd xmm15,xmm15,0
    ; xmm15 = |A|

    ;--Determinants OK;  
   
  

    ;-- D#C
    _M4INVERSE_ADJMULM2 xmm4,xmm3,xmm2,xmm6,xmm7;xmm4 = D#C <-----
    ;-- OK
       
   
    ;-- Calculate X# = |D|A - B(D#C)
    movaps xmm6,xmm0
    mulps xmm6,xmm5
        ;xmm6 = |D|A
    _M2MUL_ xmm7,xmm1,xmm4,xmm8,xmm9
        ;xmm7 =  B(D#C)
    subps xmm6,xmm7
    ; xmm6 = X#                                             <-----
    ;-- X# Ok
    

    movaps xmm9,xmm15 ;<- Saving |A|

        ;-- Start Calculating |M| (@ xmm15[0:31])--;
    mulss xmm15,xmm5; |M| = |A|*|D| + ...                   <-----


    ;-- A#B
    _M4INVERSE_ADJMULM2 xmm5,xmm0,xmm1,xmm7,xmm8;xmm5 = A#B <-----

    

    ;-- Calculate W# = |A|D - C(A#B)
    movaps xmm7,xmm3
    mulps xmm7,xmm9
        ;xmm7 = |A|D
    _M2MUL_ xmm8,xmm2,xmm5,xmm9,xmm10
        ;xmm8 = C(A#B)
    subps xmm7, xmm8
    ; xmm7 = W#                                             <-----
    ; -- W# OK

    


    ;-- Get B Determinant 
    _M2DET_ xmm9,xmm1,xmm10
    pshufd xmm9,xmm9,0
    ; xmm9 = |B|

       ;-- Get C Determinant 
    _M2DET_ xmm11,xmm2,xmm10
    pshufd xmm11,xmm11,0
    ; xmm11 = |C|
    
    ;--Determinants OK;     


           ;-- Continue Calculating |M| (@ xmm15[0:31])--;
    movss xmm10,xmm9
    mulss xmm10,xmm11
    addss xmm15,xmm10; |M| = |A|*|D| + |B|*|C| + ...        <-----

    


    ;-- Calculate Y# = |B|C - D(A#B)#
    movaps xmm8,xmm2
    mulps xmm8,xmm9
        ;xmm8 = |B|C
    _M4INVERSE_M2MULADJ xmm10,xmm3,xmm5,xmm9,xmm12
        ;xmm10  = D(A#B)#
    subps xmm8,xmm10
    ; xmm8 = Y#                                             <-----


    ;-- Calculate Z# = |C|B - A(D#C)#
    movaps xmm9,xmm1
    mulps xmm9,xmm11
        ;xmm9 = |C|B
    _M4INVERSE_M2MULADJ xmm10,xmm0,xmm4,xmm11,xmm12
        ;xmm10 = A(D#C)#
    subps xmm9,xmm10
    ; xmm9 = Z#                                             <-----
    ;-- Z# OK



    ;-- Calculate tr((A#B)(D#C))
    pshufd xmm10,xmm4,11_01_10_00b 
	mulps  xmm10, xmm5
	movshdup xmm11,xmm10
    addps xmm10,xmm11
    movhlps xmm11,xmm10
	addss    xmm10,xmm11
    ; xmm10 = tr((A#B)(D#C))                                <-----

    

    pcmpeqw xmm4,xmm4
    pslld xmm4,25
    psrld xmm4,2
    ;xmm4 = [1][1][1][1]

             ;-- Calculate |M| (@ xmm15[0:31])--;
    subss xmm15,xmm10; |M| = |A|*|D| + |B|*|C| - tr((A#B)(D#C))        <-----
    pshufd xmm15,xmm15,0
    ;xmm15 = [|M|] [|M|] [|M|] [|M|]

    pcmpeqw xmm5,xmm5
    pslld xmm5,31
    ;xmm5 = [SB][SB][SB][SB]
    pslldq xmm5,8
    psrldq xmm5,4
    ;xmm5 = [0][SB][SB][0]

    pxor xmm5,xmm4
    ;xmm5 = [1][-1][-1][1]
    divps xmm5,xmm15
    ;xmm5 = [1/|M|] [-1/|M|] [-1/|M|] [1/|M|]

    mulps xmm6,xmm5
    mulps xmm7,xmm5
    mulps xmm8,xmm5
    mulps xmm9,xmm5

    ;xmm6 (X)
    ;xmm8 (Y)
    ;xmm9 (Z)
    ;xmm7 (W)

    ;-- Submatrices needs to be adjugated--
    ;-- Submatrices are already partially adjugated--

    ;Final matrix is:
    ;   X#  Y#
    ;   Z#  W#

    ;Each Submatrix is Collum Mayor:
    ;   +X0   -X2
    ;   -X1   +X3
    
    ;-- Adjugating submatrices and ordering final matrix 

    ;First Collumn (most left one)
    movaps xmm0,xmm6
    shufps xmm0,xmm9,01_11_01_11b

    ;Second Collumn
    movaps xmm1,xmm6
    shufps xmm1,xmm9,00_10_00_10b

    ;Third Collumn
    movaps xmm2,xmm8
    shufps xmm2,xmm7,01_11_01_11b

    ;Fourth Collumn (most right one)
    movaps xmm3,xmm8
    shufps xmm3,xmm7,00_10_00_10b


    ;-- Storing final matrix
%if 1
    movntps [arg1],XMM0
    movntps [arg1+16],XMM1
    movntps [arg1+16+16],XMM2
    movntps [arg1+16+16+16],XMM3
%endif

    movups xmm8,[rsp]
    movups xmm9,[rsp+16]
    movups xmm10,[rsp+16+16]
    movups xmm15,[rsp+16+16+16]
    movups xmm11,[rsp+16+16+16+16]
    movups xmm12,[rsp+16+16+16+16+16]
    add rsp,16*6
%ifidn __OUTPUT_FORMAT__, win64 
    movups xmm6,[rsp]
    movups xmm7,[rsp+16]
    add rsp,16*2
    args_reset
%endif

    _leave_
    ret

%endif

%unmacro _M4INVERSE_M2MULADJ 5
%unmacro _M4INVERSE_ADJMULM2 5
%unmacro _M4INVERSE_Submatrices_L_ 3
%unmacro _M4INVERSE_Submatrices_H_ 3


%if 0
global M4MULV3
; M4MULV3(void * Result, void * Matrix, void * Vector);
;*******************************************************************************************
; Given a 4x4 Matrix and a 3D Vector,
; 3D Vector Result = MatrixA * VectorB, BUT:
; - In order for the operation to be possible, a 4th element (1.f) is added to Vector
;*******************************************************************************************
M4MULV3: 
    _enter_

%ifidn __OUTPUT_FORMAT__, win64 
    sub rsp,16*2
    movups [rsp],xmm6
    movups [rsp+16],xmm7
%endif
    sub rsp,16*4
    movups [rsp],xmm8
    movups [rsp+16],xmm9
    movups [rsp+16+16],xmm10
    movups [rsp+16+16+16],xmm15

    movups xmm4,[arg2]
    movups xmm5,[arg2+16]
    movups xmm6,[arg2+16+16]
    movups xmm7,[arg2+16+16+16]
        movups  arg1f, [arg2]
        movups  arg2f, [arg2+16]
        movups  arg3f, [arg2+32]
        movups  arg4f, [arg2+16+32]
    TRANS44

    _loadvec3_ xmm7,arg3,xmm15


	movaps arg3f,xmm4
	movaps arg4f,xmm5

    pxor xmm4,xmm4
    pcmpeqd xmm4,xmm4
    ;xmm4[0] = [11111111111111111111111111111111]
    psrld xmm4,25
    ;xmm4[0] = [00000000000000000000000001111111]
    pslld xmm4,23
    ;xmm4[0] = [00111111100000000000000000000000] = 1.f
    ;xmm4 = [1.f][1.f][1.f][1.f]


    movhlps xmm5,xmm7
    ;xmm5 = [?][?][W][Z]
    movss xmm4,xmm5
    ;xmm4 = [1.f][1.f][1.f][Z]
    movlhps xmm7,xmm4
    ;xmm7 = [1.f][Z][Y][X]
    movlhps xmm5,xmm5
    ;xmm5 = [W][Z][?][?]


    M4x4MULMACRO xmm7,xmm15

    movhlps xmm5,xmm15
    ;xmm5 = [W][Z][Rw][Rz]
    pshufd xmm5,xmm5,11_10_11_00b
    ;xmm5 = [W][Z][W][Rz]
    movlhps xmm15,xmm5
    ;xmm15 = [W][Rz][Ry][Rx]
    
    _storevec3_ arg1,xmm15,xmm10 

    movups xmm8,[rsp]
    movups xmm9,[rsp+16]
    movups xmm10,[rsp+16+16]
    movups xmm15,[rsp+16+16+16]
    add rsp,16*4

%ifidn __OUTPUT_FORMAT__, win64 
    movups xmm6,[rsp]
    movups xmm7,[rsp+16]
    add rsp, 16*2
%endif
    _leave_
    ret
%endif

args_reset

%if 0 
global AM4MULV3; void AM4MULV3(void * Vec3_Destiny, void * Matrix, void * Vector);
;****************************************************************************************
; Given a 4x4 Matrix and a 3D Vector,
; 3D Vector Result = Matrix * Vector, BUT:
; - In order for the operation to be possible, a 4th element (1.f) is added to Vector
; - The last row and column of the matrix are temporarily replaced both with (0,0,0,1.f)
; - This function calculates only the affine transformation.
;****************************************************************************************
AM4MULV3:
    _enter_
%ifidn __OUTPUT_FORMAT__, win64 
    sub rsp,16*2
    movups [rsp],xmm6
    movups [rsp+16],xmm7
%endif
    sub rsp,16*5
    movups [rsp],xmm8
    movups [rsp+16],xmm9
    movups [rsp+16+16],xmm10
    movups [rsp+16+16+16],xmm15
    movups [rsp+16+16+16+16],xmm14


        movups  arg1f, [arg2]
        movups  arg2f, [arg2+16]
        movups  arg3f, [arg2+32]

    pxor xmm14,xmm14
    pcmpeqd xmm14,xmm14
    ;xmm14[0] = [11111111111111111111111111111111]
    psrld xmm14,25
    ;xmm14[0] = [00000000000000000000000001111111]
    pslld xmm14,23
    ;xmm14[0] = [00111111100000000000000000000000] = 1.f
    ;xmm14 = [1.f][1.f][1.f][1.f]

    pxor arg4f,arg4f
    movss arg4f,xmm14
    pshufd arg4f,arg4f, 00_10_01_11b

    TRANS44

    _loadvec3_ xmm7,arg3,xmm15

	  movaps arg3f,xmm4

    pxor arg4f,arg4f
    movss arg4f,xmm14

    movhlps xmm5,xmm7
    ;xmm5 = [?][?][W][Z]
    movss xmm14,xmm5
    ;xmm14 = [1.f][1.f][1.f][Z]
    movlhps xmm7,xmm14
    ;xmm7 = [1.f][Z][Y][X]
    movlhps xmm5,xmm5
    ;xmm5 = [W][Z][?][?]


    M4x4MULMACRO xmm7,xmm15

    movhlps xmm5,xmm15
    ;xmm5 = [W][Z][Rw][Rz]
    pshufd xmm5,xmm5,11_10_11_00b
    ;xmm5 = [W][Z][W][Rz]
    movlhps xmm15,xmm5
    ;xmm15 = [W][Rz][Ry][Rx]

    _storevec3_ arg1,xmm15,xmm10

    movups xmm8,[rsp]
    movups xmm9,[rsp+16]
    movups xmm10,[rsp+16+16]
    movups xmm15,[rsp+16+16+16]
    movups xmm14,[rsp+16+16+16+16]
    add rsp,16*5
%ifidn __OUTPUT_FORMAT__, win64 
    movups xmm6,[rsp]
    movups xmm7,[rsp+16]
    add rsp, 16*2
%endif
    _leave_
    ret
%endif

args_reset




global M4PERSPECTIVE
;void M4PERSPECTIVE
;(float *matrix, float fovyInDegrees, float aspectRatio,float znear, float zfar);
;*********************************************************************
;It's an implementation of gluPerspective
;*********************************************************************
M4PERSPECTIVE:
 

%ifidn __OUTPUT_FORMAT__, win64 
    %define arg1f XMM1
    %define arg2f XMM2
    %define arg3f XMM3
    %define arg4f XMM4

    ;zfar is in the stack, so it must be move to XMM4

    movss arg4f,[rsp+40]

%endif

    _enter_

%ifidn __OUTPUT_FORMAT__, win64 

        sub rsp,16*2
    movups [rsp],xmm6
    movups [rsp+16],xmm7
%endif

    sub rsp,16*6
    movups [rsp],xmm9
    movups [rsp+16],xmm10
    movups [rsp+16+16],xmm11
    movups [rsp+16+16+16],xmm12
    movups [rsp+16+16+16+16],xmm13
    movups [rsp+16+16+16+16+16],xmm14

    mov rax, fc_360f
	    pxor xmm12,xmm12
	    movaps xmm11,arg4f
push rax
	    mov rax, fc_m_1f
	    pxor xmm10,xmm10
	fldpi
sub rsp,8
	fstp dword[rsp]
	    movss xmm12,arg3f
	    pxor  xmm9,xmm9
	    movss xmm13,[rsp]
	    addss xmm12,xmm12
	    subss xmm11,arg3f
	    movss xmm14,[rsp+8]
	    mulss arg1f,xmm13
	    subss xmm10,xmm12
	    divss arg1f,xmm14
	    movss [rsp],arg1f
	    mulss xmm10,arg4f
	    movss xmm9,xmm11
	fld dword [rsp]
	    divss xmm10,xmm11
	    subss xmm9,arg4f
	fptan
	fstp st0
	fstp dword [rsp]
	    subss xmm9,arg4f
	    divss xmm9,xmm11
	    pxor xmm5,xmm5
;XMM11 = temp4 = ZFAR - ZNEAR
;XMM9  = (-ZFAR - ZNEAR)/temp4
;XMM10 = (-temp * ZFAR) / temp4
;XMM12 = temp  =2.0 * ZNEAR

	    pshufd xmm7,xmm10,11_00_11_11b
	    movss arg1f, [rsp]
	    pshufd xmm6,xmm9, 11_00_11_11b
	    mulss arg1f, arg3f
	    mulss arg2f, arg1f
	    addss arg1f,arg1f
;arg1f = temp3
	    movss xmm5,xmm12
	    divss xmm5,arg1f
	    pshufd xmm5,xmm5,11_11_00_11b
	    addss arg2f,arg2f
;arg2f = temp2
	    divss xmm12,arg2f

;Resulting matrix in XMM12,XMM5,XMM6,XMM7

	    movups [arg1],XMM12
	    movups [arg1+16],XMM5
	    movups [arg1+16+16],XMM6
	    movups [arg1+16+16+16],XMM7
        mov    [arg1+16+16+12],rax

add rsp,16

    movups xmm9,[rsp]
    movups xmm10,[rsp+16]
    movups xmm11,[rsp+16+16]
    movups xmm12,[rsp+16+16+16]
    movups xmm13,[rsp+16+16+16+16]
    movups xmm14,[rsp+16+16+16+16+16]
    add rsp,16*6



%ifidn __OUTPUT_FORMAT__, win64 

      movups xmm6,[rsp]
    movups xmm7,[rsp+16]
    add rsp, 16*2

args_reset
%endif
    _leave_
    ret

global M4TRANSPOSE; void M4TRANSPOSE(void * Destiny, void * Origin)
    M4TRANSPOSE:
    _enter_
    movups xmm0,[arg2]
    movups xmm1,[arg2+16]
    movups xmm2,[arg2+16+16]
    movups xmm3,[arg2+16+16+16]

    TRANS44

    movups [arg1],xmm0
    movups [arg1+16],xmm2
    movups [arg1+16+16],xmm4
    movups [arg1+16+16+16],xmm5
    _leave_
    ret

%if 0
global M4ORTHO;
;    void M4ORTHO
;    (float *matrix, float L, float R, float T,float B, float znear, float zfar);
;*********************************************************
M4ORTHO:
    %define arg5f XMM4
%ifidn __OUTPUT_FORMAT__, win64 
    %define arg1f XMM1 ;L
    %define arg2f XMM2 ;R
    %define arg3f XMM3 ;T
    %define arg4f XMM4 ;B (in stack)
    %define arg5f XMM5 ;znear (in stack)
    %define arg6f XMM0 ;zfar (in stack)

    ;B is in the stack, so it have to be moved to XMM4
    movss arg4f,[rsp+32+8]
    ;znear is in the stack, so it have to be moved to XMM5
    movss arg5f,[rsp+32+8+4]
    ;zfar is in the stack, so it have to be moved to XMM0
    movss arg6f,[rsp+32+8+4+4]
%endif

    _enter_

%ifidn __OUTPUT_FORMAT__, win64 
    sub rsp,16*2
    movups [rsp],xmm6
    movups [rsp+16],xmm7
%endif
    
    movss xmm6,arg1f
    addss arg1f,arg2f
    subss arg2f,xmm6

    movss xmm6,arg3f
    addss arg3f,arg4f
    subss arg4f,xmm6
    
    movss xmm6,arg5f
    addss arg5f,arg6f
    subss arg6f,xmm6

    pcmpeqw xmm7,xmm7
    pslld xmm7,25
    psrld xmm7,2

    pcmpeqw xmm6,xmm6
    pslld xmm6,31

    pxor xmm7,xmm6

    ;arg1f = r+l
    ;arg2f = r-l
    ;arg3f = t+b
    ;arg4f = t-b
    ;arg5f = f+n
    ;arg6f = f-n
    ;xmm6 = [SC][SC][SC][SC]
    ;xmm7 = [-1][-1][-1][-1]

    divss arg5f,arg6f
    divss arg3f,arg4f
    divss arg1f,arg2f

    movss xmm7,arg5f
    pslldq xmm7,4
    movss xmm7,arg3f
    pslldq xmm7,4
    movss xmm7,arg1f

    pxor xmm7,xmm6

    ;xmm7 = [1][-(f+n/f-n)][-(t+b/t-b)][-(r+l/r-l)]

    pcmpeqw arg1f,arg1f
    pslld arg1f,31
    psrld arg1f,1
    movss arg3f,arg1f
    movss arg5f,arg1f

    divss arg1f,arg2f
    divss arg3f,arg4f
    divss arg5f,arg6f
    pxor arg5f,xmm6

    pslldq arg1f,12
    psrldq arg1f,12
    pslldq arg3f,12
    psrldq arg3f,8
    pslldq arg5f,12
    psrldq arg5f,4

    movups [arg1],arg1f
    movups [arg1+16],arg3f
    movups [arg1+16+16],arg5f
    movups [arg1+16+16+16],xmm7

%ifidn __OUTPUT_FORMAT__, win64 

    movups xmm6,[rsp]
    movups xmm7,[rsp+16]
    add rsp, 16*2

%endif
    _leave_
    ret 
%endif

args_reset

global OLD_M4ORTHO;
;    void M4ORTHO
;    (float *matrix, float Width, float Height, float znear, float zfar);
;*********************************************************

OLD_M4ORTHO: 


    %define arg5f XMM4
%ifidn __OUTPUT_FORMAT__, win64 
    %define arg1f XMM1
    %define arg2f XMM2
    %define arg3f XMM3
    %define arg4f XMM4
    %define arg5f XMM0

    ;zfar is in the stack, so it have to be moved to XMM4

    movss arg4f,[rsp+32+8]

    
%endif

    _enter_

%ifidn __OUTPUT_FORMAT__, win64 
    sub rsp,16*2
    movups [rsp],xmm6
    movups [rsp+16],xmm7


%endif

;    movss [arg1],arg4f

    mov arg2,fc_2f
    movss arg5f,arg4f
    subss arg5f,arg3f
    push arg2
    addss arg4f,arg3f
    divss arg4f,arg5f
    movss arg3f,[rsp]
    pxor xmm5,xmm5
    pxor xmm6,xmm6
    movss xmm7,arg3f
    mov rax,fc_1f
    divss arg3f,arg1f
    movss arg1f,xmm7
    divss xmm7,arg2f
    subss xmm6,arg1f
    subss xmm5,arg4f
    divss xmm6,arg5f

;arg3f = 2/Width
;arg4f = (zfar+znear)/(zfar-znear)
;arg5f = zfar-znear
;xmm5 = -((zfar+znear)/(zfar-znear))
;xmm6 = -2 / ((zfar+znear)/(zfar-znear))
;xmm7 = 2/Height

%if 1
    pxor arg1f,arg1f
    movss arg1f,arg3f
    ;arg1f = [0][0][0][2/Width]
    movups [arg1],arg1f


    pxor arg2f,arg2f
    movss arg2f,xmm7
    pslldq arg2f,4
    ;arg2f = [0][0][2/Height][0]
    movups [arg1+ (4*4)],arg2f


    pxor arg3f,arg3f
    movss arg3f,xmm6
    pslldq arg3f,4+4
    ;arg3f = [0][xmm6][0][0]
    movups [arg1+ (4*4*2)],arg3f


    pxor arg1f,arg1f
    movss arg1f,xmm5
    pslldq arg1f,4+4
    ;arg1f = [0][xmm5][0][0]   

    movups [arg1+ (4*4*3)],arg1f
    mov [arg1+16+16+16+12],eax
%endif

    pop rax

%ifidn __OUTPUT_FORMAT__, win64 

    movups xmm6,[rsp]
    movups xmm7,[rsp+16]
    add rsp, 16*2

    args_reset
%endif

    _leave_

    ret

%undef arg5f
    
args_reset


global M4LOOKAT
; M4LOOKAT(float * matrix, float * Vec3From_EYE, float * Vec3To_CENTER, float * Vec3Up);
;*********************************************************
;It's an implementation of glm::LookAt
;*********************************************************
M4LOOKAT: 

    _enter_ 

    %ifidn __OUTPUT_FORMAT__, win64 

        sub rsp,16*2
    movups [rsp],xmm6
    movups [rsp+16],xmm7
%endif

    sub rsp,16*6
    movups [rsp],xmm8
    movups [rsp+16],xmm11
    movups [rsp+16+16],xmm12
    movups [rsp+16+16+16],xmm13
    movups [rsp+16+16+16+16],xmm14
    movups [rsp+16+16+16+16+16],xmm15

    push rax
    xor eax,eax
    mov eax,fc_m_1f
    push rax 

    pxor arg4f,arg4f

    movups xmm7, [arg2] ;EYE
    movups xmm15, [arg3] ;CENTER
    subps xmm15,xmm7 ;xmm15 = f = CENTER - EYE

    movups xmm14, [arg4]
    ;---Normalize f----;
    NORMALIZEVEC3MACRO xmm15,arg1f,arg2f,arg3f
    ;-------------------;
    ;---Normalize up----;
    NORMALIZEVEC3MACRO xmm14,arg1f,arg2f,arg3f
    ;-------------------;

    ;Resumen:
    ;xmm15 = f
    ;xmm14 = up

    movss xmm8, [rsp]

    ;Cross Product s = f x up;
    CROSSPRODUCTMACRO xmm15,xmm14,xmm13,arg1f,arg2f,arg3f
    ;--------------------------;
    ;Normalize s-----;
    NORMALIZEVEC3MACRO xmm13,arg1f,arg2f,arg3f
    ;-----------------;

    ;Resume:
    ;xmm7 = eye
    ;xmm15 = f
    ;xmm14 = up
    ;xmm13 = s

    pshufd xmm8,xmm8,0
    ;xmm8 [-1.f][-1.f][-1.f][-1.f]

    add rsp,8

    ;Cross Product u = s x f;
    CROSSPRODUCTMACRO xmm13,xmm15,xmm14,arg1f,arg2f,arg3f
    ;-------------------------;

    ;Resume:
    ;xmm7 = eye
    ;xmm15 = f
    ;xmm14 = u
    ;xmm13 = s 

    ;calculate -( s . eye )
    DotProductXMMV3 xmm13,xmm7,xmm12,arg1f
    mulss xmm12,xmm8
    ;------------------------------;

    pop rax

    ;calculate -( u . eye )
    DotProductXMMV3 xmm14,xmm7,xmm11,arg1f
    mulss xmm11,xmm8
    ;------------------------------;

    ;calculate ( f . eye )
    DotProductXMMV3 xmm15,xmm7,xmm6,arg1f
    ;------------------------------;  

    ;do f=-f;
    mulps xmm15,xmm8
    ;----------;

    ;Resume:
    ;xmm8 = [-1][-1][-1][-1]
    ;xmm7 = eye
    ;xmm15 = -f
    ;xmm14 = u
    ;xmm13 = s 
    ;xmm12 = -dot (s,eye)
    ;xmm11 = -dot (u,eye)
    ;xmm6 = +dot (f,eye)

    mulps xmm8,xmm8
    ;xmm8 = [1.f][1.f][1.f][1.f]
    movss xmm8,xmm6
    ;xmm8 = [1.f][1.f][1.f][+dot(f,eye)]
    movlhps xmm8,xmm8
    ;xmm8 = [1.f][+dot(f,eye)][1.f][+dot(f,eye)]
    unpcklps xmm12,xmm11
    ;xmm12 = [-dot (u,eye)][-dot (s,eye)][-dot (u,eye)][-dot (s,eye)]
    movsd xmm8,xmm12
    ;xmm8 [1.f][+dot(f,eye)][-dot (u,eye)][-dot (s,eye)]

    movaps arg1f,xmm13
    movaps arg2f,xmm14
    movaps arg3f,xmm15

    TRANS44

    movaps [arg1],arg1f
    add arg1,16
    movaps [arg1],arg2f
    add arg1,16
    movaps [arg1],xmm4
    add arg1,16
    movaps [arg1],xmm8





    movups xmm8,[rsp]
    movups xmm11,[rsp+16]
    movups xmm12,[rsp+16+16]
    movups xmm13,[rsp+16+16+16]
    movups xmm14,[rsp+16+16+16+16]
    movups xmm15,[rsp+16+16+16+16+16]
    add rsp,16*6



%ifidn __OUTPUT_FORMAT__, win64 

    movups xmm6,[rsp]
    movups xmm7,[rsp+16]
    add rsp, 16*2

args_reset
%endif
    _leave_
    ret






%unmacro DotProductXMMV2 4
%unmacro M4x4MULMACRO 2
%unmacro TRANS44 0
%unmacro MULVEC4VEC4 3
%unmacro CROSSPRODUCTV2 4
%unmacro _V4Lerp_ 4
%endif
