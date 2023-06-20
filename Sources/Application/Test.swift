import Architecture
import File
import Piece
import Coding

struct Test: Scene {
    var sdk: SDK
    var package: Package
    
    func execute() async {
        while true {
            do {
                switch readLine() {
                case "": try test()
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
    
    func test() throws {
        try pieces(path: "/Users/purpln/github/uswift")
    }
    
    func pieces(path: String) throws {
        try launch(command: sdk.package, arguments: ["describe", "--type json"], path: path) { string in
            let action: () -> Void = {
                guard let pieces = Conventer(string.utf8).decode() else { print("error"); return }
                print(pieces)
                print("success")
                
                //0.000527083 seconds //0.002044709 seconds
            }
            
            let time = ContinuousClock().measure(action)
            print(time)
        }
    }
    
    func coding() {
        var library: Library = .init()
        //library.configure(values: ["sources": ["Int.swift", "Float.swift"], "target": ["board": "teensy", "arguments":["-v"]]])
        print("\n", library.target?.board ?? "nil")
    }
}

public struct Library: Coding {
    public var target: Target?
    public var sources: [String]?
    
    public init(target: Target = .init(), sources: [String] = []) {
        self.target = target
        self.sources = sources
    }
}

public struct Target: Coding {
    var board: String?
    var arguments: [String]
    
    public init(board: String = "", arguments: [String] = []) {
        self.board = board
        self.arguments = arguments
    }
}

public enum Teensy: Coding {
    case v4_1
}
