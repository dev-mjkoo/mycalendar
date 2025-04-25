//
//  ContentView.swift
//  mycalendar
//
//  Created by 구민준 on 4/25/25.
//

import SwiftUI
import SwiftData
import ActivityKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @State private var activity: Activity<CalendarActivityAttributes>? = nil

    var body: some View {
        VStack {
            if activity == nil {
                Button("Start Live Activity") {
                    startLiveActivity()
                }
            } else {
                Button("Stop Live Activity") {
                    stopLiveActivity()
                }
            }
        }
        .padding()
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }

    func startLiveActivity() {
        // 기존 Live Activity 종료
        for activity in Activity<CalendarActivityAttributes>.activities {
            Task {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
        
        let date = Date()
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        
        // 시스템 선호 언어 사용
        let preferredLocale = Locale.preferredLanguages.first.flatMap { Locale(identifier: $0) } ?? .current
        
        // 현재 기기 언어에 맞는 축약형 요일
        let formatter = DateFormatter()
        formatter.locale = preferredLocale
        formatter.dateFormat = "E"
        let weekday = formatter.string(from: date)
        print("App Debug - Creating Live Activity with weekday: \(weekday), locale: \(preferredLocale.identifier)")
        
        // 전체 날짜 포맷
        let fullDateFormatter = DateFormatter()
        fullDateFormatter.locale = preferredLocale
        fullDateFormatter.dateFormat = "yyyy년 M월 d일 (E)"
        let fullDate = fullDateFormatter.string(from: date)
        
        let initialContentState = CalendarActivityAttributes.ContentState(
            day: day,
            month: month,
            weekday: weekday,
            weekdayInt: calendar.component(.weekday, from: date),
            fullDate: fullDate
        )
        
        let activityAttributes = CalendarActivityAttributes(name: "Calendar")
        
        do {
            activity = try Activity.request(
                attributes: activityAttributes,
                contentState: initialContentState,
                pushType: nil
            )
            print("App Debug - Live Activity started successfully")
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func stopLiveActivity() {
        Task {
            await activity?.end(nil, dismissalPolicy: .immediate)
            activity = nil
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
