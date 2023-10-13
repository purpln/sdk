enum CPU: String, Equatable, Hashable {
    case cortex_m7 = "cortex-m7"
}

extension CPU {
    var instructions: Instructions {
        switch self {
        case .cortex_m7: return .bit32
        }
    }
}
