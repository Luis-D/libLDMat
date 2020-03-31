%ifndef _LD_GEOMETRY_3D_64_ASM
%define _LD_GEOMETRY_3D_64_ASM

%include "LDM_MACROS.asm" ; Compile with -i 

args_reset ;<--Sets arguments definitions to normal, as it's definitions can change.

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
section .text


global TRI3CLOSESTV3; TRI3CLOSESTV3(void * Destiny_V3, void * TRI3,void * V3);
;************************************************************************
;Given a 3D triangle TRI3 and a 3D point V3, 
;this algorithm returns the closest point (Destiny_V3) from V3 to TRI3
;************************************************************************
    TRI3CLOSESTV3:
    _enter_
%ifidn __OUTPUT_FORMAT__, win64 
    sub rsp,16+16
    movups [rsp],xmm6
    movups [rsp+16],xmm7
%endif
    sub rsp,(16*8)
    movups [rsp],xmm8
    movups [rsp+16],xmm9
    movups [rsp+16+16],xmm10
    movups [rsp+16+16+16],xmm11
    movups [rsp+16+16+16+16],xmm12
    movups [rsp+16+16+16+16+16],xmm13
    movups [rsp+16+16+16+16+16+16],xmm14
    movups [rsp+16+16+16+16+16+16+16],xmm15


	movsd xmm0,[arg3] 
    
    pxor xmm15,xmm15

	movss xmm1,[arg3+4+4]
	movlhps xmm0,xmm1

    pxor xmm14,xmm14
	
	movups xmm1,[arg2]
	movups xmm2,[arg2+4+4+4]
	pslldq xmm1,4
	psrldq xmm1,4
	movups xmm3,[arg2+4+4+4 +4+4]
	pslldq xmm2,4
	psrldq xmm2,4
	psrldq xmm3,4
	
	movaps xmm4,xmm2
	subps xmm2,xmm1
	movaps xmm5,xmm3
	subps xmm3,xmm1

	;xmm0 = P
	;xmm1 = A
	;xmm2 = B
	;xmm3 = C 
	;xmm4 = AB
	;xmm5 = AC
	;xmm14 = [0][0][0][0]
	;xmm15 = [0][0][0][0]


	;****Check A Region (START)*****;
	movaps xmm6,xmm0
	subps xmm6,xmm1
	;xmm6 = AP
    
	_V3DOT_ xmm7,xmm4,xmm6,xmm9
	_V3DOT_ xmm8,xmm5,xmm6,xmm9
	
	;xmm7[0] = d1
	;xmm8[0] = d2
	
	ucomiss xmm7,xmm15
	ja TRI3CLOSESTV3END_REGION_A_SKIP
	    ucomiss xmm8,xmm15
		ja TRI3CLOSESTV3END_REGION_A_SKIP
		    movaps xmm15,xmm1
		    jmp TRI3CLOSESTV3END
	TRI3CLOSESTV3END_REGION_A_SKIP:
	;****Check A Region (END)*****;


	;****Check B Region (START)*****;
	movaps xmm6,xmm0
	subps xmm6,xmm2
	;xmm6 = BP

	_V3DOT_ xmm9,xmm4,xmm6,xmm13
	_V3DOT_ xmm10,xmm5,xmm6,xmm13
	
	;xmm9[0] = d3
	;xmm10[0] = d4
   
	ucomiss xmm9,xmm15
	jb TRI3CLOSESTV3END_REGION_B_SKIP
	    ucomiss xmm10,xmm9
		ja TRI3CLOSESTV3END_REGION_B_SKIP
		    movaps xmm15,xmm2
		    jmp TRI3CLOSESTV3END
	TRI3CLOSESTV3END_REGION_B_SKIP:
	;****Check B Region (END)*****;


	;****Check AB edge Region (START)*****;
	movss xmm11,xmm9
	mulss xmm11,xmm8
	movss xmm6,xmm7
	mulss xmm6,xmm10
	subss xmm6,xmm11
	
	;xmm6 = vc = d1*d4 - d3*d2

	movss xmm14,xmm6 ;<-- For barycentric testing
	pslld xmm14,4

	ucomiss xmm6,xmm15
	ja TRI3CLOSESTV3END_REGION_AB_EDGE_SKIP
	    ucomiss xmm7,xmm15
	    jb TRI3CLOSESTV3END_REGION_AB_EDGE_SKIP
		ucomiss xmm9,xmm15
		ja TRI3CLOSESTV3END_REGION_AB_EDGE_SKIP
		    movss xmm6,xmm7
		    subss xmm6,xmm9
		    divss xmm7,xmm6
		    movss xmm15,xmm1
		    pshufd xmm7,xmm7,0
		    mulps xmm7,xmm4
		    addps xmm15,xmm7
		    
		    ;xmm15 = A + (AB* (d1/(d1-d3)) )

		    jmp TRI3CLOSESTV3END
	TRI3CLOSESTV3END_REGION_AB_EDGE_SKIP:
	;****Check AB edge Region (END)*****;
   
	
	;****Check C Region (START)*****;
	movaps xmm6,xmm0
	subps xmm6,xmm3
	;xmm6 = CP

	    
	_V3DOT_ xmm11,xmm4,xmm6,xmm13
	_V3DOT_ xmm12,xmm5,xmm6,xmm13
	
	;xmm11[0] = d5
	;xmm12[0] = d6

	ucomiss xmm12,xmm15
	jb TRI3CLOSESTV3END_REGION_C_SKIP
	    ucomiss xmm11,xmm12
		ja TRI3CLOSESTV3END_REGION_C_SKIP
		    movaps xmm15,xmm3
		    jmp TRI3CLOSESTV3END
	TRI3CLOSESTV3END_REGION_C_SKIP:
	;****Check C Region (END)*****;
    
	;****Check AC edge Region (START)*****;
	movss xmm13,xmm1
	mulss xmm13,xmm12
	movss xmm6,xmm11
	mulss xmm6,xmm2
	subss xmm6,xmm13
	
	;xmm6 = vb = d5*d2 - d1*d6

	movss xmm14,xmm6 ;<-- For barycentric testing
	pslld xmm14,4
    
	ucomiss xmm6,xmm15
	ja TRI3CLOSESTV3END_REGION_AC_EDGE_SKIP
	    ucomiss xmm2,xmm15
	    jb TRI3CLOSESTV3END_REGION_AC_EDGE_SKIP
		ucomiss xmm12,xmm15
		ja TRI3CLOSESTV3END_REGION_AC_EDGE_SKIP
		    movss xmm6,xmm8
		    subss xmm6,xmm12
		    divss xmm12,xmm6
		    movss xmm15,xmm1
		    pshufd xmm12,xmm12,0
		    mulps xmm12,xmm5
		    addps xmm15,xmm12
		    
		    ;xmm15 = A + (AC* (d2/(d2-d6)) )

		    jmp TRI3CLOSESTV3END
	TRI3CLOSESTV3END_REGION_AC_EDGE_SKIP:
	;****Check AC edge Region (END)*****;


	;****Check BC edge Region (START)*****;
	movss xmm13,xmm11
	mulss xmm13,xmm10
	movss xmm6,xmm9
	mulss xmm6,xmm12
	subss xmm6,xmm13
	
	;xmm6[0] = va = d3*d6 - d5*d4

	movss xmm14,xmm6 ;<-- For barycentric testing

	ucomiss xmm6,xmm15
	ja TRI3CLOSESTV3END_REGION_BC_EDGE_SKIP
	    movss xmm6,xmm10
	    subss xmm6,xmm9
	    ucomiss xmm6,xmm15
	    jb TRI3CLOSESTV3END_REGION_BC_EDGE_SKIP
		movss xmm13,xmm11
		subss xmm13,xmm12
		ucomiss xmm13,xmm15
		jb TRI3CLOSESTV3END_REGION_BC_EDGE_SKIP
		    addss xmm13,xmm6
		    divss xmm6,xmm13
		    ;xmm6[0] = W
		    pshufd xmm6,xmm6,0
		    movaps xmm15,xmm3
		    subps xmm15,xmm2
		    mulps xmm15,xmm6
		    addps xmm15,xmm2
		   
		    ;xmm15 = ((C-B)*W) + B
 
		    jmp TRI3CLOSESTV3END 
	TRI3CLOSESTV3END_REGION_BC_EDGE_SKIP:
	;****Check BC edge Region (END)*****;
	
	;****Process the inside face of the triangle****; 
	movaps xmm15,xmm1
	pcmpeqw xmm13,xmm13
	pslld xmm13,25
	psrld xmm13,2
	
	;xmm1 = A
	;xmm4 = AB
	;xmm5 = AC
	;xmm13 = [1.f][1.f][1.f][1.f]
	;xmm14 = [?][vc][vb][va]
	;xmm15 = A

	movhlps xmm3,xmm14
	movshdup xmm2,xmm14
	addss xmm14,xmm2
	addss xmm14,xmm3
	
	;xmm1 = A
	;xmm4 = AB
	;xmm5 = AC
	;xmm2[0] = vb
	;xmm3[0] = vc
	;xmm13 = [1.f][1.f][1.f][1.f]
	;xmm14[0] = va+vb+vc
	;xmm15 = A
	
	divss xmm13,xmm14
	mulss xmm2,xmm13
	mulss xmm3,xmm13
	pshufd xmm2,xmm2,0
	pshufd xmm3,xmm3,0
	
	mulps xmm5,xmm3
	mulps xmm4,xmm2
    
	addps xmm15,xmm4
	addps xmm15,xmm5

    TRI3CLOSESTV3END:	

    movsd [arg1],xmm15
    psrld xmm15,4+4
    movss [arg1+4+4],xmm15
	
    movups xmm15,[rsp+16+16+16+16+16+16+16]
    movups xmm14,[rsp+16+16+16+16+16+16]
    movups xmm13,[rsp+16+16+16+16+16]
    movups xmm12,[rsp+16+16+16+16]
    movups xmm11,[rsp+16+16+16]
    movups xmm10,[rsp+16+16]
    movups xmm9,[rsp+16]
    movups xmm8,[rsp]
    add rsp,(16*8)
