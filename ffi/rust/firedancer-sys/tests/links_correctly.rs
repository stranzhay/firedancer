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
    let data_shard_count = DATA_SHARDS;
    let parity_shard_count = PARITY_SHARDS;
    let shred_size_in_bytes = SHRED_SIZE as usize;

    // Create a new encoder
    let mut encoder = ReedSolEncoder::new(SHRED_SIZE);

    // Add data and parity
    encoder.add_data();
    encoder.add_parity();

    // Finish encoding
    let encoding_result = encoder.finish();
    assert!(encoding_result.is_ok(), "Encoding failed");

    // Simulate data loss
    for erased_shard_count in 0..=parity_shard_count + 1 {
        let mut erased_data_truth = Vec::new();
        let mut total_erased_count = 0;

        let mut recoverer = ReedSolRecover::new(SHRED_SIZE);

        for i in 0..data_shard_count {
            if rng.gen_range(0..(data_shard_count + parity_shard_count - i))
                < (erased_shard_count - total_erased_count)
            {
                erased_data_truth.push(
                    encoder.data[i * shred_size_in_bytes..(i + 1) * shred_size_in_bytes].to_vec(),
                );
                recoverer.add_erased_shred(
                    1,
                    &mut encoder.data[total_erased_count * shred_size_in_bytes
                        ..(total_erased_count + 1) * shred_size_in_bytes],
                );
                total_erased_count += 1;
            } else {
                recoverer.add_received_shred(
                    1,
                    &encoder.data[i * shred_size_in_bytes..(i + 1) * shred_size_in_bytes],
                );
            }
        }

        let mut parity_erased_count = 0;
        for i in 0..parity_shard_count {
            if rng.gen_range(0..(parity_shard_count - i))
                < (erased_shard_count - total_erased_count)
            {
                erased_data_truth.push(
                    encoder.parity[i * shred_size_in_bytes..(i + 1) * shred_size_in_bytes].to_vec(),
                );
                recoverer.add_erased_shred(
                    0,
                    &mut encoder.parity[parity_erased_count * shred_size_in_bytes
                        ..(parity_erased_count + 1) * shred_size_in_bytes],
                );
                parity_erased_count += 1;
                total_erased_count += 1;
            } else {
                recoverer.add_received_shred(
                    0,
                    &encoder.parity[i * shred_size_in_bytes..(i + 1) * shred_size_in_bytes],
                );
            }
        }

        assert_eq!(total_erased_count, erased_shard_count);

        let recovery_result = recoverer.finish();

        if erased_shard_count > parity_shard_count {
            assert_eq!(recovery_result, Err("Partial recovery"));
            continue;
        }

        assert_eq!(recovery_result, Ok(()));

        for i in 0..erased_shard_count {
            assert_eq!(
                erased_data_truth[i],
                encoder.data[i * shred_size_in_bytes..(i + 1) * shred_size_in_bytes]
            );
        }
    }
}
