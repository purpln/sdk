import Architecture
import Coding

struct Test: Scene {
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
    
    func test() throws {
        var library: Library = .init()
        library.configure(values: ["sources": ["Int.swift", "Float.swift"], "target": ["board": "teensy", "arguments":["-v"]]])
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

public class Target: Coding {
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
