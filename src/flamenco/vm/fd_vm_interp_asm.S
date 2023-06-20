#    incq    %rsi # pc++
#    movzbl  1(%r14), %r9       # regs

#    movzwl  2(%r14), %r12d      # offset = instr.offset
#    movl    4(%r14), %ecx       # imm = instr.imm

#    movl    %r9, %r8d            
#    shrq    $4, %r8               # src_reg = instr.src_reg
#    andl    $0xF, %r9d            # dst_reg = instr.dst_reg
.set case_alignment,        128
.set case_alignment_bits,   7
.set case_fill,             0x90

#define REG_FILE    %rbx
#define INSTR       %rdx
#define OPCODE      %dl
; #define IC          %rdi
#define PC          %rsi
#define CTX         %r8
#define INSTRS      %r9
#define IMM         %r10d
#define IMM64       %r10
#define SRC_REG     %rax
#define DST_REG     %rcx
#define OFFSET      %r11w
#define OFFSET64    %r11
#define BASE_PTR    %r15

#define PC_BB_BEGIN 8(%rsp)
#define IC          16(%rsp)

.altmacro

.macro case_pre case_num
.set case_counter, \case_num
.align case_alignment,case_fill
interp_case_\case_num:

.endm

.macro read_dst_reg
    movb %dh, %cl
    andq $15, DST_REG
.endm

.macro read_src_reg
    movzb %dh, %eax
    shrq $4, SRC_REG
.endm

.macro read_imm
    movq INSTR, IMM64
    sarq $32, IMM64
.endm

.macro jump_ic
    movq PC_BB_BEGIN, %rdi
    subq PC, %rdi
    negq %rdi
    addq %rdi, IC
.endm

.macro jump_start_bb
    movq PC, PC_BB_BEGIN
.endm

.macro read_offset
    movl %edx, %edi
    shrl $13, %edi
    movswq %di, OFFSET64
.endm

.macro unimplemented_instr
hlt
.endm

.macro case_post case_num
    ; incl    %edi                         # ic++
    addq    $8,PC                      # pc++
    movq    (PC), INSTR                # instr = ctx->instrs[i]

    # get opcode
    movzb   OPCODE, %eax
    
    shll    $case_alignment_bits, %eax
    addq    BASE_PTR, %rax
    jmp     *%rax
    
    .size   interp_case_\case_num, .-interp_case_\case_num
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
# Register mapping:
#   See above!
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

    subq    $24, %rsp
	.cfi_def_cfa_offset 80


    # Set up VM execution
    movq    %rdi, CTX             # ctx = param0
    # NOTE: PC is implicitly already in the right place (%rsi, aka param1), this may change.

    movq    24(CTX), INSTRS       # ctx->instrs
    leaq    48(CTX), REG_FILE     # ctx->register_file

    movq    144(CTX), %r14            # ic
    movq    %r14, IC

    shlq    $3, PC                  # PC *= 8
    addq    INSTRS, PC
    movq    PC, PC_BB_BEGIN

    movq    $interp_base_lbl,   BASE_PTR

    jmp     interp_step_lbl_no_inc

.align case_alignment,case_fill
interp_step_lbl:
    incq    IC                      # ic++
    incq    PC                      # pc++
interp_step_lbl_no_inc:
    movq    (PC), INSTR    # instr = ctx->instrs[i]

    # get opcode
    movzbq  OPCODE, %rax
    
    shlq    $case_alignment_bits, %rax
    addq    $interp_base_lbl, %rax
    jmp     *%rax

