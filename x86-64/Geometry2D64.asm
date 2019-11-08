
%ifndef _LD_GEOMETRY_2D_64_ASM
%define _LD_GEOMETRY_2D_64_ASM

%include "LDM_MACROS.asm" ; Compile with -i 

args_reset ;<--Sets arguments definitions to normal, as it's definitions can change.

; SEGMODE: 
; 4 bits flag:
;   bit 0 set the notation mode (A->B) or (A+B)
;   bit 1 and 2 set the line mode (infinite line, ray or line segment)
;   bit 3 is a placeholder for now.

;/********MACROS***********/

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

%macro _V2NORM_imm  2
;%1 Destiny/Source Operand (float)
;%2 Temporal Operand (2D vector of floats)
	   mulps %1,%1
	   movshdup %2,%1
	   addss   %1,%2
	   sqrtss  %1,%1
%endmacro

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

;/*************************/


section .text

global V2VSAABB2; char V2VSAABB2 (void * Point2D, void * AABB2, char AABB2MODE);
;****************************************************************
;Given a 2D point and a AABB2,
;this algoritm returns if the 2D point lies in the AABB2.
;AABB2MODE:
;     *2 bits flag:
;     *bit 0 set the notation mode (Center+Half_extent) or (A->B)
;     *bit 1 set the subnotation mode:
;        if (A->B) (bit 0 set): (Pivot+Direction) or (Min->Max) 
;****************************************************************
V2VSAABB2:
    _enter_
    movsd xmm0,[arg1]; <-- Point2D
        xor arg4,arg4; set to 0 
    movups xmm1,[arg2]; 
        xor rax,rax; clear return
        not arg4; set arg4 to -INF (full set) for later comparition 
    movhlps xmm2,xmm1;

    ;xmm0: [][][Py][Px]
    ;xmm1: [][][Ay][Ax]
    ;xmm2: [][][By][Bx]

    BT arg3, 0 ;check if Center+Half_Extents or Classic AABB2
    js V2VSAABB2ISCLASSIC
        ;if bit 0 is clear, then it's Center+Half_Extent
        movaps xmm3,xmm1
        subps xmm1,xmm2
        addps xmm2,xmm3
	jmp V2VSAABB2PREPROCCESSEND
    V2VSAABB2ISCLASSIC:
        ;if bit 0 is set, then:
        BT arg3,1; check if Pivot+Direction or Min->Max
        js V2VSAABB2PREPROCCESSEND
            ;if bit 1 is clear, then it's Pivot+Direction
            addps xmm2,xmm1

    V2VSAABB2PREPROCCESSEND:

    ;xmm0: [][][Py][Px]
    ;xmm1: [][][Min.y][Min.x]
    ;xmm2: [][][Max.y][Max.x]

    ;check if xmm1 <= xmm0
    cmpps xmm1,xmm0,2

    ;check if xmm0 <= xmm2
    cmpps xmm0,xmm2,2

    movq arg1,xmm1
    movq arg2,xmm0

    cmp arg1,arg4
    jne V2VSAABB2END
    cmp arg2,arg4
    jne V2VSAABB2END
    mov ax,1
    V2VSAABB2END:
    _leave_
    ret

global V2V2VSAABB2; char V2V2VSAABB2(void * Line2D, void * AABB2, char SEGAABB2RETMODE, float * Times_Return); 
;*********************************************************************
;Given a 2D line and a 2D AABB,
;This algorithm returns if the line collided with the AABB.
;This algorithm returns when the collision(s) occurs.
;
;SEGAABB2RETMODE:
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
;Original source from: 
;https://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-box-intersection
;*********************************************************************
V2V2VSAABB2:
    _enter_
        mov rax,arg3; <- Temporal variable
    movups xmm0,[arg1]
    pxor xmm4,xmm4
        shr rax,1;
        and rax,3;
        ;rax = Line mode bits
    movhlps xmm1,xmm0
    ;xmm0 = [][][LAy][LAx]
    ;xmm1 = [][][LBy][LBx]

    movups xmm2,[arg2]
    pxor xmm5,xmm5
    
    BT arg3,0 ; check if line is (A+B) or (A->B)
    jnc V2V2VSAABB2SKIPLINESUM
        subps xmm1,xmm0
    V2V2VSAABB2SKIPLINESUM:

    movhlps xmm3,xmm2

    ;xmm2 = [][][BoxAy][BoxAx]
    ;xmm3 = [][][BoxBy][BoxBx]

    BT arg3,4 ; check if AABB is (Center+Extents) or (A->B)
    jc V2V2V2AABBISTYPEB
    ;If AABB is (Center+Extents), then:
        movaps xmm4,xmm2
        subps xmm2,xmm3
        addps xmm3,xmm4
    jmp V2V2AABBSKIPISTYPEB
    V2V2V2AABBISTYPEB:
        BT arg3,5; check if (Pivot+Direction) or (Min->Max)
        jc V2V2AABBSKIPISTYPEB
        ;if (Pivot+Direction), then:
        addps xmm3,xmm2
    V2V2AABBSKIPISTYPEB:

    ;xmm0 = [][][LAy][LAx]
    ;xmm1 = [][][LBy][LBx]
    ;xmm2 = [][][MinY][MinX]
    ;xmm3 = [][][MaxY][MaxX]
    ;xmm4 = 0
    ;xmm5 = 0


    

