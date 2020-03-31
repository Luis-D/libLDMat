/*
Luis Delgado. 2019
To be used with GNU Assembler
For x86-32 architecture.

CDECL Convention
Function parameters are passed this way:
Integer values: Pushed into the stack, first the last and lastly the first.
Floating point values: Also pushed into the stack just like an Integer value.
Function return value is returned this way:
Integer value: EAX
Floating point value: x87 (FPU) ST0
EAX, ECX, EDX, SEE registry and the x87 registry are volatile.
x87 must be emptied (except ST0 if returning).

SSE, SSE2, SSE3, FPU 

Format = 
INSTRUCTION(Destiny, Operand1, Operand2, Operand3, ... , OperandN)

Collection of mathematical functions, very useful for algebra

*/

/*
December 12, 2019: Code Writing started.

*/

/*
Notes:
    - Matrices are ROW MAJOR.

*/

.intel_syntax

.section .data

    .equ fc_360f,0x43b40000                         
    .equ fc_2f,0b01000000000000000000000000000000  
    .equ fc_m_1f,0xbf800000                        
    .equ fc_1f,0x3f800000                         
    .equ SignChange32bits,  0b10000000000000000000000000000000  
    .equ fc_180f,0x43340000                         
    .equ fc_PIdiv180f,0x3c8efa35                       
    .equ fc_180fdivPI,0x42652ee1                      



.section .text

.macro _FunctionDeclareDefine_ NAME
    .ifdef USEUNDESCORE
	.global _\NAME
	_\NAME:
    .else 
	.global \NAME
	\NAME:
    .endif
.endm

.macro _enter_
    push %ebp
    mov  %ebp, %esp
.endm

.macro _leave_
    mov	%esp, %ebp  
    pop	%ebp 
.endm

.set arg1,8
.equ arg2,8+4
.equ arg3,8+4+4
.equ arg4,8+4+4+4
.equ arg5,8+4+4+4+4
.equ arg6,8+4+4+4+4+4
.set return,%eax



.macro argmov register arg
    mov \register,[%ebp+ \arg]
.endm

.macro argmovss register arg
    movss \register,[%ebp+ \arg]
.endm



.macro DotProductXMMV3 A B R T
    movaps \R, \A
    mulps  \R, \B
    movshdup \T,\R
    addps    \T,\R
    movhlps  \R,\R
    addss    \R,\T
.endm

.macro CROSSPRODUCTMACRO A B R T1 T2 T3
    movups \R,\A
    movups \T1,\B
    pshufd \T2,\R,0b11010010
    pshufd \T3,\T1,0b11001001
    pshufd \R,\R,0b11001001
    pshufd \T1,\T1,0b11010010
    mulps \R,\T1
    mulps \T2,\T3
    subps \R,\T2
.endm



.macro V2ARITH op
   
    argmov %eax,arg1 
    movsd %xmm0,[%eax]

    argmov %eax,arg3
    movsd %xmm1,[%eax]
    
    \op %xmm0,%xmm1

    argmov %eax,arg1
    movsd [%eax],%xmm0
.endm 

.macro V2ARITH_SS op
    argmov %eax,arg2
    movsd %xmm0,[%eax]
    argmovss %xmm1,arg3
    pshufd %xmm1,%xmm1,0
    \op %xmm0,%xmm1
    argmov %eax,arg1
    movsd [%eax],%xmm0
.endm

.macro V4ARITH op
    argmov %eax,arg2
    movups %xmm0,[%eax]

    argmov %eax,arg3
    movups %xmm1,[%eax]
    
    \op %xmm0,%xmm1

    argmov %eax,arg1
    movups [%eax],%xmm0
.endm 

.macro V4ARITH_SS op
    argmov %eax,arg2
    movups %xmm0,[%eax]
    argmovss %xmm1,arg3
    pshufd %xmm1,%xmm1,0
    \op %xmm0,%xmm1
    argmov %eax,arg1
    movups [%eax],%xmm0
.endm

.macro V3ARITH op
    argmov %eax,arg2
    movsd %xmm0,[%eax]
    movss %xmm2,[%eax+8]
    movlhps %xmm0,%xmm2

    argmov %eax,arg3
    movsd %xmm1,[%eax]
    movss %xmm2,[%eax+8]
    movlhps %xmm1,%xmm2

    argmov %eax,arg1

    \op %xmm0,%xmm1

    movhlps %xmm1,%xmm0

    movsd [%eax],%xmm0
    movss [%eax+8],%xmm1
.endm

.macro V3ARITH_SS op
    argmov %eax,arg2
    movsd %xmm0,[%eax]
    movss %xmm2,[%eax+8]
    movlhps %xmm0,%xmm2

    argmovss %xmm1,arg3
    pshufd %xmm1,%xmm1,0

    argmov %eax,arg1

    \op %xmm0,%xmm1

    movhlps %xmm1,%xmm0

    movsd [%eax],%xmm0
    movss [%eax+8],%xmm1
.endm

.macro VARITH_DEC System name op
    _FunctionDeclareDefine_ \name
	_enter_
	\System \op
	_leave_
	ret
.endm



    /* V2 MATH*/

.macro V2ARITH_DEC name op
    VARITH_DEC V2ARITH \name \op
.endm

.macro V2ARITH_SS_DEC name op
    VARITH_DEC V2ARITH_SS \name \op
.endm

/* void V2ADD(void * Destiny, void * A, void * B); */
V2ARITH_DEC V2ADD addps

