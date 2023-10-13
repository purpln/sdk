public protocol Conventer {
    associatedtype Value
    
    func null() -> Value?
    func bool(value: Bool) -> Value
    func double(value: Double) -> Value
    func string(value: String) -> Value
    func array(values: [Value]) -> Value
    func object(values: [String: Value]) -> Value
    
    func error(string: String)
    
    func decode(source: [UInt8]) -> Value?
    func deserialize(source: [UInt8], index: inout Int, end: Int) -> Value?
    func advance(index: inout Int, end: Int) -> Bool
    func skip(source: [UInt8], index: inout Int, end: Int)
    
    func parseArray(source: [UInt8], index: inout Int, end: Int) -> Value?
    func parseObject(source: [UInt8], index: inout Int, end: Int) -> Value?
    func parseDouble(source: [UInt8], index: inout Int, end: Int) -> Value?
    func parseString(source: [UInt8], index: inout Int, end: Int) -> Value?
    
    func parseStringValue(source: [UInt8], index: inout Int, end: Int) -> String?
    func parseEscaped(source: [UInt8], index: inout Int, end: Int) -> UnicodeScalar?
    func parseEscapedUnicode(source: [UInt8], index: inout Int, end: Int) -> UInt32?
}

public extension Conventer where Value == Piece {
    func null() -> Value? { .null }
    func bool(value: Bool) -> Value { .bool(value) }
    func string(value: String) -> Value { .string(value) }
    func double(value: Double) -> Value { .double(value) }
    func array(values: [Value]) -> Value { .array(values) }
    func object(values: [String: Value]) -> Value { .object(values) }
}

public extension Conventer where Value == Any {
    func null() -> Value? { nil }
    func bool(value: Bool) -> Value { value }
    func double(value: Double) -> Value { value }
    func string(value: String) -> Value { value }
    func array(values: [Value]) -> Value { values }
    func object(values: [String : Value]) -> Value { values }
}

public extension Conventer {
    @inlinable func error(string: String) { }
    
    @inlinable func decode(source: [UInt8]) -> Value? {
        var index = source.startIndex
        let end = source.endIndex
        
        skip(source: source, index: &index, end: end)
        
        guard index != end else { return nil }
        
        return deserialize(source: source, index: &index, end: end)
    }
    
    @inlinable func deserialize(source: [UInt8], index: inout Int, end: Int) -> Value? {
        skip(source: source, index: &index, end: end)
        switch source[index] {
        case 0x6e: return parse(string: "null", as: null(), source: source, index: &index, end: end)
        case 0x74: return parse(string: "true", as: bool(value: true), source: source, index: &index, end: end)
        case 0x66: return parse(string: "false", as: bool(value: false), source: source, index: &index, end: end)
        case 0x2d, 0x30...0x39: return parseDouble(source: source, index: &index, end: end)
        case 0x22: return parseString(source: source, index: &index, end: end)
        case 0x7b: return parseObject(source: source, index: &index, end: end)
        case 0x5b: return parseArray(source: source, index: &index, end: end)
        default: return nil
        }
    }
    
    @inlinable func advance(index: inout Int, end: Int) -> Bool {
        guard index != end, index + 1 != end else {
            error(string: "out of range");
            return false
        }
        index += 1
        return true
    }
    
    @inlinable func skip(source: [UInt8], index: inout Int, end: Int) {
        while index + 1 != end, source[index].blank {
            index += 1
        }
    }
    
    @inlinable func expect(string: StaticString, source: [UInt8], index: inout Int, end: Int) -> Bool {
        guard index != end else { return false }
        
        if !identifier(byte: string.utf8Start.pointee) {
            // when single character
            if string.utf8Start.pointee == source[index] {
                guard advance(index: &index, end: end) else { return false }
                return true
            } else {
                return false
            }
        }
        
        let start = index
        
        var p = string.utf8Start
        let endp = p.advanced(by: Int(string.utf8CodeUnitCount))
        while p != endp {
            if p.pointee != source[index] {
                index = start //unread (reset)
                return false
            }
            
            p += 1
            guard advance(index: &index, end: end) else { return false }
        }
        
        return true
    }
    
    @inlinable func expect(symbol: UInt8, source: [UInt8], index: inout Int, end: Int) -> Bool {
        if symbol == source[index] {
            guard advance(index: &index, end: end) else { return false }
            return true
        } else {
            return false
        }
    }
    
    @inlinable func identifier(byte: UInt8) -> Bool {
        switch byte {
        case .init(ascii: "a") ... .init(ascii: "z"): return true
        default: return false
        }
    }
}

public extension Conventer {
    @inlinable func parse(string: StaticString, as value: @autoclosure () -> Value?, source: [UInt8], index: inout Int, end: Int) -> Value? {
        guard expect(string: string, source: source, index: &index, end: end) else { return nil }
        return value()
    }
}

public extension Conventer {
    @inlinable func parseString(source: [UInt8], index: inout Int, end: Int) -> Value? {
        guard let value = parseStringValue(source: source, index: &index, end: end) else { return nil }
        return string(value: value)
    }
    
    @inlinable func parseStringValue(source: [UInt8], index: inout Int, end: Int) -> String? {
        guard advance(index: &index, end: end) else { return nil }
        
        var buffer = [CChar]()
        
        while index != end && source[index] != .init(ascii: "\"") {
            switch source[index] {
            case .init(ascii: "\\"):
                guard advance(index: &index, end: end) else { return nil }
                guard let escapedChar = parseEscaped(source: source, index: &index, end: end) else { return nil }
                String(escapedChar).utf8.forEach {
                    buffer.append(CChar(bitPattern: $0))
                }
            default: buffer.append(CChar(bitPattern: source[index]))
            }
            
            guard advance(index: &index, end: end) else { return nil }
        }
        
        guard expect(symbol: .init(ascii: "\""), source: source, index: &index, end: end) else { return nil }
        
        buffer.append(0) // trailing null
        
        return String(cString: buffer)
    }
    
