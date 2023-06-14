public protocol Application {
    associatedtype Content: Collection<any Scene>
    var scenes: Content { get }
    
    init() async throws
    static func main() async throws
}

extension Application {
    public static func main() async throws {
        var core = try await Core(Self.self)
        try await core.execute()
    }
}
