
%ifndef _LD_GEOMETRY_2D_64_ASM
%define _LD_GEOMETRY_2D_64_ASM

%include "LDM_MACROS.asm" ; Compile with -i 

args_reset ;<--Sets arguments definitions to normal, as it's definitions can change.

/********MACROS***********/
%macro CROSSPRODUCTV2 4
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

%macro DotProductXMMV2 4
;%1 and %2 are registers to proccess
;%3 is the result ;Result stored in the first 32-bits
;%4 is a temporal register
	movsd %3, %1
	mulps  %3, %2
	movshdup %4,%3
	addss    %3,%4
%endmacro
/*************************/


section .text

global TRI2DCENTROID; void TRI2DCENTROID(void * Destiny, void * Source);
;************************
;Given a triangle Triangle described by and array of 3 2D points (2 floats per point)
;this algorithm calculates its barycenter and returns and array of a 2D point in Result
;************************
TRI2DCENTROID:
    ;enter 0,0    
    movsd XMM0,[arg2]
    add arg2,(4*2) ;<- It jumps two times the size of a float (4 bytes)
    movsd XMM1,[arg2]
    add arg2,(4*2) ;<- It jumps two times the size of a float because of memory boundaries
    movsd XMM2,[arg2] 

    _loadimm32_ xmm3,01000000010000000000000000000000b,rax


    ;xmm0 [??][??][Ay][Ax]
    ;xmm1 [??][??][By][Bx]
    ;xmm2 [??][??][Cx][Bz]  
    ;xmm3 [??][??][??][3.0f];<- It needs to be in all sections
    movsldup xmm3,xmm3
    ;xmm3 [?][?][3.0f][3.0f]
    addps xmm0,xmm1
    addps xmm0,xmm2
    divps xmm0,xmm3
    ;xmm0 [??][??][Ry][Rx]
    movsd [arg1],xmm0
    ;leave
    ret


global P2DVSSEG2D; char P2DVSSEG2D(float * Point2D, float * Segment2D,char SEGMODE)
;*******************************************************************************
;Given a 2D point (x,y) and a line segment (define by two 2D points),
;this algorithm returns if both intersect.
;if SEGMODE is set, the segment will be define by and origind and an end.
;if SEGMODE is clear, the segment will be define by and origin and a direction.
;********************************************************************************
P2DVSSEG2D:
    ;enter 0,0
    xor RAX,RAX    
    
    movsd xmm0,[arg1]		    ;(P.x,P.y)
    movsd xmm1,[arg2]		    ;(A.x,A.y)
    movsd xmm2,[arg2+(4*2)]	    ;(B.x,B.y)
    

    movsd xmm4,xmm0
    subps xmm4,xmm1 ;xmm4=P-A
    movsd xmm5,xmm2

    cmp arg3,0
    je P2DVSSEG2D_MODE0:
        subps xmm5,xmm1 ;xmm5=B-A; xmm5 = Segment's Direction;
        jmp P2DVSSEG2D_MODE0_SKIP
    P2DVSSEG2D_MODE0:
        subps xmm2,xmm1;xmm2=B+A; xmm2 = Segment's End;
    P2DVSSEG2D_MODE0_SKIP:

    CROSSPRODUCTV2 xmm4,xmm5,xmm0,xmm3
    ;xmm0 = AP x AB

    DotProductXMMV2 xmm5,xmm4,xmm1,xmm3
    ;xmm1 = AB . AP
    
    DotProductXMMV2 xmm5,xmm5,xmm2,xmm3
    ;xmm2 = AB . AB

    pxor xmm3,xmm3
    
    cmpss xmm0,xmm3,0 ;xmm0= if xmm0 = 0
    cmpss xmm3,xmm1,2 ;xmm3= if 0 <= xmm1    
    cmpss xmm1,xmm2,2 ;xmm1= if xmm1 <= xmm2
	
    andps xmm1,xmm3
    andps xmm0,xmm1

    ;sub rsp,8
    ;movss [rsp],xmm0
    ;mov eax,[rsp]
    ;add rsp,8

    movd eax,xmm0

    cmp eax,0xFFFFFFFF
    je __set1 

    xor rax,rax
    jmp __final

__set1:
    mov rax,1

__final:
    ;leave
    ret


global P2DVSTRI2D; char P2DVSTRI2D(float * 2D_Point, float * 2D_Triangle,int bytes_offset);
;***************
;Given a 2D Triangle and a 2D Point,
;this algorithm returns 1 if the point is inside the Triangle boundaries
;else, this algoritm returns 0
;The offset can be used if the triangle vertices elements are interleaved with something else 
;***************
P2DVSTRI2D:
    ;enter 0,0
%ifidn __OUTPUT_FORMAT__, win64 
    sub rsp,16*2
    movups [rsp],xmm6
    movups [rsp+16],xmm7
