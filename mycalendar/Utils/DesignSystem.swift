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
    static let eventLineHeight: CGFloat = 19

    /// 이벤트 바의 높이
    static let eventBlockHeight: CGFloat = 16

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
    static let overflowFont = UIFont.systemFont(ofSize: 10, weight: .medium)
}

struct CalendarColor {
    /// 이벤트 텍스트 색상 (기본 컬러 기반)
    static func eventTextColor(from color: CGColor) -> UIColor {
        let baseColor = UIColor(cgColor: color)
        return UIColor { trait in
            switch trait.userInterfaceStyle {
            case .dark:
                // 어두운 배경에선 글씨를 살짝 더 밝게
                return baseColor.lighten(by: 20).withAlphaComponent(0.95)
            default:
                // 밝은 배경에선 글씨를 살짝 더 어둡게
                return baseColor.darken(by: 25).withAlphaComponent(0.95)
            }
        }
    }

    /// 이벤트 배경색 (원본 색상 유지 + 밝기 조절 + 알파)
    static func eventBackgroundColor(from color: CGColor) -> UIColor {
        let baseColor = UIColor(cgColor: color)

        return UIColor { trait in
            switch trait.userInterfaceStyle {
            case .dark:
                return baseColor.darken(by: 10).withAlphaComponent(0.4)
            default:
                return baseColor.lighten(by: 15).withAlphaComponent(0.2)
            }
        }
    }

    /// overflow 텍스트 색상
    static let overflowText = UIColor.secondaryLabel

    /// overflow 배경색 (살짝 명시적인 회색 계열)
    static let overflowBackground: UIColor = {
        UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(white: 0.2, alpha: 0.6)
                : UIColor(white: 0.85, alpha: 0.4)
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
