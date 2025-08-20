// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RadioCore",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "RadioCore", targets: ["EOIC100RadioKit"])
    ],
    targets: [
        .target(
            name: "USBShim",
            path: "Sources/USBShim",
            sources: ["USBShim.c"],
            publicHeadersPath: "include",
            cSettings: [
                .define("USB_SHIM", to: "1")
            ],
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("CoreFoundation")
            ]
        ),
        .target(
            name: "EOIC100RadioKit",
            dependencies: ["USBShim"],
            path: "Sources/EOIC100RadioKit"
        ),
    ]
)
