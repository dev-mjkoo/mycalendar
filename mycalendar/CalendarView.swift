import SwiftUI

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

#Preview {
    CalendarView(currentMonthBinding: .constant(Date()))
} 
