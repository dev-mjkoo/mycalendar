import SwiftUI
import EventKit
import SwiftData

struct CalendarView: View {
    @State private var selectedDate = Date()
    @State private var months: [Date] = []
    @State private var currentIndex: Int = 12
    @Binding var currentMonthBinding: Date
    @Environment(\.modelContext) private var modelContext
    private let calendar = Calendar.current
    @State private var monthCache: MonthDataCache?
    private let eventStore = EKEventStore()
    
    var body: some View {
        Group {
            if let monthCache = monthCache {
//                print("📅 달력 뷰 초기화 완료 - 현재 인덱스: \(currentIndex)")
                CalendarViewPager(
                    currentIndex: $currentIndex,
                    months: months,
                    selectedDate: selectedDate,
                    monthCache: monthCache,
                    onDateTap: { date in
                        selectedDate = date
                        logEventsForDate(date)
                    }
                )
                .onChange(of: currentIndex) { newIndex in
                    print("🔄 달력 페이지 변경: \(newIndex)")
                    if newIndex == months.count - 3 {
                        print("📅 다음 달 추가")
                        appendMonths()
                    } else if newIndex == 2 {
                        print("📅 이전 달 추가")
                        prependMonths()
                    }
                    if months.indices.contains(newIndex) {
                        currentMonthBinding = months[newIndex]
                    }
                }
            } else {
//                print("⏳ 달력 데이터 로딩 중...")
                ProgressView()
            }
        }
        .onAppear {
            print("🚀 달력 뷰가 나타남")
            requestCalendarAccess()
            let current = Date()
            var initialMonths: [Date] = []
            
            for i in -12...12 {
                if let date = calendar.date(byAdding: .month, value: i, to: current) {
                    initialMonths.append(date)
                }
            }
            months = initialMonths
            print("📅 초기 달 설정: \(months.count)개")
            if months.indices.contains(currentIndex) {
                currentMonthBinding = months[currentIndex]
            }
            
            monthCache = MonthDataCache(modelContext: modelContext)
            print("💾 월별 데이터 캐시 생성")
            
            // 현재 달의 데이터를 미리 로드
            if let cache = monthCache {
                _ = cache.monthData(for: current)
                print("📅 현재 달 데이터 프리로드 완료")
            }
            
            // 캐시 새로고침 알림을 구독
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("RefreshCalendarCache"),
                object: nil,
                queue: .main
            ) { _ in
                print("🔄 캘린더 캐시 새로고침 시작")
                monthCache = MonthDataCache(modelContext: modelContext)
                if let cache = monthCache {
                    _ = cache.monthData(for: current)
                    print("✅ 캘린더 캐시 새로고침 완료")
                }
            }
        }
    }
    
    private func requestCalendarAccess() {
        eventStore.requestAccess(to: .event) { granted, error in
            if granted {
                print("캘린더 접근 권한이 허용되었습니다.")
            } else if let error = error {
                print("캘린더 접근 권한 요청 실패: \(error.localizedDescription)")
            } else {
                print("캘린더 접근 권한이 거부되었습니다.")
            }
        }
    }
    
    private func appendMonths() {
        var newMonths: [Date] = []
        guard let lastMonth = months.last else { return }
        
        for i in 1...12 {
            if let date = calendar.date(byAdding: .month, value: i, to: lastMonth) {
                newMonths.append(date)
            }
        }
        
        months.append(contentsOf: newMonths)
    }
    
    private func prependMonths() {
        var newMonths: [Date] = []
        guard let firstMonth = months.first else { return }
        
        for i in (1...12).reversed() {
            if let date = calendar.date(byAdding: .month, value: -i, to: firstMonth) {
                newMonths.append(date)
            }
        }
        
        months.insert(contentsOf: newMonths, at: 0)
        currentIndex += newMonths.count
    }
    
    private func logEventsForDate(_ date: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        let dateString = dateFormatter.string(from: date)
        print("선택된 날짜: \(dateString)")
        
        guard let monthData = monthCache?.monthData(for: date) else {
            print("해당 날짜에 이벤트가 없습니다.")
            return
        }
        
        let dayItems = monthData.days.filter { dayItem in
            guard let dayDate = dayItem.date else { return false }
            return calendar.isDate(dayDate, inSameDayAs: date)
        }
        
        if dayItems.isEmpty {
            print("해당 날짜에 이벤트가 없습니다.")
            return
        }
        
        print("해당 날짜의 이벤트:")
        dayItems.forEach { dayItem in
            if let dayDate = dayItem.date {
                let dayString = dateFormatter.string(from: dayDate)
                print("- 날짜: \(dayString), 현재 월: \(dayItem.isCurrentMonth)")
                
                if !dayItem.events.isEmpty {
                    print("  이벤트 목록:")
                    dayItem.events.forEach { event in
                        let startTime = timeFormatter.string(from: event.startDate)
                        let endTime = timeFormatter.string(from: event.endDate)
                        print("  - 제목: \(event.title)")
                        print("    시간: \(startTime) ~ \(endTime)")
                        if let location = event.location {
                            print("    위치: \(location)")
                        }
                        if let notes = event.notes {
                            print("    메모: \(notes)")
                        }
                        print("    캘린더: \(event.calendar)")
                        print("    종일 여부: \(event.isAllDay ? "예" : "아니오")")
                    }
                } else {
                    print("  이벤트가 없습니다.")
                }
            }
        }
    }
}

#Preview {
    CalendarView(currentMonthBinding: .constant(Date()))
} 
