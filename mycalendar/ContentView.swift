//
//  ContentView.swift
//  mycalendar
//
//  Created by 구민준 on 4/25/25.
//

import SwiftUI
import SwiftData
import ActivityKit
import EventKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @State private var isLiveActivityEnabled = false
    @State private var isCalendarSyncEnabled = false
    @State private var activity: Activity<CalendarActivityAttributes>? = nil
    @State private var currentMonth = Date()
    @State private var syncedMonths: Set<String> = []  // 이미 동기화된 달을 추적
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedDate: Date = Date()
    @Query private var events: [Event]
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월"
        return formatter
    }()

    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter
    }()

    var selectedDateEvents: [Event] {
        let calendar = Calendar.current
        return events.filter { event in
            calendar.isDate(event.startDate, inSameDayAs: selectedDate)
        }.sorted { $0.startDate < $1.startDate }
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(dateFormatter.string(from: currentMonth))
                .font(.headline)
                .padding(.vertical, 8)
            
            CalendarView(currentMonthBinding: $currentMonth)
                .onChange(of: currentMonth) { _, _ in
                    onMonthChange()
                }
            
            if !selectedDateEvents.isEmpty {
                List(selectedDateEvents, id: \.id) { event in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .font(.headline)
                        
                        HStack {
                            if event.isAllDay {
                                Text("종일")
                                    .foregroundColor(.gray)
                            } else {
                                Text(formatEventTime(event))
                                    .foregroundColor(.gray)
                            }
                            
                            if let location = event.location, !location.isEmpty {
                                Text("📍 \(location)")
                                    .foregroundColor(.gray)
                            }
                        }
                        .font(.subheadline)
                    }
                    .padding(.vertical, 4)
                }
            } else {
                VStack {
                    Text("일정이 없습니다")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            Divider()
            
            VStack(spacing: 16) {
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
                
                Toggle(isOn: $isCalendarSyncEnabled) {
                    Text("아이폰 캘린더 동기화")
                        .font(.headline)
                }
                .padding()
                .onChange(of: isCalendarSyncEnabled) { _, newValue in
                    if newValue {
                        requestCalendarAccess()
                    }
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
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && isCalendarSyncEnabled {
                syncCurrentMonth()
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

    private func startLiveActivity() {
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
            let activity = try Activity.request(
                attributes: activityAttributes,
                contentState: initialContentState,
                pushType: nil
            )
            self.activity = activity
        } catch {
            print("Error starting Live Activity: \(error.localizedDescription)")
        }
    }
    
    private func stopLiveActivity() {
        if let activity = activity {
            Task {
                await activity.end(nil, dismissalPolicy: .immediate)
                self.activity = nil
            }
        }
    }
    
    private func requestCalendarAccess() {
        let store = EKEventStore()
        
        switch EKEventStore.authorizationStatus(for: .event) {
        case .notDetermined:
            store.requestAccess(to: .event) { granted, error in
                if granted {
                    // 캘린더 접근 권한이 허용됨
                    syncWithCalendar()
                } else {
                    // 캘린더 접근 권한이 거부됨
                    isCalendarSyncEnabled = false
                }
            }
        case .restricted, .denied:
            // 이미 권한이 거부된 상태
            isCalendarSyncEnabled = false
        case .authorized:
            // 이미 권한이 허용된 상태
            syncWithCalendar()
        @unknown default:
            break
        }
    }
    
    private func syncCurrentMonth() {
        let store = EKEventStore()
        let calendar = Calendar.current
        
        // 현재 달의 시작일과 종료일 계산
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        do {
            let predicate = store.predicateForEvents(withStart: startOfMonth, end: endOfMonth, calendars: nil)
            let events = store.events(matching: predicate)
            
            // 현재 달의 이벤트만 필터링하여 삭제
            let fetchDescriptor = FetchDescriptor<Event>()
            let existingEvents = try modelContext.fetch(fetchDescriptor)
            
            existingEvents
                .filter { event in
                    let eventComponents = calendar.dateComponents([.year, .month], from: event.startDate)
                    let currentComponents = calendar.dateComponents([.year, .month], from: currentMonth)
                    return eventComponents.year == currentComponents.year && 
                           eventComponents.month == currentComponents.month
                }
                .forEach { modelContext.delete($0) }
            
            // 새로운 이벤트 추가
            for ekEvent in events {
                let event = Event(ekEvent: ekEvent)
                modelContext.insert(event)
            }
            
            try modelContext.save()
            print("\(monthFormatter.string(from: currentMonth)) 달의 \(events.count)개 이벤트를 동기화했습니다.")
        } catch {
            print("캘린더 동기화 중 오류 발생: \(error.localizedDescription)")
            isCalendarSyncEnabled = false
        }
    }
    
    private func syncWithCalendar() {
        let monthKey = monthFormatter.string(from: currentMonth)
        guard !syncedMonths.contains(monthKey) else {
            print("\(monthKey) 달의 데이터는 이미 동기화되어 있습니다.")
            return
        }
        
        let store = EKEventStore()
        let calendar = Calendar.current
        
        // 현재 달의 시작일과 종료일 계산
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        do {
            let predicate = store.predicateForEvents(withStart: startOfMonth, end: endOfMonth, calendars: nil)
            let events = store.events(matching: predicate)
            
            // 현재 달의 이벤트만 필터링하여 삭제
            let fetchDescriptor = FetchDescriptor<Event>()
            let existingEvents = try modelContext.fetch(fetchDescriptor)
            
            existingEvents
                .filter { event in
                    let eventComponents = calendar.dateComponents([.year, .month], from: event.startDate)
                    let currentComponents = calendar.dateComponents([.year, .month], from: currentMonth)
                    return eventComponents.year == currentComponents.year && 
                           eventComponents.month == currentComponents.month
                }
                .forEach { modelContext.delete($0) }
            
            // 새로운 이벤트 추가
            for ekEvent in events {
                let event = Event(ekEvent: ekEvent)
                modelContext.insert(event)
            }
            
            try modelContext.save()
            syncedMonths.insert(monthKey)
            print("\(monthKey) 달의 \(events.count)개 이벤트를 동기화했습니다.")
        } catch {
            print("캘린더 동기화 중 오류 발생: \(error.localizedDescription)")
            isCalendarSyncEnabled = false
        }
    }
    
    private func onMonthChange() {
        if isCalendarSyncEnabled {
            syncWithCalendar()
        }
    }

    private func formatEventTime(_ event: Event) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "a h:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return "\(formatter.string(from: event.startDate)) - \(formatter.string(from: event.endDate))"
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
