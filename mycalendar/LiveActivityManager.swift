import Foundation
import ActivityKit

class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    
    @Published var isLiveActivityEnabled = false
    private var activity: Activity<CalendarActivityAttributes>?
    
    private init() {
        // 초기화 시 현재 Activity 상태만 확인
        isLiveActivityEnabled = !Activity<CalendarActivityAttributes>.activities.isEmpty
    }
    
    @MainActor
    func startLiveActivity() async {
        // 이미 실행 중인 Activity가 있는지 확인
        if !Activity<CalendarActivityAttributes>.activities.isEmpty {
            log("Live Activity is already running")
            isLiveActivityEnabled = true
            return
        }
        
        let date = Date()
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        let weekdayInt = calendar.component(.weekday, from: date)
        
        // 시스템 선호 언어 사용
        let preferredLocale = Locale.preferredLanguages.first.flatMap { Locale(identifier: $0) } ?? .current
        
        // 현재 기기 언어에 맞는 축약형 요일 (Fri, 금)
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.locale = preferredLocale
        weekdayFormatter.dateFormat = "E"  // E는 축약형 요일 (Fri, 금)
        let weekday = weekdayFormatter.string(from: date)
        
        // 전체 날짜 포맷
        let fullDateFormatter = DateFormatter()
        fullDateFormatter.locale = preferredLocale
        fullDateFormatter.dateFormat = "yyyy년 M월 d일 (E)"
        let fullDate = fullDateFormatter.string(from: date)
        
        let attributes = CalendarActivityAttributes(name: "Calendar")
        let contentState = CalendarActivityAttributes.ContentState(
            day: day,
            month: month,
            weekday: weekday,
            weekdayInt: weekdayInt,
            fullDate: fullDate
        )
        
        do {
            let content = ActivityContent(state: contentState, staleDate: nil)
            activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            isLiveActivityEnabled = true
            log("Live Activity started: \(activity?.id ?? "")")
        } catch {
            log("Error starting Live Activity: \(error.localizedDescription)")
            isLiveActivityEnabled = false
        }
    }
    
    @MainActor
    func stopLiveActivity() async {
        guard isLiveActivityEnabled else { return }
        
        for activity in Activity<CalendarActivityAttributes>.activities {
            let finalContent = ActivityContent(state: activity.content.state, staleDate: nil)
            await activity.end(finalContent, dismissalPolicy: .immediate)
        }
        
        isLiveActivityEnabled = false
        log("Live Activity stopped")
    }
    
    @MainActor
    func toggleLiveActivity() async {
        if isLiveActivityEnabled {
            await stopLiveActivity()
        } else {
            await startLiveActivity()
        }
    }
} 
