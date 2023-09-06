pub use crate::generated::{
    fd_reedsol_align, fd_reedsol_encode_abort, fd_reedsol_encode_add_data_shred,
    fd_reedsol_encode_add_parity_shred, fd_reedsol_encode_fini, fd_reedsol_encode_init,
    fd_reedsol_footprint, fd_reedsol_recover_abort, fd_reedsol_recover_add_erased_shred,
    fd_reedsol_recover_add_rcvd_shred, fd_reedsol_recover_fini, fd_reedsol_recover_init,
    fd_reedsol_strerror, fd_reedsol_t, FD_REEDSOL_ALIGN, FD_REEDSOL_DATA_SHREDS_MAX,
    FD_REEDSOL_ERR_CORRUPT, FD_REEDSOL_ERR_PARTIAL, FD_REEDSOL_FOOTPRINT,
    FD_REEDSOL_PARITY_SHREDS_MAX, FD_REEDSOL_SUCCESS,
};
use std::ffi::{c_int, c_ulong, c_void};

const SHRED_SIZE: c_ulong = 1024 * 1024;
const DATA_SHARDS: usize = 32;
const PARITY_SHARDS: usize = 32;

#[repr(transparent)]
pub struct ReedSolomon {
    inner: *mut fd_reedsol_t,
}

impl ReedSolomon {
    pub fn new(mem: *mut c_void, shred_sz: u64) -> Self {
        unsafe {
            let rs_ptr: *mut fd_reedsol_t = fd_reedsol_encode_init(mem, shred_sz);
            ReedSolomon { inner: rs_ptr }
        }
    }

    pub fn add_data_shred(&mut self, data_shred: &[u8]) {
        unsafe {
            fd_reedsol_encode_add_data_shred(self.inner, data_shred.as_ptr() as *const c_void);
        }
    }

    pub fn add_parity_shred(&mut self, parity_shred: &mut [u8]) {
        unsafe {
            fd_reedsol_encode_add_parity_shred(
                self.inner,
                parity_shred.as_mut_ptr() as *mut c_void,
            );
        }
    }

    pub fn encode_fini(&mut self) {
        unsafe {
            fd_reedsol_encode_fini(self.inner);
        }
    }

    pub fn recover_init(mem: *mut c_void, shred_size: u64) -> Self {
        unsafe {
            let rs_ptr = fd_reedsol_recover_init(mem, shred_size);
            ReedSolomon { inner: rs_ptr }
        }
    }

    pub fn add_received_shred(&mut self, is_data_shred: bool, shred: &[u8]) {
        unsafe {
            fd_reedsol_recover_add_rcvd_shred(
                self.inner,
                is_data_shred as c_int,
                shred.as_ptr() as *const c_void,
            );
        }
    }

    pub fn add_erased_shred(&mut self, is_data_shred: bool, shred: &mut [u8]) {
        unsafe {
            fd_reedsol_recover_add_erased_shred(
                self.inner,
                is_data_shred as c_int,
                shred.as_mut_ptr() as *mut c_void,
            );
        }
    }

    pub fn recover_fini(mut self) {
        unsafe {
            fd_reedsol_recover_fini(self.inner);
        }
    }
}

#[test]
fn reedsol_wrapper() {
    use rand::Rng;
    use std::ffi::{c_ulong, c_void};

    const SHRED_SIZE: c_ulong = 1024 * 1024;
    const DATA_SHARDS: usize = 16;
    const PARITY_SHARDS: usize = 48;

    let mut rng = rand::thread_rng();

    let mut mem = [0; FD_REEDSOL_FOOTPRINT as usize];
    let mut reedsol = ReedSolomon::new(mem.as_mut_ptr() as *mut c_void, SHRED_SIZE as u64);

    // Initialize data as all ones
    let mut data: Vec<u8> = vec![1; DATA_SHARDS * SHRED_SIZE as usize];
    for d in data.chunks_mut(SHRED_SIZE as usize) {
        reedsol.add_data_shred(d);
    }

    // Initialize parity as all zeros
    // Should become all ones upon encoding
    let mut parity: Vec<u8> = vec![0; PARITY_SHARDS * SHRED_SIZE as usize];
    for p in parity.chunks_mut(SHRED_SIZE as usize) {
        reedsol.add_parity_shred(p);
    }

    // Finish
    reedsol.encode_fini();

    // Save a copy of the original data and parity
    let original_data = data.clone();
    let original_parity = parity.clone();

    // Simulate data loss
    let mut data_loss_indices = Vec::new();
    for i in 0..DATA_SHARDS {
        if rng.gen_bool(0.5) {
            data[i * SHRED_SIZE as usize..(i + 1) * SHRED_SIZE as usize].fill(0);
            data_loss_indices.push(i);
        }
    }

    let mut parity_loss_indices = Vec::new();
    for i in 0..PARITY_SHARDS {
        if rng.gen_bool(0.3) {
            parity[i * SHRED_SIZE as usize..(i + 1) * SHRED_SIZE as usize].fill(0);
            parity_loss_indices.push(i);
        }
    }

    // Recovery process start
    // Initialize a new ReedSolomon instance for recovery
    let mut recoverer =
        ReedSolomon::recover_init(mem.as_mut_ptr() as *mut c_void, SHRED_SIZE as u64);

    for i in 0..DATA_SHARDS {
        if data_loss_indices.contains(&i) {
            recoverer.add_erased_shred(
                true,
                &mut data[i * SHRED_SIZE as usize..(i + 1) * SHRED_SIZE as usize],
            );
        } else {
            recoverer.add_received_shred(
                true,
                &data[i * SHRED_SIZE as usize..(i + 1) * SHRED_SIZE as usize],
            );
        }
    }

    for i in 0..PARITY_SHARDS {
        if parity_loss_indices.contains(&i) {
            recoverer.add_erased_shred(
                false,
                &mut parity[i * SHRED_SIZE as usize..(i + 1) * SHRED_SIZE as usize],
            );
        } else {
            recoverer.add_received_shred(
                false,
                &parity[i * SHRED_SIZE as usize..(i + 1) * SHRED_SIZE as usize],
            );
        }
    }

    // finish recovery
    recoverer.recover_fini();

    // assert recovery
    assert_eq!(data, original_data, "Data recovery failed");
    assert_eq!(parity, original_parity, "Parity recovery failed");
}
