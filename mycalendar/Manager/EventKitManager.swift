import Foundation
import EventKit
import SwiftUI
import Combine

@MainActor
class EventKitManager: ObservableObject {
    static let shared = EventKitManager()
    
    @Published var isCalendarAccessGranted: Bool = false
    @Published var cacheVersion = UUID() // ✅ cache invalidate trigger용 (SwiftUI View에서 감지용)

    private let eventStore = EKEventStore()
    private var cancellables = Set<AnyCancellable>()
    private var eventCache: [Date: [Event]] = [:]

    private init() {
        setupEKEventStoreChangedListener()
        Task {
            await checkCalendarAccess()
        }
    }
    
    // ✅ 이벤트 스토어 변경 감지해서 캐시 리셋 & 뷰 갱신 트리거
    private func setupEKEventStoreChangedListener() {
        NotificationCenter.default.publisher(for: .EKEventStoreChanged)
            .sink { [weak self] _ in
                guard let self = self else { return }
                log("📣 EKEventStoreChanged 감지됨 -> 캐시 리셋 & 뷰 리프레시")
                self.clearCache()
                self.cacheVersion = UUID() // 뷰 업데이트 트리거
            }
            .store(in: &cancellables)
    }
    
    // ✅ 권한 체크 (앱 진입, scenePhase 등에서 호출)
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
                log("❗️ 캘린더 권한 요청 실패: \(error.localizedDescription)")
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
    
    // ✅ 특정 날짜 이벤트 가져오기 (캐시 없으면 자동 fetch)
    func events(for day: Date) -> [Event] {
        let calendar = Calendar.current
        let startOfMonth = calendar.startOfMonth(for: day)

        // 캐시 없으면 fetch (lazy load 패턴)
        if eventCache[startOfMonth] == nil {
            log("⚡️ [AUTO FETCH ON DEMAND] \(startOfMonth.formatted(date: .long, time: .omitted))")
            fetchEvents(for: startOfMonth) { _ in }
            return []
        }

        // 캐시에서 필터링된 일간 이벤트 반환
        return eventCache[startOfMonth]!.filter {
            isEvent($0, on: day, calendar: calendar, monthStart: startOfMonth)
        }
    }

    private func isEvent(_ event: Event, on day: Date, calendar: Calendar, monthStart: Date) -> Bool {
        let startOfDay = calendar.startOfDay(for: day)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        if let _ = event.recurrenceRule {
            return event.occurrences(in: monthStart).contains { calendar.isDate($0, inSameDayAs: day) }
        } else if let start = event.ekEvent.startDate,
                  let end = event.ekEvent.endDate {
            return start < endOfDay && end >= startOfDay
        } else if let start = event.ekEvent.startDate {
            return calendar.isDate(start, inSameDayAs: day)
        } else {
            return false
        }
    }
    
    // ✅ 월별 이벤트 fetch + 캐시화
    func fetchEvents(for month: Date, completion: @escaping ([Event]) -> Void) {
        guard isCalendarAccessGranted else {
            completion([])
            return
        }
        
        let calendar = Calendar.current
        let startOfMonth = calendar.startOfMonth(for: month)

        // 캐시 히트 시 바로 리턴
        if let cached = eventCache[startOfMonth] {
            log("🧠 [CACHE HIT] \(formattedMonth(from: startOfMonth))")
            completion(cached)
            return
        }

        log("🌐 [FETCH EVENTS] \(formattedMonth(from: startOfMonth))")

        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        let predicate = eventStore.predicateForEvents(withStart: startOfMonth, end: endOfMonth, calendars: nil)
        let ekEvents = eventStore.events(matching: predicate)
        
        let events = ekEvents.map { Event(ekEvent: $0) }
        eventCache[startOfMonth] = events
        completion(events)
    }
    
    private func notifyCacheInvalidated() {
        NotificationCenter.default.post(name: .eventKitCacheInvalidated, object: nil)
    }

    func clearCache() {
        eventCache.removeAll()
        cacheVersion = UUID() // 기존 View용
        notifyCacheInvalidated() // DailyEventSheetViewModel용
    }
    
    private func formattedMonth(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }
}

extension Notification.Name {
    static let eventKitCacheInvalidated = Notification.Name("eventKitCacheInvalidated")
}
