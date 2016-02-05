import PackageDescription

let package = Package(
    name: "SwiftIO",
    dependencies: [
        .Package(url: "https://github.com/schwa/SwiftUtilities.git", versions: Version(0,0,27)..<Version(0,1,0)),
    ]
)

