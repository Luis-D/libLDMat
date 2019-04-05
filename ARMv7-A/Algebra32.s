/*
Luis Delgado. 2019
To be used with GNU Assembler
For ARMv7-A architecture

AAPCS ABI Convention:
Function parameters are passed this way:
Integer values: R0,R1,R2,R3
Floating point values: S0 ~ S15
Return address: R14 (LR)
Function return value is/are returned this way:
Integer values: R0,R1,R2,R3
Floatint point values: S0 ~ S15
R12 is volatile

VFPV3, NEON

Format =
INSTRUCTION(Destiny, Operand1, Operand2, Operand3, ... , OperandN)

Collection of mathematical functions, very useful for algebra.

March 24, 2019: Code writing started.

Notes:
   - Matrices are ROW MAJOR.
*/


.arch armv7-a
.fpu neon-vfpv3

.macro _enter_
.endm

.macro _leave_
.endm

.macro _ret_
    mov pc,lr
.endm

.set arg1,r0
.set arg2,r1
.set arg3,r2
.set arg4,r3

/*.section .rodata*/

.F_2: .word 0x40000000
.PI: .word 0x40490fdb
.COSSIN:
    .PI_2: .word 0x3fc90fdb
    .D4_PI: .word 0x3fa2f983
    .DM4_PIPI: .word 0xbecf817b
    .F__255: .word 0x3e666666 
    

.macro _GLOBAL_FUNC_ Y
	.type	\Y, %function
	.global \Y
.endm

.macro _V2MATH_ARITHMETIC_ROUTINE_EXT Y,X	
	.type	\Y, %function
	.global \Y
	\Y:
		vld1.64 d0,[r1]
		vld1.64 d1,[r2]
		\X d0,d0,d1
		vst1.64 d0,[r0]	
	_ret_
.endm

.macro _V2MATH_SCALAR_ROUTINE_EXT Y,X
    _GLOBAL_FUNC_ \Y
    \Y:
		vld1.64 d1,[r1]
		\X d1,d1,d0[0]
		vst1.64 d1,[r0]	
    _ret_    
.endm

.macro _V2MATH_SCALAR_ROUTINE_DUP_EXT Y,X
    _GLOBAL_FUNC_ \Y
    \Y:
		vld1.64 d1,[r1]
		vmov s1,s0
		\X d1,d1,d0
		vst1.64 d1,[r0]	
    _ret_    
.endm

	
.text

_GLOBAL_FUNC_ SSSIN
    SSSIN:

    _ret_

_GLOBAL_FUNC_ SSCOS
    SSCOS:

    _ret_


_GLOBAL_FUNC_ SSTAN
    SSTAN:

    _ret_

_GLOBAL_FUNC_ RADTODEG
    DEGTORAD:
	mov r1,#0x2ee1
	movt r1,#0x4265
	vmov.F32 s1,r1
	vmul.F32 s0,s1
    _ret_

_GLOBAL_FUNC_ DEGTORAD
    DEGTORAD:
	mov r1,#0x3c8e
	movt r1,#0xfa35
	vmov.F32 s1,r1
	vmul.F32 s0,s1
    _ret_


_GLOBAL_FUNC_ SSLERP
    SSLERP:
	vsub.F32 s1,s1,s0
	vmul.F32 s1,s1,s3
	vadd.F32 s0,s0,s1	
    _ret_


_V2MATH_ARITHMETIC_ROUTINE_EXT V2SUB,vsub.F32
_V2MATH_ARITHMETIC_ROUTINE_EXT V2ADD,vadd.F32
_V2MATH_ARITHMETIC_ROUTINE_EXT V2MUL,vmul.F32

.type V2DIV,%function
.global V2DIV
    V2DIV:
	vld1.64 d0,[r1]
	vld1.64 d1,[r2]
	vdiv.F32 s0,s0,s2
	vdiv.F32 s1,s1,s3
	vst1.64 d0,[r0]	
    _ret_
    
_V2MATH_SCALAR_ROUTINE_DUP_EXT V2SUBSS,vsub.F32
_V2MATH_SCALAR_ROUTINE_DUP_EXT V2ADDSS,vadd.F32
_V2MATH_SCALAR_ROUTINE_EXT V2MULSS,vmul.F32

.type V2DIVSS,%function
.global V2DIVSS
    V2DIVSS:
	vld1.64 d1,[r1]
	vdiv.F32 s2,s2,s0
	vdiv.F32 s3,s3,s1
	vst1.64 d1,[r0]	
    _ret_

.global V2DOT
.type V2DOT,%function
    V2DOT:
	vld1.64 d0,[r0]
	vld1.64 d1,[r1]
	vmul.F32 d0,d0,d1
	vadd.F32 s0,s0,s1
    _ret_

.global V2CROSS
.type V2CROSS,%function
    V2CROSS:
    vld1.64 d0,[r1]
    vld1.64 d1,[r2]
    vtrn.32 d1,d1 /*<-Check. To Exchange*/
    vmul.F32 d1,d1,d0
    vsub.F32 d1,d1,d0
    vst1.64 d1,[r0] 
    _ret_

_GLOBAL_FUNC_ V2NORM
   V2NORM: 
    vld1.64 d0,[r1]
    vmul.F32 d0,d0
    vadd.F32 s0,s0,s1
    vsqrt.F32 s0,s0
    _ret_

