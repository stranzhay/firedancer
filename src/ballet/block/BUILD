load("//bazel:fd_build_system.bzl", "fd_cc_library")

package(default_visibility = ["//src/ballet:__subpackages__"])

fd_cc_library(
    name = "block",
    hdrs = [
        "fd_block.h",
    ],
    deps = [
        "//src/ballet:base_lib",
        "//src/ballet/sha256",
    ],
)

fd_cc_test(
    srcs = ["test_block.c"],
    compile_data = ["//src/ballet/shred:fixtures/localnet-slot0-batch0.bin"],
    deps = ["//src/ballet"],
)

fd_cc_test(
    srcs = ["test_poh.c"],
    args = [
        "--shreds",
        "src/ballet/shred/fixtures/localnet-slot50-shreds.ar",
    ],
    data = ["//src/ballet/shred:fixtures/localnet-slot50-shreds.ar"],
    deps = ["//src/ballet"],
)
