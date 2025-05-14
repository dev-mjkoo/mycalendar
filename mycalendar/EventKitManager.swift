import Foundation
import EventKit
import SwiftUI

@MainActor
class EventKitManager: ObservableObject {
    static let shared = EventKitManager()
    
    @Published var isCalendarAccessGranted: Bool = false
    
    private let eventStore = EKEventStore()
    
    private var eventCache: [Date: [Event]] = [:]  // ✅ 캐시도 Event 기준

    private init() {
        Task {
            await checkCalendarAccess()
        }
    }
    
    func checkCalendarAccess() async {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .fullAccess, .writeOnly:
            isCalendarAccessGranted = true
        default:
            isCalendarAccessGranted = false
        }
    }
    
    func requestAccess() async -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)

        switch status {
        case .fullAccess, .writeOnly:
            isCalendarAccessGranted = true
            return true
        case .denied, .restricted:
            isCalendarAccessGranted = false
            return false
        case .notDetermined:
            do {
                let granted = try await eventStore.requestFullAccessToEvents()
                isCalendarAccessGranted = granted
                return granted
            } catch {
                log("캘린더 권한 요청 실패: \(error.localizedDescription)")
                isCalendarAccessGranted = false
                return false
            }
        @unknown default:
            isCalendarAccessGranted = false
            return false
        }
    }
    
    func revokeAccessFlagOnly() {
        isCalendarAccessGranted = false
    }
    
    /// 🔥 특정 월의 이벤트를 [Event] 형태로 가져오기 (더 이상 그룹화 없음)
    func fetchEvents(for month: Date, completion: @escaping ([Event]) -> Void) {
        guard isCalendarAccessGranted else {
            completion([])
            return
        }
        
        let calendar = Calendar.current
        let startOfMonth = calendar.startOfMonth(for: month)

        // ✅ 캐시 확인 먼저
        if let cached = eventCache[startOfMonth] {
            log("🧠 [CACHE HIT] \(formattedMonth(from: startOfMonth))")
            completion(cached)
            return
        }
        
        log("🌐 [FETCH EVENTS] \(formattedMonth(from: startOfMonth))")
        
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        let predicate = eventStore.predicateForEvents(withStart: startOfMonth, end: endOfMonth, calendars: nil)
        let ekEvents = eventStore.events(matching: predicate)
        
        let events = ekEvents.map { Event(ekEvent: $0) }  // ✅ 직접 Event로 변환
        eventCache[startOfMonth] = events  // ✅ 캐시 저장
        completion(events)
    }
    
    func clearCache() {
        eventCache.removeAll()
    }
    
    private func formattedMonth(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        return self.date(from: self.dateComponents([.year, .month], from: date))!
    }
}
