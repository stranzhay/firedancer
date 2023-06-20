#    incq    %rsi # pc++
#    movzbl  1(%r14 %r9       # regs

#    movzwl  2(%r14 %r12d      # offset = instr.offset
#    movl    4(%r14 %ecx       # imm = instr.imm

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
#define OFFSET      %dx
#define OFFSET64    %rdx
#define BASE_PTR    %r15

#define PC_BB_BEGIN %r14
#define IC          %r11

.altmacro

.macro case_pre case_num
.set case_counter, \case_num
.p2align 5, 0x90
interp_case_\case_num:

.endm

.macro read_dst_reg
    movb 1(PC), %cl
    andq $15, DST_REG
.endm

.macro read_src_reg
    movzb 1(PC), %eax
    shrl $4, %eax
.endm

.macro read_imm
    # movq INSTR, IMM64
    # sarq $32, IMM64
    movslq 4(PC), IMM64
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
    movswq 2(PC), OFFSET64
    shlq $3, OFFSET64
   # movl %edx, %edi
    #shrl $13, %edi
    #movswq %di, OFFSET64
.endm

.macro unimplemented_instr
hlt
.endm

.macro case_post case_num
                         # pc++
    # movq    (PC), INSTR                # instr = ctx->instrs[i]

    # get opcode
    movzb   8(PC), %eax
    addq    $8,PC
    jmp     *fd_vm_interp_asm.locs(,%rax,8)
    
    .size   interp_case_\case_num, .-interp_case_\case_num
.endm

.macro skip_case
; interp_case_skip.\@:
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
    # NOTE: PC is implicitly already in the right place (%rsi, aka param1 this may change.

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
   # movq    (PC), INSTR    # instr = ctx->instrs[i]

    # get opcode
    movzbq  0(PC), %rax

    jmp     *fd_vm_interp_asm.locs(,%rax,8)

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
    read_dst_reg
    read_src_reg
    movq (REG_FILE,DST_REG,8), %rbp
    addq (REG_FILE,SRC_REG,8), %rbp
    read_src_reg
    movq %rbp, (REG_FILE,DST_REG,8)
    case_post 0x0f

    skip_case
    skip_case
    skip_case
    skip_case

    case_pre 0x14
    unimplemented_instr
    case_post 0x14

    # FD_SBPF_OP_JEQ_IMM
    case_pre 0x15
    read_dst_reg
    read_imm
    read_offset
    cmpq IMM64, (REG_FILE,DST_REG,8)
    movq $0, %rbp
    cmovneq %rbp, OFFSET64
    jump_ic
    addq OFFSET64, PC
    jump_start_bb
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

    // FD_SBPF_OP_JEQ_REG
    case_pre 0x1d
    read_dst_reg
    read_src_reg
    read_offset
    movq (REG_FILE,SRC_REG,8), %rbp
    cmpq %rbp, (REG_FILE,DST_REG,8)
    movq $0, %rbp
    cmovneq %rbp, OFFSET64
    jump_ic
    addq OFFSET64, PC
    jump_start_bb
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
    read_src_reg
    read_dst_reg
    movl    $1, %ebp
    movq    (REG_FILE,SRC_REG,8), %rdx
    testq   %rdx, %rdx
    movq (REG_FILE,DST_REG,8), %rax
    cmovnzq %rdx, %rbp
    xor     %edx, %edx
    divq    %rbp
    movq    %rdx, (REG_FILE,DST_REG,8)
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

