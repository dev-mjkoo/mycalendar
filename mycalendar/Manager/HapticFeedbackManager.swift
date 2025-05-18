
import UIKit

/// ✅ Haptic Feedback 유틸 클래스
final class HapticFeedbackManager {
  
  /// 📌 진동 발생 함수
  static func trigger(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
    let generator = UIImpactFeedbackGenerator(style: style)
    generator.prepare()
    generator.impactOccurred()
  }
  
  /// 📌 더 강한 진동 (Success, Warning, Error)
  static func triggerNotification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
    let generator = UINotificationFeedbackGenerator()
    generator.prepare()
    generator.notificationOccurred(type)
  }
}
