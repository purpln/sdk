import Process

struct SDK {
    var board: any Board
    var path: Paths
    var compiler: Compilers
    var uswift: uSwift
    var zephyr: Zephyr
    
    init(board: any Board, path: String, uswift: String) {
        self.board = board
        self.path = Paths(path: path)
        self.compiler = Compilers(path: "\(path)/toolchain")
        self.uswift = uSwift(board: board.description, compilers: self.compiler, paths: self.path, sources: uswift)
        self.zephyr = Zephyr(path: "\(path)/zephyr")
        
        do {
            try clear()
        } catch {
            print(error)
        }
    }
    
    func clear() throws {
        try Process("rm", arguments: ["-rf", "\(path.current)/.build"]).run()
    }
}

extension SDK {
    struct Target {
        var swift: String
    }
}

extension SDK {
    struct Paths {
        var current: String
        var build: String
        
        init(path: String) {
            self.current = path
            self.build = "\(path)/.build"
        }
        
        var uswift: String { "\(build)/uswift" }
        var cmake: String { "\(current)/cmake" }
    }
}

extension SDK {
    struct Compilers {
        var toolchain: String
        
        var clang: String
        var swiftc: String
        
        init(path: String) {
            self.toolchain = path
            self.clang = "\(path)/usr/bin/clang"
            self.swiftc = "swiftc"//"\(path)/usr/bin/swiftc"
        }
        
        var link: String { "\(toolchain)/usr/bin/arm-none-eabi-ar" }
    }
}

extension SDK {
    struct uSwift {
        var sources: String
        var arguments: [String]
        
        init(board: String, compilers: Compilers, paths: Paths, sources: String) {
            self.sources = sources
            self.arguments = [
                "-B .build",
                "-D CMAKE_C_COMPILER:FILEPATH=\(compilers.clang)",
                "-D CMAKE_CXX_COMPILER:FILEPATH=\(compilers.clang)",
                "-D CMAKE_Swift_COMPILER:FILEPATH=\(compilers.swiftc)",
                "-D CMAKE_ARCHIVE_OUTPUT_DIRECTORY=\(paths.uswift)",
                "-D CMAKE_BUILD_TYPE=Release",
                "-D CMAKE_Swift_COMPILER_TARGET=\(board)", //thumbv7em-unknown-none-eabihf
                "-DCMAKE_TOOLCHAIN_FILE=cmake/toolchain-arm-none-eabi.cmake",
                //#"-D CMAKE_OSX_SYSROOT="""#,
                "-G Ninja", "-S ."
            ]
        }
        
        func build() throws {
            try Process("cmake", arguments: arguments, path: sources).run()
            try Process("ninja", arguments: ["-C .build"], path: sources).run()
        }
    }
}

extension SDK {
    struct Zephyr {
        var sources: String
        
        init(path: String) {
            self.sources = path
        }
        
        func build() {
            
        }
    }
}
