import Foundation

enum DistributionChannel {
    case appStore
    case direct

    static var current: DistributionChannel {
        #if APP_STORE
        return .appStore
        #else
        return .direct
        #endif
    }
}
