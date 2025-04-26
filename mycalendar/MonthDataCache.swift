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
        
        print("날짜: \(startOfDay) ~ \(endOfDay)의 이벤트를 가져옵니다.")
        
        let descriptor = FetchDescriptor<Event>(
            predicate: #Predicate<Event> { event in
                // 시작 시간이 해당 날짜에 있거나
                (event.startDate >= startOfDay && event.startDate < endOfDay) ||
                // 종료 시간이 해당 날짜에 있거나
                (event.endDate > startOfDay && event.endDate <= endOfDay) ||
                // 시작과 종료 사이에 해당 날짜가 있거나
                (event.startDate < startOfDay && event.endDate > endOfDay) ||
                // 종일 이벤트인 경우
                (event.isAllDay && event.startDate <= endOfDay && event.endDate >= startOfDay)
            }
        )
        
        do {
            let events = try modelContext.fetch(descriptor)
            print("가져온 이벤트 수: \(events.count)")
            events.forEach { event in
                print("- 이벤트: \(event.title), 시작: \(event.startDate), 종료: \(event.endDate)")
            }
            return events
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
