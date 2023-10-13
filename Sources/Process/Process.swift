public enum Arguments {
    case command(Command)
    case array([String])
    case path(String)
    case sudo(Password)
    case environment([String: String])
}

public extension Arguments {
    enum Command: ExpressibleByStringLiteral, CustomStringConvertible {
        case custom(String)
        
        public init(stringLiteral value: StringLiteralType) {
            self = .custom(value)
        }
        
        public var description: String {
            switch self {
            case .custom(let string): return string
            }
        }
    }
    
    enum Password: ExpressibleByStringLiteral, CustomStringConvertible {
        case defined(String)
        case request(String? = readLine())
        
        public init(stringLiteral value: StringLiteralType) {
            self = .defined(value)
        }
        
        public var description: String {
            switch self {
            case .defined(let string): return string
            case .request(let string): return string ?? ""
            }
        }
    }
}

public struct Process {
    var arguments: [Arguments]
    
    public init(_ command: String, arguments: [String] = [], path: String = "", environment: [String: String] = [:]) {
        let paths = ["PATH":"/opt/homebrew/bin:/usr/bin:/bin:$PATH"].reduce(environment) { r, e in var r = r; r[e.0] = e.1; return r }
        self.arguments = [.command(.custom(command)), .array(arguments), .environment(paths)]
        guard path != "" else { return }
        self.arguments.append(.path(path))
    }
    
    public init(arguments: [Arguments]) {
        self.arguments = arguments
    }
    
    public func run(closure: (String) -> Void = { string in print(string) }) throws {
        try launch(closure: closure)
    }
    
    public func launch(logs debug: Bool = false, closure: (String) -> Void = { _ in }) throws {
        var command: String?
        var password: String?
        var arguments: [String] = []
        var path: String?
        var environment: [String: String] = [:]
        
        for argument in self.arguments {
            switch argument {
            case .command(let value):
                command = value.description
            case .array(let array):
                arguments.append(contentsOf: array)
            case .path(let string):
                path = string
            case .sudo(let value):
                let code = value.description
                guard code != "" else { break }
                password = code
            case .environment(let dictionary):
                environment = dictionary
            }
        }
        guard var value = command else { throw Fault.empty }
        if let code = password {
            value = "echo \(code) | sudo -S " + value
        }
        
        guard process(command: value, arguments: arguments, path: path, environment: environment, debug: debug, redirect: true, closure: closure) else { throw Fault.launch }
    }
    
    public func launch(logs debug: Bool = false) throws -> [String] {
        var array: [String] = []
        
        try launch(logs: debug) { string in
            array.append(string)
        }
        
        return array
    }
}
