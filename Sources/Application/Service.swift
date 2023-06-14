import Architecture
import Piece

struct Service: Scene {
    var sdk: SDK
    var package: Package
    
    func execute() async {
        while true {
            do {
                switch readLine() {
                case "": try library(path: "/Users/purpln/github/uswift/Sources/Core", target: "thumbv7em-unknown-none-eabihf")
                case "test": try test()
                case "build": try build()
                case "otool": try otool()
                default: break
                }
            } catch {
                break
            }
        }
    }
    
    init(sdk: SDK, package: Package) {
        self.sdk = sdk
        self.package = package
    }
    
    func piece() {
        let configuraton: Piece = ["swift":["safe","fast","expressive"]]
        
        print(configuraton["swift"].array ?? "nil")
    }
    
    func test() throws {
        try launch(command: sdk.swiftc, arguments: ["-c", "release", "-nostdimport", "-parse-stdlib", "-c", "test.swift", "-o", "sum.o"], path: sdk.path) { string in
            print(string)
        }
    }
    
    func library(path: String, target: String) throws {
        try launch(command: sdk.package, arguments: ["describe", "--type json"], path: path) { string in
            print(string)
        }
        /*
        let module: [String] = [
            "-module-name", "\(library)",
            "-incremental", "-emit-dependencies", "-emit-module",
            "-emit-module-path", "\(path)/.build/\(target)/release/\(library).swiftmodule",
            //"-output-file-map", "\(path)/.build/\(target)/release/\(library).build/output-file-map.json",
            "-module-cache-path", "\(path)/.build/\(target)/release/ModuleCache",
            "-num-threads", "24",
            "-swift-version", "5",
            "-O", "-g", "-j24", "-DSWIFT_PACKAGE",
            "-module-cache-path", "\(path)/.build/\(target)/release/ModuleCache",
            "-parseable-output", "-parse-as-library", "-whole-module-optimization", "-color-diagnostics",//"-disable-objc-interop",
            "-Xfrontend", "-enable-resilience", "-Xfrontend", "-function-sections", "-Xfrontend", "-data-sections",
            "-static-executable",
            "-nostdimport", "-parse-stdlib", "-Xclang-linker", "-nostdlib",
        ]
        
        let uswift: [String] = [
            "AdditiveArithmetic.swift",
            "Assert.swift",
            "BidirectionalCollection.swift",
            "BinaryInteger.swift",
            "Bool.swift",
            "Builtin.swift",
            "BuiltinTypes.swift",
            "Collection.swift",
            "Comparable.swift",
            "CompilerProtocols.swift",
            "CTypes.swift",
            "Equatable.swift",
            "FixedWidthInteger.swift",
            "Int.swift",
            "Int8.swift",
            "Int16.swift",
            "Int32.swift",
            "Int64.swift",
            "Integers.swift",
            "IteratorProtocol.swift",
            "Lifetime.swift",
            "Never.swift",
            "Numeric.swift",
            "OpaquePointer.swift",
            "Operators.swift",
            "Optional.swift",
            "OptionSet.swift",
            "Pointer.swift",
            "Range.swift",
            "RangeExpression.swift",
            "Sequence.swift",
            "SignedNumeric.swift",
            "StaticString.swift",
            "Strideable.swift",
            "UInt.swift",
            "UInt8.swift",
            "UInt16.swift",
            "UInt32.swift",
            "UInt64.swift",
            "UnsafeMutablePointer.swift",
            "UnsafeMutableRawPointer.swift",
            "UnsafePointer.swift",
            "UnsafeRawPointer.swift",
            "Void.swift",
        ]
        
        let platform: [String] = [
            "-target-cpu", "cortex-m7",
            "-target", "thumbv7em-unknown-none-eabihf",
            "-Xcc", "-mhard-float", "-Xcc", "-mfloat-abi=hard",
            "-Xcc", "-D_POSIX_THREADS", "-Xcc", "-D_POSIX_READER_WRITER_LOCKS", "-Xcc", "-D_UNIX98_THREAD_MUTEX_ATTRIBUTES",
        ]
        
        let paths: [String] = uswift.map { file in "\(path)/Sources/Core/\(file)" }
        
        let arguments: [String] = ["-v"] + module + ["-c"] + paths + platform + ["-o \(library).o"]
                                                                        
        try launch(command: sdk.swiftc, arguments: arguments, path: path) { string in
            print(string)
        }
         */
    }
    
    func build() throws {
        try launch(command: sdk.package, arguments: ["describe", "--type json"], path: package.path) { string in
            print(string)
            
            let arguments = ["-c", "release", "-nostdimport", "-parse-stdlib"]
            try launch(command: sdk.swiftc, arguments: arguments + ["--destination", ".build/destination.json"], path: package.path) { string in
                print(string)
            }
        }
        
        try launch(command: sdk.swiftc, arguments: ["-Xfrontend", "-parse-stdlib"], path: package.path) { string in
            print(string)
        }
    }
    
    func otool() throws {
        try launch(command: "otool", arguments: ["-L", "sum.o"], path: sdk.path) { string in
            print(string)
        }
    }
}
