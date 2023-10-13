enum Teensy: String, Board {
    case v4_1 = "teensy 4.1"
    
    var description: String {
        switch self {
        case .v4_1: return "teensy41"
        }
    }
}
