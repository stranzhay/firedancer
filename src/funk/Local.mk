$(call make-lib,fd_funk)
$(call add-hdrs,fd_funk_base.h fd_funk_txn.h fd_funk.h)
$(call add-objs,fd_funk_base fd_funk_txn fd_funk,fd_funk)
$(call make-unit-test,test_funk_base,test_funk_base,fd_funk fd_util)
$(call make-unit-test,test_funk_txn,test_funk_txn,fd_funk fd_util)
$(call make-unit-test,test_funk,test_funk,fd_funk fd_util)
$(call run-unit-test,test_funk_base,)
$(call run-unit-test,test_funk_txn,)
$(call run-unit-test,test_funk,)