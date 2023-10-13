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
