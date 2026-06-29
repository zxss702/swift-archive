// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "Archive",
    platforms: [.macOS(.v13), .iOS(.v15), .tvOS(.v15), .watchOS(.v10)],
    products: [
        .library(name: "Archive", targets: ["Archive"]),
    ],
    traits: [
        // On macOS, zlib and bzip2 are in the SDK. On Linux, dev packages
        // (liblzma-dev, libbz2-dev) must be installed separately, so compression
        // traits are not enabled by default.
        .trait(name: "GzipSupport", description: "Enable gzip compression (zlib)"),
        .trait(name: "Bzip2Support", description: "Enable bzip2 compression"),
        .trait(name: "LZMASupport", description: "Enable lzma compression (requires liblzma)"),
        .trait(name: "ZstdSupport", description: "Enable Zstandard compression (requires libzstd)"),
        .default(enabledTraits: [/*"GzipSupport"*/]),
    ],
    targets: [
        .target(
            name: "CArchive",
            dependencies: [
                .target(name: "Cliblzma", condition: .when(platforms: [.macOS, .linux, .windows], traits: ["LZMASupport"])),
                .target(name: "Clibzstd", condition: .when(platforms: [.macOS, .linux, .windows], traits: ["ZstdSupport"])),
            ],
            path: "libarchive",
            exclude: [ "test" ],
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath("../contrib/android/include", .when(platforms: [.android])),
                .define("PLATFORM_CONFIG_H", to: "\"config_spm.h\""),
                .define("HAVE_ZLIB_H", .when(traits: ["GzipSupport"])),
                .define("HAVE_LIBZ", .when(traits: ["GzipSupport"])),
                .define("HAVE_BZLIB_H", .when(platforms: [.macOS, .linux, .windows], traits: ["Bzip2Support"])),
                .define("HAVE_LIBBZ2", .when(platforms: [.macOS, .linux, .windows], traits: ["Bzip2Support"])),
                .define("HAVE_LZMA_H", .when(platforms: [.macOS, .linux, .windows], traits: ["LZMASupport"])),
                .define("HAVE_LIBLZMA", .when(platforms: [.macOS, .linux, .windows], traits: ["LZMASupport"])),
                .define("HAVE_LZMA_STREAM_ENCODER_MT", .when(platforms: [.macOS, .linux, .windows], traits: ["LZMASupport"])),
                .define("HAVE_ZSTD_H", .when(platforms: [.macOS, .linux, .windows], traits: ["ZstdSupport"])),
                .define("HAVE_LIBZSTD", .when(platforms: [.macOS, .linux, .windows], traits: ["ZstdSupport"])),
                .define("HAVE_ZSTD_compressStream", .when(platforms: [.macOS, .linux, .windows], traits: ["ZstdSupport"])),
            ],
            linkerSettings: [
                .linkedLibrary("z", .when(traits: ["GzipSupport"])),
                .linkedLibrary("bz2", .when(platforms: [.macOS, .linux, .windows], traits: ["Bzip2Support"])),
                .linkedLibrary("iconv", .when(platforms: [.macOS, .iOS, .tvOS, .watchOS, .visionOS])),
                .linkedLibrary("crypto", .when(platforms: [.linux])),
            ]
        ),
        .target(
            name: "Cliblzma",
            exclude: [
                "Makefile.am",
                "Makefile.in",
                "api/Makefile.am",
                "api/Makefile.in",
                "validate_map.sh",
                "liblzma.pc.in",
                "liblzma_generic.map",
                "liblzma_linux.map",
                "liblzma_w32res.rc",
                "check/crc32_x86.S",
                "check/crc64_x86.S",
                "check/crc32_tablegen.c",
                "check/crc64_tablegen.c",
                "rangecoder/price_tablegen.c",
                "lzma/fastpos_tablegen.c",
                "check/crc32_small.c",
                "check/crc64_small.c"
            ],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("."),
                .headerSearchPath("common"),
                .headerSearchPath("check"),
                .headerSearchPath("lz"),
                .headerSearchPath("lzma"),
                .headerSearchPath("rangecoder"),
                .headerSearchPath("simple"),
                .headerSearchPath("delta"),
                .headerSearchPath("include"),
                .define("HAVE_CONFIG_H")
            ]
        ),
        .systemLibrary(
            name: "Clibzstd",
            providers: [
                .brew(["zstd"]),
                .apt(["libzstd-dev"])
            ]
        ),
        .target(
            name: "Archive",
            dependencies: ["CArchive"]
        ),
        .testTarget(
            name: "ArchiveTests",
            dependencies: ["Archive"]
        ),
    ]
)
