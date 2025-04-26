//
//  DayItem.swift
//  mycalendar
//
//  Created by 구민준 on 4/26/25.
//
import SwiftUI

struct DayItem: Hashable {
    let id = UUID()
    let date: Date?
    let isCurrentMonth: Bool
    
    static func == (lhs: DayItem, rhs: DayItem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