    @inlinable func parseEscaped(source: [UInt8], index: inout Int, end: Int) -> UnicodeScalar? {
        let character = UnicodeScalar(source[index])
        
        // 'u' indicates unicode
        guard character == "u" else {
            return unescape[character] ?? character
        }
        
        guard let surrogateValue = parseEscapedUnicode(source: source, index: &index, end: end) else { return nil }
        
        // two consecutive \u#### sequences represent 32 bit unicode characters
        if source[index + 1] == .init(ascii: "\\") && source[index.advanced(by: 2)] == .init(ascii: "u") {
            guard advance(index: &index, end: end) else { return nil }
            guard advance(index: &index, end: end) else { return nil }
            
            guard let surrogatePairValue = parseEscapedUnicode(source: source, index: &index, end: end) else { return nil }
            
            return UnicodeScalar(surrogateValue << 16 | surrogatePairValue)
        }
        
        return UnicodeScalar(surrogateValue)
    }
    
    @inlinable func parseEscapedUnicode(source: [UInt8], index: inout Int, end: Int) -> UInt32? {
        let requiredLength = 4
        
        var length = 0
        var value: UInt32 = 0
        while let d = source[index + 1].hexToDigit, length < requiredLength {
            guard advance(index: &index, end: end) else { return nil }
            length += 1
            
            value <<= 4
            value |= d
        }
        
        guard length == requiredLength else { return nil }
        return value
    }
}

public extension Conventer {
    @inlinable func parseObject(source: [UInt8], index: inout Int, end: Int) -> Value? {
        guard advance(index: &index, end: end) else { return nil }
        skip(source: source, index: &index, end: end)
        
        var values = [String: Value]()
        
        while index != end && !expect(symbol: .init(ascii: "}"), source: source, index: &index, end: end) {
            skip(source: source, index: &index, end: end)
            guard let key = parseStringValue(source: source, index: &index, end: end) else { return nil }
            
            skip(source: source, index: &index, end: end)
            guard expect(symbol: .init(ascii: ":"), source: source, index: &index, end: end) else { return nil }
            skip(source: source, index: &index, end: end)
            
            let value = deserialize(source: source, index: &index, end: end)
            values[key] = value
            
            skip(source: source, index: &index, end: end)
            
            guard !expect(symbol: .init(ascii: "}"), source: source, index: &index, end: end) else { break }
            
            guard expect(symbol: .init(ascii: ","), source: source, index: &index, end: end) else { return nil }
        }
        
        return object(values: values)
    }
}

public extension Conventer {
    @inlinable func parseArray(source: [UInt8], index: inout Int, end: Int) -> Value? {
        guard advance(index: &index, end: end) else { return nil }
        skip(source: source, index: &index, end: end)
        
        var values = [Value]()
        
        while index != end && !expect(symbol: .init(ascii: "]"), source: source, index: &index, end: end) {
            if let json = deserialize(source: source, index: &index, end: end) {
                skip(source: source, index: &index, end: end)
                
                values.append(json)
                
                if expect(symbol: .init(ascii: ","), source: source, index: &index, end: end) {
                    continue
                } else if expect(symbol: .init(ascii: "]"), source: source, index: &index, end: end) {
                    break
                } else { return nil }
            }
        }
        
        return array(values: values)
    }
}

public extension Conventer {
    @inlinable func parseDouble(source: [UInt8], index: inout Int, end: Int) -> Value? {
        let sign = expect(symbol: .init(ascii: "-"), source: source, index: &index, end: end) ? -1.0 : 1.0
        
        var integer: Int64 = 0
        switch source[index] {
        case .init(ascii: "0"):
            guard advance(index: &index, end: end) else { return nil }
        case .init(ascii: "1") ... .init(ascii: "9"):
            while let value = source[index].digitToInt, index != end {
                integer = (integer * 10) + Int64(value)
                guard advance(index: &index, end: end) else { return nil }
            }
        default: return nil
        }
        
        var fraction: Double = 0.0
        if expect(symbol: .init(ascii: "."), source: source, index: &index, end: end) {
            var factor = 0.1
            var fractionLength = 0
            
            while let value = source[index].digitToInt , index != end {
                fraction += (Double(value) * factor)
                factor /= 10
                fractionLength += 1
                
                guard advance(index: &index, end: end) else { return nil }
            }
            
            guard fractionLength != 0 else { return nil }
        }
        
        var exponent: Int64 = 0
        if expect(symbol: .init(ascii: "e"), source: source, index: &index, end: end) || expect(symbol: .init(ascii: "E"), source: source, index: &index, end: end) {
            var expSign: Int64 = 1
            if expect(symbol: .init(ascii: "-"), source: source, index: &index, end: end) {
                expSign = -1
            } else if expect(symbol: .init(ascii: "+"), source: source, index: &index, end: end) {
                // do nothing
            }
            
            exponent = 0
            
            var exponentLength = 0
            while let value = source[index].digitToInt , index != end {
                exponent = (exponent * 10) + Int64(value)
                exponentLength += 1
                guard advance(index: &index, end: end) else { return nil }
            }
            
            guard exponentLength != 0 else { return nil }
            
            exponent *= expSign
        }
        
        let value = sign * (Double(integer) + fraction) * Double(pow(10, exponent))
        
        return double(value: value)
    }
}
