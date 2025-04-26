//
//  MonthDataCache.swift
//  mycalendar
//
//  Created by 구민준 on 4/26/25.
//

import SwiftUI

class MonthDataCache {
    private var cache: [String: MonthData] = [:]
    private let calendar = Calendar.current
    
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
        
        var days: [DayItem] = []
        
        // 이전 달의 날짜들
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
        
        // 현재 달의 날짜들
        for day in 1...range.count {
            var components = calendar.dateComponents([.year, .month], from: start)
            components.day = day
            if let date = calendar.date(from: components) {
                days.append(DayItem(date: date, isCurrentMonth: true))
            }
        }
        
        // 다음 달의 날짜들
        let remainingDays = 42 - days.count
        if remainingDays > 0 {
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: start)!
            for day in 1...remainingDays {
                var components = calendar.dateComponents([.year, .month], from: nextMonth)
                components.day = day
                if let date = calendar.date(from: components) {
                    days.append(DayItem(date: date, isCurrentMonth: false))
                }
            }
        }
        
        return MonthData(date: date, days: days)
    }
}