.align case_alignment,case_fill
interp_base_lbl:
    case_pre 0x00
    unimplemented_instr
    case_post 0x00

    skip_case
    skip_case
    skip_case
    
    # FD_SBPF_OP_ADD_IMM
    case_pre 0x04
    read_dst_reg
    read_imm
    addq (REG_FILE,DST_REG,8), IMM64
    movq IMM64, (REG_FILE,DST_REG,8)
    case_post 0x04

    # FD_SBPF_OP_JA
    case_pre 0x05
    read_offset
    jump_ic
    addq OFFSET64, PC
    jump_start_bb
    case_post 0x05

    skip_case

    # FD_SBPF_OP_ADD64_IMM
    case_pre 0x07
    read_dst_reg
    read_imm
    addq IMM64, (REG_FILE,DST_REG,8)
    case_post 0x07

    skip_case
    skip_case
    skip_case
    skip_case

    # FD_SBPF_OP_ADD_REG
    case_pre 0x0c
    unimplemented_instr
    case_post 0x0c

    skip_case
    skip_case 
    
    # FD_SBPF_OP_ADD64_REG
    case_pre 0x0f
    unimplemented_instr
    case_post 0x0f

    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0x14
    unimplemented_instr
    case_post 0x14

    case_pre 0x15
    unimplemented_instr
    case_post 0x15

    skip_case

    case_pre 0x17
    unimplemented_instr
    case_post 0x17

    case_pre 0x18
    unimplemented_instr
    case_post 0x18

    skip_case
    skip_case
    skip_case

    case_pre 0x1c
    unimplemented_instr
    case_post 0x1c

    case_pre 0x1d
    unimplemented_instr
    case_post 0x1d

    skip_case

    # FD_SBPF_OP_SUB64_REG
    case_pre 0x1f
    read_dst_reg
    movq (REG_FILE,DST_REG,8), %rbp
    read_src_reg
    subq (REG_FILE,SRC_REG,8), %rbp
    movq %rbp, (REG_FILE,DST_REG,8)
    case_post 0x1f

    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0x24
    unimplemented_instr
    case_post 0x24

    # FD_SBPF_OP_JGT_IMM
    case_pre 0x25
    read_dst_reg
    read_imm
    read_offset
    cmpq IMM64, (REG_FILE,DST_REG,8)
    movq $0, %rbp
    cmovbeq %rbp, OFFSET64
    jump_ic
    addq OFFSET64, PC
    jump_start_bb
    case_post 0x25

    skip_case

    case_pre 0x27
    unimplemented_instr
    case_post 0x27

    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0x2c
    unimplemented_instr
    case_post 0x2c

    case_pre 0x2d
    unimplemented_instr
    case_post 0x2d

    skip_case

    # FD_SBPF_OP_MUL64_REG
    case_pre 0x2f
    read_dst_reg
    read_src_reg
    movq (REG_FILE,DST_REG,8), %rbp
    imulq (REG_FILE,SRC_REG,8), %rbp
    read_src_reg
    movq %rbp, (REG_FILE,DST_REG,8)
    case_post 0x2f

    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0x34
    unimplemented_instr
    case_post 0x34

    case_pre 0x35
    unimplemented_instr
    case_post 0x35

    skip_case

    case_pre 0x37
    unimplemented_instr
    case_post 0x37

    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0x3c
    unimplemented_instr
    case_post 0x3c

    # FD_BPF_OP_JGE_REG
    case_pre 0x3d
    read_dst_reg
    read_src_reg
    read_offset
    movq (REG_FILE,SRC_REG,8), %rbp
    cmpq %rbp, (REG_FILE,DST_REG,8)
    movq $0, %rbp
    cmovbq %rbp, OFFSET64
    jump_ic
    addq OFFSET64, PC
    jump_start_bb
    case_post 0x3d

    skip_case

    # FD_SBPF_OP_DIV64_REG
    case_pre 0x3f
    read_src_reg
    read_dst_reg
    xor     %eax, %eax
    movl    $1, %ebp
    movq    (REG_FILE,SRC_REG,8), %rdx
    testq   %rdx, %rdx
    cmovnzq (REG_FILE,DST_REG,8), %rax
    cmovnzq %rdx, %rbp
    xor     %edx, %edx
    divq    %rbp
    movq    %rax, (REG_FILE,DST_REG,8)
    case_post 0x3f

    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0x44
    unimplemented_instr
    case_post 0x44

    case_pre 0x45
    unimplemented_instr
    case_post 0x45

    skip_case

    case_pre 0x47
    unimplemented_instr
    case_post 0x47

    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0x4c
    unimplemented_instr
    case_post 0x4c


    case_pre 0x4d
    unimplemented_instr
    case_post 0x4d

    skip_case

    case_pre 0x4f
    unimplemented_instr
    case_post 0x4f

    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0x54
    unimplemented_instr
    case_post 0x54

    # FD_SBPF_OP_JNE_IMM
    case_pre 0x55
    read_dst_reg
    read_imm
    read_offset
    cmpq IMM64, (REG_FILE,DST_REG,8)
    movq $0, %rbp
    cmoveq %rbp, OFFSET64
    jump_ic
    addq OFFSET64, PC
    jump_start_bb
    case_post 0x55

    skip_case

    case_pre 0x57
    unimplemented_instr
    case_post 0x57

    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0x5c
    unimplemented_instr
    case_post 0x5c

    case_pre 0x5d
    unimplemented_instr
    case_post 0x5d

    skip_case

    case_pre 0x5f
    unimplemented_instr
    case_post 0x5f

    skip_case

    case_pre 0x61
    unimplemented_instr
    case_post 0x61

    case_pre 0x62
    unimplemented_instr
    case_post 0x62

    case_pre 0x63
    unimplemented_instr
    case_post 0x63

    case_pre 0x64
    unimplemented_instr
    case_post 0x64

    case_pre 0x65
    unimplemented_instr
    case_post 0x65

    skip_case

    case_pre 0x67
    unimplemented_instr
    case_post 0x67

    skip_case

    case_pre 0x69
    unimplemented_instr
    case_post 0x69

    case_pre 0x6a
    unimplemented_instr
    case_post 0x6a

    case_pre 0x6b
    unimplemented_instr
    case_post 0x6b

    case_pre 0x6c
    unimplemented_instr
    case_post 0x6c

    case_pre 0x6d
    unimplemented_instr
    case_post 0x6d

    skip_case

    case_pre 0x6f
    unimplemented_instr
    case_post 0x6f

    skip_case

    case_pre 0x71
    unimplemented_instr
    case_post 0x71

    case_pre 0x72
    unimplemented_instr
    case_post 0x72

    case_pre 0x73
    unimplemented_instr
    case_post 0x73

    case_pre 0x74
    unimplemented_instr
    case_post 0x74

    case_pre 0x75
    unimplemented_instr
    case_post 0x75

    skip_case

    case_pre 0x77
    unimplemented_instr
    case_post 0x77

    skip_case

    case_pre 0x79
    unimplemented_instr
    case_post 0x79

    case_pre 0x7a
    unimplemented_instr
    case_post 0x7a

    case_pre 0x7b
    unimplemented_instr
    case_post 0x7b

    case_pre 0x7c
    unimplemented_instr
    case_post 0x7c

    case_pre 0x7d
    unimplemented_instr
    case_post 0x7d

    skip_case

    case_pre 0x7f
    unimplemented_instr
    case_post 0x7f

    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0x84
    unimplemented_instr
    case_post 0x84

    case_pre 0x85
    unimplemented_instr
    case_post 0x85

    skip_case

    case_pre 0x87
    unimplemented_instr
    case_post 0x87

    skip_case
    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0x8d
    unimplemented_instr
    case_post 0x8d

    skip_case
    skip_case
    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0x94
    unimplemented_instr
    case_post 0x94

    case_pre 0x95
    # TODO: handle call exit
    jmp interp_ret_lbl
    case_post 0x95

    skip_case

    case_pre 0x97
    unimplemented_instr
    case_post 0x97

    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0x9c
    unimplemented_instr
    case_post 0x9c

    skip_case
    skip_case

    case_pre 0x9f
    unimplemented_instr
    case_post 0x9f

    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0xa4
    unimplemented_instr
    case_post 0xa4

    case_pre 0xa5
    unimplemented_instr
    case_post 0xa5

    skip_case

    case_pre 0xa7
    unimplemented_instr
    case_post 0xa7

    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0xac
    unimplemented_instr
    case_post 0xac

    case_pre 0xad
    unimplemented_instr
    case_post 0xad

    skip_case

    case_pre 0xaf
    unimplemented_instr
    case_post 0xaf

    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0xb4
    unimplemented_instr
    case_post 0xb4

    case_pre 0xb5
    unimplemented_instr
    case_post 0xb5

    skip_case

    # FD_SBPF_OP_MOV64_IMM
    case_pre 0xb7
    read_dst_reg
    read_imm
    movq IMM64, (REG_FILE,DST_REG,8)
    case_post 0xb7

    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0xbc
    unimplemented_instr
    case_post 0xbc

    case_pre 0xbd
    unimplemented_instr
    case_post 0xbd

    skip_case

    # FD_SBPF_OP_MOV64_REG
    case_pre 0xbf
    read_src_reg
    read_dst_reg
    movq (REG_FILE,SRC_REG,8), %rbp
    movq %rbp, (REG_FILE,DST_REG,8)
    case_post 0xbf

    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0xc4
    unimplemented_instr
    case_post 0xc4

    case_pre 0xc5
    unimplemented_instr
    case_post 0xc5

    skip_case

    case_pre 0xc7
    unimplemented_instr
    case_post 0xc7

    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0xcc
    unimplemented_instr
    case_post 0xcc

    case_pre 0xcd
    unimplemented_instr
    case_post 0xcd

    skip_case

    case_pre 0xcf
    unimplemented_instr
    case_post 0xcf

    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0xd4
    unimplemented_instr
    case_post 0xd4

    case_pre 0xd5
    unimplemented_instr
    case_post 0xd5

    skip_case
    skip_case
    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0xdc
    unimplemented_instr
    case_post 0xdc

    case_pre 0xdd
    unimplemented_instr
    case_post 0xdd
interp_ret_lbl:
    shrq $3, PC
    movq PC, 136(CTX)

    shrq $3, IC
    movq IC, %r14
    movq %r14, 144(CTX)

	addq	$24, %rsp
    .cfi_def_cfa_offset 56
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
