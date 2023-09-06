use firedancer_sys::ballet::{
    fd_reedsol_encode_add_data_shred, fd_reedsol_encode_add_parity_shred, fd_reedsol_encode_fini,
    fd_reedsol_encode_init, fd_reedsol_recover_fini, fd_reedsol_t, ReedSolomon,
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


