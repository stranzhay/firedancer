.set case_alignment,        64
.set case_alignment_bits,   6
.set case_fill,             0xF4

.altmacro

.macro case_pre case_num
.set case_counter, \case_num
.align case_alignment,case_fill
interp_case_\case_num:

.endm

.macro read_imm
    ; movl    4(%r14), %ecx       # imm = instr.imm
.endm

.macro read_offset
    ; movzwl  2(%r14), %r12d       # offset = instr.offset
.endm

.macro goto_instr

.endm

.macro unimplemented_instr
hlt
.endm

.macro case_post
    jmp interp_step_lbl
.endm

.macro skip_case

.align case_alignment,case_fill
interp_case_skip.\@:
    .space case_alignment,case_fill
.endm

.text
.globl	fd_vm_interp_asm
.type	fd_vm_interp_asm,@function
.align	32
# Register mapping:m
#   Caller saved:
#       rdi:    ctx
#       rsi:    pc
#       r10:    ic
#       rcx:    imm
#       rbx:    reg_file
#       r8:     src_reg
#       r9:     dst_reg
#       r12:    offset
#       r13:    (scratch)
#       r14:    instr
#       r15:    (scratch)
fd_vm_interp_asm:
    .cfi_startproc
    pushq %r12
    .cfi_def_cfa_offset 16
    .cfi_offset 12, -16
    
    pushq %r13
    .cfi_def_cfa_offset 24
    .cfi_offset 13, -24
    
    pushq %r14
    .cfi_def_cfa_offset 32
    .cfi_offset 14, -32
    
    pushq %r15
    .cfi_def_cfa_offset 40
    .cfi_offset 15, -40
    
    pushq %rbx
    .cfi_def_cfa_offset 48
    .cfi_offset 3, -48
    
    pushq %rbp
    .cfi_def_cfa_offset 56
    .cfi_offset 6, -56

    movq    %rdi, %rbx             # ctx->register_file
    addq    $48, %rbx

    movq    144(%rdi), %r10        # ic

    movq    24(%rdi), %r13          # ctx->instrs
    leaq    (%r13,%rsi,8), %r14     # &ctx->instrs[i]

    
    movzbl  1(%r14), %ebp           # regs
    movl    %ebp, %r8d            
    shrq    $4, %r8                 # src_reg = instr.src_reg
    andl    $0xF, %ebp              # dst_reg = instr.dst_reg
  
    movzbl	(%r14), %eax	        # get opcode
    shlq    $case_alignment_bits, %rax
    addq    $interp_base_lbl, %rax

    movl    4(%r14), %ecx           # imm = instr.imm
    movzwl  2(%r14), %r12d          # offset = instr.offset
    jmp     *%rax


.align case_alignment,case_fill
interp_step_lbl:
    incq    %r10 # ic++
    incq    %rsi # pc++
    movq    24(%rdi), %r13         # ctx->instrs
    leaq    (%r13,%rsi,8), %r14    # &ctx->instrs[i]

    movq	(%r14), %rax	         # get opcode
    movzbl  1(%r14), %r9       # regs
    movzwl  2(%r14), %r12d      # offset = instr.offset
    movl    4(%r14), %ecx       # imm = instr.imm

    movl    %r9, %r8d            
    shrq    $4, %r8               # src_reg = instr.src_reg
    andl    $0xF, %r9d            # dst_reg = instr.dst_reg

    shrq
    shlq    $case_alignment_bits, %rax
    addq    $interp_base_lbl, %rax
    jmp     *%rax

