use firedancer_sys::ballet::{
    fd_reedsol_encode_add_data_shred, fd_reedsol_encode_add_parity_shred, fd_reedsol_encode_fini,
    fd_reedsol_encode_init, fd_reedsol_recover_fini, ReedSolEncoder, ReedSolRecover,
    FD_REEDSOL_FOOTPRINT,
};

#[test]
fn links_correctly() {
    println!("{}", unsafe { firedancer_sys::util::fd_tile_id() });
}

// #[test]
// fn links_static_inline_correctly() {
//     println!("{:?}", unsafe {
//         firedancer_sys::tango::fd_cnc_app_laddr(std::ptr::null_mut())
//     });
// }

#[test]
fn reedsol_wrapper() {
    use std::ffi::{c_ulong, c_void};

    const SHRED_SIZE: c_ulong = 1024 * 1024;

    // Create a new encoder
    let mut encoder = ReedSolEncoder::new(SHRED_SIZE);

    // Add data and parity
    encoder.add_data();
    encoder.add_parity();

    // Finish encoding
    let result = encoder.finish();
    assert!(result.is_ok(), "Encoding failed");

    // Simulate data loss
    let mut erased_indices: Vec<(usize, usize)> = Vec::new();
    for i in 0..5 {
        let start = i * SHRED_SIZE as usize;
        let end = (i + 1) * SHRED_SIZE as usize;
        for byte in encoder.data[start..end].iter_mut() {
            *byte = 0;
        }
        erased_indices.push((start, end));
    }

    // Start recovery
    let mut recoverer = ReedSolRecover::new(SHRED_SIZE);

    // Add erased data shreds to the recoverer
    for (start, end) in &erased_indices {
        let shred = &mut encoder.data[*start..*end];
        recoverer.add_erased_shred(1, shred);
    }

    // Add received data shreds to the recoverer
    for shred in encoder.data.chunks(SHRED_SIZE as usize) {
        recoverer.add_received_shred(1, shred);
    }

    // Add received parity shreds to the recoverer
    for shred in encoder.parity.chunks(SHRED_SIZE as usize) {
        recoverer.add_received_shred(0, shred);
    }

    // Finish recovery
    let recovery_result = recoverer.finish();
    assert!(recovery_result.is_ok(), "Recovery failed");
}
