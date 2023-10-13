enum Architecture: Equatable, Hashable {
    case armv7(cpu: CPU, float: HardwareFloatingPoint)
}

extension Architecture {
    var target: String {
        switch self {
        case .armv7(let cpu, let float):
            let fpu = float == .soft ? "" : "hf"
            switch cpu {
            case .cortex_m7: return "thumbv7em-unknown-none-eabi" + fpu
            }
        }
    }
    
    var cpu: String {
        switch self {
        case .armv7(let cpu, _): return cpu.rawValue
        }
    }
    
    var flags: [String] {
        switch self {
        case .armv7(_, let float): return float.flags
        }
    }
}
