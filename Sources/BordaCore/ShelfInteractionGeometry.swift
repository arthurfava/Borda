import Foundation

public enum ShelfInteractionState: Sendable {
    case collapsed
    case expanded
}

public enum ShelfInteractionGeometry {
    /// A pequena margem invisivel evita que movimentos naturais do ponteiro
    /// atravessem um pixel de separacao e fechem a caixa prematuramente.
    public static func region(around frame: CGRect, state: ShelfInteractionState) -> CGRect {
        switch state {
        case .collapsed:
            return frame.insetBy(dx: -18, dy: -14)
        case .expanded:
            return frame.insetBy(dx: -10, dy: -10)
        }
    }
}
