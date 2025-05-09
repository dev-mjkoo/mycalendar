//
//  UIKitCalendarView.swift
//  mycalendar
//
//  Created by 구민준 on 5/9/25.
//
import SwiftUI
import UIKit

struct UIKitCalendarView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CalendarViewController {
        return CalendarViewController()
    }

    func updateUIViewController(_ uiViewController: CalendarViewController, context: Context) {
        // SwiftUI에서 데이터 바뀔 때 호출됨 (우리는 지금 필요 없음)
    }
}
