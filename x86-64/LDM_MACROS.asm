
%ifndef _LD_M_MACROS_64_ASM_
%define _LD_M_MACROS_64_ASM_

;*****************************
;MACROS
;*****************************

%define _FRAMESTACKPOINTER_

%macro _enter_ 0
%ifdef _FRAMESTACKPOINTER_ 
    push rbp
    mov rbp, rsp
%endif 
%endmacro

%macro _leave_ 0
%ifdef _FRAMESTACKPOINTER_ 
    mov rsp, rbp
    pop rbp
%endif
%endmacro


%macro args_reset 0
    %ifidn __OUTPUT_FORMAT__, elf64 
        %define arg1 RDI
        %define arg2 RSI
        %define arg3 RDX
        %define arg4 RCX
        %define arg5 R8
        %define arg6 R9 
    %elifidn __OUTPUT_FORMAT__, win64
        %define arg1 RCX
        %define arg2 RDX
        %define arg3 R8
        %define arg4 R9
        %define arg5 [rbp+(8*5)]
        %define arg6 [rbp+(8*5)+8]
    %endif
    %define arg1f XMM0
    %define arg2f XMM1
    %define arg3f XMM2
    %define arg4f XMM3
    %define arg5f XMM4
    %define arg6f XMM5
    %define arg7f XMM6
    %define arg8f XMM7
%endmacro
args_reset ;<--Sets arguments definitions to normal, as it's definitions can change.

%macro _loadimm32_ 3
;%1 Destiny XMM Operand (float)
;%2 imm32 to load into the XMM Register
;%3 Temporal Integer Register
    mov %3,%2
    movd %1,%3
%endmacro 

%macro _fillimm32_ 3
;%1 Destiny XMM Operand (128 bits)
;%2 imm32 to load into the XMM Register
;%3 Temporal Integer Register
    _loadimm32_ %1,%2,%3
    pshufd %1,%1,0
%endmacro

%macro _loadsignbit32_ 1
;%1 Desinty XMM Operand (float)
    pcmpeqw %1,%1
    pslld %1,31
    
%endmacro



%endif
