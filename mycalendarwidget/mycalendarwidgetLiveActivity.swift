//
//  mycalendarwidgetLiveActivity.swift
//  mycalendarwidget
//
//  Created by 구민준 on 4/25/25.
//

import ActivityKit
import WidgetKit
import SwiftUI
import os

private let logger = Logger(subsystem: "com.yourapp.mycalendar", category: "LiveActivity")

struct CalendarActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var day: Int
        var month: Int
        var weekday: String
        var weekdayInt: Int  // Calendar의 weekday 값 (1=일요일, 7=토요일)
        var fullDate: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct CalendarGridView: View {
    let currentDate: Date
    let weekdayInt: Int
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: currentDate)
        let year = calendar.component(.year, from: currentDate)
        let today = calendar.component(.day, from: currentDate)
        
        let firstDayOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentDate)?.count ?? 30
        
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: firstDayOfMonth)!
        let daysInPreviousMonth = calendar.range(of: .day, in: .month, for: previousMonth)?.count ?? 30
        
        // 마지막 날짜가 있는 주의 마지막 인덱스 계산
        let lastDayIndex = firstWeekday - 2 + daysInMonth
        let lastWeekStartIndex = (lastDayIndex / 7) * 7
        let numberOfWeeksToShow = (lastWeekStartIndex + 6) / 7 + 1
        
        VStack(spacing: 2) {  // 전체 간격 더욱 줄임
            // 요일 헤더
            HStack {
                ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 10, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .foregroundColor(
                            day == "일" ? .red :
                            day == "토" ? .blue :
                            colorScheme == .dark ? .white : .black
                        )
                }
            }
            .padding(.bottom, 0)
            
            // 날짜 그리드
            ForEach(0..<numberOfWeeksToShow) { row in
                HStack {
                    ForEach(0..<7) { column in
                        let dayNumber = row * 7 + column + 2 - firstWeekday
                        
                        if dayNumber <= 0 {
                            // 이전 달의 날짜
                            Text("\(daysInPreviousMonth + dayNumber)")
                                .font(.system(size: 10, weight: .regular))
                                .frame(maxWidth: .infinity, minHeight: 16)
                                .foregroundColor(colorScheme == .dark ? .gray.opacity(0.5) : .gray)
                        } else if dayNumber <= daysInMonth {
                            // 현재 달의 날짜
                            Text("\(dayNumber)")
                                .font(.system(size: 10, weight: .semibold))
                                .frame(maxWidth: .infinity, minHeight: 16)
                                .foregroundColor(
                                    today == dayNumber ? (
                                        column == 0 || column == 6 ? .white :
                                        colorScheme == .dark ? .black : .white
                                    ) :
                                    column == 0 ? .red :
                                    column == 6 ? .blue :
                                    colorScheme == .dark ? .white : .black
                                )
                                .background(
                                    today == dayNumber ?
                                        Capsule()
                                            .fill(
                                                column == 0 ? .red :
                                                column == 6 ? .blue :
                                                colorScheme == .dark ? .white : Color.gray.opacity(0.8)
                                            )
                                            .frame(width: 18, height: 15)
                                        : nil
                                )
                        } else if row * 7 + column <= lastWeekStartIndex + 6 {
                            // 다음 달의 날짜
                            Text("\(dayNumber - daysInMonth)")
                                .font(.system(size: 10, weight: .regular))
                                .frame(maxWidth: .infinity, minHeight: 16)
                                .foregroundColor(colorScheme == .dark ? .gray.opacity(0.5) : .gray)
                        } else {
                            // 빈 공간
                            Text("")
                                .frame(maxWidth: .infinity, minHeight: 16)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 2)
    }
}

struct mycalendarwidgetLiveActivity: Widget {
    func weekdayColor(_ weekdayInt: Int) -> Color {
        switch weekdayInt {
        case 1:  // 일요일
            return .red
        case 7:  // 토요일
            return .blue
        default:
            return .white
        }
    }
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CalendarActivityAttributes.self) { context in
            // Lock Screen/Banner UI goes here
            HStack(spacing: 0) {
                VStack(spacing: 8) {
                    CalendarGridView(
                        currentDate: Date(),
                        weekdayInt: context.state.weekdayInt
                    )
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
                
                Spacer()
                    .frame(maxWidth: .infinity)
            }
            .padding(.vertical)
            .activityBackgroundTint(Color(uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ?
                    UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0) :  // 매우 진한 회색
                    UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)    // 매우 연한 회색
            }))
            .activitySystemActionForegroundColor(Color(.label))

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here
                DynamicIslandExpandedRegion(.leading) {
                    Text("\(context.state.month)/\(context.state.day)")
                        .font(.title)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.weekday)")
                        .font(.title)
                        .foregroundColor(weekdayColor(context.state.weekdayInt))
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.fullDate)
                        .font(.headline)
                }
            } compactLeading: {
                Text("\(context.state.month)/\(context.state.day)")
                  .font(.title)
            } compactTrailing: {
                Text("\(context.state.weekday)")
                .font(.title)
                    .foregroundColor(weekdayColor(context.state.weekdayInt))
            } minimal: {
                Text(context.state.weekday)
                .font(.title)
                    .foregroundColor(weekdayColor(context.state.weekdayInt))
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.white)
        }
    }
}

extension CalendarActivityAttributes {
    static var preview: CalendarActivityAttributes {
        CalendarActivityAttributes(name: "Calendar")
    }
}

extension CalendarActivityAttributes.ContentState {
    static var today: CalendarActivityAttributes.ContentState {
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
        
        print("Widget Debug - Locale: \(preferredLocale.identifier)")
        print("Widget Debug - Weekday: \(weekday)")
        
        return CalendarActivityAttributes.ContentState(
            day: day,
            month: month,
            weekday: weekday,
            weekdayInt: weekdayInt,
            fullDate: fullDate
        )
    }
}

#Preview("Notification", as: .content, using: CalendarActivityAttributes.preview) {
    mycalendarwidgetLiveActivity()
} contentStates: {
    CalendarActivityAttributes.ContentState.today
}