/* void V2SUB(void * Destiny, void * A, void * B); */
V2ARITH_DEC V2SUB subps

/* void V2MUL(void * Destiny, void * A, void * B); */
V2ARITH_DEC V2MUL mulps

/* void V2DIV(void * Destiny, void * A, void * B); */
V2ARITH_DEC V2DIV divps

/* void V2MULSS(void * Destiny, void * Operand, float Scalar); */
V2ARITH_SS_DEC V2MULSS mulps

/* void V2DIVSS(void * Destiny, void * Operand, float Scalar); */
V2ARITH_SS_DEC V2DIVSS divps


    /* V4 MATH*/

.macro V4ARITH_DEC name op
    VARITH_DEC V4ARITH \name \op
.endm

.macro V4ARITH_SS_DEC name op
    VARITH_DEC V4ARITH_SS \name \op
.endm

/* void V2ADD(void * Destiny, void * A, void * B); */
V4ARITH_DEC V4ADD addps

/* void V2SUB(void * Destiny, void * A, void * B); */
V4ARITH_DEC V4SUB subps

/* void V2MUL(void * Destiny, void * A, void * B); */
V4ARITH_DEC V4MUL mulps

/* void V2DIV(void * Destiny, void * A, void * B); */
V4ARITH_DEC V4DIV divps

/* void V2MULSS(void * Destiny, void * Operand, float Scalar); */
V4ARITH_SS_DEC V4MULSS mulps

/* void V2DIVSS(void * Destiny, void * Operand, float Scalar); */
V4ARITH_SS_DEC V4DIVSS divps



    /* V3 MATH */

.macro V3ARITH_DEC name op
    VARITH_DEC V3ARITH \name \op
.endm

.macro V3ARITH_SS_DEC name op
    VARITH_DEC V3ARITH_SS \name \op
.endm

/* void V3ADD(void * Destiny, void * A, void * B); */
V3ARITH_DEC V3ADD addps

/* void V3SUB(void * Destiny, void * A, void * B); */
V3ARITH_DEC V3SUB subps

/* void V3MUL(void * Destiny, void * A, void * B); */
V3ARITH_DEC V3MUL mulps

/* void V3DIV(void * Destiny, void * A, void * B); */
V3ARITH_DEC V3DIV divps

/* void V3MULSS(void * Destiny, void * Operand, float Scalar); */
V3ARITH_SS_DEC V3MULSS mulps

/* void V3DIVSS(void * Destiny, void * Operand, float Scalar); */
V3ARITH_SS_DEC V3DIVSS divps




    /* QUAT MATH */

/* void QUATMUL(void * Destiny, void * A, void * B); */
_FunctionDeclareDefine_ QUATMUL
    _enter_

    pxor %xmm4,%xmm4

    argmov %eax,arg2
    movups %xmm2,[%eax]
    argmov %edx,arg3
    movups %xmm3,[%edx]

    mov %ecx,SignChange32bits
    
    pshufd %xmm1,%xmm2,0

    movd %xmm4,%ecx


    pshufd %xmm5,%xmm3,0b00011011
    pshufd %xmm6,%xmm3,0b01001110
    pshufd %xmm7,%xmm2,0b01010101
    pshufd %xmm4,%xmm4,0b00110011
    mulps %xmm1,%xmm5
    mulps %xmm7,%xmm6
    pxor %xmm1,%xmm4
    pshufd %xmm5,%xmm3,0b10110001
    pshufd %xmm6,%xmm2,0b10101010
    pshufd %xmm4,%xmm4,0b11110000
    mulps %xmm5,%xmm6
    pxor %xmm7,%xmm4
    pshufd %xmm6,%xmm2,0b11111111
    pshufd %xmm4,%xmm4,0b11000111
    addps %xmm1,%xmm7
    pxor %xmm5,%xmm4
    mulps %xmm6,%xmm3
    addps %xmm1,%xmm5
    addps %xmm1,%xmm6

    argmov %eax,arg1
    movups [%eax],%xmm1

    _leave_
    ret

/* void QUATROTV3(void * Destiny, void * A, void * B); */
_FunctionDeclareDefine_ QUATROTV3
    _enter_

    argmov %eax,arg2
    movups %xmm0,[%eax]	    
    movss %xmm1,[%eax+4+4+4] 
    argmov %eax,arg3
    movsd %xmm2,[%eax]    
    movss %xmm3,[%eax+4+4]
    movlhps %xmm2,%xmm3	
    
    DotProductXMMV3 %xmm0 %xmm2 %xmm3 %xmm4
    addss %xmm3,%xmm3 
    movaps %xmm6,%xmm0
    DotProductXMMV3 %xmm0 %xmm6 %xmm5 %xmm4
    movss %xmm4,%xmm1
    mulss %xmm4,%xmm4
    subss %xmm4,%xmm5

    pshufd %xmm3,%xmm3,0
    mulps %xmm3,%xmm0

    pshufd %xmm4,%xmm4,0
    mulps %xmm4,%xmm2

    addps %xmm4,%xmm3

    CROSSPRODUCTMACRO %xmm0 %xmm2 %xmm3 %xmm5 %xmm6 %xmm7
    
    addss %xmm1,%xmm1
    pshufd %xmm1,%xmm1,0
    mulps %xmm1,%xmm3
    
    addps %xmm4,%xmm1
    movhlps %xmm1,%xmm4

    argmov %eax,arg1
    movsd [%eax],%xmm4
    movss [%eax+4+4],%xmm1

    _leave_
    ret
