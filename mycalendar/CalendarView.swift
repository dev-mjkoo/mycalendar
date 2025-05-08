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
    @State private var isAppendingMonths = false
    @State private var isPrependingMonths = false
    
    // 버퍼 설정
    private let minPageCount = 5
    private let maxPageCount = 15
    private let bufferThreshold = 3
    
    var body: some View {
        Group {
            if let monthCache = monthCache {
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
                    handleIndexChange(newIndex)
                }
            } else {
                ProgressView()
            }
        }
        .onAppear {
            setupInitialState()
        }
    }
    
    private func handleIndexChange(_ newIndex: Int) {
        // 현재 월 업데이트만 즉시 수행
        if months.indices.contains(newIndex) {
            currentMonthBinding = months[newIndex]
        }
        
        // 나머지 작업은 Task로 분리하여 순차적으로 처리
        Task {
            // 페이지 추가 로직
            if newIndex >= months.count - bufferThreshold && !isAppendingMonths {
                await appendMonths()
            } else if newIndex <= bufferThreshold && !isPrependingMonths {
                await prependMonths()
            }
            
            // 버퍼 유지
            await maintainPageBuffer()
        }
    }
    
    private func setupInitialState() {
        requestCalendarAccess()
        let current = Date()
        var initialMonths: [Date] = []
        
        for i in -12...12 {
            if let date = calendar.date(byAdding: .month, value: i, to: current) {
                initialMonths.append(date)
            }
        }
        months = initialMonths
        if months.indices.contains(currentIndex) {
            currentMonthBinding = months[currentIndex]
        }
        
        monthCache = MonthDataCache(modelContext: modelContext)
        
        if let cache = monthCache {
            _ = cache.monthData(for: current)
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("RefreshCalendarCache"),
            object: nil,
            queue: .main
        ) { _ in
            monthCache = MonthDataCache(modelContext: modelContext)
            if let cache = monthCache {
                _ = cache.monthData(for: current)
            }
        }
    }
    
    private func maintainPageBuffer() async {
        if months.count < minPageCount {
            await appendMonths()
        } else if months.count > maxPageCount {
            let excessCount = months.count - maxPageCount
            if currentIndex > excessCount {
                await MainActor.run {
                    withAnimation(.none) {
                        months.removeFirst(excessCount)
                        currentIndex -= excessCount
                    }
                }
            }
        }
    }
    
    private func appendMonths() async {
        guard !isAppendingMonths else { return }
        isAppendingMonths = true
        
        let newMonths = await Task.detached {
            var months: [Date] = []
            guard let lastMonth = self.months.last else { return months }
            
            for i in 1...12 {
                if let date = self.calendar.date(byAdding: .month, value: i, to: lastMonth) {
                    months.append(date)
                }
            }
            return months
        }.value
        
        await MainActor.run {
            withAnimation(.none) {
                months.append(contentsOf: newMonths)
            }
            isAppendingMonths = false
        }
    }
    
    private func prependMonths() async {
        guard !isPrependingMonths else { return }
        isPrependingMonths = true
        
        let newMonths = await Task.detached {
            var months: [Date] = []
            guard let firstMonth = self.months.first else { return months }
            
            for i in (1...12).reversed() {
                if let date = self.calendar.date(byAdding: .month, value: -i, to: firstMonth) {
                    months.append(date)
                }
            }
            return months
        }.value
        
        await MainActor.run {
            withAnimation(.none) {
                months.insert(contentsOf: newMonths, at: 0)
                currentIndex += newMonths.count
            }
            isPrependingMonths = false
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
