//
//  CalendarViewPager.swift
//  mycalendar
//
//  Created by 구민준 on 4/26/25.
//
import SwiftUI

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