.align case_alignment,case_fill
interp_base_lbl:
    case_pre 0x00
    unimplemented_instr
    case_post

    skip_case
    skip_case
    skip_case
    
    # FD_SBPF_OP_ADD_IMM
    case_pre 0x04
    read_imm
    addl (%rbx,%r9,8), %ecx
    movq %rcx, (%rbx,%r9,8)
    case_post

    # FD_SBPF_OP_JA
    case_pre 0x05
    read_offset
    movswq %r12w, %rax
    addq %rax, %rsi
    case_post

    skip_case

    # FD_SBPF_OP_ADD64_IMM
    case_pre 0x07
    read_imm
    addq %rcx, (%rbx,%r9,8)
    case_post

    skip_case
    skip_case
    skip_case
    skip_case

    # FD_SBPF_OP_ADD_REG
    case_pre 0x0c
    unimplemented_instr
    case_post

    skip_case
    skip_case 
    
    # FD_SBPF_OP_ADD64_REG
    case_pre 0x0f
    unimplemented_instr
    case_post

    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0x14
    unimplemented_instr
    case_post

    case_pre 0x15
    unimplemented_instr
    case_post

    skip_case

    case_pre 0x17
    unimplemented_instr
    case_post

    case_pre 0x18
    unimplemented_instr
    case_post

    skip_case
    skip_case
    skip_case

    case_pre 0x1c
    unimplemented_instr
    case_post

    case_pre 0x1d
    unimplemented_instr
    case_post

    skip_case

    # FD_SBPF_OP_SUB64_REG
    case_pre 0x1f
    leaq (%rbx,%r9,8), %rdx
    movq (%rdx), %rax
    subq (%rbx,%r8,8), %rax
    movq %rax, (%rdx)
    case_post

    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0x24
    unimplemented_instr
    case_post

    # FD_SBPF_OP_JGT_IMM
    case_pre 0x25
    cmpq %rcx, (%rbx,%r9,8)
    movl $0, %eax
    cmovbel %eax, %r12d
    movswq %r12w, %rax
    addq %rax, %rsi
    case_post

    skip_case

    case_pre 0x27
    unimplemented_instr
    case_post

    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0x2c
    unimplemented_instr
    case_post

    case_pre 0x2d
    unimplemented_instr
    case_post

    skip_case

    # FD_SBPF_OP_MUL64_REG
    case_pre 0x2f
    leaq (%rbx,%r9,8), %rdx
    movq (%rdx), %rax
    imulq (%rbx,%r8,8), %rax
    movq %rax, (%rdx)
    case_post

    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0x34
    unimplemented_instr
    case_post


    case_pre 0x35
    unimplemented_instr
    case_post

    skip_case

    case_pre 0x37
    unimplemented_instr
    case_post

    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0x3c
    unimplemented_instr
    case_post

    # FD_BPF_OP_JGE_REG
    case_pre 0x3d
    movq (%rbx,%r8,8), %rdx
    cmpq %rdx, (%rbx,%r9,8)
    movl $0, %eax
    read_offset
    cmovbl %eax, %r12d
    movswq %r12w, %rax
    addq %rax, %rsi
    case_post

    skip_case

    # FD_SBPF_OP_DIV64_REG
    case_pre 0x3f
    movq    (%rbx,%r8,8), %rax # src_reg
    movq    (%rbx,%r9,8), %r15 # dst_reg
    movq    $0, %rdx
    movq    $1, %r13

    testq   %rax, %rax
    cmovzq  %rdx, %rax
    cmovzq  %r13, %r15
    divq    %r15
    movq    %rax, (%rbx,%r9,8)
    case_post

    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0x44
    unimplemented_instr
    case_post

    case_pre 0x45
    unimplemented_instr
    case_post

    skip_case

    case_pre 0x47
    unimplemented_instr
    case_post

    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0x4c
    unimplemented_instr
    case_post


    case_pre 0x4d
    unimplemented_instr
    case_post

    skip_case

    case_pre 0x4f
    unimplemented_instr
    case_post

    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0x54
    unimplemented_instr
    case_post

    # FD_SBPF_OP_JNE_IMM
    case_pre 0x55
    read_imm
    cmpq %rcx, (%rbx,%r9,8)
    movl $0, %eax

    read_offset
    cmovel %eax, %r12d
    movswq %r12w, %rax
    addq %rax, %rsi
    case_post

    skip_case

    case_pre 0x57
    unimplemented_instr
    case_post

    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0x5c
    unimplemented_instr
    case_post

    case_pre 0x5d
    unimplemented_instr
    case_post

    skip_case

    case_pre 0x5f
    unimplemented_instr
    case_post

    skip_case

    case_pre 0x61
    unimplemented_instr
    case_post

    case_pre 0x62
    unimplemented_instr
    case_post

    case_pre 0x63
    unimplemented_instr
    case_post


    case_pre 0x64
    unimplemented_instr
    case_post


    case_pre 0x65
    unimplemented_instr
    case_post

    skip_case

    case_pre 0x67
    unimplemented_instr
    case_post

    skip_case

    case_pre 0x69
    unimplemented_instr
    case_post

    case_pre 0x6a
    unimplemented_instr
    unimplemented_instr
    case_post


    case_pre 0x6b
    unimplemented_instr
    case_post

    case_pre 0x6c
    unimplemented_instr
    case_post

    case_pre 0x6d
    unimplemented_instr
    case_post

    skip_case

    case_pre 0x6f
    unimplemented_instr
    case_post

    skip_case

    case_pre 0x71
    unimplemented_instr
    case_post

    case_pre 0x72
    unimplemented_instr
    case_post

    case_pre 0x73
    unimplemented_instr
    case_post

    case_pre 0x74
    unimplemented_instr
    case_post

    case_pre 0x75
    unimplemented_instr
    case_post

    skip_case

    case_pre 0x77
    unimplemented_instr
    case_post

    skip_case

    case_pre 0x79
    unimplemented_instr
    case_post

    case_pre 0x7a
    unimplemented_instr
    case_post

    case_pre 0x7b
    unimplemented_instr
    case_post

    case_pre 0x7c
    unimplemented_instr
    case_post

    case_pre 0x7d
    unimplemented_instr
    case_post

    skip_case

    case_pre 0x7f
    unimplemented_instr
    case_post

    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0x84
    unimplemented_instr
    case_post

    case_pre 0x85
    unimplemented_instr
    case_post

    skip_case

    case_pre 0x87
    unimplemented_instr
    case_post

    skip_case
    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0x8d
    unimplemented_instr
    case_post

    skip_case
    skip_case
    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0x94
    unimplemented_instr
    case_post

    case_pre 0x95
    # TODO: handle call exit
    jmp interp_ret_lbl
    case_post

    skip_case

    case_pre 0x97
    unimplemented_instr
    case_post

    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0x9c
    unimplemented_instr
    case_post

    skip_case
    skip_case

    case_pre 0x9f
    unimplemented_instr
    case_post

    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0xa4
    unimplemented_instr
    case_post

    case_pre 0xa5
    unimplemented_instr
    case_post

    skip_case

    case_pre 0xa7
    unimplemented_instr
    case_post

    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0xac
    unimplemented_instr
    case_post

    case_pre 0xad
    unimplemented_instr
    case_post

    skip_case

    case_pre 0xaf
    unimplemented_instr
    case_post

    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0xb4
    unimplemented_instr
    case_post

    case_pre 0xb5
    unimplemented_instr
    case_post

    skip_case

    # FD_SBPF_OP_MOV64_IMM
    case_pre 0xb7
    movq %rcx, (%rbx,%r9,8)
    case_post

    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0xbc
    unimplemented_instr
    case_post

    case_pre 0xbd
    unimplemented_instr
    case_post

    skip_case

    # FD_SBPF_OP_MOV64_REG
    case_pre 0xbf
    movq (%rbx,%r8,8), %rax
    movq %rax, (%rbx,%r9,8)
    case_post

    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0xc4
    unimplemented_instr
    case_post

    case_pre 0xc5
    unimplemented_instr
    case_post

    skip_case

    case_pre 0xc7
    unimplemented_instr
    case_post

    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0xcc
    unimplemented_instr
    case_post

    case_pre 0xcd
    unimplemented_instr
    case_post

    skip_case

    case_pre 0xcf
    unimplemented_instr
    case_post

    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0xd4
    unimplemented_instr
    case_post

    case_pre 0xd5
    unimplemented_instr
    case_post

    skip_case
    skip_case
    skip_case
    skip_case
    skip_case
    skip_case
    case_pre 0xdc
    unimplemented_instr
    case_post
    case_pre 0xdd
    unimplemented_instr
    case_post
interp_ret_lbl:
    movq %r10, 144(%rdi)

    popq %rbp
    .cfi_def_cfa_offset 48
    popq %rbx
    .cfi_def_cfa_offset 40
    popq %r15
    .cfi_def_cfa_offset 32
    popq %r14
    .cfi_def_cfa_offset 24
    popq %r13
    .cfi_def_cfa_offset 16
    popq %r12
    .cfi_def_cfa_offset 8
    ret
    .cfi_endproc
    .size fd_vm_interp_asm, .-fd_vm_interp_asm
