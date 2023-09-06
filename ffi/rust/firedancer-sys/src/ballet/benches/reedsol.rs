use criterion::{black_box, criterion_group, criterion_main, Criterion};
use firedancer_sys::ballet::ReedSolomon;
use rand::Rng;
use std::ffi::{c_int, c_ulong, c_void};

const SHRED_SIZE: c_ulong = 1024 * 1024;
const DATA_SHARDS: usize = 32;
const PARITY_SHARDS: usize = 32;

fn bench_reedsol() {
    let mut data: Vec<u8> = vec![0; DATA_SHARDS * SHRED_SIZE as usize];
    let mut parity: Vec<u8> = vec![0; PARITY_SHARDS * SHRED_SIZE as usize];

    let mut mem = vec![0u8; (DATA_SHARDS + PARITY_SHARDS) * SHRED_SIZE as usize];
    let mut reedsol = ReedSolomon::new(mem.as_mut_ptr() as *mut c_void, SHRED_SIZE as u64);

    for chunk in data.chunks_mut(SHRED_SIZE as usize) {
        reedsol.add_data_shred(chunk);
    }

    for chunk in parity.chunks_mut(SHRED_SIZE as usize) {
        reedsol.add_parity_shred(chunk);
    }

    reedsol.encode_fini();

    // Simulate data loss
    let mut rng = rand::thread_rng();
    let num_lost_shards = 5;
    let mut lost_data_indices = Vec::new();
    let mut lost_parity_indices = Vec::new();

    for _ in 0..num_lost_shards {
        let index = rng.gen_range(0..DATA_SHARDS);
        data[index * SHRED_SIZE as usize..(index + 1) * SHRED_SIZE as usize].fill(0);
        lost_data_indices.push(index);
    }

    // Simulate parity loss (if needed)
    for _ in 0..num_lost_shards {
        let index = rng.gen_range(0..PARITY_SHARDS);
        parity[index * SHRED_SIZE as usize..(index + 1) * SHRED_SIZE as usize].fill(0);
        lost_parity_indices.push(index);
    }

    // Recovery process
    let mut recover_mem = vec![0u8; (DATA_SHARDS + PARITY_SHARDS) * SHRED_SIZE as usize];
    let mut recoverer =
        ReedSolomon::recover_init(recover_mem.as_mut_ptr() as *mut c_void, SHRED_SIZE as u64);

    for (i, chunk) in data.chunks(SHRED_SIZE as usize).enumerate() {
        if lost_data_indices.contains(&i) {
            let mut erased_chunk = chunk.to_vec();
            recoverer.add_erased_shred(true, &mut erased_chunk);
        } else {
            recoverer.add_received_shred(true, &chunk);
        }
    }

    for (i, chunk) in parity.chunks(SHRED_SIZE as usize).enumerate() {
        if lost_parity_indices.contains(&i) {
            let mut erased_chunk = chunk.to_vec();
            recoverer.add_erased_shred(false, &mut erased_chunk);
        } else {
            recoverer.add_received_shred(false, &chunk);
        }
    }

    recoverer.recover_fini();
}

fn criterion_benchmark(c: &mut Criterion) {
    c.bench_function("reedsol", |b| b.iter(|| black_box(bench_reedsol())));
}

criterion_group!(benches, criterion_benchmark);
criterion_main!(benches);
