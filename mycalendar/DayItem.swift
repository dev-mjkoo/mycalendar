//
//  DayItem.swift
//  mycalendar
//
//  Created by 구민준 on 4/26/25.
//
import SwiftUI
import SwiftData

struct DayItem: Hashable {
    let id = UUID()
    let date: Date?
    let isCurrentMonth: Bool
    var events: [Event] = []
    
    static func == (lhs: DayItem, rhs: DayItem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

