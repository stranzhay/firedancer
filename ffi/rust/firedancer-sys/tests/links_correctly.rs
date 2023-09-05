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
    use rand::Rng;
    use std::ffi::{c_ulong, c_void};

    const SHRED_SIZE: c_ulong = 1024 * 1024;
    const DATA_SHARDS: usize = 32;
    const PARITY_SHARDS: usize = 32;

    let mut rng = rand::thread_rng();
    let d_cnt = DATA_SHARDS;
    let p_cnt = PARITY_SHARDS;
    let shred_size = SHRED_SIZE as usize;

    // Create a new encoder
    let mut encoder = ReedSolEncoder::new(SHRED_SIZE);

    // Add data and parity
    encoder.add_data();
    encoder.add_parity();

    // Finish encoding
    let result = encoder.finish();
    assert!(result.is_ok(), "Encoding failed");

    // Simulate data loss
    for e_cnt in 0..=p_cnt + 1 {
        let mut erased_truth = Vec::new();
        let mut erased_cnt = 0;

        let mut recoverer = ReedSolRecover::new(SHRED_SIZE);

        let mut encoder = ReedSolEncoder::new(SHRED_SIZE);
        encoder.add_data();
        encoder.add_parity();

        for i in 0..d_cnt {
            if rng.gen_range(0..(d_cnt + p_cnt - i)) < (e_cnt - erased_cnt) {
                erased_truth.push(encoder.data[i * shred_size..(i + 1) * shred_size].to_vec());
                recoverer.add_erased_shred(
                    1,
                    &mut encoder.data[erased_cnt * shred_size..(erased_cnt + 1) * shred_size],
                );
                erased_cnt += 1;
            } else {
                recoverer
                    .add_received_shred(1, &encoder.data[i * shred_size..(i + 1) * shred_size]);
            }
        }

        for i in 0..p_cnt {
            if rng.gen_range(0..(p_cnt - i)) < (e_cnt - erased_cnt) {
                erased_truth.push(encoder.parity[i * shred_size..(i + 1) * shred_size].to_vec());
                recoverer.add_erased_shred(
                    0,
                    &mut encoder.parity[erased_cnt * shred_size..(erased_cnt + 1) * shred_size],
                );
                erased_cnt += 1;
            } else {
                recoverer
                    .add_received_shred(0, &encoder.parity[i * shred_size..(i + 1) * shred_size]);
            }
        }

        assert_eq!(erased_cnt, e_cnt);

        let retval = recoverer.finish();

        if e_cnt > p_cnt {
            assert_eq!(retval, Err("Partial recovery"));
            continue;
        }

        assert_eq!(retval, Ok(()));

        for i in 0..e_cnt {
            assert_eq!(
                erased_truth[i],
                encoder.data[i * shred_size..(i + 1) * shred_size]
            );
        }
    }
}
