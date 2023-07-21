$(call add-hdrs,fd_stakes.h)
$(call add-objs,fd_stakes,fd_flamenco)
$(call make-bin,fd_stakes_from_snapshot,fd_stakes_from_snapshot,fd_flamenco fd_ballet fd_util)