%endif
    xor RAX,RAX
   
    movsd xmm0,[arg1]		    ;(P.x,P.y)
    movsd xmm1,[arg2]		    ;(A.x,A.y)
    add arg2,arg3
    movsd xmm2,[arg2+(4*2)]	    ;(B.x,B.y)
    add arg2,arg3
    movsd xmm3,[arg2+(4*2)+(4*2)]   ;(C.x,C.y)

    movsd xmm4,xmm0
    subps xmm4,xmm1 ;xmm4=P-A
    movsd xmm5,xmm2
    subps xmm5,xmm1 ;xmm5=B-A

    CROSSPRODUCTV2 xmm5,xmm4,xmm6,xmm7
    ;xmm6 = PAB

 
    movsd xmm4,xmm0
    subps xmm4,xmm2 ;xmm4=P-B
    movsd xmm5,xmm3
    subps xmm5,xmm2 ;xmm5=C-B

    CROSSPRODUCTV2 xmm5,xmm4,xmm2,xmm7
    ;xmm2 = PBC
    
    movsd xmm4,xmm0
    subps xmm4,xmm3 ;xmm4=P-C
    movsd xmm5,xmm1
    subps xmm5,xmm3 ;xmm5=A-C

    CROSSPRODUCTV2 xmm5,xmm4,xmm3,xmm7
    ;xmm3 = PCA

    xor arg1,arg1
    xor arg2,arg2
    xor arg3,arg3
    
    pxor xmm0,xmm0
    MOVMSKPS arg3,xmm3
    MOVMSKPS arg1,xmm6
    MOVMSKPS arg2,xmm2

    and arg1,1 ; 1 = Negative, 0 = Positive
    and arg2,1 ; 1 = Negative, 0 = Positive
    and arg3,1 ; 1 = Negative, 0 = Positive
    cmp arg1,arg2 
    jne final
    cmp arg1,arg3
    jne final

    mov rax,1 
final:
%ifidn __OUTPUT_FORMAT__, win64 
    movups xmm6,[rsp]
    movups xmm7,[rsp+16]
    add rsp, 16*2
%endif
    ;leave
    ret


global Check_Segment_vs_Segment_2D
;char Check_Segment_vs_Segment_2D(float * Seg_A, float * Seg_B,char SEGMODE, float * Time_Return);
;Seg_A = Q -> S
;Seg_B = P -> R
Check_Segment_vs_Segment_2D:
    enter 0,0
    
    xor RAX,RAX

    movsd xmm0,[arg2]	;xmm0=Q
    movsd xmm2,[arg1]	;xmm2=P
    add arg2,8    
    movsd xmm1,[arg2]	;xmm1=Q+S
    subps xmm1,xmm0     ;xmm1=Q
    add arg1,8
    subps xmm0,xmm2	;xmm0 = Q-P
    movsd xmm3,[arg1]   ;xmm3 = P+R
    subps xmm3,xmm2     ;xmm3 = P

    CROSSPRODUCTV2 xmm0,xmm1,xmm2,xmm4
    ;xmm2 = (Q-P) x S
    
    CROSSPRODUCTV2 xmm3,xmm1,xmm4,xmm5
    ;xmm4 = (R x S)

    CROSSPRODUCTV2 xmm0,xmm3,xmm1,xmm5
    ;xmm1 = (Q-P) x R
  
 
%if 1
 
    sub rsp,8
    movss [rsp],xmm4
    mov eax,[rsp]

    divss xmm2,xmm4;xmm2 = t = (Q-P) x S / (R x S)
    

    divss xmm1,xmm4;xmm1 = u = (Q-P) x R / (R x S)
   
    movss xmm0,xmm2;<- save to return

    movlhps xmm1,xmm2
    ;xmm1 = [?][t][?][u]
    pshufd xmm1,xmm1,10_0_10_00b

    cmp eax,0
    je _final 
    mov rax,0
    
    sub rsp,8

    pxor xmm2,xmm2
    movss xmm3,[fc_1f_mem]
    pshufd xmm3,xmm3,0
   
    ;movups [arg3],xmm1

    cmpps xmm2,xmm1,2 ;xmm2= if 0 <= xmm1    
    cmpps xmm1,xmm3,2 ;xmm1= if xmm1 <= 1.f

    ;movups [arg3],xmm2

    movlhps xmm2,xmm1
    ;xmm2 [t<1.f][u<1.f][0<t][0<u]

    ;movups [arg3],xmm2    
    
    movups [rsp],xmm2
    mov arg1,[rsp]
    add rsp,8
    mov arg2,[rsp]
    add rsp,8
    
    mov arg4,0xFFFFFFFFFFFFFFFF

    cmp arg1,arg4
    jne _final
    cmp arg2,arg4
    jne _final

    mov eax,1
    cmp arg3,0
    je _final
    movss [arg3],xmm0
%endif
   
_final:
    leave
    ret

%endif



%unmacro CROSSPRODUCTV2 4
%unmacro DotProductXMMV2 4
%endif