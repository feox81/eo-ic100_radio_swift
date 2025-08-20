// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RadioCore",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "RadioCoreKit", targets: ["RadioCoreKit"])
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
            name: "RadioCoreCPP",
            dependencies: ["USBShim"],
            path: "Sources/RadioCoreCPP",
            publicHeadersPath: "include",
            cxxSettings: [
                .unsafeFlags(["-std=c++17"]) 
            ]
        ),
        .target(
            name: "RadioCoreKit",
            dependencies: ["RadioCoreCPP"],
            path: "Sources/RadioCoreKit"
        ),
    ]
)
