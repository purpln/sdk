public enum Piece: Hashable, Equatable {
    public typealias Key   = String
    public typealias Value = Piece
    public typealias Index = Int
    
    case null
    case bool(Bool)
    case double(Double)
    case string(String)
    case array([Value])
    case object([Key: Value])
}

extension Piece: CustomStringConvertible {
    public var description: String { string(space: 4) }
    
    public func string(depth: Int = 0, separator: String = "", terminator: String = "", sorted: Bool = false) -> String {
        let i = String(repeating: separator, count: depth)
        let g = separator == "" ? "" : " "
        switch self {
        case .null: return "null"
        case .bool(let value): return value.description
        case .double(let value): return value.description
        case .string(let value): return value.debugDescription
        case .array(let array):
            let value = array
                .map { $0.string(depth: depth + 1, separator: separator, terminator: terminator, sorted: sorted) }
                .map { i + separator + $0 }
                .joined(separator: "," + terminator)
            return "[" + terminator + value + terminator + i + "]" + (depth == 0 ? terminator : "")
        case .object(let object):
            let a = sorted ? object.map { $0 }.sorted { $0.0 < $1.0 } : object.map { $0 }
            return "{" + terminator + a.map { $0.debugDescription + ":" + g + $1.string(depth: depth + 1, separator: separator, terminator: terminator, sorted: sorted) }
                .map{ i + separator + $0 }.joined(separator:"," + terminator) + terminator
            + i + "}" + (depth == 0 ? terminator : "")
        }
    }
    
    public func string(space: Int = 0) -> String {
        space == 0 ? string() : string(depth: 0, separator: String(repeating:" ", count: space), terminator:"\n", sorted: true)
    }
}

extension Piece: ExpressibleByNilLiteral,
                 ExpressibleByBooleanLiteral,
                 ExpressibleByFloatLiteral,
                 ExpressibleByIntegerLiteral,
                 ExpressibleByStringLiteral,
                 ExpressibleByArrayLiteral,
                 ExpressibleByDictionaryLiteral {
    public init()                                { self = .null }
    public init(nilLiteral: ())                  { self = .null }
    
    public typealias BooleanLiteralType = Bool
    public init(_ value: Bool)                   { self = .bool(value) }
    public init(booleanLiteral value: Bool)      { self = .bool(value) }
    
    public typealias FloatLiteralType = Double
    public init(_ value: Double)                 { self = .double(value) }
    public init(floatLiteral value: Double)      { self = .double(value) }
    
    public typealias IntegerLiteralType = Int
    public init(_ value: Int)                    { self = .double(Double(value)) }
    public init(integerLiteral value: Int)       { self = .double(Double(value)) }
    
    public typealias StringLiteralType = String
    public init(_ value: String)                 { self = .string(value) }
    public init(stringLiteral value: String)     { self = .string(value) }
    
    public typealias ArrayLiteralElement = Value
    public init(_ value: [Value])                { self = .array(value)  }
    public init(arrayLiteral value: Value...)    { self = .array(value)  }
    
    public init(_ value: [Key: Value])            { self = .object(value) }
    public init(dictionaryLiteral value: (Key, Value)...) {
        var object = [Key: Value]()
        value.forEach { object[$0.0] = $0.1 }
        self = .object(object)
    }
}

extension Piece {
    public enum ContentType {
        case error, null, bool, double, string, array, object
    }
    
    public var type:ContentType {
        switch self {
        case .null:         return .null
        case .bool(_):      return .bool
        case .double(_):    return .double
        case .string(_):    return .string
        case .array(_):     return .array
        case .object(_):    return .object
        }
    }
    
    public var null: Bool { return type == .null }
    
    public var bool: Bool? {
        get { if case .bool(let value) = self { return value } else { return nil } }
        set { self = .bool(newValue!) }
    }
    public var number: Double? {
        get { if case .double(let value) = self { return value } else { return nil } }
        set { self = .double(newValue!) }
    }
    public var string: String? {
        get { if case .string(let value) = self { return value } else { return nil } }
        set { self = .string(newValue!) }
    }
    public var array: [Value]? {
        get { if case .array(let array) = self { return array } else { return nil } }
        set { self = .array(newValue!) }
    }
    public var object: [Key: Value]?  {
        get { if case .object(let object) = self { return object } else { return nil } }
        set { self = .object(newValue!) }
    }
}

extension Piece {
    func log(_ string: String) {
        print(string)
    }
}

