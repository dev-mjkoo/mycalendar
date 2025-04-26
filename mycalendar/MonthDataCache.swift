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
            return cached
        }
        
        let monthData = createMonthData(for: date)
        cache[key] = monthData
        
        prefetchMonths(around: date, range: 1)
        
        return monthData
    }
    
    private func monthKey(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)"
    }
    
    private func createMonthData(for date: Date) -> MonthData {
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let range = calendar.range(of: .day, in: .month, for: start)!
        
        let firstWeekday = calendar.component(.weekday, from: start)
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: start)!
        
        var days: [DayItem] = []
        
        // 이전 달 날짜들
        if firstWeekday > 1 {
            let daysInPreviousMonth = calendar.range(of: .day, in: .month, for: previousMonth)!.count
            for day in (daysInPreviousMonth - firstWeekday + 2)...daysInPreviousMonth {
                var components = calendar.dateComponents([.year, .month], from: previousMonth)
                components.day = day
                if let date = calendar.date(from: components) {
                    let events = fetchEvents(for: date)
                    days.append(DayItem(date: date, isCurrentMonth: false, events: events))
                }
            }
        }
        
        // 현재 달 날짜들
        for day in range {
            var components = calendar.dateComponents([.year, .month], from: start)
            components.day = day
            let date = calendar.date(from: components)!
            let events = fetchEvents(for: date)
            days.append(DayItem(date: date, isCurrentMonth: true, events: events))
        }
        
        // 다음 달 날짜들 (6주 채우기)
        while days.count % 7 != 0 {
            if let lastDate = days.last?.date {
                let nextDate = calendar.date(byAdding: .day, value: 1, to: lastDate)!
                let events = fetchEvents(for: nextDate)
                days.append(DayItem(date: nextDate, isCurrentMonth: false, events: events))
            }
        }
        
        return MonthData(date: start, days: days)
    }
    
    private func fetchEvents(for date: Date) -> [Event] {
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        print("\n=== 이벤트 검색 시작 ===")
        print("검색 날짜: \(date)")
        print("시작 시간: \(startOfDay)")
        print("종료 시간: \(endOfDay)")
        
        do {
            // 먼저 모든 이벤트를 가져와서 로그
            let allEvents = try modelContext.fetch(FetchDescriptor<Event>())
            print("\nSwiftData에 저장된 모든 이벤트:")
            allEvents.forEach { event in
                print("- \(event.title): \(event.startDate) ~ \(event.endDate)")
            }
            
            // 메모리에서 필터링
            let filteredEvents = allEvents.filter { event in
                let eventStart = calendar.startOfDay(for: event.startDate)
                let eventEnd = calendar.startOfDay(for: event.endDate)
                let searchDate = calendar.startOfDay(for: date)
                
                let isInRange = eventStart == searchDate || eventEnd == searchDate ||
                               (eventStart < searchDate && eventEnd > searchDate) ||
                               (event.isAllDay && eventStart <= searchDate && eventEnd >= searchDate)
                
                if isInRange {
                    print("이벤트 매칭: \(event.title) - \(eventStart) ~ \(eventEnd)")
                }
                
                return isInRange
            }
            
            print("\n필터링된 이벤트 수: \(filteredEvents.count)")
            return filteredEvents
        } catch {
            print("이벤트 가져오기 실패: \(error.localizedDescription)")
            return []
        }
    }
    
    private func prefetchMonths(around date: Date, range: Int) {
        for offset in -range...range {
            if let prefetchDate = calendar.date(byAdding: .month, value: offset, to: date) {
                let key = monthKey(for: prefetchDate)
                if cache[key] == nil {
                    let monthData = createMonthData(for: prefetchDate)
                    cache[key] = monthData
                }
            }
        }
    }
}
