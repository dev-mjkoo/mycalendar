import SwiftUI
import EventKit
import SwiftData

class MonthDataCache {
    private var cache: [String: MonthData] = [:]
    private let calendar = Calendar.current
    private let eventStore = EKEventStore()
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func monthData(for date: Date) -> MonthData {
        let key = monthKey(for: date)
        if let cached = cache[key] {
            print("📦 캐시 히트: \(key)")
            return cached
        }
        
        print("🔄 캐시 미스: \(key) - 새로운 데이터 생성")
        let monthData = createMonthData(for: date)
        cache[key] = monthData
        print("💾 캐시 저장: \(key)")
        
        prefetchMonths(around: date, range: 1)
        
        return monthData
    }
    
    private func monthKey(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)"
    }
    
    private func createMonthData(for date: Date) -> MonthData {
        print("📅 월 데이터 생성 시작: \(monthKey(for: date))")
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let range = calendar.range(of: .day, in: .month, for: start)!
        
        let firstWeekday = calendar.component(.weekday, from: start)
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: start)!
        
        // 한 달의 시작과 끝 날짜 계산 (사용자의 로컬 시간대 기준)
        let startOfMonth = calendar.startOfDay(for: start)
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        // 마지막 날의 끝 시간을 23:59:59로 설정
        var endComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: endOfMonth)
        endComponents.hour = 23
        endComponents.minute = 59
        endComponents.second = 59
        let endOfMonthDay = calendar.date(from: endComponents)!
        
        // 로그 출력을 위한 날짜 포맷터 설정
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        dateFormatter.timeZone = TimeZone.current // 사용자의 로컬 시간대 사용
        
        print("📅 이벤트 가져오기 시작: \(dateFormatter.string(from: startOfMonth)) ~ \(dateFormatter.string(from: endOfMonthDay))")
        // 한 달의 모든 이벤트를 한 번에 가져오기
        let monthEvents = fetchEventsForMonth(start: startOfMonth, end: endOfMonthDay)
        print("📅 이벤트 가져오기 완료: \(monthEvents.count)개")
        
        var days: [DayItem] = []
        
        // 이전 달 날짜들
        if firstWeekday > 1 {
            print("📅 이전 달 날짜 추가 시작")
            let daysInPreviousMonth = calendar.range(of: .day, in: .month, for: previousMonth)!.count
            for day in (daysInPreviousMonth - firstWeekday + 2)...daysInPreviousMonth {
                var components = calendar.dateComponents([.year, .month], from: previousMonth)
                components.day = day
                if let date = calendar.date(from: components) {
                    let dayEvents = filterEventsForDate(monthEvents, date: date)
                    days.append(DayItem(date: date, isCurrentMonth: false, events: dayEvents))
                }
            }
            print("📅 이전 달 날짜 추가 완료: \(days.count)일")
            print("─────────────────────────────────────────────")
        }
        
        // 현재 달 날짜들
        print("📅 현재 달 날짜 추가 시작")
        for day in range {
            var components = calendar.dateComponents([.year, .month], from: start)
            components.day = day
            let date = calendar.date(from: components)!
            let dayEvents = filterEventsForDate(monthEvents, date: date)
            days.append(DayItem(date: date, isCurrentMonth: true, events: dayEvents))
        }
        print("📅 현재 달 날짜 추가 완료: \(days.count)일")
        print("─────────────────────────────────────────────")
        
        // 다음 달 날짜들 (6주 채우기)
        print("📅 다음 달 날짜 추가 시작 (6주 채우기)")
        while days.count % 7 != 0 {
            if let lastDate = days.last?.date {
                let nextDate = calendar.date(byAdding: .day, value: 1, to: lastDate)!
                let dayEvents = filterEventsForDate(monthEvents, date: nextDate)
                days.append(DayItem(date: nextDate, isCurrentMonth: false, events: dayEvents))
            }
        }
        print("📅 다음 달 날짜 추가 완료: \(days.count)일")
        print("─────────────────────────────────────────────")
        
        print("✅ 월 데이터 생성 완료: \(days.count)일")
        return MonthData(date: start, days: days)
    }
    
    private func fetchEventsForMonth(start: Date, end: Date) -> [Event] {
        do {
            let fetchDescriptor = FetchDescriptor<Event>(
                predicate: #Predicate<Event> { event in
                    (event.startDate >= start && event.startDate <= end) ||
                    (event.endDate >= start && event.endDate <= end) ||
                    (event.startDate <= start && event.endDate >= end)
                }
            )
            return try modelContext.fetch(fetchDescriptor)
        } catch {
            print("❌ 이벤트 가져오기 실패: \(error.localizedDescription)")
            return []
        }
    }
    
    private func filterEventsForDate(_ events: [Event], date: Date) -> [Event] {
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return events.filter { event in
            let eventStart = calendar.startOfDay(for: event.startDate)
            let eventEnd = calendar.startOfDay(for: event.endDate)
            let searchDate = calendar.startOfDay(for: date)
            
            return eventStart == searchDate || eventEnd == searchDate ||
                   (eventStart < searchDate && eventEnd > searchDate) ||
                   (event.isAllDay && eventStart <= searchDate && eventEnd >= searchDate)
        }
    }
    
    private func prefetchMonths(around date: Date, range: Int) {
        print("📥 주변 월 프리페칭 시작: \(range)개")
        // 선택된 월의 시작일을 기준으로 계산
        let startOfSelectedMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        
        for offset in -range...range {
            if let prefetchDate = calendar.date(byAdding: .month, value: offset, to: startOfSelectedMonth) {
                let key = monthKey(for: prefetchDate)
                if cache[key] == nil {
                    print("📥 프리페칭: \(key)")
                    let monthData = createMonthData(for: prefetchDate)
                    cache[key] = monthData
                }
            }
        }
        print("✅ 주변 월 프리페칭 완료")
    }
}