extension Piece: Sequence {
    public enum IteratorKey {
        case None
        case Index(Int)
        case Key(String)
        public var index:Int?  { switch self { case .Index(let v): return v default: return nil } }
        public var key:String? { switch self { case .Key(let v):   return v default: return nil } }
    }
    public typealias Element = (key: IteratorKey, value: Value)
    public typealias Iterator = AnyIterator<Element>
    public func makeIterator() -> AnyIterator<Element> {
        switch self {
        case .array(let array):
            var i = -1
            return AnyIterator {
                i += 1
                return array.count <= i ? nil : (IteratorKey.Index(i), array[i])
            }
        case .object(let object):
            let kv = object.map { $0 }
            var i = -1
            return AnyIterator {
                i += 1
                return kv.count <= i ? nil : (IteratorKey.Key(kv[i].0), kv[i].1)
            }
        default:
            return AnyIterator { nil }
        }
    }
    public var iterable: Bool {
        return type == .array || type == .object
    }
    public func walk<T>(depth: Int = 0, collect: (Self, [(IteratorKey, T)], Int) -> T, visit: (Self) -> T) -> T {
        return collect(self, self.map {
            let value = $0.1.iterable ? $0.1.walk(depth: depth + 1, collect: collect, visit: visit) : visit($0.1)
            return ($0.0, value)
        }, depth)
    }
    public func walk(depth: Int = 0, visit: (Self) -> Self) -> Self {
        return self.walk(depth: depth, collect: { node, pairs, depth in
            switch node.type {
            case .array:
                return .array(pairs.map { $0.1 })
            case .object:
                var o = [Key: Value]()
                pairs.forEach { o[$0.0.key!] = $0.1 }
                return .object(o)
            default:
                log("not iterable: \(node.type)")
                return .null
            }
        }, visit: visit)
    }
    public func walk(depth: Int = 0, collect: (Self, [Element], Int) -> Self) -> Self {
        self.walk(depth: depth, collect: collect, visit: { $0 })
    }
    public func pick(picker: (Self) -> Bool) -> Self {
        return self.walk { node, pairs, depth in
            switch node.type {
            case .array:
                return .array(pairs.map { $0.1 }.filter { picker($0) })
            case .object:
                var o = [Key: Value]()
                pairs.filter { picker($0.1) }.forEach { o[$0.0.key!] = $0.1 }
                return .object(o)
            default:
                log("not iterable: \(node.type)")
                return .null
            }
        }
    }
}

extension Piece {
    public subscript(_ index: Index) -> Self {
        get {
            switch self {
            case .array(let array):
                guard index < array.count else {
                    log("out of range \(type) \(index)")
                    return .null
                }
                return array[index]
            default:
                log("not subscriptable \(type)")
                return .null
            }
        }
        set {
            switch self {
            case .array(var array):
                if index < array.count {
                    array[index] = newValue
                } else {
                    for _ in array.count ..< index {
                        array.append(.null)
                    }
                    array.append(newValue)
                }
                self = .array(array)
            default:
                log("\(type) is not an array")
            }
        }
    }
    public subscript(_ key: Key) -> Self {
        get {
            switch self {
            case .object(let object):
                guard let value = object[key] else {
                    log("\(key) not exist")
                    return .null
                }
                return value
            default:
                log("not subscriptable \(type)")
                return .null
            }
        }
        set {
            switch self {
            case .object(var object):
                object[key] = newValue
                self = .object(object)
            default:
                log("\(type) is not an object")
            }
        }
    }
}

extension Piece: Codable {
    private static let codableTypes: [Codable.Type] = [
        [Key: Value].self, [Value].self,
        String.self,
        Bool.self,
        UInt.self, Int.self,
        Double.self, Float.self,
        UInt64.self, UInt32.self, UInt16.self, UInt8.self,
        Int64.self,  Int32.self,  Int16.self,  Int8.self,
    ]
    public init(from decoder: Decoder) throws {
        if let c = try? decoder.singleValueContainer(), !c.decodeNil() {
            for type in Self.codableTypes {
                switch type {
                case let t as Bool.Type:         if let v = try? c.decode(t) { self = .bool(v); return }
                case let t as Int.Type:          if let v = try? c.decode(t) { self = .double(Double(v)); return }
                case let t as Int8.Type:         if let v = try? c.decode(t) { self = .double(Double(v)); return }
                case let t as Int32.Type:        if let v = try? c.decode(t) { self = .double(Double(v)); return }
                case let t as Int64.Type:        if let v = try? c.decode(t) { self = .double(Double(v)); return }
                case let t as UInt.Type:         if let v = try? c.decode(t) { self = .double(Double(v)); return }
                case let t as UInt8.Type:        if let v = try? c.decode(t) { self = .double(Double(v)); return }
                case let t as UInt16.Type:       if let v = try? c.decode(t) { self = .double(Double(v)); return }
                case let t as UInt32.Type:       if let v = try? c.decode(t) { self = .double(Double(v)); return }
                case let t as UInt64.Type:       if let v = try? c.decode(t) { self = .double(Double(v)); return }
                case let t as Float.Type:        if let v = try? c.decode(t) { self = .double(Double(v)); return }
                case let t as Double.Type:       if let v = try? c.decode(t) { self = .double(v); return }
                case let t as String.Type:       if let v = try? c.decode(t) { self = .string(v); return }
                case let t as [Value].Type:      if let v = try? c.decode(t) { self = .array(v); return }
                case let t as [Key: Value].Type: if let v = try? c.decode(t) { self = .object(v); return }
                default: break
                }
            }
        }
        self = .null
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        if self.null {
            try c.encodeNil()
            return
        }
        switch self {
        case .bool(let v):      try c.encode(v)
        case .double(let v):    try c.encode(v)
        case .string(let v):    try c.encode(v)
        case .array(let v):     try c.encode(v)
        case .object(let v):    try c.encode(v)
        default:
            break
        }
    }
}
