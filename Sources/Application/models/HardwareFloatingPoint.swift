enum HardwareFloatingPoint: Equatable, Hashable {
    case soft
    case softfp(fpu: String)
    case hard(fpu: String)
}

extension HardwareFloatingPoint {
    var flags: [String] {
        switch self {
        case .soft: return ["-msoft-float", "-mfloat-abi=soft"]
        case .softfp(let fpu): return ["-mhard-float", "-mfloat-abi=softfp", "-mfpu=\(fpu)"]
        case .hard(let fpu): return ["-mhard-float", "-mfloat-abi=hard", "-mfpu=\(fpu)"]
        }
    }
}
