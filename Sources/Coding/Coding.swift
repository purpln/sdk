public protocol Coding: Decoding, Encoding { }

extension Coding {
    @discardableResult mutating
    public func apply(_ block: (inout Self) -> Void) -> Self {
        block(&self)
        return self
    }
}

public protocol Decoding {
    mutating func configure(values: Any?)
}

public extension Decoding {
    mutating func configure(values: Any?) {
        guard let values = values as? [String: Any] else { return }
        //var types: [String: (AnyExtensions.Type, Int)] = [:]
        let address = address()
        let properties = properties()
        for (label, variable) in mirror.children {
            guard let label = label, let indent = properties[label] else { continue }
            let type = extensions(of: type(of: variable))
            //types[label] = (type, indent)
            type.set(value: values[label], to: address + indent)
        }
    }
    //private var key: UnsafeRawPointer { unsafeBitCast(Self.self, to: UnsafeRawPointer.self) }
    private var mirror: Mirror { Mirror(reflecting: self) }
    private var structure: Bool { mirror.displayStyle == .struct }
}

public extension Decoding {
    mutating func address() -> Int { structure ? addressStruct() : addressClass() }
    mutating func properties() -> [String: Int] { structure ? propertiesStruct() : propertiesClass() }
}

extension Decoding {
    private mutating func addressStruct() -> Int { MemoryAddress(of: &self).value }
    private mutating func propertiesStruct() -> [String: Int] {
        var list: [String: Int] = [:]
        var address = 0
        for (label, value) in mirror.children {
            guard let label = label else { continue }
            list[label] = address
            address += extensions(of: type(of: value)).size
        }
        return list
    }
}

extension Decoding {
    private func addressClass() -> Int { unsafeBitCast(self, to: Int.self) }
    private func propertiesClass() -> [String: Int] {
        var list: [String: Int] = [:]
        var address = 16
        for (label, value) in mirror.children {
            guard let label = label else { continue }
            list[label] = address
            address += extensions(of: type(of: value)).size
        }
        return list
    }
}

public protocol Encoding {
    var values: [String: Any] { get }
}

public extension Encoding {
    var values: [String: Any] {
        let mirror = Mirror(reflecting: self)
        var dictionary: [String: Any] = [:]
        for i in mirror.children {
            guard let label = i.label else { continue }
            dictionary[label] = convert(i.value)
        }
        return dictionary
    }
    
    private func convert(_ any: Any) -> Any {
        if let array = any as? [Any] {
            var dictionary: [Any] = []
            for i in array {
                dictionary.append(convert(i))
            }
            return dictionary
        } else if let value = check(any) {
            return value
        } else { return any }
    }
    
    private func check(_ value: Any) -> Any? {
        let value = unwrap(any: value)
        if let model = value as? Encoding {
            return model.values
        } else { return value }
    }
}

func unwrap(any: Any) -> Any? {
    let mirror = Mirror(reflecting: any)
    if mirror.displayStyle != .optional { return any }
    
    guard let (_, some) = mirror.children.first else { return nil }
    return some
}