%if 0 ;Deactivated because of ptest
    xor arg1,arg1 ; arg1 will be used to record volume collision
    bt arg3,3 ;check if collide with the volume is set
    jnc V2V2VSAABB2SKIPCHECKINSIDE
        movsd xmm4,xmm0
        movsd xmm5,xmm2
        ;xmm4: [][][Py][Px]
        ;xmm5: [][][Min.y][Min.x]
        ;xmm3: [][][Max.y][Max.x]
        ;check if xmm5 <= xmm4
        cmpps xmm5,xmm0,2
        ;check if xmm4 <= xmm3
        cmpps xmm4,xmm2,2
        pand xmm4,xmm5
        pcmpeqd xmm5, xmm5 
        pxor xmm4,xmm5
        ptest xmm4,xmm4 ;if zero, then the point is inside the AABB
        jnz V2V2VSAABB2SKIPCHECKINSIDE
        mov arg1,1
    V2V2VSAABB2SKIPCHECKINSIDE:
%endif

    ;Calculate FirstCol = (Min - LA) / LB
    subps xmm2,xmm0
    divps xmm2,xmm1

    shr arg3,6

    ;Calculate LastCol = (Max - LA) / LB
    subps xmm3,xmm0
    divps xmm3,xmm1

;    movsd [arg1],xmm2 

    movshdup xmm4,xmm2
    movshdup xmm5,xmm3
    
    ;xmm2= [][][][FCx]
    ;xmm4= [][][][FCy]
    ;xmm3= [][][][LCx]
    ;xmm5= [][][][LCy]



    ucomiss xmm2,xmm3
    jna V2V2AABBSKIPMINMAX
	pxor xmm2,xmm3
	pxor xmm3,xmm2
	pxor xmm2,xmm3
    V2V2AABBSKIPMINMAX:

    ucomiss xmm4,xmm5
    jna V2V2AABBSKIPMINMAXY
	pxor xmm4,xmm5
	pxor xmm5,xmm4
	pxor xmm4,xmm5
    V2V2AABBSKIPMINMAXY:
    
    ucomiss xmm5,xmm2
    jbe V2V2AABBCHECKIFINSIDE
    ucomiss xmm3,xmm4
    jbe V2V2AABBCHECKIFINSIDE

    ucomiss xmm4,xmm2
    jna V2V2AABBSKIPMINMAXF
	movss xmm2,xmm4
    V2V2AABBSKIPMINMAXF:

    ucomiss xmm5,xmm3
    jnb V2V2AABBSKIPMINMAXFF
	movss xmm3,xmm5
    V2V2AABBSKIPMINMAXFF:

    ;xmm2=tmin
    ;xmm3=tmax

   
 
    jmp V2V2AABBSKIPCHECKIFINSIDE
    V2V2AABBCHECKIFINSIDE:
	jmp V2V2AABBENDZERO
    V2V2AABBSKIPCHECKIFINSIDE:

%if 1

    ;rax = Line Mode
    ;arg3 = Return Mode

    ;Check time return Mode
    cmp arg3,0 ;if no time returns
    je V2V2AABBSKIPSTORE ;return no time

    movshdup xmm5,xmm3

    bt arg3,1 ;check if return last collision is enabled
    jnc V2V2AABBNOLAST
        movss xmm0,xmm3
    V2V2AABBNOLAST:

    bt arg3,0 ;check if return first collision is enabled
    jnc V2V2AABBNOFIRST
        psllq xmm0,4 ;shift the float to make space for the new result
        movss xmm0,xmm2 
    V2V2AABBNOFIRST:

    ;xmm0 [][][LCT][FCT]

    pxor xmm2,xmm2

    cmp arg3,3
    je V2V2AABBSTOREBOTH
        movss [arg4],xmm0 ;Store the two results
        jmp V2V2AABBSKIPSTORE
    V2V2AABBSTOREBOTH:
        movsd [arg4],xmm0 ;Store one retult

    V2V2AABBSKIPSTORE:

