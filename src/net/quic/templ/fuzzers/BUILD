load("//bazel:fd_build_system.bzl", "fd_cc_fuzz_test", "fd_cc_library")

fd_cc_fuzz_test(
    srcs = ["fuzz_quic_parse_transport_params.c"],
    deps = ["//src/net/quic/templ"],
)

fd_cc_fuzz_test(
    srcs = ["fuzz_quic_parse_bla.c"],
    deps = ["//src/net/quic/templ", "//src/net/quic"],
)

