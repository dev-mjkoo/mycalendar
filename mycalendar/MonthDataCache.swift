import SwiftUI
import EventKit
import SwiftData

class MonthDataCache {
    private var cache: [String: MonthData] = [:]
    private let calendar = Calendar.current
    private let modelContext: ModelContext
    private var eventCache: [String: [Event]] = [:]  // 이벤트 캐시 추가
    
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
        
        let startOfMonth = calendar.startOfDay(for: start)
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        var endComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: endOfMonth)
        endComponents.hour = 23
        endComponents.minute = 59
        endComponents.second = 59
        let endOfMonthDay = calendar.date(from: endComponents)!
        
        let monthEvents = fetchEventsForMonth(start: startOfMonth, end: endOfMonthDay)
        var days: [DayItem] = []
        
        if firstWeekday > 1 {
            let daysInPreviousMonth = calendar.range(of: .day, in: .month, for: previousMonth)!.count
            for day in (daysInPreviousMonth - firstWeekday + 2)...daysInPreviousMonth {
                var components = calendar.dateComponents([.year, .month], from: previousMonth)
                components.day = day
                if let date = calendar.date(from: components) {
                    let dayEvents = filterEventsForDate(monthEvents, date: date)
                    days.append(DayItem(date: date, isCurrentMonth: false, events: dayEvents))
                }
            }
        }
        
        for day in range {
            var components = calendar.dateComponents([.year, .month], from: start)
            components.day = day
            let date = calendar.date(from: components)!
            let dayEvents = filterEventsForDate(monthEvents, date: date)
            days.append(DayItem(date: date, isCurrentMonth: true, events: dayEvents))
        }
        
        while days.count % 7 != 0 {
            if let lastDate = days.last?.date {
                let nextDate = calendar.date(byAdding: .day, value: 1, to: lastDate)!
                let dayEvents = filterEventsForDate(monthEvents, date: nextDate)
                days.append(DayItem(date: nextDate, isCurrentMonth: false, events: dayEvents))
            }
        }
        
        return MonthData(date: start, days: days)
    }
    
    private func fetchEventsForMonth(start: Date, end: Date) -> [Event] {
        let monthKey = "\(calendar.component(.year, from: start))-\(calendar.component(.month, from: start))"
        
        // 캐시된 이벤트가 있으면 반환
        if let cachedEvents = eventCache[monthKey] {
            return cachedEvents
        }
        
        do {
            let fetchDescriptor = FetchDescriptor<Event>(
                predicate: #Predicate<Event> { event in
                    (event.startDate >= start && event.startDate <= end) ||
                    (event.endDate >= start && event.endDate <= end) ||
                    (event.startDate <= start && event.endDate >= end)
                }
            )
            let events = try modelContext.fetch(fetchDescriptor)
            
            // 이벤트를 캐시에 저장
            eventCache[monthKey] = events
            
            // 캐시 크기 제한 (최근 12개월만 유지)
            if eventCache.count > 12 {
                let sortedKeys = eventCache.keys.sorted()
                let keysToRemove = sortedKeys[0...(sortedKeys.count - 13)]
                keysToRemove.forEach { eventCache.removeValue(forKey: $0) }
            }
            
            return events
        } catch {
            print("이벤트 가져오기 실패: \(error.localizedDescription)")
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
    
    func clearCache() {
        cache.removeAll()
        eventCache.removeAll()
    }
}