%endif

    ;Load 1.0
    pcmpeqw xmm3,xmm3
    pslld xmm3,25
    psrld xmm3,2
    ;-----------

    ;xmm2 = 0
    ;xmm3 = 1.0

    ;check times according with line type

    test rax,rax; if infinite (arg3==0), then skip checking boundaries
    jz V2V2AABBENDONE

    ;check if 0<= first (or only) time
    ucomiss xmm0,xmm2
    jb V2V2AABBENDZERO; if times (only first time) is below 0, then return 0


    BT rax,1; check if line is a line segment
    jnc V2V2AABBENDONE

    ;check if first (or only) time is <=1

    ucomiss xmm0,xmm3
    ja V2V2AABBENDZERO; if the time is above 1, then return 0
    
    V2V2AABBENDONE:
    mov rax,1
    jmp V2V2AABBEND
    V2V2AABBENDZERO:
    xor rax,rax
    V2V2AABBEND:
    _leave_
    ret


global V2VSV2RADIUS; char V2VSV2RADIUS(void * Point2D, void * CircleCenter, float Radius)
;****************************************************************
;Given a 2D point and a Circunference by a center and a Radius,
;This algorithm returns if the point lies in the circle.
;****************************************************************
V2VSV2RADIUS:
%ifidn __OUTPUT_FORMAT__, win64 
   %define arg1f xmm2
%endif
    _enter_
    movsd xmm5,[arg1]
    
    mov rax,1

    movsd xmm4,[arg2]

    xor arg4,arg4

    subps xmm4,xmm5

    ;Norm
    mulps xmm4,xmm4
    movshdup xmm1,xmm4
    addss   xmm1,xmm4
    sqrtss xmm1,xmm1
    ;------------;

    ucomiss arg1f,xmm1
    cmovb rax,arg4
    
    _leave_
    ret
%ifidn __OUTPUT_FORMAT__, win64 
    args_reset
%endif

global V2VSV2; char V2VSV2(void * A,void *B)
;******************************************************
;Given two 2D points,
;This algorithm returns if both lies in the same place
;*******************************************************
V2VSV2:
    _enter_
    mov arg3,[arg1]
    mov arg4,0
    mov rax,1
    cmp arg3,[arg2]
    cmovne rax,arg4
    _leave_
    ret

global TRI2CENTROID; void TRI2CENTROID(void * Destiny, void * Source);
;************************
;Given a triangle Triangle described by and array of 3 2D points (2 floats per point)
;this algorithm calculates its barycenter and returns and array of a 2D point in Result
;************************
TRI2CENTROID:
    _enter_    
    movsd XMM0,[arg2]
    add arg2,(4*2) ;<- It jumps two times the size of a float (4 bytes)
    movsd XMM1,[arg2]
    add arg2,(4*2) ;<- It jumps two times the size of a float because of memory boundaries
    movsd XMM2,[arg2] 

    _loadimm32_ xmm3,01000000010000000000000000000000b,eax


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
    _leave_
    ret


