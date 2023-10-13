@usableFromInline let unescape: [UnicodeScalar: UnicodeScalar] = ["t": "\t", "r": "\r", "n": "\n"]
private let digits: [UnicodeScalar:Int] = ["0":0, "1":1, "2":2, "3":3, "4":4, "5":5, "6":6, "7":7, "8":8, "9":9,]
private let hex: [UnicodeScalar : UInt32] = ["0":0x0, "1":0x1, "2":0x2, "3":0x3, "4":0x4, "5":0x5, "6":0x6, "7":0x7, "8":0x8, "9":0x9, "a":0xa, "A":0xa, "b":0xb, "B":0xb, "c":0xc, "C":0xc, "d":0xd, "D":0xd, "e":0xe, "E":0xe, "f":0xf, "F":0xf]

extension UInt8 {
    @usableFromInline var digitToInt: Int? { digits[UnicodeScalar(self)] }
    @usableFromInline var hexToDigit: UInt32? { hex[UnicodeScalar(self)] }
    
    @usableFromInline var blank: Bool {
        switch self {
        case .space, .t, .r, .n: return true
        default: return false
        }
    }
    
    static var space: UInt8 { 0x20 } // space
    static var t: UInt8 { 0x09 } // \t
    static var n: UInt8 { 0x0a } // \n
    static var r: UInt8 { 0x0d } // \r
}

@usableFromInline func pow<T: BinaryInteger>(_ base: T, _ power: T) -> T {
    func expBySq(_ y: T, _ x: T, _ n: T) -> T {
        precondition(n >= 0)
        if n == 0 {
            return y
        } else if n == 1 {
            return y * x
        } else if n.isMultiple(of: 2) {
            return expBySq(y, x * x, n / 2)
        } else { // n is odd
            return expBySq(y * x, x * x, (n - 1) / 2)
        }
    }
    
    return expBySq(1, base, power)
}
