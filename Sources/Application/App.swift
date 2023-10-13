import Architecture

@main
struct App: Application {
    let board: any Board
    let sdk: SDK
    let package: Package
    
    var scenes: [any Scene] { [
        Service(board: board, sdk: sdk, package: package),
    ] }
    
    init() throws {
        board = try Self.from(string: "teensy 4.1")
        sdk = SDK(board: board, path: "/Users/purpln/github/sdk", uswift: "/Users/purpln/github/uswift")
        package = Package(path: "/Users/purpln/Developer/project")
    }
    
    static func from(string: String) throws -> any Board {
        switch string {
        case "teensy 4.1": return Teensy.v4_1
        default: throw Fault.failure("unsupported board")
        }
    }
}