global V2VSV2V2; char V2VSV2V2(float * Point2D, float * Segment2D,char SEGMODE)
;*******************************************************************************
;Given a 2D point (x,y) and a line segment (define by two 2D points),
;this algorithm returns if both intersect.
; SEGMODE: 
; 4 bits flag:
;   bit 0 set the notation mode (A+B)(clear) or (A->B)(set)
;   bit 1 and 2 set the line mode (infinite line, ray or line segment)
;   bit 3 is a placeholder for now.
;********************************************************************************
V2VSV2V2:
    _enter_
    xor RAX,RAX    
    
    movsd xmm0,[arg1]		    ;(P.x,P.y)
    movsd xmm1,[arg2]		    ;(A.x,A.y)
    movsd xmm2,[arg2+(4*2)]	    ;(B.x,B.y)
    

    movsd xmm4,xmm0
    subps xmm4,xmm1 ;xmm4=P-A
    movsd xmm5,xmm2

    bt arg3,0
    jnc V2VSV2V2_MODE0
        subps xmm5,xmm1 ;xmm5=B-A; xmm5 = Segment's Direction;
        jmp V2VSV2V2_MODE0_SKIP
    V2VSV2V2_MODE0:
        subps xmm2,xmm1;xmm2=B+A; xmm2 = Segment's End;
    V2VSV2V2_MODE0_SKIP:

    CROSSPRODUCTV2 xmm4,xmm5,xmm0,xmm3
    ;xmm0 = AP x AB

    shr arg3,1 ;<-- Get SEGMODE

    DotProductXMMV2 xmm5,xmm4,xmm1,xmm3
    ;xmm1 = AB . AP
    
    DotProductXMMV2 xmm5,xmm5,xmm2,xmm3
    ;xmm2 = AB . AB

    pxor xmm3,xmm3
    
    cmpss xmm0,xmm3,0 ;xmm0= if xmm0 == 0

    cmp arg3,0
    je V2VSV2V2_INFLINE

    cmpss xmm3,xmm1,2 ;xmm3= if 0 <= xmm1  

    cmp arg3,1
    je V2VSV2V2_RAY

    cmpss xmm1,xmm2,2 ;xmm1= if xmm1 <= xmm2

    andps xmm3,xmm1

    V2VSV2V2_RAY:
    andps xmm0,xmm3

    V2VSV2V2_INFLINE:


    movd eax,xmm0

    cmp eax,0xFFFFFFFF
    je __set1 

    xor rax,rax
    jmp __final

__set1:
    mov rax,1

__final:
    _leave_
    ret


global V2VSTRI2_EXT; char V2VSTRI2_EXT(float * 2D_Point, float * 2D_Triangle,int bytes_offset);
;***************
;Given a 2D Triangle and a 2D Point,
;this algorithm returns 1 if the point is inside the Triangle boundaries
;else, this algoritm returns 0
;The offset can be used if the triangle vertices elements are interleaved with something else 
;***************
V2VSTRI2_EXT:
    _enter_
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
    args_reset
%endif
    _leave_
    ret

    


global V2V2VSV2V2
;char V2V2VSV2V2 (float * Seg_A, float * Seg_B,char SEGMODE, float * Time_Return);
;*************************************
; Given two V2V2, this algorithm calculates if intersect.
; low 4 bits in SEGMODE is SEGMODE A
; high 4 bits in SEGMODE is SEGMODE B
;*************************************
V2V2VSV2V2:
    _enter_
    
    mov rax,arg3
    and arg3,0xF
    shr rax,4

    ;arg3 = SEGMODE A
    ;rax = SEGMODE B

    movsd xmm0,[arg2]	;xmm0=Q (Aa)
    movsd xmm2,[arg1]	;xmm2=P (Ba)
    add arg2,8    
    movsd xmm1,[arg2]	;xmm1= (Ab)
    bt rax,0
    jnc S2DVSS2D_SKIPSMA ;if bit 0, clear xmm1= S
    subps xmm1,xmm0     ;xmm1=S = (Q+S)-Q (Ab)
    S2DVSS2D_SKIPSMA:
    add arg1,8
    subps xmm0,xmm2	;xmm0 = Q-P
    movsd xmm3,[arg1]   ;xmm3 = (Bb)
    bt arg3,0
    jnc S2DVSS2D_SKIPSMB ;if bit 0, clear xmm3= R
    subps xmm3,xmm2     ;xmm3 = R = (P+R) -P (Bb)
    S2DVSS2D_SKIPSMB:
    
    shr arg3,1

    CROSSPRODUCTV2 xmm0,xmm1,xmm2,xmm4
    ;xmm2 = (Q-P) x S
   
    and arg3,3 
    shr rax,1

    CROSSPRODUCTV2 xmm3,xmm1,xmm4,xmm5
    ;xmm4 = (R x S)
    
    shl rax,2

    CROSSPRODUCTV2 xmm0,xmm3,xmm1,xmm5
    ;xmm1 = (Q-P) x R
  
    

    or arg3,rax
 
