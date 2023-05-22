$(call make-lib,fd_vm)
$(call add-hdrs,fd_instr.h fd_log_collector.h fd_opcodes.h fd_mem_map.h fd_sbpf_interp.h fd_syscalls.h fd_sbpf_disasm.h)
$(call add-objs,fd_log_collector fd_sbpf_interp fd_mem_map fd_stack fd_syscalls fd_sbpf_disasm,fd_vm)
$(call make-bin,fd_sbpf_tool,fd_sbpf_tool,fd_vm fd_ballet fd_util)
$(call make-unit-test,test_interp,test_interp,fd_vm fd_ballet fd_util)