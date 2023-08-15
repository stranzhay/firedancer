#!/bin/bash

fseq0=$(fd_tango_ctl query-fseq fd1_quic_verify0.wksp:81814656 0 2>/dev/null)
echo "fsesq0=$fseq0"
fseq1=$(fd_tango_ctl query-fseq fd1_quic_verify0.wksp:162565376 0 2>/dev/null)
echo "fsesq1=$fseq1"
fseq2=$(fd_tango_ctl query-fseq fd1_quic_verify0.wksp:243316096 0 2>/dev/null)
echo "fsesq2=$fseq2"
fseq3=$(fd_tango_ctl query-fseq fd1_quic_verify0.wksp:324066816 0 2>/dev/null)
echo "fsesq3=$fseq3"

echo "FSEQ total: $(($fseq0+$fseq1+$fseq2+$fseq3))"
