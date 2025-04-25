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
    @State private var isLiveActivityEnabled = false
    @State private var activity: Activity<CalendarActivityAttributes>? = nil
    @State private var currentMonth = Date()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월"
        return formatter
    }()

    var body: some View {
        VStack(spacing: 0) {
            Text(dateFormatter.string(from: currentMonth))
                .font(.headline)
                .padding(.vertical, 8)
            
            CalendarView(currentMonthBinding: $currentMonth)
            
            Spacer()
            
            Divider()
            
            Toggle(isOn: $isLiveActivityEnabled) {
                Text("캘린더 Live Activity")
                    .font(.headline)
            }
            .padding()
            .onChange(of: isLiveActivityEnabled) { _, newValue in
                if newValue {
                    startLiveActivity()
                } else {
                    stopLiveActivity()
                }
            }
        }
        .onAppear {
            Task {
                for activity in Activity<CalendarActivityAttributes>.activities {
                    isLiveActivityEnabled = true
                    self.activity = activity
                    break
                }
            }
        }
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
            isLiveActivityEnabled = false  // 실패 시 토글 상태를 false로 되돌림
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
