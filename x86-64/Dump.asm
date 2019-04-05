
global M4ORTHOPAN
;void M4ORTHOPAN(void * Result, void * Matrix,void * vec3_Axis);
;******************************************************************************************
; Given an Orthogonal Matrix made with M4ORTHO, this function moves it along the given axis
;******************************************************************************************
M4ORTHOPAN:
    _enter_
%ifidn __OUTPUT_FORMAT__, win64 
    ;sub rsp,16*2
    ;movups [rsp],xmm6
    ;movups [rsp+16],xmm7
%endif

    movups xmm0,[arg2]
	    
    movups xmm1,[arg2+16]

    movups xmm2,[arg2+16+16]

	    test arg1,arg1
	    cmovz arg1,arg2

    _loadvec3_ xmm3,arg3,xmm5	

	    test arg1,arg2
	    jnz RESULTISNULL
		movntps [arg1],xmm0
		movntps [arg1+16],xmm1
		movntps [arg1+16+16],xmm2
	    RESULTISNULL:


    psrldq xmm1,4
    psrldq xmm2,8

    movups xmm4,[arg2+16+16+16]

    ;xmm0 = [?][?][?][2/(Der-Izq)]	= W
    ;xmm1 = [?][?][?][2/(Top-Bottom)]	= H
    ;xmm2 = [?][?][?][-2 /(Far-Near)]	= D
    ;xmm3 = [0][Z][Y][X]
    ;xmm4 = [1][MZ][MY][MX]
 
    unpcklps xmm0,xmm1
    movlhps xmm0,xmm2 
    

    ;xmm0 = [0][D][H][W]
    ;xmm3 = [0][-Z][-Y][X]

    
    mulps xmm3,xmm0

    ;xmm3 = [0.0][(D*Z)][(H*Y)][(W*X)]

    addps xmm3,xmm4

    ;xmm3 = [1.0][MZ+(D*Z)][MY+(H*Y)][MX+(W*X)]
   
	    movntps [arg1+16+16+16],xmm3

    
    
%ifidn __OUTPUT_FORMAT__, win64 
    ;movups xmm6,[rsp]
    ;movups xmm7,[rsp+16]
    ;add rsp, 16*2
    args_reset
%endif

    _leave_
    ret 