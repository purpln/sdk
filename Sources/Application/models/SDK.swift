struct SDK {
    var path: String = "/Users/purpln/github/sdk"
    var package: String { "swift package"/*"\(path)/swift-package"*/ }
    var swiftc: String { "\(path)/swiftc" }
    var flags: [String] = ["-c", "release", "-nostdimport", "-parse-stdlib"]
}

