//
//  mycalendarApp.swift
//  mycalendar
//
//  Created by 구민준 on 4/25/25.
//

import SwiftUI
import SwiftData
import ActivityKit

@main
struct mycalendarApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    startLiveActivity()
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    private func startLiveActivity() {
        let date = Date()
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        let weekdayInt = calendar.component(.weekday, from: date)
        let weekday = calendar.weekdaySymbols[calendar.component(.weekday, from: date) - 1]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일 (E)"
        let fullDate = formatter.string(from: date)
        
        let attributes = CalendarActivityAttributes(name: "Calendar")
        let contentState = CalendarActivityAttributes.ContentState(
            day: day,
            month: month,
            weekday: weekday,
            weekdayInt: weekdayInt,
            fullDate: fullDate
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                contentState: contentState,
                pushType: nil
            )
            print("Live Activity started: \(activity.id)")
        } catch {
            print("Error starting Live Activity: \(error.localizedDescription)")
        }
    }
}