fd_vm_interp_asm.locs:
/* 0x00 */ .quad interp_case_0x00
/* 0x01 */ .quad 0
/* 0x02 */ .quad 0
/* 0x03 */ .quad 0
/* 0x04 */ .quad interp_case_0x04
/* 0x05 */ .quad interp_case_0x05
/* 0x06 */ .quad 0
/* 0x07 */ .quad interp_case_0x07
/* 0x08 */ .quad 0
/* 0x09 */ .quad 0
/* 0x0a */ .quad 0
/* 0x0b */ .quad 0
/* 0x0c */ .quad interp_case_0x0c
/* 0x0d */ .quad 0
/* 0x0e */ .quad 0
/* 0x0f */ .quad interp_case_0x0f
/* 0x10 */ .quad 0
/* 0x11 */ .quad 0
/* 0x12 */ .quad 0
/* 0x13 */ .quad 0
/* 0x14 */ .quad interp_case_0x14
/* 0x15 */ .quad interp_case_0x15
/* 0x16 */ .quad 0
/* 0x17 */ .quad interp_case_0x17
/* 0x18 */ .quad interp_case_0x18
/* 0x19 */ .quad 0
/* 0x1a */ .quad 0
/* 0x1b */ .quad 0
/* 0x1c */ .quad interp_case_0x1c
/* 0x1d */ .quad interp_case_0x1d
/* 0x1e */ .quad 0
/* 0x1f */ .quad interp_case_0x1f
/* 0x20 */ .quad 0
/* 0x21 */ .quad 0
/* 0x22 */ .quad 0
/* 0x23 */ .quad 0
/* 0x24 */ .quad interp_case_0x24
/* 0x25 */ .quad interp_case_0x25
/* 0x26 */ .quad 0
/* 0x27 */ .quad interp_case_0x27
/* 0x28 */ .quad 0
/* 0x29 */ .quad 0
/* 0x2a */ .quad 0
/* 0x2b */ .quad 0
/* 0x2c */ .quad interp_case_0x2c
/* 0x2d */ .quad interp_case_0x2d
/* 0x2e */ .quad 0
/* 0x2f */ .quad interp_case_0x2f
/* 0x30 */ .quad 0
/* 0x31 */ .quad 0
/* 0x32 */ .quad 0
/* 0x33 */ .quad 0
/* 0x34 */ .quad interp_case_0x34
/* 0x35 */ .quad interp_case_0x35
/* 0x36 */ .quad 0
/* 0x37 */ .quad interp_case_0x37
/* 0x38 */ .quad 0
/* 0x39 */ .quad 0
/* 0x3a */ .quad 0
/* 0x3b */ .quad 0
/* 0x3c */ .quad interp_case_0x3c
/* 0x3d */ .quad interp_case_0x3d
/* 0x3e */ .quad 0
/* 0x3f */ .quad interp_case_0x3f
/* 0x40 */ .quad 0
/* 0x41 */ .quad 0
/* 0x42 */ .quad 0
/* 0x43 */ .quad 0
/* 0x44 */ .quad interp_case_0x44
/* 0x45 */ .quad interp_case_0x45
/* 0x46 */ .quad 0
/* 0x47 */ .quad interp_case_0x47
/* 0x48 */ .quad 0
/* 0x49 */ .quad 0
/* 0x4a */ .quad 0
/* 0x4b */ .quad 0
/* 0x4c */ .quad interp_case_0x4c
/* 0x4d */ .quad interp_case_0x4d
/* 0x4e */ .quad 0
/* 0x4f */ .quad interp_case_0x4f
/* 0x50 */ .quad 0
/* 0x51 */ .quad 0
/* 0x52 */ .quad 0
/* 0x53 */ .quad 0
/* 0x54 */ .quad interp_case_0x54
/* 0x55 */ .quad interp_case_0x55
/* 0x56 */ .quad 0
/* 0x57 */ .quad interp_case_0x57
/* 0x58 */ .quad 0
/* 0x59 */ .quad 0
/* 0x5a */ .quad 0
/* 0x5b */ .quad 0
/* 0x5c */ .quad interp_case_0x5c
/* 0x5d */ .quad interp_case_0x5d
/* 0x5e */ .quad 0
/* 0x5f */ .quad interp_case_0x5f
/* 0x60 */ .quad 0
/* 0x61 */ .quad interp_case_0x61
/* 0x62 */ .quad interp_case_0x62
/* 0x63 */ .quad interp_case_0x63
/* 0x64 */ .quad interp_case_0x64
/* 0x65 */ .quad interp_case_0x65
/* 0x66 */ .quad 0
/* 0x67 */ .quad interp_case_0x67
/* 0x68 */ .quad 0
/* 0x69 */ .quad interp_case_0x69
/* 0x6a */ .quad interp_case_0x6a
/* 0x6b */ .quad interp_case_0x6b
/* 0x6c */ .quad interp_case_0x6c
/* 0x6d */ .quad interp_case_0x6d
/* 0x6e */ .quad 0
/* 0x6f */ .quad interp_case_0x6f
/* 0x70 */ .quad 0
/* 0x71 */ .quad interp_case_0x71
/* 0x72 */ .quad interp_case_0x72
/* 0x73 */ .quad interp_case_0x73
/* 0x74 */ .quad interp_case_0x74
/* 0x75 */ .quad interp_case_0x75
/* 0x76 */ .quad 0
/* 0x77 */ .quad interp_case_0x77
/* 0x78 */ .quad 0
/* 0x79 */ .quad interp_case_0x79
/* 0x7a */ .quad interp_case_0x7a
/* 0x7b */ .quad interp_case_0x7b
/* 0x7c */ .quad interp_case_0x7c
/* 0x7d */ .quad interp_case_0x7d
/* 0x7e */ .quad 0
/* 0x7f */ .quad interp_case_0x7f
/* 0x80 */ .quad 0
/* 0x81 */ .quad 0
/* 0x82 */ .quad 0
/* 0x83 */ .quad 0
/* 0x84 */ .quad interp_case_0x84
/* 0x85 */ .quad interp_case_0x85
/* 0x86 */ .quad 0
/* 0x87 */ .quad interp_case_0x87
/* 0x88 */ .quad 0
/* 0x89 */ .quad 0
/* 0x8a */ .quad 0
/* 0x8b */ .quad 0
/* 0x8c */ .quad 0
/* 0x8d */ .quad interp_case_0x8d
/* 0x8e */ .quad 0
/* 0x8f */ .quad 0
/* 0x90 */ .quad 0
/* 0x91 */ .quad 0
/* 0x92 */ .quad 0
/* 0x93 */ .quad 0
/* 0x94 */ .quad interp_case_0x94
/* 0x95 */ .quad interp_case_0x95
/* 0x96 */ .quad 0
/* 0x97 */ .quad interp_case_0x97
/* 0x98 */ .quad 0
/* 0x99 */ .quad 0
/* 0x9a */ .quad 0
/* 0x9b */ .quad 0
/* 0x9c */ .quad interp_case_0x9c
/* 0x9d */ .quad 0
/* 0x9e */ .quad 0
/* 0x9f */ .quad interp_case_0x9f
/* 0xa0 */ .quad 0
/* 0xa1 */ .quad 0
/* 0xa2 */ .quad 0
/* 0xa3 */ .quad 0
/* 0xa4 */ .quad interp_case_0xa4
/* 0xa5 */ .quad interp_case_0xa5
/* 0xa6 */ .quad 0
/* 0xa7 */ .quad interp_case_0xa7
/* 0xa8 */ .quad 0
/* 0xa9 */ .quad 0
/* 0xaa */ .quad 0
/* 0xab */ .quad 0
/* 0xac */ .quad interp_case_0xac
/* 0xad */ .quad interp_case_0xad
/* 0xae */ .quad 0
/* 0xaf */ .quad interp_case_0xaf
/* 0xb0 */ .quad 0
/* 0xb1 */ .quad 0
/* 0xb2 */ .quad 0
/* 0xb3 */ .quad 0
/* 0xb4 */ .quad interp_case_0xb4
/* 0xb5 */ .quad interp_case_0xb5
/* 0xb6 */ .quad 0
/* 0xb7 */ .quad interp_case_0xb7
/* 0xb8 */ .quad 0
/* 0xb9 */ .quad 0
/* 0xba */ .quad 0
/* 0xbb */ .quad 0
/* 0xbc */ .quad interp_case_0xbc
/* 0xbd */ .quad interp_case_0xbd
/* 0xbe */ .quad 0
/* 0xbf */ .quad interp_case_0xbf
/* 0xc0 */ .quad 0
/* 0xc1 */ .quad 0
/* 0xc2 */ .quad 0
/* 0xc3 */ .quad 0
/* 0xc4 */ .quad interp_case_0xc4
/* 0xc5 */ .quad interp_case_0xc5
/* 0xc6 */ .quad 0
/* 0xc7 */ .quad interp_case_0xc7
/* 0xc8 */ .quad 0
/* 0xc9 */ .quad 0
/* 0xca */ .quad 0
/* 0xcb */ .quad 0
/* 0xcc */ .quad interp_case_0xcc
/* 0xcd */ .quad interp_case_0xcd
/* 0xce */ .quad 0
/* 0xcf */ .quad interp_case_0xcf
/* 0xd0 */ .quad 0
/* 0xd1 */ .quad 0
/* 0xd2 */ .quad 0
/* 0xd3 */ .quad 0
/* 0xd4 */ .quad interp_case_0xd4
/* 0xd5 */ .quad interp_case_0xd5
/* 0xd6 */ .quad 0
/* 0xd7 */ .quad 0
/* 0xd8 */ .quad 0
/* 0xd9 */ .quad 0
/* 0xda */ .quad 0
/* 0xdb */ .quad 0
/* 0xdc */ .quad interp_case_0xdc
/* 0xdd */ .quad interp_case_0xdd
.size fd_vm_interp_asm.locs, .-fd_vm_interp_asm.locs
