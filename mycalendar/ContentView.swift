//
//  ContentView.swift
//  mycalendar
//
//  Created by 구민준 on 4/25/25.

import SwiftUI
import EventKit

#if canImport(UIKit)
import UIKit
#endif

#if canImport(ActivityKit)
import ActivityKit
#endif

private let openSettingsURLString = "app-settings:"

struct ContentView: View {
    @StateObject private var liveActivityManager = LiveActivityManager.shared
    @StateObject private var calendarManager = CalendarManager.shared
    @State private var showingSettingsAlert = false
    @State private var currentDate = Date()
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        VStack(spacing: 0) {
 
            Spacer()
            
            Divider()
            
            VStack(spacing: 16) {
                Toggle(isOn: Binding(
                    get: { liveActivityManager.isLiveActivityEnabled },
                    set: { newValue in
                        Task { @MainActor in
                            await liveActivityManager.toggleLiveActivity()
                        }
                    }
                )) {
                    Text("캘린더 Live Activity")
                        .font(.headline)
                }
                .padding()
                
                Toggle(isOn: Binding(
                    get: { calendarManager.isCalendarAccessGranted },
                    set: { newValue in
                        if newValue {
                            Task {
                                let granted = await calendarManager.requestCalendarAccess()
                                if !granted {
                                    showingSettingsAlert = true
                                }
                            }
                        } else {
                            calendarManager.isCalendarAccessGranted = false
                        }
                    }
                )) {
                    Text("캘린더 연동")
                }
                .padding()
                .alert("캘린더 접근 권한이 필요합니다", isPresented: $showingSettingsAlert) {
                    Button("설정으로 이동") {
                        if let url = URL(string: openSettingsURLString) {
                            openURL(url)
                        }
                    }
                    Button("취소", role: .cancel) { }
                } message: {
                    Text("설정에서 캘린더 접근을 허용해주세요.")
                }
            }
        }
    }
    
    private func moveMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: currentDate) {
            currentDate = newDate
        }
    }
    
    private func getDaysOfWeek() -> [String] {
        let calendar = Calendar.current
        let symbols = calendar.veryShortWeekdaySymbols
        return symbols
    }
    
    private func getDaysInMonth() -> [Date?] {
        let calendar = Calendar.current
        let interval = calendar.dateInterval(of: .month, for: currentDate)!
        let firstDay = interval.start
        
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let offsetDays = firstWeekday - calendar.firstWeekday
        
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentDate)!.count
        
        var days: [Date?] = Array(repeating: nil, count: offsetDays)
        
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        
        // 마지막 주를 채우기 위한 빈 칸 추가
        let remainingDays = 7 - (days.count % 7)
        if remainingDays < 7 {
            days.append(contentsOf: Array(repeating: nil, count: remainingDays))
        }
        
        return days
    }
    
    private func isToday(date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
