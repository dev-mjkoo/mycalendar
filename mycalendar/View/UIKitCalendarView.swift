//
//  UIKitCalendarView.swift
//  mycalendar
//
//  Created by 구민준 on 5/9/25.
//
import SwiftUI
import UIKit
import FloatingPanel

struct UIKitCalendarView: UIViewControllerRepresentable {
    @Binding var currentMonthText: String
    @Binding var scrollToToday: Bool
    @Binding var selectedDate: Date?
    @Binding var panelState: FloatingPanelState?
    @Binding var refreshVisibleMonths: Bool
    var onScroll: (() -> Void)? = nil


    
    // UIKit - swiftui 바인딩
    func makeUIViewController(context: Context) -> CalendarViewController {
        let vc = CalendarViewController()
        vc.onMonthChange = { newText, monthDate in
            DispatchQueue.main.async {
                self.currentMonthText = newText

                // ✅ 달이 바뀔 때마다 이벤트 불러오기
                EventKitManager.shared.fetchEvents(for: monthDate) { events in
                    for event in events {
                        let occurrences = event.occurrences(in: monthDate)
                        for occurrenceDate in occurrences {
                            let dateStr = DateFormatter.localizedString(from: occurrenceDate, dateStyle: .short, timeStyle: .none)
                            log("📅 \(dateStr): \(event.ekEvent.title ?? "(제목 없음)")")
                        }
                    }

                    vc.setEvents(for: monthDate, events: events)
                }
            }
        }
        vc.onScroll = onScroll
        vc.selectedDate = self.selectedDate  // ✅ 초기값 전달

        vc.onDateSelected = { date in
            DispatchQueue.main.async {
                self.selectedDate = date
                self.panelState = .half
                vc.selectedDate = date               // ✅ ViewController 내부도 갱신!
                vc.collectionView.reloadData()       // ✅ 선택 상태 반영 todo해야하나


            }
        }
        
        return vc
    }
    
    func updateUIViewController(_ uiViewController: CalendarViewController, context: Context) {
        // 변경되면 오늘로 스크롤
        if scrollToToday {
            uiViewController.scrollToToday()
            DispatchQueue.main.async {
                self.scrollToToday = false
            }
        }
        
        // ✅ SwiftUI에서 변경된 selectedDate가 있다면 ViewController에도 반영
            if uiViewController.selectedDate != selectedDate {
                uiViewController.selectedDate = selectedDate
                uiViewController.collectionView.reloadData()
            }
        
        if refreshVisibleMonths {
            uiViewController.reloadVisibleMonths()
            DispatchQueue.main.async {
                self.refreshVisibleMonths = false
            }
        }
    }
}
