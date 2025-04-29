//
//  ContentView.swift
//  mycalendar
//
//  Created by 구민준 on 4/25/25.

//주요 개선사항을 설명드리겠습니다:
//스크롤 방향 기반 프리페칭:
//사용자가 스크롤하는 방향을 감지하여 해당 방향의 다음 달 데이터만 미리 로드
//불필요한 데이터 로드를 줄임
//점진적 데이터 로딩:
//현재 보이는 월의 데이터만 먼저 로드
//스크롤 방향에 따라 필요한 데이터만 추가로 로드
//메모리 최적화:
//필요한 데이터만 메모리에 유지
//캐시된 데이터는 필요한 경우에만 로드
//이렇게 수정하면:
//앱의 반응성이 더 빨라집니다
//메모리 사용량이 최적화됩니다
//사용자 경험이 더 부드러워집니다
//추가로 개선할 수 있는 부분:
//백그라운드 스레드에서 데이터 로딩
//데이터 압축 저장
//캐시 만료 시간 설정
//메모리 부족 시 오래된 캐시 자동 정리
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
    @State private var cachedMonths: Set<String> = []  // 캐시된 달을 추적
    @State private var scrollDirection: ScrollDirection = .none  // 스크롤 방향 추적
    @State private var visibleMonths: Set<String> = []  // 현재 보이는 월들
    @Environment(\.scenePhase) private var scenePhase
    
    // 캐시된 월의 최대 개수 제한
    private let maxCachedMonths = 12  // 1년치 데이터만 캐시
    
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

    enum ScrollDirection {
        case none, forward, backward
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
            
            Spacer()
            
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
                    } else {
                        // 동기화 중지 로직
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
                // 앱이 포그라운드로 돌아올 때 모든 캐시를 초기화하고 현재 월만 동기화
                syncedMonths.removeAll()
                cachedMonths.removeAll()
                syncWithCalendar()
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
        print("🔄 현재 월 동기화 시작: \(monthFormatter.string(from: currentMonth))")
        let store = EKEventStore()
        let calendar = Calendar.current
        
        // 현재 달의 시작일과 종료일 계산
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        do {
            let predicate = store.predicateForEvents(withStart: startOfMonth, end: endOfMonth, calendars: nil)
            let events = store.events(matching: predicate)
            print("📅 이벤트 가져오기 완료: \(events.count)개")
            
            // 현재 달의 이벤트만 필터링하여 삭제
            let fetchDescriptor = FetchDescriptor<Event>(
                predicate: #Predicate<Event> { event in
                    event.startDate >= startOfMonth && event.startDate <= endOfMonth
                }
            )
            let existingEvents = try modelContext.fetch(fetchDescriptor)
            print("🗑️ 기존 이벤트 삭제: \(existingEvents.count)개")
            
            // 기존 이벤트 삭제
            for event in existingEvents {
                modelContext.delete(event)
            }
            
            // 새로운 이벤트 추가
            for ekEvent in events {
                let event = Event(ekEvent: ekEvent)
                modelContext.insert(event)
            }
            
            try modelContext.save()
            print("✅ \(monthFormatter.string(from: currentMonth)) 달의 \(events.count)개 이벤트 동기화 완료")
        } catch {
            print("❌ 캘린더 동기화 중 오류 발생: \(error.localizedDescription)")
            isCalendarSyncEnabled = false
        }
    }
    
    private func syncWithCalendar() {
        let monthKey = monthFormatter.string(from: currentMonth)
        print("🔄 캘린더 동기화 시작: \(monthKey)")
        
        // 현재 월의 데이터만 먼저 로드
        loadMonthData(for: currentMonth)
        
        // 스크롤 방향에 따라 다음 데이터 프리페칭
        switch scrollDirection {
        case .forward:
            if let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) {
                print("📥 다음 달 프리페칭: \(monthFormatter.string(from: nextMonth))")
                loadMonthData(for: nextMonth)
            }
        case .backward:
            if let prevMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) {
                print("📥 이전 달 프리페칭: \(monthFormatter.string(from: prevMonth))")
                loadMonthData(for: prevMonth)
            }
        case .none:
            break
        }
    }
    
    private func loadMonthData(for month: Date) {
        let monthKey = monthFormatter.string(from: month)
        guard !cachedMonths.contains(monthKey) else {
            print("📦 이미 캐시된 월: \(monthKey)")
            return
        }
        
        // 캐시된 월이 최대 개수를 초과하면 오래된 데이터 정리
        if cachedMonths.count >= maxCachedMonths {
            print("🧹 캐시 정리 필요: \(cachedMonths.count)개")
            cleanupOldCache()
        }
        
        let store = EKEventStore()
        let calendar = Calendar.current
        
        // 해당 월의 시작일과 종료일 계산
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        // 1일이 속한 주의 시작일 계산 (이전 달 날짜 포함)
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let firstWeekStart = calendar.date(byAdding: .day, value: -(firstWeekday - 1), to: startOfMonth)!
        
        // 마지막 날이 속한 주의 마지막 날 계산 (다음 달 날짜 포함)
        let lastWeekday = calendar.component(.weekday, from: endOfMonth)
        let lastWeekEnd = calendar.date(byAdding: .day, value: (7 - lastWeekday), to: endOfMonth)!
        
        do {
            let predicate = store.predicateForEvents(withStart: firstWeekStart, end: lastWeekEnd, calendars: nil)
            let events = store.events(matching: predicate)
            print("📅 이벤트 가져오기 완료: \(events.count)개")
            
            // 해당 기간의 이벤트만 필터링하여 삭제
            let fetchDescriptor = FetchDescriptor<Event>(
                predicate: #Predicate<Event> { event in
                    event.startDate >= firstWeekStart && event.startDate <= lastWeekEnd
                }
            )
            let existingEvents = try modelContext.fetch(fetchDescriptor)
            print("🗑️ 기존 이벤트 삭제: \(existingEvents.count)개")
            
            // 기존 이벤트 삭제
            for event in existingEvents {
                modelContext.delete(event)
            }
            
            // 새로운 이벤트 추가
            for ekEvent in events {
                let event = Event(ekEvent: ekEvent)
                modelContext.insert(event)
            }
            
            try modelContext.save()
            cachedMonths.insert(monthKey)
            print("✅ \(monthKey) 달의 \(events.count)개 이벤트 로드 완료")
            
            // 캘린더 뷰 새로고침
            NotificationCenter.default.post(name: NSNotification.Name("RefreshCalendarCache"), object: nil)
        } catch {
            print("❌ 캘린더 데이터 로드 중 오류 발생: \(error.localizedDescription)")
            // 오류 발생 시 캐시에서 해당 월 제거
            cachedMonths.remove(monthKey)
        }
    }
    
    private func cleanupOldCache() {
        print("🧹 오래된 캐시 정리 시작")
        // 현재 보이는 월을 제외한 오래된 캐시 정리
        let monthsToKeep = visibleMonths
        let monthsToRemove = cachedMonths.subtracting(monthsToKeep)
        
        for monthKey in monthsToRemove {
            print("🗑️ 캐시 정리: \(monthKey)")
            // 해당 월의 이벤트 삭제
            let calendar = Calendar.current
            if let date = monthFormatter.date(from: monthKey) {
                let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
                let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
                
                do {
                    let fetchDescriptor = FetchDescriptor<Event>(
                        predicate: #Predicate<Event> { event in
                            event.startDate >= startOfMonth && event.startDate <= endOfMonth
                        }
                    )
                    let events = try modelContext.fetch(fetchDescriptor)
                    for event in events {
                        modelContext.delete(event)
                    }
                    try modelContext.save()
                    print("✅ \(monthKey) 캐시 정리 완료")
                } catch {
                    print("❌ 캐시 정리 중 오류 발생: \(error.localizedDescription)")
                }
            }
            cachedMonths.remove(monthKey)
        }
        print("✅ 캐시 정리 완료")
    }
    
    private func onMonthChange() {
        if isCalendarSyncEnabled {
            // 현재 보이는 월 업데이트
            visibleMonths = [monthFormatter.string(from: currentMonth)]
            
            // 스크롤 방향 감지
            let newScrollDirection: ScrollDirection
            if let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth),
               lastMonth > currentMonth {
                newScrollDirection = .backward
            } else if let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth),
                      nextMonth < currentMonth {
                newScrollDirection = .forward
            } else {
                newScrollDirection = .none
            }
            
            scrollDirection = newScrollDirection
            syncWithCalendar()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
