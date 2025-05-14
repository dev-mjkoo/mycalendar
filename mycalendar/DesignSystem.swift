//
//  DesignSystem.swift
//  mycalendar
//
//  Created by 구민준 on 5/9/25.
//

import UIKit

struct CalendarLayout {
    /// 요일 셀 하나의 높이 (정사각형 기준)
    static let dayCellHeight: CGFloat = 90
    
    /// 요일 셀 하나의 너비 계산용 분모 (보통 7일)
    static let dayCellWidthDivider: CGFloat = 7
    
    /// 주차 간격 (요일 행 간 간격)
    static let rowSpacing: CGFloat = 8
    
    /// 최대 주 수 (캘린더 셀 내부에 표시될 주)
    static let rowsPerMonth: Int = 6
    
    /// 월 타이틀 (예: "May 2025")의 높이
    static let monthTitleHeight: CGFloat = 32
    
    /// MonthCell 상하 여백
    static let verticalPadding: CGFloat = 16
    
    /// 하루에 표기할 라인 최대 수 
    static let maxVisibleLines = 3

}
