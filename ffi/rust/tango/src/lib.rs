use std::{
    ffi::CString,
    hint::spin_loop,
    mem::{transmute, self},
    ops::Not,
    ptr, sync::atomic::{Ordering, compiler_fence}, os::raw::c_int,
};
use anyhow::{
    anyhow,
    Result,
};
use chrono::Utc;
use firedancer_sys::{
    tango::{
        fd_chunk_to_laddr_const,
        fd_dcache_join,
        fd_frag_meta_seq_query,
        fd_mcache_depth,
        fd_mcache_join,
        fd_mcache_line_idx,
        fd_mcache_seq_laddr_const,
        fd_mcache_seq_query,
        fd_tempo_lazy_default, fd_fseq_join, fd_fseq_app_laddr, FD_FSEQ_DIAG_PUB_CNT, FD_FSEQ_DIAG_PUB_SZ, FD_FSEQ_DIAG_FILT_CNT, FD_FSEQ_DIAG_FILT_SZ, FD_FSEQ_DIAG_OVRNP_CNT, FD_FSEQ_DIAG_OVRNR_CNT, FD_FSEQ_DIAG_SLOW_CNT,
    },
    util::{
        fd_pod_query_subpod,
        fd_wksp_containing,
        fd_wksp_pod_attach,
        fd_wksp_pod_map, fd_wksp_map, fd_boot,
    },
};
use libc::c_char;
use rand::prelude::*;

/// Tango exposes a simple API for consuming from a Tango mcache/dcache queue.
/// This is an unreliable consumer: if the producer overruns the consumer, the 
/// consumer will skip data to catch up with the producer.
struct Tango {
    /// Configuration
    // TODO: proper config, for now hard-code mcache and dcache
    mcache: String,
    dcache: String,
    fseq: String,
}