%if 1
 
    movd eax,xmm4

    divss xmm2,xmm4;xmm2 = t = (Q-P) x S / (R x S)

    divss xmm1,xmm4;xmm1 = u = (Q-P) x R / (R x S)
   
    movss xmm0,xmm2;<- save to return

    
    

    movlhps xmm1,xmm2
    ;xmm1 = [?][t][?][u]
    pshufd xmm1,xmm1,10_00_10_00b

    cmp eax,0
    je _final 
    mov rax,0

    pxor xmm2,xmm2

    pcmpeqw xmm3,xmm3
    pslld xmm3,25
    psrld xmm3,2
    ;xmm3 = [1.f][1.f][1.f][1.f]

    ;xmm0 = [][][][t]
    ;xmm1 = [t][u][t][u]
    ;xmm2 = [0][0][0][0]
    ;xmm3 = [1.f][1.f][1.f][1.f]
    ;arg3 = SEGMODE (u)(t)
	;arg3 [B][B][A][A]

    mov rax,arg3

    cmpps xmm2,xmm1,2 ;xmm2= if 0 <= xmm1    
    cmpps xmm1,xmm3,2 ;xmm1= if xmm1 <= 1.f
    ;movlhps xmm2,xmm1 ;xmm2 [t<1.f][u<1.f][0<t][0<u]

    and arg3,3
    shr rax,2 ;<-- Shift to get needed data

    UNPCKLPS xmm1,xmm2
    ;xmm1 [t<1.f][0<t][u<1.f][0<u]
    
    movq arg2,xmm1
	;arg2 [u<1.f][0<u]


    ;FOR SEGMENT B
    mov arg1,0xFFFFFFFFFFFFFFFF ; Test both conditions (segment mode)
    cmp rax,0              ; Test none conditions (line mode)
    jne S2DVSS2D_SKIPSB
    xor arg1,arg1   ;<-- Setting line mode
    S2DVSS2D_SKIPSB:
    cmp rax,1                  ; Test Only 0 <= condition (ray mode)
    jne S2DVSS2D_SKIPSB_RAY
        shr arg1,32 ;<-- Setting ray mode by shifting 32 bits right
    S2DVSS2D_SKIPSB_RAY:
    and arg2,arg1
    cmp arg1,arg2
    jne _finalzero

	PSRLDQ xmm1,(4+4)
	;xmm1 [0][0][t<1.f][0<t]

    movq arg2,xmm1
	;arg2 [t<1.f][0<t]

    ;FOR SEGMENT A
    mov arg1,0xFFFFFFFFFFFFFFFF ; Test both conditions (segment mode)
    cmp arg3,0              ; Test none conditions (line mode)
    jne S2DVSS2D_SKIPSA
    xor arg1,arg1   ;<-- Setting line mode
    S2DVSS2D_SKIPSA:
    cmp arg3,1                  ; Test Only 0 <= condition (ray mode)
    jne S2DVSS2D_SKIPSA_RAY
        shr arg1,32 ;<-- Setting ray mode by shifting 32 bits right
    S2DVSS2D_SKIPSA_RAY:
    and arg2,arg1
    cmp arg1,arg2
    jne _finalzero


    mov rax,1
    test arg4,arg4
    je _final
    movss [arg4],xmm0
    jmp _final
%endif

_finalzero:
    xor rax,rax
_final:
    _leave_
    ret

global AABB2CENTROID; void AABB2CENTROID (void * Destiny, void * Source, char AABB2MODE);
;*************************************************
;Given a 2D AABB, this algoritm return its center
;AABB2MODE:
;     *2 bits flag:
;     *bit 0 set the notation mode (Center+Half_extent) or (A->B)
;     *bit 1 set the subnotation mode:
;        if (A->B) (bit 0 set): (Pivot+Direction) or (Min->Max) 
;*************************************************
AABB2CENTROID:
    _enter_
        BT arg3,0 ; check if (A->B)
        jc AABB2CENTROIDCALCULATE
            ;if it's Center+Half_exntent (bit clear):
                ;Just memcpy from Source (first point) to Destiny
            mov rax,[arg2]
            mov [arg1],rax
        jmp AABB2CENTROIDEND
        AABB2CENTROIDCALCULATE:
            movups xmm1,[arg2]
            pcmpeqw xmm0,xmm0
            psllq xmm0,55
            psrlq xmm0,2
            movups xmm2,[arg2+8]

            ;xmm0 = [0.5][0.5][0.5][0.5]
            ;xmm1 = AABB.Axy 
            ;xmm2 = AABB.Bxy

            BT arg3,1 ; check if (Min->Max)
            jnc AABB2CENTROIDSKIPMINMAX
                ;if it's (bit set) Min->Max, then:
                ;   Max = Max-Min
                subps xmm2,xmm1
            AABB2CENTROIDSKIPMINMAX:

            ;xmm0 = [0.5][0.5][0.5][0.5]
            ;xmm1 = AABB.Origin
            ;xmm2 = AABB.Dimensions

            mulps xmm2,xmm0  

            ;xmm2 = AABB.Dimensions / 2.0

            addps xmm1,xmm2

            ;xmm1 = AABB.center = AABB.Center + (AABB.Dimensions / 2.0)

            movsd [arg1],xmm1

    AABB2CENTROIDEND:
    _leave_
    ret

