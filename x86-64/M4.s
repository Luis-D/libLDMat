// M4 Matrices Operations

// Luis Delgado. 2020
// To be used with GAS-Compatible Assemblers
// For x86-64 architecture.
// INTEL SYNTAX

// System V AMD64 ABI Convention (*nix)
// Function parameters are passed this way:
// Interger values: RDI, RSI, RDX, RCX, R8, R9
// Floating Point values: XMM0, XMM1, XMM2, XMM3, XMM4, XMM5, XMM6, XMM7
// Extra arguments are pushed on the stack starting from the most left argument
// Function return value is returned this way:
// Integer value: RAX:RDX 
// Floating point value: XMM0:XMM1
// RAX, R10 and R11 are volatile

// Microsoft x64 calling convention (Windows)
// Function parameters are passed this way:
// Interger values: RCX, RDX, R8, R9
// Floating point values: XMM0, XMM1, XMM2, XMM3 
// Both kind of arguments are counted together
// e.g. if the second argument is a float, it will be in arg2f, if Interger, then RDX
// Extra arguments are pushed on the stack (WITH 8 BYTES BOUNDARIES) 
// Function return value is returned this way:
// Integer value: RAX
// Floating point value: XMM0
// XMM4, XMM5, RAX, R10 and R11 are volatile

// SSE, SSE2, SSE3, FPU

// Format =
// INSTRUCTION(Destiny, Operand1, Operand2, Operand3, ... , OperandN)

// Original Source code from Luis-D/Boring-NASM-Code.

// Collection of mathematical functions and MACROS, very useful for algebra.

//January 11, 2019: Code writing started (NASM).
//January 21, 2019: 2x2 Matrix Math added.
//February 05,2019: 2D Norm fixed
//February 28,2019: Projection and view matrix operations added.
//March   02, 2019: Many errors fixed.
//March	 14, 2019: Windows routines prologues fixed.
//April	 02, 2019: Quaternion Normalized LERP added.
//April	 14, 2019: MADSS and SSMAD Operations added.
//June	 03, 2019: Inversion instructions added. Absolute value instruction added.
//April	 01, 2020: Orthogonal projection redone.
//July	 28, 2020: Code wirting started (GAS).


//TODO:
//When rewriting a function from NASM, do it in GAS

.intel_syntax

.include "Macros_Intel.s"
.include "Algebra_Macros_Intel.s"

.section .text

args_reset

.global M4ORTHO
//***************************************
//    void M4ORTHO
//    (float *matrix, float L, float R, float T,float B, float znear, float zfar);
//*********************************************************
M4ORTHO:
    .intel_syntax
    .ifdef _WIN64_
	.set arg1f,%xmm1 
	.set arg2f,%xmm2 
	.set arg3f,%xmm3 
	.set arg4f,%xmm4 
	.set arg5f,%xmm5 
	.set arg6f,%xmm0 
	movss arg4f,[%rsp+32+8] 
	movss arg5f,[%rsp+32+8+8] 
	movss arg6f,[%rsp+32+8+8+8] 
    .endif
    _enter_
    .ifdef _WIN64_
	sub %rsp,32
	movups [%rsp],%xmm6
	movups [%rsp],%xmm7
    .endif


    movss %xmm6,arg1f
    addss arg1f,arg2f
    subss arg2f,%xmm6

    movss %xmm6,arg3f
    addss arg3f,arg4f
    subss arg4f,%xmm6
    
    movss %xmm6,arg5f
    addss arg5f,arg6f
    subss arg6f,%xmm6

    pcmpeqw %xmm7,%xmm7
    pslld %xmm7,25
    psrld %xmm7,2

    pcmpeqw %xmm6,%xmm6
    pslld %xmm6,31

    pxor %xmm7,%xmm6


    //;arg1f = r+l
    //;arg2f = r-l
    //;arg3f = t+b
    //;arg4f = t-b
   // ;arg5f = f+n
    //;arg6f = f-n
  //  ;xmm6 = [SC][SC][SC][SC]
