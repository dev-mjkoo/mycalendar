//
//  EventBlock.swift
//  mycalendar
//
//  Created by 구민준 on 5/12/25.
//

import EventKit

struct EventBlock {
    let startDate: Date
    let endDate: Date
    let event: EKEvent
    var lineIndex: Int = 0

    private let calendar = Calendar.current

    func daysBetween() -> [Date] {
        var result: [Date] = []
        var current = startDate
        while current <= endDate {
            result.append(calendar.startOfDay(for: current))
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        return result
    }
}
