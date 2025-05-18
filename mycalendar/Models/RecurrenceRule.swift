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
