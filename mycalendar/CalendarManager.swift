import Foundation
import EventKit
import SwiftUI

@MainActor
class CalendarManager: ObservableObject {
    static let shared = CalendarManager()

    @Published var isCalendarAccessGranted = false
    private let eventStore = EKEventStore()

    private init() {
        Task {
            await checkCalendarAccess()
        }
    }

    func checkCalendarAccess() async {
        let status = EKEventStore.authorizationStatus(for: .event)
        isCalendarAccessGranted = (status == .fullAccess)
    }

    func requestCalendarAccess() async -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)

        if status == .fullAccess {
            isCalendarAccessGranted = true
            return true
        }

        if status == .denied || status == .restricted {
            isCalendarAccessGranted = false
            return false
        }

        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            isCalendarAccessGranted = granted
            return granted
        } catch {
            print("캘린더 권한 요청 실패: \(error.localizedDescription)")
            isCalendarAccessGranted = false
            return false
        }
    }

    func revokeCalendarAccess() {
        isCalendarAccessGranted = false
        // 시스템 권한은 설정에서만 변경 가능함
    }
}