//    ;xmm7 = [-1][-1][-1][-1]


    divss arg5f,arg6f
    divss arg3f,arg4f
    divss arg1f,arg2f

    movss %xmm7,arg5f
    pslldq %xmm7,4
    movss %xmm7,arg3f
    pslldq %xmm7,4
    movss %xmm7,arg1f

    pxor %xmm7,%xmm6

    //xmm7 = [1][-(f+n/f-n)][-(t+b/t-b)][-(r+l/r-l)]

    pcmpeqw arg1f,arg1f
    pslld arg1f,31
    psrld arg1f,1
    movss arg3f,arg1f
    movss arg5f,arg1f

    divss arg1f,arg2f
    divss arg3f,arg4f
    divss arg5f,arg6f
    pxor arg5f,%xmm6

    pslldq arg1f,12
    psrldq arg1f,12
    pslldq arg3f,12
    psrldq arg3f,8
    pslldq arg5f,12
    psrldq arg5f,4


    movups [arg1],arg1f
    movups [arg1+16],arg3f
    movups [arg1+16+16],arg5f
    movups [arg1+16+16+16],%xmm7

    .ifdef _WIN64_
	movups %xmm6,[%rsp]
	movups %xmm7,[%rsp+16]
	add %rsp, 32
    .endif
    _leave_
    ret
    
args_reset

.global M4MAKE
//void M4MAKE(void * Dest, float Scale)
//************************************
//This algorithm fills a matrix buffer with a scaling constant
//Using 1.0 as the constant is equal to the Identity Matrix
//************************************
M4MAKE:
    _enter_
.intel_syntax
    .ifdef _WIN64_
	movaps arg1f,arg2f
    .endif
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


.global M4MUL
//void M4MUL(void*Result,void*A,void*B)//
//*************************************
//Given A and B (both 4x4 Matrices),
//4x4 Matrix Result = A * B//
//A generalized re-implementation from the GLM one
//*************************************
M4MUL:
    _enter_
    .ifdef _WIN64_
	.intel_syntax
	sub %rsp,16*2
	movups [%rsp],%xmm6
	movups [%rsp+16],%xmm7
    .endif
	.att_syntax
	movups	0(arg3), %xmm0
	movups  (arg2),%xmm4
	movups	%xmm0, %xmm1
	shufps	$0, %xmm0, %xmm1
	movups	%xmm0, %xmm3
	shufps	$85, %xmm0, %xmm3
	movups	%xmm0, %xmm2

	    movups 16(arg3),%xmm7
		mulps	%xmm4, %xmm1

	shufps	$170, %xmm0, %xmm2
	    mulps	16(arg2), %xmm3
	shufps	$255, %xmm0, %xmm0

	    movups	%xmm7, %xmm6
	mulps	32(arg2), %xmm2
	    shufps	$0, %xmm7, %xmm6
	mulps	48(arg2), %xmm0
	addps	%xmm3, %xmm1
	    movups  16(arg2),%xmm5
	addps	%xmm2, %xmm0
	addps	%xmm1, %xmm0
	    movups	%xmm7, %xmm3

	movups	%xmm0, (arg1)

	shufps	$85, %xmm7, %xmm3
	movups	%xmm7, %xmm2


	shufps	$170, %xmm7, %xmm2
	shufps	$255, %xmm7, %xmm7

	mulps	%xmm4, %xmm6
	mulps	%xmm5, %xmm3
	    movups	32(arg3), %xmm0
	mulps	32(arg2), %xmm2
	addps	%xmm3, %xmm6
	mulps	48(arg2), %xmm7
	    movups	%xmm0, %xmm1
	addps	%xmm2, %xmm7
	addps	%xmm6, %xmm7

	    shufps	$0, %xmm0, %xmm1
	movups	%xmm7, 16(arg1)

	movups	%xmm0, %xmm3
	shufps	$85, %xmm0, %xmm3
	movups	%xmm0, %xmm2

		mulps	%xmm4, %xmm1
	shufps	$170, %xmm0, %xmm2
		mulps	%xmm5, %xmm3
	shufps	$255, %xmm0, %xmm0


	movups 32(arg2),%xmm7
	mulps	48(arg2), %xmm0
	mulps	%xmm7, %xmm2
	addps	%xmm3, %xmm1
	addps	%xmm2, %xmm0
	    movups	48(arg3), %xmm6
	addps	%xmm1, %xmm0


	movups	%xmm6, %xmm1
	shufps	$0, %xmm6, %xmm1
	movups	%xmm6, %xmm3
	shufps	$85, %xmm6, %xmm3
	movups	%xmm6, %xmm2

	    movups	%xmm0, 32(arg1)

		mulps	%xmm4, %xmm1
	shufps	$170, %xmm6, %xmm2
		mulps	%xmm5, %xmm3
	shufps	$255, %xmm6, %xmm6

	mulps	%xmm7, %xmm2
	mulps	48(arg2), %xmm6
	addps	%xmm3, %xmm1
	addps	%xmm2, %xmm6
	addps	%xmm1, %xmm6

	movups	%xmm6, 48(arg1)
    
