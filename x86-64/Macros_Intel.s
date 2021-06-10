.intel_syntax
.macro _enter_
    push %rbp
    mov %rbp, %rsp
.endm

.macro _leave_
    mov %rsp, %rbp
    pop %rbp
.endm



.macro args_reset

    .ifdef _WIN64_
	.set arg1, %rcx
	.set arg2, %rdx
	.set arg3, %r8
	.set arg4, %r9
	.set arg5, %r10
	.set arg6, %r11
	.set return,%rax
    .else
	.set arg1, %rdi
	.set arg2, %rsi
	.set arg3, %rdx
	.set arg4, %rcx
	.set arg5, %r8
	.set arg6, %r9
	.set return,%rax
    .endif

    .set arg1f, %xmm0
    .set arg2f, %xmm1
    .set arg3f, %xmm2
    .set arg4f, %xmm3
    .set arg5f, %xmm4
    .set arg6f, %xmm5
    .set arg7f, %xmm6
    .set returnf, %xmm0

.endm

args_reset