%ifidn __OUTPUT_FORMAT__, win64 
    movups xmm6,[rsp]
    movups xmm7,[rsp+16]
    add rsp,16+16
%endif
    _leave_
    ret

global SPHEREVSTRI3; char SPHEREVSTRI3(void * Sphere, void * TRI3)
    SPHEREVSTRI3:
    _enter_
    sub rsp,(8*2)
    push arg1
	mov arg3,arg1
	mov arg1,rsp
	;arg1 = Destiny
	;arg2 = TRI3
	;arg3 = Sphere (Sphere center)
	call TRI3CLOSESTV3
    pop arg1
	xor rax,rax
	movups xmm0,[arg1]
	mov arg4,1
	movhlps xmm1,xmm0
	movups xmm2,[rsp]
	mulss xmm1,xmm1
	subps xmm2,xmm0
	mulps xmm2,xmm2
	movhlps xmm3,xmm2
	movshdup xmm4,xmm2
	addps xmm4,xmm2
	addss xmm4,xmm3	
	ucomiss xmm4,xmm1
	cmovbe rax,arg4
    add rsp,(8*2)
    _leave_
    ret

global TRI3CENTROID; void TRI3DCENTROID(void * Destiny, void * Source)
;************************
;Given a triangle Triangle described by and array of 3 3D points (3 floats per point)
;this algorithm calculates its barycenter and returns and array of a 3D point in Result
;************************
TRI3CENTROID:
    _enter_
    ;enter 0,0    
    movups XMM0,[arg2]
    add arg2,(4*3) ;<- It jumps three times the size of a float (4 bytes)
    movups XMM1,[arg2]
    add arg2,(4*2) ;<- It jumps two times the size of a float because of memory boundaries
    movups XMM2,[arg2] 

    _fillimm32_ xmm3,01000000010000000000000000000000b,eax

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
    _leave_
    ;leave
    ret

