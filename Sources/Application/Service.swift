import Architecture
import Pieces
import File
import Process

struct Service: Scene {
    var board: Board
    var sdk: SDK
    var package: Package
    
    func execute() async {
        while true {
            let string = readLine()
            do {
                switch string {
                case "test": try test()
                case "": try uswift()
                case "build": try build(path: "/Users/purpln/Developer/project")
                default: continue
                }
            } catch {
                continue
            }
        }
    }
    
    init(board: Board, sdk: SDK, package: Package) {
        self.board = board
        self.sdk = sdk
        self.package = package
    }
    
    func uswift() throws {
        do {
            try sdk.uswift.build()
        } catch {
            
        }
    }
    
    func swift() throws {
        
    }
    
    func test() throws {
        let toolchain = "/Users/purpln/github/sdk/toolchain"
        let command = "\(toolchain)/usr/bin/swiftc"
        
        let arguments = [
            "-module-name", "test", "-emit-object",
            "test.swift", "-v", "-gnone", "-Osize",
            "-target", "thumbv7em-unknown-none-eabihf",
            "-target-cpu", "cortex-m7",
            "-parse-stdlib", "-nostdimport",
            "-use-ld=\(toolchain)/usr/arm-none-eabi/bin/ld",
            "-parse-as-library",
            //"-sdk /Users/purpln/github/uswift/.build/swift",
            
            "-lswiftCore",
            "-I/Users/purpln/github/uswift/.build/swift",
            "-L/Users/purpln/github/uswift/.build/swift",
            "-static-executable"
        ]
        
        try Process(command, arguments: arguments, path: "/Users/purpln/github/sdk").run()
    }
    
    func build(path: String) throws {
        /*
        let libraries = [
            Library(name: "Runtime", path: "/Users/purpln/github/uswift/out/lib/libswiftRuntime.a"),
            Library(name: "Swift", path: "/Users/purpln/github/uswift/out/lib/libswiftCore.a"),
            Library(name: "SwiftOnoneSupport", path: "/Users/purpln/github/uswift/out/lib/libswiftOnoneSupport.a"),
            Library(name: "_Concurrency", path: "/Users/purpln/github/uswift/.build/out/lib/libswift_Concurrency.a"),
        ]
        let description = description(executable: true, sdk: sdk.path, board: board, libraries: libraries)
        
        print(description)
        
        var file = File(path: "\(path)/.build/destination.json", mode: .writeOnly)
        file?.write(description.utf8)
        file = nil
        
        let arguments: [Arguments] = [
            .sudo(.defined("7890")),
            .command(.custom(sdk.build)),
            .array(["-c", "release", "--destination", ".build/destination.json", "--static-swift-stdlib", "-v"]),
            .path(path)
        ]
        
        try Process(arguments: arguments).launch { string in
            print(string)
        }
         */
    }
}

extension Service {
    func description(executable: Bool, sdk path: String, board: Board, libraries: [Library]) -> String {
        let target = board.architecture.target
        let cpu = board.architecture.cpu
        let define = board.flags + [
            "-D_POSIX_THREADS",
            "-D_POSIX_READER_WRITER_LOCKS",
            "-D_UNIX98_THREAD_MUTEX_ATTRIBUTES",
        ]
        let flags = [
            "-nostdinc",
            "--rtlib=libgcc",
            "-Wno-unused-command-line-argument",
        ]
        let toolchain = [
            "\(path)/toolchain/usr/arm-none-eabi/include",
            "\(path)/toolchain/usr/lib/gcc/arm-none-eabi/10.3.1/include",
            "\(path)/toolchain/usr/lib/gcc/arm-none-eabi/10.3.1/include-fixed",
        ]
        let other = [
            "-nostdimport", "-parse-stdlib",
            //"-use-ld=\(path)/toolchain/usr/arm-none-eabi/bin/ld",
            executable ? "-static-executable" : "-static",
        ]
        
        let link = [
            "-I/Users/purpln/github/uswift/.build/lib/libswiftCore.a",
            "-L/Users/purpln/github/uswift/.build/lib/libswiftCore.a",
            "-lswiftCore",
        ]
        /*
        libraries.reduce(into: [String]()) { array, library in
            array.append("-L \(library.path)")
            array.append("-I \(library.path)")
            array.append("-l\(library.name)")
        }
         */
        
        let ccFlags: [String] = ["-mcpu=\(cpu)"] + flags + define + toolchain.map { string in "-I\(string)" }
        let cppFlags: [String] = ["-mcpu=\(cpu)"] + flags + define + toolchain.map { string in "-I\(string)" }
        let swiftcFlags: [String] = ["-target", target, "-target-cpu", cpu] + other + link // + define.xcc + toolchain.xccI
        
        let description: Piece = .object([
            "extra-cc-flags": Piece.array(ccFlags.map { string in .string(string) }),
            "extra-cpp-flags": Piece.array(cppFlags.map { string in .string(string) }),
            "extra-swiftc-flags": Piece.array(swiftcFlags.map { string in .string(string) }),
            "sdk": .string("\(path)/toolchain"),
            "target": .string(target),
            "toolchain-bin-dir": .string("\(path)/toolchain/usr/bin"),
            "dynamic-library-extension":"lib",
            "version": .double(1)
        ])
        
        return description.description
    }
}


private extension Array where Element == String {
    var xcc: [String] {
        reduce(into: [String]()) { array, string in
            array.append("-Xcc")
            array.append(string)
        }
    }
    
    var xccI: [String] {
        reduce(into: [String]()) { array, string in
            array.append("-Xcc")
            array.append("-I")
            array.append("-Xcc")
            array.append(string)
        }
    }
}


extension Service {
    func otool(path: String) throws {
        try Process("nm", arguments: [path]).run()
        //try Process("otool", arguments: ["-L", path]).run()
    }
}