global AABB2VSAABB2 ;char AABB2VSAABB2(void* AABB2_A,void * AABB2_B, char AABB2MODE);
;************************************************************************;
;Given two 2D AABB, this algoritm return if they intersects
;AABB2MODE:
;     *2 bits flag:
;     *bit 0 set the notation mode (Center+Half_extent) or (A->B)
;     *bit 1 set the subnotation mode:
;        if (A->B) (bit 0 set): (Pivot+Direction) or (Min->Max)
;AABB2_A Flag: 0 ~ 3
;AABB2_B Flag: 4 ~ 7
;************************************************************************;
    AABB2VSAABB2:
    _enter_
	movups xmm0,[arg1]
	
	pcmpeqw xmm4,xmm4
        psllq xmm4,55
        psrlq xmm4,2
    
	movups xmm2,[arg2]
	xor rax,rax

	pcmpeqw xmm5,xmm5
	psrld xmm5,1

	movhlps xmm1,xmm0
	BT arg3,0
	jnc AABB2VSAABB2_ACH
		BT arg3,1
		jnc AABB2VSAABB2_APD
		    subps xmm1,xmm0
		AABB2VSAABB2_APD:
		mulps xmm1,xmm4
		addps xmm0,xmm1
	AABB2VSAABB2_ACH:

	mov arg4,1

	movhlps xmm3,xmm2
	BT arg3,4
	jnc AABB2VSAABB2_BCH
		BT arg3,5
		jnc AABB2VSAABB2_BPD
		    subps xmm3,xmm2
		AABB2VSAABB2_BPD:
		mulps xmm3,xmm4
		addps xmm2,xmm3
	AABB2VSAABB2_BCH:

	subps xmm0,xmm2	
	addps xmm1,xmm3
	pand xmm0,xmm5
	
	cmpss xmm4,xmm4,0

	cmpps xmm0,xmm1,2
	movshdup xmm1,xmm0
	pand xmm0,xmm1
	ucomiss xmm0,xmm4
	cmove rax,arg4

    _leave_
    ret

global CIRCLE2VSAABB2;char CIRCLE2VSAABB2(void* CIRCLE2,void * AABB2, char AABB2MODE);
;************************************************************************;
;Given a 2D Circle and a 2D AABB, this algoritm return if they intersect
;AABB2MODE:
;     *2 bits flag:
;     *bit 0 set the notation mode (Center+Half_extent) or (A->B)
;     *bit 1 set the subnotation mode:
;        if (A->B) (bit 0 set): (Pivot+Direction) or (Min->Max)
;************************************************************************;
    CIRCLE2VSAABB2:
	_enter_
	xor rax,rax
	movss xmm2,[arg2]
	movsd xmm0,[arg1]
	
	movhlps xmm3,xmm2
        BT arg3,0
        jc AABB2VSAABB2_CH__
            BT arg3,1
            js CIRCLE2VSAABB2_AABBREADY
                addps xmm3,xmm2
                jmp CIRCLE2VSAABB2_AABBREADY
	AABB2VSAABB2_CH__:
	    movsd xmm4,xmm3
	    addps xmm3,xmm2
	    subps xmm2,xmm4
	CIRCLE2VSAABB2_AABBREADY:

 	movss xmm1,[arg1+8]
	
	movups xmm4,xmm0
	movups xmm5,xmm0
	
	mulss xmm1,xmm1

	mov arg4,1

    ;Calculate Square Distance from Center to AABB -> xmm0
	cmpps xmm5,xmm2,1
	subps xmm2,xmm0
	mulps xmm2,xmm2
	pand xmm2,xmm5

	cmpps xmm3,xmm0,1
	subps xmm4,xmm3
	mulps xmm4,xmm4
	pand xmm4,xmm3

	addps xmm2,xmm4
	movshdup xmm0,xmm2
	addss xmm0,xmm2
    ;----------------------------------------------------;
   
	ucomiss xmm0,xmm1
	cmovbe rax,arg4 
    
    _leave_
    ret

global CIRCLE2VSCIRCLE2;char CIRCLE2VSCIRCLE2(void * Circle2D_A,void * Circle2D_B);
    CIRCLE2VSCIRCLE2:
    _enter_
	xor rax,rax
	movsd xmm0,[arg1]
	movss xmm1,[arg1+8]
	mov arg4,1
	movsd xmm2,[arg2]
	movss xmm3,[arg2+8]
	subps xmm2,xmm0
	addss xmm1,xmm3
	mulps xmm2,xmm2
	movshdup xmm0,xmm2
	addss xmm2,xmm0
	sqrtss xmm2,xmm2
	ucomiss xmm2,xmm1
	cmovbe rax,arg4
    _leave_
    ret