global TRI3NORMAL
; void TRI3NORMAL(void * Vec3_Destiny, void * Triangle, char TriangleMode);
;*******************************************************************************
;Given a 3D triangle (a vector of three vectors of three floats -3D vertices-),
;depending on its mode (CCW or CW), this algoritm will return its normal
; TRIMODE (TriangleMode):
; 1 bit mask: CCW or CW
;*******************************************************************************
    TRI3NORMAL:
    _enter_
    movups xmm1,[arg2]
    pcmpeqw xmm0,xmm0
    pslld xmm0,31
    movups xmm2,[arg2+4+4+4]  
    pslldq xmm1,4
    psrldq xmm1,4
    movups xmm3,[arg2+4+4+4 +4+4]
    pslldq xmm2,4
    psrldq xmm2,4
    psrldq xmm3,4

    ;xmm0 = SC
    ;xmm1 = V1 (A)
    ;xmm2 = V2 (B)
    ;xmm3 = V3 (C)

    subps xmm2,xmm1
    subps xmm3,xmm1

    _V3CROSS_ xmm1,xmm2,xmm3,xmm4,xmm5

    bt arg3,0
    jnc TRI3NORMAL_SKIP_INVERTNORMAL
	pxor xmm1,xmm0
    TRI3NORMAL_SKIP_INVERTNORMAL:

    

    movsd [arg1],xmm1
    movhlps xmm1,xmm1
    movss [arg1+4+4],xmm1
    _leave_
    ret

global V3VSTRI3
;char V3VSTRI3(void * V3, void *TRI3D)
;******************************************************************************
;Given a 3D Point V3, this algoritm return if it lies inside 3D Triangle TRI3D
;******************************************************************************
    V3VSTRI3:
    _enter_
	movsd xmm0,[arg1]
	
	xor rax,rax

	movss xmm1,[arg1+4+4]
	movlhps xmm0,xmm1
	
	movups xmm1,[arg2]
	movups xmm2,[arg2+4+4+4]
	pslldq xmm1,4
	psrldq xmm1,4
	movups xmm3,[arg2+4+4+4 +4+4]
	pslldq xmm2,4
	psrldq xmm2,4
	psrldq xmm3,4

	;xmm0 = V3
	;xmm1 = A
	;xmm2 = B
	;xmm3 = C
	
	subps xmm1,xmm0
	subps xmm2,xmm0
	subps xmm3,xmm0

	_V3DOT_ xmm4,xmm1,xmm2,xmm5
	_V3DOT_ xmm5,xmm1,xmm3,xmm0
	_V3DOT_ xmm1,xmm2,xmm3,xmm0
	_V3DOT_ xmm2,xmm3,xmm3,xmm0

	movaps xmm0,xmm2
	
	;xmm4[0] = a . b
	;xmm5[0] = a . c 
	;xmm1[0] = b . c
	;xmm2[0] = c . c
	
	movss xmm3,xmm5
	subss xmm3,xmm2
	mulss xmm3,xmm4
	mulss xmm3,xmm1
	
	subss xmm1,xmm5
	;xmm1 = (b . c) - (a . c)

	_V3DOT_ xmm2,xmm0,xmm0,xmm5
	;xmm2 = b . b

	pxor xmm0,xmm0

	ucomiss xmm3,xmm0
	jb V3VSTRI3_END

	mulss xmm1,xmm2
	mulss xmm4,xmm1

	ucomiss xmm4,xmm0
	jb V3VSTRI3_END
    
    
	mov rax,1	
    V3VSTRI3_END:
    _leave_
    ret
    

global V3V3VSTRI3
;char V3V3VSTRI3 (void *Line3D, void *TRI3D, char SEGTRIMODE, float * Time_return)
;****************************************************
;SEGTRIMODE:
;Bit 0 = Line notation (A+B) or (A->B)
;Bit 1~2 = Line type (infinite line, ray or segment)
;Bit 3 = Nothing
;Bit 4 = Triangle CCW or CW
;****************************************************
    V3V3VSTRI3:
    _enter_
%ifidn __OUTPUT_FORMAT__, win64 
    sub rsp,16+16
    movups [rsp],xmm6
    movups [rsp+16],xmm7
