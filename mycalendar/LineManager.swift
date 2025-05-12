//
//  LineManager.swift
//  mycalendar
//
//  Created by 구민준 on 5/12/25.
//

import Foundation
import EventKit

class LineManager {
    private var lineUsage: [Date: [Int: String]] = [:]
    private let calendar = Calendar.current

    func assignLineIndex(for block: EventBlock) -> Int {
        let days = block.daysBetween()
        var usedLines = Set<Int>()

        for day in days {
            if let lines = lineUsage[day] {
                usedLines.formUnion(lines.keys)
            }
        }

        var line = 0
        while usedLines.contains(line) {
            line += 1
        }

        for day in days {
            if lineUsage[day] == nil {
                lineUsage[day] = [:]
            }
            lineUsage[day]![line] = block.event.eventIdentifier
        }

        return line
    }

    func reset() {
        lineUsage.removeAll()
    }
}