_GLOBAL_FUNC_ V2DISTANCE
    V2DISTANCE:
    vld1.64 d1,[r1]
    vld1.64 d2,[r2]
    vsub.F32 d0,d2,d1
    vmul.F32 d0,d0
    vadd.F32 s0,s0,s1
    vsqrt.F32 s0,s0
    _ret_

.global V2NORMALIZE
.type V2NORMALIZE,%function
    V2NORMALIZE:
    vld1.64 d1,[r1]
    vmul.F32 d0,d1,d1
    vadd.F32 s4,s2,s3
    vsqrt.F32 s4,s4
    vdiv.F32 s0,s2,s4 
    vdiv.F32 s1,s3,s4 
    vst1.64 d0,[r0]
    _ret_

_GLOBAL_FUNC_ V2LERP
    V2LERP:
	vld1.64 d1,[r1]
	vld1.64 d2,[r2]
	vsub.F32 d3,d2,d1
	vmul.F32 d3,d0[0]
	vadd.F32 d1,d3
	vst1.64 d1,[r0]
    _ret_


.global ANGLEROTV2 /*(RADIANS)*/
.type ANGLEROTV2,%function
    ANGLEROTV2:
	mov r3,#.COSSIN
	vld1.64 {d1,d2},[r3]!
	vadd.F32 s1,s0,s2	
    /*CONTINUAR*/    
    _ret_

_GLOBAL_FUNC_ V2ANGLE /*(RADIANS)*/
    V2ANGLE:

    _ret_

    .type M2MAKE,%function
.global M2MAKE
    M2MAKE:
	veor d1,d1
	vmov s3,s0
	vmov s1,s2
	vstmia r0,{d0,d1}
    _ret_

.type M2MULV2, %function
.global M2MULV2
    M2MULV2:
	vld1.64 {d0,d1},[r1]
	vld1.64 d2,[r2]
	vmul.F32 d0,d2[0]
	vmul.F32 d1,d2[1]
	vadd.F32 d0,d1
	vst1.F32 d0,[r0]
    _ret_

.type M2MUL,%function
.global M2MUL
    M2MUL:
	vld1.64 {d0,d1},[r1]
	vld1.64 {d2,d3},[r2]
	vmul.F32 d4,d0,d2[0]
	vmul.F32 d5,d0,d3[0]
	vmla.F32 d4,d1,d2[1]
	vmla.F32 d5,d1,d3[1]
	vst1.F32 {d4,d5},[r0]	
    _ret_


.type M2DET,%function
.global M2DET
    M2DET:
	vld2.32 {d0,d1},[r1]
	vtrn.32 d1,d1
	vmul.F32 d0,d1
	vsub.F32 s0,s1
	vst1.F32 d0,[r0]
    _ret_

.type M2INV,%function
.global M2INV
    M2INV:
	vld1.64 {d0,d1},[r1]
	vmov.32 s4,s0
	vneg.F32 s1,s1
	vmov.32 s5,s3
	vneg.F32 s2,s2
	vmov.32 s0,s5
	vmov.32 s3,s4
	vst1.64 {d0,d1},[r0]
    _ret_

.global V4ADD
.type	V4ADD, %function
    V4ADD:
	vld1.64 {d0,d1},[r1]
	vld1.64 {d2,d3},[r2]
	vadd.F32 q0,q0,q1	
	vst1.64 {d0,d1},[r0]	
	mov pc,lr

_GLOBAL_FUNC_ V4LERP
    V4LERP:
	vld1.64 {d2,d3},[r1]
	vld1.64 {d4,d5},[r2]
	vsub.F32 q3,q2,q1
	vmul.F32 q3,d0[0]
	vadd.F32 q1,q3
	vst1.64 {d2,d3},[r0]
    _ret_


.type M4MAKE,%function
.global M4MAKE
    M4MAKE:
	veor q3,q3
	veor q2,q2
	veor q1,q1
	vmov s5,s0
	veor q0,q0
	vmov s10,s5
	vmov s15,s5
	vmov s0,s5
	vstmia r0,{q0,q1,q2,q3}
    _ret_

.type M4MUL,%function
.global M4MUL
    M4MUL:
    _enter_
    vpush {q4,q5,q6,q7}
    vld4.32 {d8,d10,d12,d14},[r1]!
    vld4.32 {d9,d11,d13,d15},[r1] 
        
    mov r3,#4
    .M4MULLOOP:
	vld1.64 {d6,d7},[r2]!
	vmul.f32 q1,q4,q3
	vmul.f32 q2,q5,q3
	vpadd.f32 d0,d2,d3
	vpadd.f32 d1,d4,d5
	vpadd.f32 d0,d0,d1 

	vmul.f32 q1,q6,q3
	vmul.f32 q2,q7,q3
	vpadd.f32 d6,d2,d3
	vpadd.f32 d7,d4,d5
	vpadd.f32 d1,d6,d7 
	vst1.64{d0,d1},[r0]!
	subs r3,#1
	bne .M4MULLOOP    

    vpop {q4,q5,q6,q7}
    _ret_	

.type	V3ADD, %function
.global V3ADD
    V3ADD:
	vld1.64 d0,[r1]!
	add r3,r0,#8
	vldr.32 s2,[r1]
	vld1.64 d2,[r2]!
	vldr.32 s6,[r2]
	vadd.F32 q0,q0,q1
	vstr.64 d0,[r0]
	vstr.32 s2,[r3]
    _ret_