%endif
    sub rsp,16+16
    movups [rsp],xmm8
    movups [rsp+16],xmm9

    pxor xmm7,xmm7
    
    movups xmm1,[arg2]

    pcmpeqw xmm0,xmm0
    pslld xmm0,31
    movups xmm2,[arg2+4+4+4]  
    pslldq xmm1,4
    psrldq xmm1,4
    movups xmm3,[arg2+4+4+4 +4+4]
    pslldq xmm2,4
    psrldq xmm2,4
    psrldq xmm3,4

    ;xmm0 = [SC][SC][SC][SC]
    ;xmm1 = V1 (A)
    ;xmm2 = V2 (B)
    ;xmm3 = V3 (C)
    ;xmm7 = [0][0][0][0]


    subps xmm2,xmm1
    subps xmm3,xmm1

    _V3CROSS_ xmm6,xmm2,xmm3,xmm4,xmm5

    bt arg3,4
    jnc __TRI3NORMAL_SKIP_INVERTNORMAL
	pxor xmm6,xmm0
    __TRI3NORMAL_SKIP_INVERTNORMAL:
   
    ;xmm2 = ab
    ;xmm3 = ac 
    ;xmm6 = TRI Normal

    
    movups xmm4,[arg1]

    xor rax,rax

    movups xmm5,[arg1+4+4]
    pslldq xmm4,4
    psrldq xmm4,4
    psrldq xmm5,4
   
    BT arg3,0 ; check if line is (A+B) or (A->B)
    jnc V3V3VSPLANESKIPLINESUM
        subps xmm5,xmm4
    V3V3VSPLANESKIPLINESUM:

    shr arg3,1 ;<- to get Line type
    
    subps xmm4,xmm1 
    pxor xmm5,xmm0 ;To invert line vector and get p-q instead of q-p


    _V3DOT_ xmm1,xmm5,xmm6,xmm8

    and arg3,3

    movlhps xmm7,xmm0

    ;xmm1[0] = d
    ;xmm2 = ab
    ;xmm3 = ac
    ;xmm4 = ap
    ;xmm5 = qp
    ;xmm6 = n (TRI Normal)
    ;xmm7 = [SC][SC][0][0]
    ;arg3 = Line type
    ;arg1 = Triangle type


    ucomiss xmm1,xmm7 ;check if d <= 0, if so then exit and return 0
    jbe V3V3VSTRI3END

    _V3DOT_ xmm0,xmm4,xmm6,xmm8 
    
    ;xmm0[0] = t 

    test arg3,arg3
    jz V3V3VSTRIISLINE

	cmp arg3,1 ;<- if ray
	jne V3V3VSTRINORAY
	    ucomiss xmm0,xmm7
	    jb V3V3VSTRI3END
	    jmp V3V3VSTRIISLINE
	V3V3VSTRINORAY:

	;if not ray and if not line (then it's a segment)
	ucomiss xmm0,xmm1 	
	ja V3V3VSTRI3END

    V3V3VSTRIISLINE:
  
 
    ;xmm0[0] = t
    ;xmm1[0] = d
    ;xmm2 = ab
    ;xmm3 = ac
    ;xmm4 = ap
    ;xmm5 = qp
    ;xmm6 = n (TRI Normal)
    ;xmm7 = [SC][SC][0][0]
    
    _V3CROSS_ xmm6,xmm5,xmm4,xmm8,xmm9
    ;xmm6 = e

    movhlps xmm8,xmm7

    _V3DOT_ xmm4,xmm3,xmm6,xmm5
    ;xmm4 = v = dot(ac,e)

    _V3DOT_ xmm5,xmm2,xmm6,xmm3
    pxor xmm5,xmm8
    ;xmm5 = w = -dot(ab,e) 

    movss xmm6,xmm4 
    addss xmm6,xmm5
    ;xmm6 = v+w

    ucomiss xmm4,xmm7
    jb V3V3VSTRI3END
    ucomiss xmm4,xmm1
    ja V3V3VSTRI3END

    ucomiss xmm5,xmm7
    jb V3V3VSTRI3END
    ucomiss xmm6,xmm1
    ja V3V3VSTRI3END 

    test arg4,arg4
    jz V3V3VSTRI3SKIPRETURN
	divss xmm0,xmm1 ;<- Time is t/d
	movss [arg4],xmm0 
    V3V3VSTRI3SKIPRETURN:    

    mov rax,1

    V3V3VSTRI3END:    

    movups xmm9,[rsp+16]
    movups xmm8,[rsp]
    add rsp,16+16
%ifidn __OUTPUT_FORMAT__, win64 
    movups xmm6,[rsp]
    movups xmm7,[rsp+16]
    add rsp,16+16
%endif
    _leave_
    ret



global V3V3VSAABB3
; char V3V3VSAABB3(void * Line3D, void * AABB3, char SEGAABB3RETMODE, float * Times_Return); 
;*********************************************************************
;Given a 3D line and a 3D AABB,
;This algorithm returns if the line collided with the AABB.
;This algorithm returns when the collision(s) occurs.
;
;SEGAABB3RETMODE:
; 8 bits flag:
;   bit 0 set the line notation mode (A+B)(clear) or (A->B)(set)
;   bit 1 and 2 set the line mode (infinite line, ray or line segment)
;   bit 3 check collision with only the edges or with also the volume.
;   bit 4 set the AABB notation mode (Center+Half_extent) or (A->B)
;   bit 5 set the subnotation mode:
;        if (A->B) (bit 0 set): (Pivot+Direction) or (Min->Max) 
;   bits 6 and 7 set the return data:
;     0 = none contact
;     1 = First contact
;     2 = Last contact
;     3 = Both contact 
;Original (partial) source from: 
;https://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-box-intersection
;*********************************************************************
    V3V3VSAABB3:
    _enter_
        mov rax,arg3; <- Temporal variable
    movups xmm0,[arg1]
    pxor xmm4,xmm4
        shr rax,1;
        and rax,3;
        ;rax = Line mode bits
    movups xmm1,[arg1+4+4]
    pslldq xmm0,4
    psrldq xmm0,4

    pcmpeqw xmm5,xmm5
    psrld xmm5,1

    movups xmm2,[arg2]

    BT arg3,0 ; check if line is (A+B) or (A->B)
    jnc V3V3VSAABB2SKIPLINESUM
        subps xmm1,xmm0
    V3V3VSAABB2SKIPLINESUM:

 
    psrldq xmm1,4

    movups xmm3,[arg2+4+4]
    
    
    pslldq xmm2,4
    psrldq xmm2,4
    psrldq xmm3,4
    
    ;xmm0 = [0][LAz][LAy][LAx]
    ;xmm1 = [0][LBz][LBy][LBx]
    ;xmm3 = [0][BoxAz][BoxAy][BoxAx]
    ;xmm4 = [0][BoxBz][BoxBy][BoxBx]
 




    BT arg3,4 ; check if AABB is (Center+Extents) or (A->B)
    jc V3V3V3AABBISTYPEB
    ;If AABB is (Center+Extents), then:
        movaps xmm4,xmm2
        subps xmm2,xmm3
        addps xmm3,xmm4
    jmp V3V3AABBSKIPISTYPEB
    V3V3V3AABBISTYPEB:
        BT arg3,5; check if (Pivot+Direction) or (Min->Max)
        jc V3V3AABBSKIPISTYPEB
        ;if (Pivot+Direction), then:
        addps xmm3,xmm2
    V3V3AABBSKIPISTYPEB:

    ;xmm0 = [][LAz][LAy][LAx]
    ;xmm1 = [][LBz][LBy][LBx]
    ;xmm2 = [][MinZ][MinY][MinX]
    ;xmm3 = [][MaxZ][MaxY][MaxX]
    ;xmm4 = 0
    ;xmm5 = INF
    

    ;Calculate FirstCol = (Min - LA) / LB
    subps xmm2,xmm0
    divps xmm2,xmm1

    shr arg3,6

    ;Calculate LastCol = (Max - LA) / LB
    subps xmm3,xmm0
    divps xmm3,xmm1

    
    ;movups [arg1],xmm3; <- For debug 

    movhlps xmm0,xmm2
    movhlps xmm1,xmm3
    movshdup xmm4,xmm2
    movshdup xmm5,xmm3
 
    ;xmm2= [][][][FCx] =tmin
    ;xmm4= [][][][FCy]
    ;xmm0= [][][][FCz]
    ;xmm3= [][][][LCx] =tmax
    ;xmm5= [][][][LCy]
    ;xmm1= [][][][LCz]


;    movups [arg1],xmm2
;    movsd [arg1+4+4+4],xmm3
;    movhlps xmm6,xmm3
;    movss [arg1+4+4+4+4],xmm6

    ucomiss xmm2,xmm3
    jna V3V3AABBSKIPMINMAX
	pxor xmm2,xmm3
	pxor xmm3,xmm2
	pxor xmm2,xmm3
    V3V3AABBSKIPMINMAX:

    ucomiss xmm4,xmm5
    jna V3V3AABBSKIPMINMAXY
	pxor xmm4,xmm5
	pxor xmm5,xmm4
	pxor xmm4,xmm5
    V3V3AABBSKIPMINMAXY:
    
    ucomiss xmm5,xmm2
    jbe V3V3AABBCHECKIFINSIDE
    ucomiss xmm3,xmm4
    jbe V3V3AABBCHECKIFINSIDE

    ucomiss xmm4,xmm2
    jna V3V3AABBSKIPMINMAXF
	movss xmm2,xmm4
    V3V3AABBSKIPMINMAXF:

    ucomiss xmm5,xmm3
    jnb V3V3AABBSKIPMINMAXFF
	movss xmm3,xmm5
    V3V3AABBSKIPMINMAXFF:

    ;xmm2=tmin
    ;xmm3=tmax

%if 1
    ucomiss xmm0,xmm1
    jna V3V3AABBSKIPMINMAXZ
	pxor xmm1,xmm0
	pxor xmm0,xmm1
	pxor xmm1,xmm0
    V3V3AABBSKIPMINMAXZ:

    ucomiss xmm2,xmm1
    ja V3V3AABBCHECKIFINSIDE
    ucomiss xmm0,xmm3
    ja V3V3AABBCHECKIFINSIDE

    ucomiss xmm0,xmm2
    jna V3V3AABBSKIPMINMAXZF
	movss xmm2,xmm0
    V3V3AABBSKIPMINMAXZF:

    ucomiss xmm1,xmm3
    jnb V3V3AABBSKIPMINMAXZFF
	movss xmm3,xmm1
    V3V3AABBSKIPMINMAXZFF:


%endif 


    jmp V3V3AABBSKIPCHECKIFINSIDE
    V3V3AABBCHECKIFINSIDE:
    ;Here should be a checker if origin is inside the volume
	jmp V3V3AABBENDZERO
    V3V3AABBSKIPCHECKIFINSIDE:
    

    ;xmm2[0] = tmin 
    ;xmm3[0] = tmax
%if 1

    ;rax = Line Mode
    ;arg3 = Return Mode

    ;Check time return Mode
    cmp arg3,0 ;if no time returns
    je V3V3AABBSKIPSTORE ;return no time

    movshdup xmm5,xmm3

    bt arg3,1 ;check if return last collision is enabled
    jnc V3V3AABBNOLAST
        movss xmm5,xmm3
    V3V3AABBNOLAST:

    bt arg3,0 ;check if return first collision is enabled
    jnc V3V3AABBNOFIRST
        psllq xmm5,4 ;shift the vector to make space for the new result
        movss xmm5,xmm2 
    V3V3AABBNOFIRST:

    ;xmm0 [][][LCT][FCT]

    pxor xmm2,xmm2

    cmp arg3,3
    je V3V3AABBSTOREBOTH
        movss [arg4],xmm5 ;Store the two results
        jmp V3V3AABBSKIPSTORE
    V3V3AABBSTOREBOTH:
        movsd [arg4],xmm5 ;Store one retult

    V3V3AABBSKIPSTORE:

%endif
    pxor xmm2,xmm2

    ;Load 1.0
    pcmpeqw xmm3,xmm3
    pslld xmm3,25
    psrld xmm3,2
    ;-----------

    ;xmm2 = 0
    ;xmm3 = 1.0

    ;check times according with line type

    test rax,rax; if infinite (arg3==0), then skip checking boundaries
    jz V3V3AABBENDONE

    ;check if 0<= first (or only) time
    ucomiss xmm5,xmm2
    jb V3V3AABBENDZERO; if times (only first time) is below 0, then return 0


    BT rax,1; check if line is a line segment
    jnc V3V3AABBENDONE

    ;check if first (or only) time is <=1

    ucomiss xmm5,xmm3
    ja V3V3AABBENDZERO; if the time is above 1, then return 0
    
    V3V3AABBENDONE:
    mov rax,1
    jmp V3V3AABBEND
    V3V3AABBENDZERO:
    xor rax,rax
    V3V3AABBEND:


    _leave_
    ret


global V3V3VSSPHERE
;char V3V3VSSPHERE(void * V3V3, void* SPHERE, char SEGRETMODE,float* Time_Return);
;
;    /**SEGMODE:
;     4 bits flag:
;	bit 0 set the notation mode (A+B) or (A->B)
;	bit 1 and 2 set the line mode (infinite line, ray or line segment)
;	bit 3 is a placeholder for now.**/	
;
;    /**RETMODE:
;     *2 bits flag:
;     0 = none contact
;     1 = First contact
;     2 = Last contact
;     3 = Both contact **/
;   
;   /**SEGRETMODE:
;   bits 0 ~ 3: SEGMENT MODE
;   /**bits 4 ~ 5: RETURN MODE
V3V3VSSPHERE:
    _enter_

%ifidn __OUTPUT_FORMAT__, win64 
    sub rsp,16
    movups [rsp],xmm6
%endif

    movups xmm0,[arg1]
    xor rax,rax

    movups xmm1,[arg1+4+4]
    pslldq xmm0,4
    psrldq xmm0,4
    movups xmm2,[arg2]
    psrldq xmm1,4
    

    ;xmm0 = [0][Az][Ay][Ax]
    ;xmm1 = [0][Bz][By][Bx]
    ;xmm2 = [Sr][Sz][Sy][Sx]

    BT arg3,0 ; check if line is (A+B) or (A->B)
    jnc V3V3VSSPHERESKIPLINESUM
        subps xmm1,xmm0
    V3V3VSSPHERESKIPLINESUM:

    _V4NORM_ xmm6,xmm1,xmm3    

    pshufd xmm6,xmm6,0
    divps xmm1,xmm6

    shr arg3,1;arg3 = Line type
    mov arg2,arg3
    and arg2,3

    movaps xmm3,xmm0
    subps xmm3,xmm2

    ;xmm3 = m
    
    _V3DOT_ xmm4,xmm3,xmm1,xmm5

    _V3DOT_ xmm5,xmm3,xmm3,xmm1

    pxor xmm1,xmm1

    ;xmm1 = [0][0][0][0]
    ;xmm3 = CORRUPTED
    ;xmm4[0] = b
    ;xmm5[0] = dot(m,m)
    ;xmm6[0] = Direction norm


    pshufd xmm3,xmm2,00000011b
    ;xmm3[0] = Sr
    mulss xmm3,xmm3


    subss xmm5,xmm3
    
    movss xmm3,xmm4

    ;xmm1 = [0][0][0][0]
    ;xmm3[0] = b
    ;xmm4[0] = b
    ;xmm5[0] = c = dot(m,m) - (Sr*Sr)


    ucomiss xmm5,xmm1
    jbe V3V3VSSPHERESKIPPREMATURERETURN
	ucomiss xmm4,xmm1
	jbe V3V3VSSPHERESKIPPREMATURERETURN
	    jmp V3V3VSSPHERERETURNZERO
    V3V3VSSPHERESKIPPREMATURERETURN:

    mulss xmm3,xmm3
    subss xmm3,xmm5
    ;xmm3[0] = discr = (b*b) - c


    ucomiss xmm3,xmm1
    jb V3V3VSSPHERERETURNZERO

    sqrtss xmm3,xmm3

    pcmpeqw xmm2,xmm2
    pslld xmm2,31
    pxor xmm4,xmm2
    movss xmm5,xmm4 

    ;xmm1 = [0][0][0][0]
    ;xmm2 = [SC][SC][SC][SC]
    ;xmm3[0] = sqrt(discr)
    ;xmm4[0] = -b
    ;xmm5[0] = -b   
 
    subss xmm4,xmm3
    addss xmm5,xmm3

    ;xmm4[0] = t1 = -b - sqrt(discr)
    ;xmm5[0] = t2 = -b + sqrt(discr)

    ucomiss xmm4,xmm1
    jb V3V3VSSPHERERETURNZERO
   
 
    ;check line type
    cmp arg2,0
    je V3V3VSSPHERERETURNONE

    ucomiss xmm4,xmm1
    jb V3V3VSSPHERERETURNZERO

    cmp arg2,1
    je V3V3VSSPHERERETURNONE

    ;At this point, line is a segment...
    

    ucomiss xmm4,xmm6
    ja V3V3VSSPHERERETURNZERO
     

    V3V3VSSPHERERETURNONE:
    mov rax,1

    ;Store times;
    
    divss xmm4,xmm6; <- To get the normalized time


    shr arg3,3; arg3 store type
    cmp arg4,0
    je V3V3VSSPHERESKIPSTORE
	cmp arg3,0
	je  V3V3VSSPHERESKIPSTORE
 
	xor arg2,arg2    

	bt arg3,1
	jnc V3V3VSSPHERESKIPSTORET2
	    movss xmm0,xmm5
	    pslldq xmm0,4
	    inc arg2
	V3V3VSSPHERESKIPSTORET2:

	bt arg3,0
	jnc V3V3VSSPHERESKIPSTORET1
	    movss xmm0,xmm4
	    inc arg2 
	V3V3VSSPHERESKIPSTORET1:

	cmp arg2,2
	je V3V3VSSPHERESTORETWO
	    movss [arg4],xmm0
	    jmp V3V3VSSPHERESKIPSTORE	
	V3V3VSSPHERESTORETWO:
	   movsd [arg4],xmm0

    V3V3VSSPHERESKIPSTORE:

    V3V3VSSPHERERETURNZERO:
 
%ifidn __OUTPUT_FORMAT__, win64 
    movups xmm6,[rsp]
    add rsp,16
%endif
    _leave_
    ret


global V3V3VSPLANE
;char V3V3VSPLANE(void * V3V3, void * PLANE, char SEGMODE, float * Time_return);
    V3V3VSPLANE:
    _enter_
%ifidn __OUTPUT_FORMAT__, win64 
    sub rsp,16
    movups [rsp],xmm6
%endif

    movups xmm0,[arg1]
    xor rax,rax
    pxor xmm5,xmm5

    movups xmm1,[arg1+4+4]
    pslldq xmm0,4
    psrldq xmm0,4
    psrldq xmm1,4
   
    movups xmm2,[arg2]
     
    BT arg3,0 ; check if line is (A+B) or (A->B)
    jnc V3V3VSTRI3SKIPLINESUM
        subps xmm1,xmm0
    V3V3VSTRI3SKIPLINESUM:
    
    shr arg3,1

    movups xmm3,[arg2+4+4]
    pslldq xmm2,4
    psrldq xmm2,4
    psrldq xmm3,4
    
    ;xmm0 = [0][Az][Ay][Ax]
    ;xmm1 = [0][Bz][By][Bx] = ab
    ;xmm2 = [0][Pz][Py][Px] 
    ;xmm3 = [0][Nz][Ny][Nx]


    _V3DOT_ xmm4,xmm3,xmm1,xmm6

    ucomiss xmm4,xmm5
    je V3V3VSPLANEEND
	;Zero means line is perpendicular
	;if perpendicular, then it's ignored	
   
    _V3DOT_ xmm5,xmm3,xmm2,xmm6 
    ;xmm5[0] = d = (N . P)
 
    _V3DOT_ xmm1,xmm3,xmm0,xmm6
    subss xmm5,xmm1
    divss xmm5,xmm4   
    ;xmm5[0] = Time;
 
    pxor xmm2,xmm2
    pcmpeqw xmm6,xmm6
    pslld xmm6,25
    psrld xmm6,2

    ;xmm2 = [0][0][0][0]
    ;xmm6 = [1.0][1.0][1.0][1.0]

    test arg3,arg3
    jz V3V3VSPLANERETURNONE
    
    ucomiss xmm5,xmm2
    jb V3V3VSPLANEEND


    cmp arg3,1
    je V3V3VSPLANERETURNONE

    ucomiss xmm5,xmm6
    ja V3V3VSPLANEEND
 
    V3V3VSPLANERETURNONE:
    mov rax,1
    
    test arg4,arg4
    jz V3V3VSPLANEEND
	movss [arg4],xmm5

    V3V3VSPLANEEND:
%ifidn __OUTPUT_FORMAT__, win64 
    movups xmm6,[rsp]
    add rsp,16
%endif
    _leave_
    ret

global V3DISTANCEPLANE
; float V3DISTANCEPLANE(void * V3, void * Plane)
    V3DISTANCEPLANE:
    _enter_
   
    movsd xmm1,[arg1]
    pxor xmm0,xmm0
    movss xmm0,[arg1+4+4]
 
    movups xmm2,[arg2]

    movlhps xmm1,xmm0
    
    movups xmm3,[arg2+4+4]
    pslldq xmm2,4
    psrldq xmm2,4
    psrldq xmm3,4

    _V3DOT_ xmm4,xmm3,xmm2,xmm5 
    ;xmm4[0] = d = (N . P)

    _V3DOT_ xmm0,xmm3,xmm1,xmm5
    ;xmm0[0] = (N . V3)
   
    _V3DOT_ xmm5,xmm3,xmm3,xmm2
    ;xmm5[0] = (N . N)
 
    subss xmm0,xmm4
    divss xmm0,xmm5

    _leave_
    ret

global SPHEREVSSPHERE; char SPHEREVSSPHERE(void * A, void * B);
;*************************************************************************
;Return 1 if the sum of the radii is less than or equal than the distance
;between the centers
;*************************************************************************
    SPHEREVSSPHERE:
    _enter_
	xor rax,rax
	movsd xmm0,[arg1]
	movss xmm4,[arg1+8]
	movlhps xmm0,xmm4
	movups xmm2,[arg2]
	mov arg4,1	
	movhlps xmm1,xmm0
	movshdup xmm1,xmm1
	movhlps xmm3,xmm2
	movshdup xmm3,xmm2
	;xmm0.xyz = A Position
	;xmm1.x = A Radius
	;xmm2.xyz = B Position
	;xmm3.x = B Radius
	subps xmm2,xmm0
	addss xmm1,xmm3
	mulps xmm2,xmm2
	movhlps xmm3,xmm2
	;xmm2.x = X*X
	;xmm2.y = Y*Y
	;xmm3.x = Z*Z
	movshdup xmm0,xmm2
	;xmm0.x = Y*Y
	addss xmm2,xmm0
	addss xmm2,xmm3
	sqrtss xmm2,xmm2
	ucomiss xmm2,xmm1
	cmovbe rax,arg4
    _leave_
    ret


global V3VSSPHERE; char V3VSSPHERE(void * Point3D, void * Sphere)
    V3VSSPHERE:
    _enter_
	movsd xmm0,[arg1]
	mov arg4,1
	xor rax,rax
	movss xmm4,[arg1+(2*4)]
	movlhps xmm0,xmm4
	movups xmm2,[arg2]
	movhlps xmm1,xmm2
	movshdup xmm1,xmm1
	;xmm0.xyz = Point
	;xmm2.xyz = Center
	;xmm1.x = Radius
	subps xmm2,xmm0
	mulps xmm2,xmm2
	movhlps xmm3,xmm2
	;xmm2.x = X*X
	;xmm2.y = Y*Y
	;xmm3.x = Z*Z
	movshdup xmm0,xmm2
	;xmm0.x = Y*Y
	addss xmm2,xmm0
	addss xmm2,xmm3
	sqrtss xmm2,xmm2
	ucomiss xmm2,xmm1
	cmovbe rax,arg4
    _leave_
    ret

global V3VSV3
    V3VSV3:
    _enter_
	movsd xmm0,[arg1]
	mov arg4,1
	xor rax,rax
	movss xmm3,[arg1+(2*4)]
	movlhps xmm0,xmm3
	movsd xmm1,[arg2]
	pxor xmm4,xmm4
	movss xmm2,[arg2+(2*4)]
	movlhps xmm1,xmm2
	;xmm0 = Point A
	;xmm1 = Point B
	;xmm4 = 0

	CMPNEQPS xmm1, xmm2
	;if (xmm1==xmm2) then xmm1.xyzw = 0

	;OR all the members
	movhlps xmm3,xmm1
	por xmm3,xmm1
	movshdup xmm1,xmm3
	por xmm1,xmm3

	;Now check if they're still all 0
	ucomiss xmm1,xmm4
	cmove rax,arg4
    _leave_
    ret

global V3VSAABB3;char V2VSAABB2(void * Point3D,void * AABB3,char AABB3MODE);  
;****************************************************************
;Given a 3D point and a AABB3,
;this algoritm returns if the 2D point lies in the AABB2.
;AABB3MODE:
;     *2 bits flag:
;     *bit 0 set the notation mode (Center+Half_extent) or (A->B)
;     *bit 1 set the subnotation mode:
;        if (A->B) (bit 0 set): (Pivot+Direction) or (Min->Max) 
;****************************************************************
    V3VSAABB3:
    _enter_

    movsd xmm0,[arg1]
    movss xmm3,[arg1+8]
    movlhps xmm0,xmm3

    xor arg4,arg4; set to 0 
    xor rax,rax; clear return
    not arg4; set arg4 to -INF (full set) for later comparition
    ;arg4 = 0xFFFFFFFFFFFFFFFF

    movups xmm1,[arg2]
    movups xmm2,[arg2+((2*4))]
    pslldq xmm1,4
    psrldq xmm1,4
    psrldq xmm2,4

    ;xmm0 = Point3D
    ;xmm1 = AABB Vertex 1
    ;xmm2 = AABB Vertex 2

    BT arg3, 0 ;check if Center+Half_Extents or Classic AABB3
    js V3VSAABB3ISCLASSIC
        ;if bit 0 is clear, then it's Center+Half_Extent
        movaps xmm3,xmm1
        subps xmm1,xmm2
        addps xmm2,xmm3
	jmp V3VSAABB3PREPROCCESSEND
    V3VSAABB3ISCLASSIC:
        ;if bit 0 is set, then:
        BT arg3,1; check if Pivot+Direction or Min->Max
        js V3VSAABB3PREPROCCESSEND
            ;if bit 1 is clear, then it's Pivot+Direction
            addps xmm2,xmm1
    V3VSAABB3PREPROCCESSEND:

    ;xmm0: [][Pz][Py][Px]
    ;xmm1: [][Min.z][Min.y][Min.x]
    ;xmm2: [][Max.z][Max.y][Max.x]

    ;check if xmm1 <= xmm0
    cmpps xmm1,xmm0,2
    movhlps xmm3,xmm1
    pand xmm1,xmm3

    ;check if xmm0 <= xmm2
    cmpps xmm0,xmm2,2
    movhlps xmm4,xmm0
    pand xmm0,xmm4

    movq arg1,xmm1
    movq arg2,xmm0

    cmp arg1,arg4
    jne V3VSAABB3END
    cmp arg3,arg4
    jne V3VSAABB3END
    mov ax,1
    V3VSAABB3END:

    _leave_
    ret

global V3VSPLANE; char V3VSPLANE(void * V3, void * Plane);
;******************************************************************************
;Given a 3D Point (A) and a Plane consisting in a 3D point (P) and a normal (N),
;this algoritm returns 1 if (((A-P).N) == 0). NOTE: (.) <- dot product
;******************************************************************************
    V3VSPLANE:
    _enter_
    movups xmm1,[arg2]
    xor rax,rax
    pxor xmm4,xmm4
    movsd xmm0,[arg1]
    pslldq xmm1,4
    movss xmm3,[arg1+8]
    psrldq xmm1,4
    movups xmm2,[arg2+((2*4))]
    mov arg4,1
    movlhps xmm0,xmm3
    psrldq xmm2,4

    ;xmm0 = V3 (A)
    ;xmm1 = Point in Plane (P)
    ;xmm2 = Plane Normal (N)

    subps xmm0,xmm1
    mulps xmm0,xmm2
    movhlps xmm3,xmm0
    movshdup xmm2,xmm0
    addps xmm0,xmm4
    addss xmm0,xmm2
    
    ucomiss xmm0,xmm4
    cmove rax,arg4
    _leave_
    ret


global AABB3VSAABB3 ;char AABB3VSAABB3(void * A, void * B,char AABB3MODE);
;************************************************************************;
;Given two 3D AABB, this algoritm returns 1 if they intersects
;AABB3MODE:
;     *2 bits flag:
;     *bit 0 set the notation mode (Center+Half_extent) or (A->B)
;     *bit 1 set the subnotation mode:
;        if (A->B) (bit 0 set): (Pivot+Direction) or (Min->Max)
;AABB3_A Flag: 0 ~ 3
;AABB3_B Flag: 4 ~ 7
;************************************************************************;
    AABB3VSAABB3:
    _enter_

    movups xmm0,[arg1]
	pcmpeqw xmm5,xmm5
	psrld xmm5,1
    movups xmm1,[arg1+((2*4))]
    pslldq xmm0,4
    psrldq xmm0,4
    psrldq xmm1,4

    movups xmm2,[arg2]
	pcmpeqw xmm4,xmm4
        psllq xmm4,55
        psrlq xmm4,2
    movups xmm3,[arg2+((2*4))]
    pslldq xmm2,4
    psrldq xmm2,4
    psrldq xmm3,4

    mov arg4,1

    BT arg3,0
    jc AABB3VSAABB3_ACH
	    BT arg3,1
	    js AABB3VSAABB3_APD
		subps xmm1,xmm0
	    AABB3VSAABB3_APD:
	    mulps xmm1,xmm4
	    addps xmm0,xmm1
    AABB3VSAABB3_ACH:

    BT arg3,4
    jc AABB3VSAABB3_BCH
	    BT arg3,5
	    js AABB3VSAABB3_BPD
		subps xmm3,xmm2
	    AABB3VSAABB3_BPD:
	    mulps xmm3,xmm4
	    addps xmm2,xmm3
    AABB3VSAABB3_BCH:

    subps xmm0,xmm2 ;A.center - B.center
    addps xmm1,xmm3 ;A.HL + B.HL
    pand xmm0,xmm5;Abs(A.center-B.center)
    
    cmpss xmm4,xmm4,0

    CMPLEPS xmm1,xmm0; A.r <= A.c
    ;if this is true, then return 0
    
    movhlps xmm2,xmm1
    movshdup xmm0,xmm1
    por xmm0,xmm1
    por xmm0,xmm2
    
    ;if(xmm0 != FF){return 1;}
    ucomiss xmm0,xmm4
    cmovne rax,arg4

    _leave_
    ret

%unmacro DotProductXMMV3 4
%unmacro _V3DOT_ 4
%unmacro NORMALIZEVEC3MACRO 4 
%unmacro _V4NORM_ 3
%unmacro _V3CROSS_ 5

%endif
