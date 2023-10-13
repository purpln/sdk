struct Library: Equatable, Hashable {
    var name: String
    var path: String
    
    init(name: String, path: String) {
        self.name = name
        self.path = path
    }
}
