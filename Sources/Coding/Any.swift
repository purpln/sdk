protocol AnyExtensions {}

extension AnyExtensions {
    public static var size: Int { MemoryLayout<Self>.size }
    
    public static func set(value: Any?, to address: Int) {
        if let value = value as? Self {
            UnsafeMutablePointer<Self>(bitPattern: address)?.pointee = value
            return
        }
        if let values = value as? [String: Any] {
            guard var object = UnsafeMutablePointer<Self>(bitPattern: address)?.pointee as? Decoding else { return }
            let properties = object.properties()
            
            for (label, variable) in Mirror(reflecting: object).children {
                guard let label = label, let indent = properties[label] else { continue }
                let type = extensions(of: type(of: variable))
                type.set(value: values[label], to: address + indent)
            }
            return
        }
    }
}

func extensions(of type: Any.Type) -> AnyExtensions.Type {
    var extensions: AnyExtensions.Type?
    withUnsafePointer(to: &extensions) { pointer in
        UnsafeMutableRawPointer(mutating: pointer).assumingMemoryBound(to: Any.Type.self).pointee = type
    }
    return extensions!
}

struct MemoryAddress<T>: CustomStringConvertible {
    let value: Int
    
    var description: String { .init(value+8, radix: 16) }
    
    init(of structPointer: UnsafePointer<T>) {
        value = Int(bitPattern: structPointer)
    }
}
