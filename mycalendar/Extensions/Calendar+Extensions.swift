//
//  Calendar+Extensions.swift
//  mycalendar
//
//  Created by 구민준 on 5/18/25.
//
import Foundation

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        return self.date(from: self.dateComponents([.year, .month], from: date))!
    }
    
    func startOfWeek(for date: Date) -> Date {
        let weekday = component(.weekday, from: date)
        let daysToSubtract = weekday - 1
        return self.date(byAdding: .day, value: -daysToSubtract, to: startOfDay(for: date))!
    }
}
