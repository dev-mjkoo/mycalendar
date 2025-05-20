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
    static let dayCellHeight: CGFloat = 110
    

    /// 요일 셀 하나의 너비 계산용 분모 (보통 7일)
    static let dayCellWidthDivider: CGFloat = 7

    /// 주차 간격 (요일 행 간 간격) -> 주차별 간격
    static let rowSpacing: CGFloat = 8

    /// 최대 주 수 (캘린더 셀 내부에 표시될 주)
    static let rowsPerMonth: Int = 6

    /// 월 타이틀 (예: "May 2025")의 높이
    static let monthTitleHeight: CGFloat = 24

    /// MonthCell 상하 여백
    static let verticalPadding: CGFloat = 16

    /// 하루에 표기할 이벤트 라인 최대 수
    static let maxVisibleLines = 2

    /// 이벤트 바 한 줄의 세로 간격 (lineIndex * 이 값)
    static let eventLineHeight: CGFloat = 16

    /// 이벤트 바의 높이
    static let eventBlockHeight: CGFloat = 14

    /// 이벤트 바 X축 여백 (좌우 한쪽)
    static let eventHorizontalInset: CGFloat = 2

    /// 이벤트 바 Y축 추가 마진
    static let eventBlockYMargin: CGFloat = 2
    
    static let eventBlockGap: CGFloat = 16
    
    
}

struct CalendarFont {
    /// 월 타이틀 (예: May 2025)용 굵은 텍스트
    static let titleFont = UIFont.boldSystemFont(ofSize: 20)

    /// 이벤트 바 텍스트
    static let eventFont = UIFont.systemFont(ofSize: 11, weight: .semibold)

    /// overflow indicator 텍스트
    static let overflowFont = UIFont.systemFont(ofSize: 11, weight: .medium)
}

struct CalendarColor {
    /// 이벤트 텍스트 색상 (다크/라이트 모드 대응)
    static func eventTextColor(from color: CGColor) -> UIColor {
        let baseColor = UIColor(cgColor: color)
        return UIColor { trait in
            return trait.userInterfaceStyle == .dark
                ? baseColor.lighten(by: 30) // 다크모드에서는 밝게
                : baseColor.darken(by: 40)  // 라이트모드에서는 더 진하게
        }
    }

    /// 이벤트 배경색 (투명도 + 다크/라이트 모드 대응)
    static func eventBackgroundColor(from color: CGColor) -> UIColor {
        let baseColor = UIColor(cgColor: color)
        return UIColor { trait in
            let alpha: CGFloat = trait.userInterfaceStyle == .dark ? 0.25 : 0.15
            return baseColor.withAlphaComponent(alpha)
        }
    }

    /// overflow indicator 텍스트 색상 (시스템 컬러 그대로)
    static let overflowText = UIColor.secondaryLabel

    /// overflow indicator 배경 색상 (다크/라이트에 따라 회색 계열)
    static let overflowBackground: UIColor = {
        return UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(white: 0.3, alpha: 0.8)  // 어두운 회색
                : UIColor(white: 0.7, alpha: 0.6)  // 밝은 회색
        }
    }()
}

extension UIColor {
    func lighten(by percentage: CGFloat) -> UIColor {
        return adjustBrightness(by: abs(percentage))
    }

    func darken(by percentage: CGFloat) -> UIColor {
        return adjustBrightness(by: -abs(percentage))
    }

    private func adjustBrightness(by percentage: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0

        guard getHue(&h, saturation: &s, brightness: &b, alpha: &a) else {
            // fallback to RGB
            var r: CGFloat = 0, g: CGFloat = 0, bl: CGFloat = 0
            guard getRed(&r, green: &g, blue: &bl, alpha: &a) else { return self }

            return UIColor(
                red: max(min(r + percentage / 100, 1.0), 0),
                green: max(min(g + percentage / 100, 1.0), 0),
                blue: max(min(bl + percentage / 100, 1.0), 0),
                alpha: a
            )
        }

        return UIColor(
            hue: h,
            saturation: s,
            brightness: max(min(b + percentage / 100, 1.0), 0),
            alpha: a
        )
    }
}
