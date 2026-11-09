import SwiftUI
#if os(iOS)
import UIKit
#endif

public final class HapticService: Sendable {
    public static let shared = HapticService()
    
    public init() {}
    
    public func triggerNotification(_ type: NotificationFeedbackType) {
        #if os(iOS)
        Task { @MainActor in
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            switch type {
            case .success: generator.notificationOccurred(.success)
            case .warning: generator.notificationOccurred(.warning)
            case .error: generator.notificationOccurred(.error)
            }
        }
        #endif
    }
    
    public func triggerImpact(_ style: ImpactFeedbackStyle) {
        #if os(iOS)
        Task { @MainActor in
            let feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle
            switch style {
            case .light: feedbackStyle = .light
            case .medium: feedbackStyle = .medium
            case .heavy: feedbackStyle = .heavy
            case .rigid: feedbackStyle = .rigid
            case .soft: feedbackStyle = .soft
            }
            let generator = UIImpactFeedbackGenerator(style: feedbackStyle)
            generator.prepare()
            generator.impactOccurred()
        }
        #endif
    }
}

public enum NotificationFeedbackType: Sendable {
    case success
    case warning
    case error
}

public enum ImpactFeedbackStyle: Sendable {
    case light
    case medium
    case heavy
    case rigid
    case soft
}