.intel_syntax
    .ifdef _WIN64_
	.intel_syntax
	movups %xmm6,[%rsp]
	movups %xmm7,[%rsp+16]
	add %rsp,16*2
    .endif
    _leave_
    ret


.global M4INV
// void M4INV(void * Result, void * Matrix);
//****************************************************************
// This function returns the inverse of a given 4x4 Matrix (A).
// It is an implementation of Eric Zhang's Fast 4x4 Matrix Inverse
// Source: 
// https://lxjk.github.io/2017/09/03/Fast-4x4-Matrix-Inverse-with-SSE-SIMD-Explained.html
//**************************************************************
M4INV:
.intel_syntax 
    _enter_
    .ifdef _WIN64_
	.intel_syntax
	sub %rsp,16*2
	movups [%rsp],%xmm6
	movups [%rsp+16],%xmm7
    .endif
 
    movups %xmm0,[arg2]
    movups %xmm1,[arg2+16]
    movups %xmm2,[arg2+16+16]
    movups %xmm3,[arg2+16+16+16]

    

    .ifdef _WIN64_
	.intel_syntax
	movups %xmm6,[%rsp]
	movups %xmm7,[%rsp+16]
	add %rsp,16*2
    .endif

    .intel_syntax
    _leave_
    ret


.global M4LERP
//M4LERP(float * Result, float * MatrixA, float * MatrixB, float Factor)
//***************************************************************
//Given two 4x4 Matrices A and B and a scalar factor,
//This function will return a linear interpolation between them
//***************************************************************
//NOTE 
M4LERP:
    .intel_syntax
    .ifdef _WIN64_
	.set arg1f, %xmm3
    .endif
    .macro _M4LERP_inner_V4LERP DESTINY
	movups %XMM1,[arg2]
	MOVUPS %XMM4,[arg3]
	add arg2,4*4
	subps \DESTINY,%XMM1
	mulps \DESTINY,arg1f
	addps \DESTINY,%XMM1
	add arg3,4*4
    .endm
    _enter_
	 
    //XMM4 - XMM7 OUTPUT MATRIX (one at a time)
    //XMM1	 MATRIX A COLUMNS (one at a time)
    //XMM2	 MATRIX B COLUMNS (one at a time)

    pshufd arg1f,arg1f,0

    //XMM4
    _M4LERP_inner_V4LERP %XMM4

    //XMM5
    _M4LERP_inner_V4LERP %XMM5

    //OUTPUT FIRST COLUMN
    movups [arg1],%XMM4
    add arg1,4*4

    //XMM6
    _M4LERP_inner_V4LERP %XMM6

    //OUTPUT SECOND COLUMN
    movups [arg1],%XMM5
    add arg1,4*4

    //XMM7
    _M4LERP_inner_V4LERP %XMM7

    //OUTPUT THIRD COLUMN
    movups [arg1],%XMM6
    add arg1,4*4

    //OUTPUT FOURTH COLUMN
    movups [arg1],%XMM7


    _leave_
    .ifdef _WIN64_
	args_reset
    .endif
    ret



