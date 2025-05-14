//
//  Models.swift
//  mycalendar
//
//  Created by 구민준 on 5/13/25.
//

import Foundation
import EventKit

struct RecurrenceRule {
    let weekdays: [Int] // 1(Sun) ~ 7(Sat)

    func generateDates(in month: Date) -> [Date] {
        var dates: [Date] = []
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: month) else { return [] }

        for day in range {
            if let date = calendar.date(bySetting: .day, value: day, of: month),
               weekdays.contains(calendar.component(.weekday, from: date)) {
                dates.append(date)
            }
        }
        return dates
    }
}

struct Event {
    let ekEvent: EKEvent
    let recurrenceRule: RecurrenceRule?

    init(ekEvent: EKEvent) {
        self.ekEvent = ekEvent
        if let ekRule = ekEvent.recurrenceRules?.first,
           ekRule.frequency == .weekly,
           let days = ekRule.daysOfTheWeek {
            self.recurrenceRule = RecurrenceRule(weekdays: days.map { $0.dayOfTheWeek.rawValue })
        } else {
            self.recurrenceRule = nil
        }
    }

    /// 🔥 월 기준 발생일 계산 (단일, 반복, 멀티기간 모두 커버)
    func occurrences(in month: Date) -> [Date] {
        let calendar = Calendar.current

        if let rule = recurrenceRule {
            return rule.generateDates(in: month)
        } else {
            guard let start = ekEvent.startDate, let end = ekEvent.endDate else { return [] }
            
            // ✅ 해당 월의 범위 계산
            let startOfMonth = calendar.startOfMonth(for: month)
            guard let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)?.addingTimeInterval(-1) else { return [] }
            
            // ✅ 이벤트 기간과 월 기간이 겹치면
            if end >= startOfMonth && start <= endOfMonth {
                var dates: [Date] = []
                var currentDate = max(calendar.startOfDay(for: start), startOfMonth)
                let finalDate = min(calendar.startOfDay(for: end), endOfMonth)
                
                while currentDate <= finalDate {
                    dates.append(currentDate)
                    currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
                }
                return dates
            } else {
                return []
            }
        }
    }
}
