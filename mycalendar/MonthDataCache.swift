import SwiftUI
import EventKit
import SwiftData

class MonthDataCache {
    private var cache: [String: MonthData] = [:]
    private let calendar = Calendar.current
    private let eventStore = EKEventStore()
    
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
                    days.append(DayItem(date: date, isCurrentMonth: false))
                }
            }
        }
        
        // 현재 달 날짜들
        for day in range {
            var components = calendar.dateComponents([.year, .month], from: start)
            components.day = day
            let date = calendar.date(from: components)!
            days.append(DayItem(date: date, isCurrentMonth: true))
        }
        
        // 다음 달 날짜들 (6주 채우기)
        while days.count % 7 != 0 {
            if let lastDate = days.last?.date {
                let nextDate = calendar.date(byAdding: .day, value: 1, to: lastDate)!
                days.append(DayItem(date: nextDate, isCurrentMonth: false))
            }
        }
        
        return MonthData(date: start, days: days)
    }
    
    private func fetchEvents(for date: Date) -> [EKEvent] {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        let predicate = eventStore.predicateForEvents(withStart: startOfMonth, end: endOfMonth, calendars: nil)
        return eventStore.events(matching: predicate)
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