global V2V2VSCIRCLE2
;char V2V2VSCIRCLE2 (void * LINE2D, void * Circle, char SEGRETMODE, float * Time_Return)
;***********************************************************
;Given a 2D Line (Infinite line, ray or segment) and a 2D Circle,
;This algorithm return if a collision ocurred and the collisions times
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
;***********************************************************
    V2V2VSCIRCLE2:
    _enter_
%ifidn __OUTPUT_FORMAT__, win64 
    sub rsp,16
    movups [rsp],xmm6
%endif


    movups xmm0,[arg1]
    xor rax,rax
    movsd xmm2,[arg2]
    movhlps xmm1,xmm0
    movss xmm3,[arg2+4+4]

    ;xmm0 = [0][0][Ay][Ax]
    ;xmm1 = [0][0][By][Bx]
    ;xmm2 = [0][0][Sy][Sx]
    ;xmm3[0] = sr
    
    BT arg3,0 ; check if line is (A+B) or (A->B)
    jnc V2V2VSSPHERESKIPLINESUM
        subps xmm1,xmm0
    V2V2VSSPHERESKIPLINESUM:
   
 
    movaps xmm6,xmm1
    _V2NORM_imm xmm6,xmm4
    pshufd xmm6,xmm6,0
    divps xmm1,xmm6

    shr arg3,1;arg3 = Line type
    mov arg2,arg3
    and arg2,3

    mulss xmm3,xmm3

    subps xmm0,xmm2
    
    _V2DOT_ xmm4,xmm0,xmm1,xmm5 
    _V2DOT_ xmm5,xmm0,xmm0,xmm2 
    subss xmm5,xmm3
    pxor xmm1,xmm1
    
    
    ;xmm0 = m
    ;xmm1 = [0][0][0][0]
    ;xmm4[0] = b = dot(m,d)
    ;xmm5[0] = c = dot(m,m) - (sr*sr)
    ;xmm6[0] = Direction norm
    
    ucomiss xmm5,xmm1
    jbe V2V2VSSPHERESKIPPREMATURERETURN
	ucomiss xmm4,xmm1
	jbe V2V2VSSPHERESKIPPREMATURERETURN
	    jmp V2V2VSSPHERERETURNZERO
    V2V2VSSPHERESKIPPREMATURERETURN:

    movss xmm3,xmm4
    mulss xmm3,xmm3
    subss xmm3,xmm5
    ;xmm3[0] = discr = (b*b) - c

    ucomiss xmm3,xmm1
    jb V2V2VSSPHERERETURNZERO

    sqrtss xmm3,xmm3
    
    pcmpeqw xmm2,xmm2
    pslld xmm2,31
    pxor xmm4,xmm2
    movss xmm5,xmm4 

    subss xmm4,xmm3
    addss xmm5,xmm3
    
    ;xmm4[0] = t1 = -b - sqrt(discr)
    ;xmm5[0] = t2 = -b + sqrt(discr)

    ucomiss xmm4,xmm1
    jb V2V2VSSPHERERETURNZERO
   

 
    ;check line type
    cmp arg2,0
    je V2V2VSSPHERERETURNONE

    ucomiss xmm4,xmm1
    jb V2V2VSSPHERERETURNZERO

    cmp arg2,1
    je V2V2VSSPHERERETURNONE

    ;At this point, line is a segment...
    

    ucomiss xmm4,xmm6
    ja V2V2VSSPHERERETURNZERO
     

    V2V2VSSPHERERETURNONE:
    mov rax,1

    ;Store times;
    
    divss xmm4,xmm6; <- To get the normalized time


    shr arg3,3; arg3 store type
    cmp arg4,0
    je V2V2VSSPHERESKIPSTORE
	cmp arg3,0
	je  V2V2VSSPHERESKIPSTORE
 
	xor arg2,arg2    

	bt arg3,1
	jnc V2V2VSSPHERESKIPSTORET2
	    movss xmm0,xmm5
	    pslldq xmm0,4
	    inc arg2
	V2V2VSSPHERESKIPSTORET2:

	bt arg3,0
	jnc V2V2VSSPHERESKIPSTORET1
	    movss xmm0,xmm4
	    inc arg2 
	V2V2VSSPHERESKIPSTORET1:

	cmp arg2,2
	je V2V2VSSPHERESTORETWO
	    movss [arg4],xmm0
	    jmp V2V2VSSPHERESKIPSTORE	
	V2V2VSSPHERESTORETWO:
	   movsd [arg4],xmm0

    V2V2VSSPHERESKIPSTORE:


    V2V2VSSPHERERETURNZERO:

%ifidn __OUTPUT_FORMAT__, win64 
    movups xmm6,[rsp]
    add rsp,16
%endif
    _leave_
    ret

global V2VSRANGEDLINE2;
;char V2VSRANGEDLINE2(void * V2, void * Range2_Line, char LINEMode,float Range2_Angle);
;**************************************************************************************
;Given a 2D Point and a Field of View described by a Line and a aperture angle (radians),
;This algorithm returns if the point is inside the range
;**************************************************************************************
    V2VSRANGEDLINE2:
    _enter_
%ifidn __OUTPUT_FORMAT__, win64
	movss xmm0,xmm3
%endif
	sub rsp,8

	pcmpeqw xmm4,xmm4
	pslld xmm4,25
	psrld xmm4,2	
	
	mulss xmm0,xmm4

	movss [rsp],xmm0

	pcmpeqw xmm5,xmm5
	pslld xmm5,25
	psrld xmm5,2	

	movups xmm0,[arg2] 
	xor rax,rax
	movsd xmm2,[arg1]
	movhlps xmm1,xmm0

	BT arg3,0 ; check if line is (A+B) or (A->B)
	jnc __V2VSRANGE____
	    subps xmm1,xmm0
	__V2VSRANGE____:

	subps xmm2,xmm0

	_V2DOT_ xmm0,xmm1,xmm2,xmm3
   
	fld dword [rsp]
	fcos 
	fstp dword [rsp]

	movss xmm1,[rsp]

	ucomiss xmm0,xmm5
	ja V2VSRANGE2FAIL
	    ucomiss xmm0,xmm1
	    jb V2VSRANGE2FAIL
		mov rax,1
	V2VSRANGE2FAIL:

	add rsp,8
    _leave_
    ret



global V2VSPOLY2;  char V2VSPOLY2(void * Point2D,void * 2Dverticesbuffer,unsigned int vertices count);
;********************
;Implementation of: http://geomalgorithms.com/a03-_inclusion.html#wn_PnPoly()
;********************
    V2VSPOLY2:
    _enter_
	push r10
	push r11
	xor rax,rax
	cmp arg3,3
	jb V2VSPOLY2END
	mov r10,arg2

	movss xmm3,[arg1]
	xor r11,r11
	
	
	mov arg4,arg2

	V2VSPOLY2LOOP:
	    dec arg3
	    add arg4,(4*2)
	    test arg3,arg3
	    cmovz arg4,r10

	    movss xmm0,xmm3
	    movss xmm1,[arg2]
	    movss xmm2,[arg4]
	    movshdup xmm4,xmm1
	    movshdup xmm5,xmm2

	    subps xmm2,xmm1
	    subps xmm0,xmm1
	    pshufd xmm1,xmm0,11100001b
	    mulps xmm1,xmm2
	    movshdup xmm2,xmm1
	    subss xmm1,xmm2	   
 
	    pxor xmm2,xmm2

	    movshdup xmm0,xmm3

	    
	    ucomiss xmm0,xmm4
	    ja V2VSPOLY2LOOPNOTESTNEEDED
		ucomiss xmm5,xmm4
		jna V2VSPOLY2LOOPNOTESTEND
		    ucomiss xmm1,xmm2
		    jna V2VSPOLY2LOOPNOTESTEND
			inc r11

	    jmp V2VSPOLY2LOOPNOTESTEND
	    V2VSPOLY2LOOPNOTESTNEEDED:
		ucomiss xmm5,xmm4
		ja V2VSPOLY2LOOPNOTESTEND
		    ucomiss xmm1,xmm2
		    jnb V2VSPOLY2LOOPNOTESTEND
			dec r11
	   
	    V2VSPOLY2LOOPNOTESTEND:


	    mov arg2,arg4
	test arg3,arg3
	jnz V2VSPOLY2LOOP
   
	mov arg4,1

	test r11,r11
	cmovnz rax,arg4

 
	V2VSPOLY2END:
	pop r11
	pop r10
    _leave_
    ret

%unmacro CROSSPRODUCTV2 4
%unmacro DotProductXMMV2 4
%endif