impl Tango {
    pub unsafe fn run(&self) -> Result<()> {
        // Boot up the Firedancer tile        
        let mut argv = get_strings(&mut c_int::from(2));
        fd_boot(&mut c_int::from(2), &mut argv);

        // Join the mcache
        let mcache = fd_mcache_join(fd_wksp_map(
            CString::new(self.mcache.clone())?.as_ptr(),
        ));
        mcache
            .is_null()
            .not()
            .then(|| ())
            .ok_or(anyhow!("fd_mcache_join failed"))?;

        // Join the dcache
        let dcache = fd_dcache_join( fd_wksp_map(
            CString::new(self.dcache.clone())?.as_ptr(),
        ));
        dcache
            .is_null()
            .not()
            .then(|| ())
            .ok_or(anyhow!("fd_dcache_join failed"))?;

        // Look up the mline cache line
        let depth = fd_mcache_depth(mcache);
        let sync = fd_mcache_seq_laddr_const(mcache);
        let mut seq = fd_mcache_seq_query(sync);
        let mut mline = mcache.add(fd_mcache_line_idx(seq, depth).try_into().unwrap());
        
        // Join the workspace
        let workspace = fd_wksp_containing(transmute(mline));
        workspace
            .is_null()
            .not()
            .then(|| ())
            .ok_or(anyhow!("fd_wksp_containing failed"))?;

        // Hook up to flow control diagnostics
        let fseq = fd_fseq_join( fd_wksp_map( CString::new(self.fseq.clone())?.as_ptr() ) );
        fseq
            .is_null()
            .not()
            .then(|| ())
            .ok_or(anyhow!("fd_fseq_join failed"))?;
        let fseq_diag = fd_fseq_app_laddr( fseq ) as *mut u64;

        let mut accum_pub_cnt: u64 = 0;
        let mut accum_pub_sz: u64 = 0;
        let mut accum_ovrnp_cnt: u64 = 0;
        let mut accum_ovrnr_cnt: u64 = 0;

        compiler_fence(Ordering::AcqRel);
        fseq_diag.add(FD_FSEQ_DIAG_PUB_CNT.try_into().unwrap()).write_volatile(accum_pub_cnt);
        fseq_diag.add(FD_FSEQ_DIAG_PUB_SZ.try_into().unwrap()).write_volatile(accum_pub_sz);
        fseq_diag.add(FD_FSEQ_DIAG_FILT_CNT.try_into().unwrap()).write_volatile(0);
        fseq_diag.add(FD_FSEQ_DIAG_FILT_SZ.try_into().unwrap()).write_volatile(0);
        fseq_diag.add(FD_FSEQ_DIAG_OVRNP_CNT.try_into().unwrap()).write_volatile(accum_ovrnp_cnt);
        fseq_diag.add(FD_FSEQ_DIAG_OVRNR_CNT.try_into().unwrap()).write_volatile(accum_ovrnr_cnt);
        fseq_diag.add(FD_FSEQ_DIAG_SLOW_CNT.try_into().unwrap()).write_volatile(0);
        compiler_fence(Ordering::AcqRel);

        // Set frequency of houskeeping operations
        let mut next_housekeeping = Utc::now().timestamp_nanos();
        let housekeeping_interval_ns = fd_tempo_lazy_default(depth);
        let mut rng = rand::thread_rng();

        // TODO: cleanup: fd_kill, leave shared memory objects

        // Continually consume data from the queue
        loop {
            // Do housekeeping at intervals
            let now = Utc::now().timestamp_nanos();
            if now >= next_housekeeping {
                compiler_fence(Ordering::AcqRel);
                fseq_diag.add(FD_FSEQ_DIAG_PUB_CNT.try_into().unwrap()).write_volatile(accum_pub_cnt);
                fseq_diag.add(FD_FSEQ_DIAG_PUB_SZ.try_into().unwrap()).write_volatile(accum_pub_sz);
                fseq_diag.add(FD_FSEQ_DIAG_OVRNP_CNT.try_into().unwrap()).write_volatile(accum_ovrnp_cnt);
                fseq_diag.add(FD_FSEQ_DIAG_OVRNR_CNT.try_into().unwrap()).write_volatile(accum_ovrnr_cnt);
                compiler_fence(Ordering::AcqRel);

                next_housekeeping =
                    now + rng.gen_range(housekeeping_interval_ns..=2 * housekeeping_interval_ns)                
            }

            // Overrun check
            let seq_found = fd_frag_meta_seq_query(mline);
            if seq_found != seq {
                // Check to see if we have caught up to the producer - if so, wait
                if seq_found < seq {
                    spin_loop();
                    continue;
                }

                // We were overrun by the producer. Keep processing from the new sequence number.
                accum_ovrnp_cnt += 1;
                seq = seq_found;
            }

            // Speculatively copy data out of dcache
            let chunk = fd_chunk_to_laddr_const(
                transmute(workspace),
                (*mline).__bindgen_anon_1.as_ref().chunk.into(),
            ) as *const u8;
            let size = (*mline).__bindgen_anon_1.as_ref().sz;
            let mut bytes = Vec::with_capacity(size.into());
            ptr::copy_nonoverlapping(chunk, bytes.as_mut_ptr(), size.into());
            bytes.set_len(size.into());

            // Check the producer hasn't overran us while we were copying the data
            let seq_found = fd_frag_meta_seq_query(mline);
            if seq_found != seq {
                accum_ovrnr_cnt += 1;
                seq = seq_found;
                continue;
            }

            accum_pub_cnt += 1;
            accum_pub_sz += bytes.len() as u64;

            println!("received data");

            // Update seq and mline
            seq += 1;
            mline = mcache.add(fd_mcache_line_idx( seq, depth ).try_into().unwrap());

            // TODO: send the data on the channel
            // TODO: pop extra two bytes off (tx size, labs stage only accepts raw payloads)
            // self.output.send(bytes)?;
        }
    }
}

unsafe fn get_strings(outlen: *mut c_int) -> *mut *mut c_char {
    let mut v = vec![];

    // Let's fill a vector with null-terminated strings
    v.push(CString::new("--tile-cpus").unwrap());
    v.push(CString::new("0").unwrap());

    // Turning each null-terminated string into a pointer.
    // `into_raw` takes ownershop, gives us the pointer and does NOT drop the data.
    let mut out = v
        .into_iter()
        .map(|s| s.into_raw())
        .collect::<Vec<_>>();

    // Make sure we're not wasting space.
    out.shrink_to_fit();
    assert!(out.len() == out.capacity());

    // Get the pointer to our vector.
    let len = out.len();
    let ptr = out.as_mut_ptr();
    mem::forget(out);

    // Let's write back the length the caller can expect
    ptr::write(outlen, len as c_int);
    
    // Finally return the data
    ptr
}

#[test]
fn test_basic_tango_consumer() {
    // FIXME: trying to open /.gigantic/test_ipc
    //        not            /mnt/.fd/.gigantic/test_ipc
    // Should be 
    let tango = Tango {
        mcache: "test_ipc:2101248".to_string(),
        dcache: "test_ipc:3158016".to_string(),
        fseq: "test_ipc:57696256".to_string(),
    };
    unsafe {
        tango.run().expect("consuming data");
    }
}
