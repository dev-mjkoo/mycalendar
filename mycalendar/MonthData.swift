//
//  MonthData.swift
//  mycalendar
//
//  Created by 구민준 on 4/26/25.
//
import SwiftUI

struct MonthData: Identifiable {
    let id = UUID()
    let date: Date
    let days: [DayItem]
}


