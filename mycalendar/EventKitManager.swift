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
    
    func events(for day: Date) -> [Event] {
        let calendar = Calendar.current
        let startOfMonth = calendar.startOfMonth(for: day)

        // ✅ 캐시 없으면 바로 fetch 걸고 빈 리스트 리턴 (자동 선행)
        if eventCache[startOfMonth] == nil {
            log("⚡️ [AUTO FETCH ON DEMAND] \(startOfMonth.formatted(date: .long, time: .omitted))")
            fetchEvents(for: startOfMonth) { events in
                log("✅ [FETCH DONE] \(startOfMonth.formatted(date: .long, time: .omitted))")
                // 필요하다면 NotificationCenter 등으로 UI 리프레시 트리거
            }
            // ❗️ 당장 빈 리스트 리턴하더라도, 다음 클릭 시에는 뜸
            return []
        }

        return eventCache[startOfMonth]!.filter {
            isEvent($0, on: day, calendar: calendar, monthStart: startOfMonth)
        }
    }
    
    private func isEvent(_ event: Event, on day: Date, calendar: Calendar, monthStart: Date) -> Bool {
        let startOfDay = calendar.startOfDay(for: day)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        if let rule = event.recurrenceRule {
            return event.occurrences(in: monthStart).contains { calendar.isDate($0, inSameDayAs: day) }
        } else if let start = event.ekEvent.startDate,
                  let end = event.ekEvent.endDate {
            // 🔥 하루종일/시간 있는 이벤트 모두 정확히 커버
            return start < endOfDay && end >= startOfDay
        } else if let start = event.ekEvent.startDate {
            return calendar.isDate(start, inSameDayAs: day)
        } else {
            return false
        }
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
