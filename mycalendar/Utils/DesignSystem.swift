//
//  DesignSystem.swift
//  mycalendar
//
//  Created by 구민준 on 5/9/25.
//

import UIKit

struct CalendarLayout {
    /// 주차별 블록 Y 위치값 :
    /// monthTitleHeight +verticalPadding + rowindex * (dayCellHeight + rowSpacing)
    
    
    /// 요일 셀 하나의 높이 (정사각형 기준) -> 일자별 셀높이
    static let dayCellHeight: CGFloat = 90

    /// 요일 셀 하나의 너비 계산용 분모 (보통 7일)
    static let dayCellWidthDivider: CGFloat = 7

    /// 주차 간격 (요일 행 간 간격) -> 주차별 간격
    static let rowSpacing: CGFloat = 8

    /// 최대 주 수 (캘린더 셀 내부에 표시될 주)
    static let rowsPerMonth: Int = 6

    /// 월 타이틀 (예: "May 2025")의 높이
    static let monthTitleHeight: CGFloat = 32

    /// MonthCell 상하 여백
    static let verticalPadding: CGFloat = 16

    /// 하루에 표기할 이벤트 라인 최대 수
    static let maxVisibleLines = 3

    /// 이벤트 바 한 줄의 세로 간격 (lineIndex * 이 값)
    static let eventLineHeight: CGFloat = 16

    /// 이벤트 바의 높이
    static let eventBlockHeight: CGFloat = 14

    /// 이벤트 바 X축 여백 (좌우 한쪽)
    static let eventHorizontalInset: CGFloat = 2

    /// 이벤트 바 Y축 추가 마진
    static let eventBlockYMargin: CGFloat = 2
    
    
}

struct CalendarFont {
    /// 월 타이틀 (예: May 2025)용 굵은 텍스트
    static let titleFont = UIFont.boldSystemFont(ofSize: 20)

    /// 이벤트 바 텍스트
    static let eventFont = UIFont.systemFont(ofSize: 10, weight: .semibold)

    /// overflow indicator 텍스트
    static let overflowFont = UIFont.systemFont(ofSize: 10, weight: .medium)
}

struct CalendarColor {
    /// 이벤트 텍스트 색상 (원본 색상 그대로)
    static func eventTextColor(from color: CGColor) -> UIColor {
        return         UIColor(cgColor: color).darken(by: 20) // 진하게

    }

    /// 이벤트 바 배경 (투명도 있는 색)
    static func eventBackgroundColor(from color: CGColor) -> UIColor {
        return UIColor(cgColor: color).withAlphaComponent(0.3)
    }

    /// overflow indicator 텍스트 색상 (시스템 컬러)
    static let overflowText = UIColor.secondaryLabel

    /// overflow indicator 배경 색상 (진한 회색)
    static let overflowBackground = UIColor.gray.withAlphaComponent(0.8)
}

extension UIColor {
    func lighten(by percentage: CGFloat) -> UIColor {
        return adjust(by: abs(percentage))
    }

    func darken(by percentage: CGFloat) -> UIColor {
        return adjust(by: -abs(percentage))
    }

    private func adjust(by percentage: CGFloat) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard getRed(&r, green: &g, blue: &b, alpha: &a) else { return self }
        return UIColor(red: min(r + percentage / 100, 1.0),
                       green: min(g + percentage / 100, 1.0),
                       blue: min(b + percentage / 100, 1.0),
                       alpha: a)
    }
}
