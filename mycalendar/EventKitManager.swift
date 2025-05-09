import Foundation
import EventKit
import SwiftUI

@MainActor
class EventKitManager: ObservableObject {
    static let shared = EventKitManager()

    @Published var isCalendarAccessGranted: Bool = false

    private let eventStore = EKEventStore()

    private init() {
        Task {
            await checkCalendarAccess()
        }
    }

    /// 현재 권한 상태 확인 (앱 진입 시 사용)
    func checkCalendarAccess() async {
        let status = EKEventStore.authorizationStatus(for: .event)
        isCalendarAccessGranted = (status == .authorized || status == .fullAccess)
    }

    /// 권한 요청 및 결과 처리
    func requestAccess() async -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)

        switch status {
        case .authorized, .fullAccess:
            isCalendarAccessGranted = true
            return true

        case .denied, .restricted:
            isCalendarAccessGranted = false
            return false

        case .notDetermined:
            do {
                let granted = try await eventStore.requestAccess(to: .event)
                isCalendarAccessGranted = granted
                return granted
            } catch {
                print("캘린더 권한 요청 실패: \(error.localizedDescription)")
                isCalendarAccessGranted = false
                return false
            }

        @unknown default:
            isCalendarAccessGranted = false
            return false
        }
    }

    /// 내부 상태만 해제 (설정 앱에서 권한을 끄는 건 사용자가 직접 해야 함)
    func revokeAccessFlagOnly() {
        isCalendarAccessGranted = false
    }

    /// 특정 월의 이벤트 가져오기
    func fetchEvents(for month: Date, completion: @escaping ([Date: [EKEvent]]) -> Void) {
        guard isCalendarAccessGranted else {
            completion([:])
            return
        }

        let calendar = Calendar.current
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
              let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else {
            completion([:])
            return
        }

        let predicate = eventStore.predicateForEvents(withStart: startOfMonth, end: endOfMonth, calendars: nil)
        let events = eventStore.events(matching: predicate)

        var grouped: [Date: [EKEvent]] = [:]

        for event in events {
            // 날짜별로 분해 (중복 표시)
            let start = max(calendar.startOfDay(for: event.startDate), calendar.startOfDay(for: startOfMonth))
            let end = min(calendar.startOfDay(for: event.endDate), calendar.startOfDay(for: endOfMonth))

            var date = start
            while date <= end {
                grouped[date, default: []].append(event)
                date = calendar.date(byAdding: .day, value: 1, to: date)!
            }
        }

        completion(grouped)
    }}
