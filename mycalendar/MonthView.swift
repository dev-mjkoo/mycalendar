//
//  MonthView.swift
//  mycalendar
//
//  Created by 구민준 on 4/26/25.
//

import SwiftUI

struct MonthView: View {
    let monthData: MonthData
    let selectedDate: Date
    let onDateTap: (Date) -> Void
    
    private let calendar = Calendar.current
    private let today = Date()
    
    var body: some View {
        ScrollView {
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
                
                // 나중에 여기에 일별 일정 리스트가 추가될 예정
                Spacer(minLength: 100)
            }
            .padding(.horizontal)
            .padding(.top, 5)
        }
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