.global M4MULV4
//M4MULV4(void * Result, void * MatrixA, void *VectorB);
//******************************************************
// Given a 4x4 Matrix MatrixA and a 4D Vector VectorB,
// 4D Vector Result = MatrixA * VectorB;
//******************************************************
M4MULV4:
.intel_syntax
    .macro _M4MULV4_GENERAL_MED_
	//Load First Column of Matrix (X Axis)
	movups %xmm0, [arg2]
	//pshufd first elements of Vector
	pshufd %xmm4,%xmm5,0
	//Update Matrix pointer
	add arg2,16
	//pshufd second elements of Vector
	pshufd %xmm3,%xmm5,(1+4+16+64)
	//Load Second Column of Matrix (Y Axis)
	movups %xmm1, [arg2]
	//multiply First Column (X axis) with first element
	mulps %xmm0,%xmm4
	//Update Matrix pointer
	add arg2,16
	//multiply Second column (Y Axis) with second element
	mulps %xmm1,%xmm3
	//Load Third Column (Z axis) 
	movups %xmm2, [arg2]
	//pshufd third element of Vector
	pshufd %xmm4,%xmm5,(2+8+32+128)
	//Add the first two muls
	addps %xmm0,%xmm1
	//Update Matrix Pointer
	add arg2,16
	//multiply Third column (Z Axis) with third element
	mulps %xmm2,%xmm4
	//Add the third mul
	addps %xmm0,%xmm2
    .endm
    _enter_

    //Load Vector
    movups %xmm5, [arg3]

    _M4MULV4_GENERAL_MED_

    //Load Fourth Column (Translate) 
    movups %xmm1, [arg2]
    //pshufd fourth element of vector
    pshufd %xmm5,%xmm5,(1+2+4+8+16+32+64+128)
    //multiply Fourth column (Translate) with fourth element
    mulps %xmm1, %xmm5
    //add the fourth mul
    addps %xmm0,%xmm1
    
    //Store result
    movups [arg1],%xmm0

    _leave_
    ret



.global M4MULV3
//M4MULV3(void * Result, void * MatrixA, void *VectorB);
//******************************************************
// Given a 4x4 Matrix MatrixA and a 3D Vector VectorB,
// The translation is simply added
// 3D Vector Result = MatrixA * VectorB;
//******************************************************
M4MULV3:
    .intel_syntax
    _enter_

    //Load Vector
    movsd %xmm5,[arg3]
    movss %xmm4,[arg3+8]
    movlhps %xmm5,%xmm4

    _M4MULV4_GENERAL_MED_

    //Load Fourth Column (Translate) 
    movups %xmm1, [arg2]

    //add to result
    addps %xmm0,%xmm1
    
    //Store result
    movhlps %xmm2,%xmm0
    movsd [arg1],%xmm0
    movss [arg1+8],%xmm2

    _leave_
    ret

.global AM4MULV3
//void AM4MULV3(void*Vec3_Destiny,void * Matrix,void * Vector);
//*************************************************************
// Given a 4x4 Matrix MatrixA and a 3D Vector VectorB,
// only the matrix affine transformation is taked in account,
// 3D Vector Result = AffineofMatrixA * VectorB;
//*************************************************************
AM4MULV3:
    .intel_syntax
    _enter_
    //Load Vector
    movsd %xmm5,[arg3]
    movss %xmm4,[arg3+8]
    movlhps %xmm5,%xmm4

    _M4MULV4_GENERAL_MED_
    
    //Store result
    movhlps %xmm2,%xmm0
    movsd [arg1],%xmm0
    movss [arg1+8],%xmm2
    _leave_
    ret


