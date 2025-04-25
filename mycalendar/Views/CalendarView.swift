import SwiftUI

struct DayItem: Hashable {
    let id = UUID()
    let date: Date?
    let isCurrentMonth: Bool
    
    static func == (lhs: DayItem, rhs: DayItem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct MonthData: Identifiable {
    let id = UUID()
    let date: Date
    let days: [DayItem]
}

struct MonthView: View {
    let monthData: MonthData
    let selectedDate: Date
    let onDateTap: (Date) -> Void
    
    private let calendar = Calendar.current
    private let today = Date()
    
    var body: some View {
        VStack(spacing: 10) {
            // 요일 헤더
            HStack {
                ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 14, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .foregroundColor(
                            day == "일" ? .red :
                            day == "토" ? .blue :
                            .primary
                        )
                }
            }
            
            // 날짜 그리드
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(monthData.days, id: \.id) { dayItem in
                    if let date = dayItem.date {
                        Text("\(calendar.component(.day, from: date))")
                            .font(.system(size: 16))
                            .frame(height: 35)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(foregroundColor(for: date, isCurrentMonth: dayItem.isCurrentMonth))
                            .background(
                                ZStack {
                                    if calendar.isDate(date, inSameDayAs: selectedDate) {
                                        Circle()
                                            .fill(backgroundColor(for: date))
                                    }
                                    if calendar.isDate(date, inSameDayAs: today) {
                                        Circle()
                                            .stroke(todayColor(for: date), lineWidth: 1.5)
                                    }
                                }
                            )
                            .onTapGesture {
                                onDateTap(date)
                            }
                    } else {
                        Text("")
                            .frame(height: 35)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 5)
    }
    
    private func foregroundColor(for date: Date, isCurrentMonth: Bool) -> Color {
        if !isCurrentMonth {
            return .gray
        }
        
        if calendar.isDate(date, inSameDayAs: selectedDate) {
            return .white
        }
        
        let day = calendar.component(.weekday, from: date)
        if day == 1 { return .red }    // 일요일
        if day == 7 { return .blue }   // 토요일
        return .primary
    }
    
    private func backgroundColor(for date: Date) -> Color {
        let day = calendar.component(.weekday, from: date)
        if day == 1 { return .red }    // 일요일
        if day == 7 { return .blue }   // 토요일
        return .gray
    }
    
    private func todayColor(for date: Date) -> Color {
        let day = calendar.component(.weekday, from: date)
        if day == 1 { return .red }    // 일요일
        if day == 7 { return .blue }   // 토요일
        return .gray
    }
}

class MonthDataCache {
    private var cache: [String: MonthData] = [:]
    private let calendar = Calendar.current
    
    func monthData(for date: Date) -> MonthData {
        let key = monthKey(for: date)
        if let cached = cache[key] {
            return cached
        }
        
        let monthData = createMonthData(for: date)
        cache[key] = monthData
        return monthData
    }
    
    private func monthKey(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)"
    }
    
    private func createMonthData(for date: Date) -> MonthData {
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let range = calendar.range(of: .day, in: .month, for: start)!
        
        let firstWeekday = calendar.component(.weekday, from: start)
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: start)!
        
        var days: [DayItem] = []
        
        // 이전 달의 날짜들
        if firstWeekday > 1 {
            let daysInPreviousMonth = calendar.range(of: .day, in: .month, for: previousMonth)!.count
            for day in (daysInPreviousMonth - firstWeekday + 2)...daysInPreviousMonth {
                var components = calendar.dateComponents([.year, .month], from: previousMonth)
                components.day = day
                if let date = calendar.date(from: components) {
                    days.append(DayItem(date: date, isCurrentMonth: false))
                }
            }
        }
        
        // 현재 달의 날짜들
        for day in 1...range.count {
            var components = calendar.dateComponents([.year, .month], from: start)
            components.day = day
            if let date = calendar.date(from: components) {
                days.append(DayItem(date: date, isCurrentMonth: true))
            }
        }
        
        // 다음 달의 날짜들
        let remainingDays = 42 - days.count
        if remainingDays > 0 {
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: start)!
            for day in 1...remainingDays {
                var components = calendar.dateComponents([.year, .month], from: nextMonth)
                components.day = day
                if let date = calendar.date(from: components) {
                    days.append(DayItem(date: date, isCurrentMonth: false))
                }
            }
        }
        
        return MonthData(date: date, days: days)
    }
}

#if os(iOS)
struct CalendarViewPager: View {
    @Binding var currentIndex: Int
    let months: [Date]
    let selectedDate: Date
    let monthCache: MonthDataCache
    let onDateTap: (Date) -> Void
    
    var body: some View {
        TabView(selection: $currentIndex) {
            ForEach(months.indices, id: \.self) { index in
                MonthView(
                    monthData: monthCache.monthData(for: months[index]),
                    selectedDate: selectedDate,
                    onDateTap: onDateTap
                )
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
}
#else
struct CalendarViewPager: View {
    @Binding var currentIndex: Int
    let months: [Date]
    let selectedDate: Date
    let monthCache: MonthDataCache
    let onDateTap: (Date) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(months.indices, id: \.self) { index in
                MonthView(
                    monthData: monthCache.monthData(for: months[index]),
                    selectedDate: selectedDate,
                    onDateTap: onDateTap
                )
                .frame(width: NSScreen.main?.visibleFrame.width ?? 400)
                .tag(index)
            }
        }
        .offset(x: -CGFloat(currentIndex) * (NSScreen.main?.visibleFrame.width ?? 400))
        .gesture(
            DragGesture()
                .onEnded { value in
                    let threshold: CGFloat = 50
                    if value.translation.width > threshold && currentIndex > 0 {
                        withAnimation {
                            currentIndex -= 1
                        }
                    } else if value.translation.width < -threshold && currentIndex < months.count - 1 {
                        withAnimation {
                            currentIndex += 1
                        }
                    }
                }
        )
    }
}
#endif

struct CalendarView: View {
    @State private var selectedDate = Date()
    @State private var months: [Date] = []
    @State private var currentIndex: Int = 12
    @Binding var currentMonthBinding: Date
    private let calendar = Calendar.current
    private let monthCache = MonthDataCache()
    
    var body: some View {
        CalendarViewPager(
            currentIndex: $currentIndex,
            months: months,
            selectedDate: selectedDate,
            monthCache: monthCache,
            onDateTap: { date in
                selectedDate = date
            }
        )
        .onChange(of: currentIndex) { newIndex in
            if newIndex == months.count - 3 {
                appendMonths()
            } else if newIndex == 2 {
                prependMonths()
            }
            if months.indices.contains(newIndex) {
                currentMonthBinding = months[newIndex]
            }
        }
        .onAppear {
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
}

// Array extension for safe index access
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    CalendarView(currentMonthBinding: .constant(Date()))
} 