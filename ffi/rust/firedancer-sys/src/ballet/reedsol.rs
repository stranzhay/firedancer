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

pub struct ReedSolEncoder {
    reedsol: Box<fd_reedsol_t>,
    pub data: Vec<u8>,
    pub parity: Vec<u8>,
}

impl ReedSolEncoder {
    pub fn new(shred_size: c_ulong) -> Self {
        let mut mem = Box::new([0; FD_REEDSOL_FOOTPRINT as usize]);
        let reedsol =
            unsafe { fd_reedsol_encode_init(Box::into_raw(mem) as *mut c_void, shred_size) };

        Self {
            reedsol: unsafe { Box::from_raw(reedsol) },
            data: vec![1; DATA_SHARDS * shred_size as usize],
            parity: vec![0; PARITY_SHARDS * shred_size as usize],
        }
    }

    pub fn add_data(&mut self) {
        for d in self.data.chunks_mut(SHRED_SIZE as usize) {
            unsafe {
                fd_reedsol_encode_add_data_shred(
                    self.reedsol.as_mut(),
                    d.as_mut_ptr() as *mut c_void,
                )
            };
        }
    }

    pub fn add_parity(&mut self) {
        for p in self.parity.chunks_mut(SHRED_SIZE as usize) {
            unsafe {
                fd_reedsol_encode_add_parity_shred(
                    self.reedsol.as_mut(),
                    p.as_mut_ptr() as *mut c_void,
                )
            };
        }
    }

    pub fn finish(&mut self) -> Result<(), &'static str> {
        unsafe { fd_reedsol_encode_fini(self.reedsol.as_mut() as *mut fd_reedsol_t) };

        if !self.parity.iter().all(|p| *p == 1) {
            Err("Failed to encode properly")
        } else {
            Ok(())
        }
    }
}

pub struct ReedSolRecover {
    rs: Box<fd_reedsol_t>,
}

impl ReedSolRecover {
    pub fn new(shred_size: c_ulong) -> Self {
        let mut mem = Box::new([0; FD_REEDSOL_FOOTPRINT as usize]);
        let rs = unsafe { fd_reedsol_recover_init(Box::into_raw(mem) as *mut c_void, shred_size) };
        Self {
            rs: unsafe { Box::from_raw(rs) },
        }
    }

    pub fn add_erased_shred(&mut self, flag: c_int, shred: &mut [u8]) {
        unsafe {
            fd_reedsol_recover_add_erased_shred(
                self.rs.as_mut() as *mut _,
                flag,
                shred.as_mut_ptr() as *mut c_void,
            )
        };
    }

    pub fn add_received_shred(&mut self, flag: c_int, shred: &[u8]) {
        unsafe {
            fd_reedsol_recover_add_rcvd_shred(
                self.rs.as_mut() as *mut _,
                flag,
                shred.as_ptr() as *const c_void,
            )
        };
    }

    pub fn finish(self) -> Result<(), &'static str> {
        let result = unsafe { fd_reedsol_recover_fini(Box::into_raw(self.rs)) };
        match result {
            x if x == FD_REEDSOL_SUCCESS as i32 => Ok(()),
            x if x == FD_REEDSOL_ERR_CORRUPT as i32 => Err("Data is corrupted"),
            x if x == FD_REEDSOL_ERR_PARTIAL as i32 => Err("Partial recovery"),
            _ => Err("Unknown error"),
        }
    }
}
