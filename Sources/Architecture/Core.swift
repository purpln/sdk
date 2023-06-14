import Platform
import Loop

struct Core {
    private var application: any Application
    
    mutating func execute() async throws {
        for scene in application.scenes as any Collection {
            guard let scene = scene as? Scene else { continue }
            Task.detached {
                do {
                    try await scene.execute()
                } catch {
                    print(error)
                }
            }
        }
        await loop.run()
    }
    
    init<T>(_ t: T.Type) async throws where T: Application {
        application = try await T()
    }
}
