//
//  UIKitCalendarView.swift
//  mycalendar
//
//  Created by 구민준 on 5/9/25.
//
import SwiftUI
import UIKit

struct UIKitCalendarView: UIViewControllerRepresentable {
    @Binding var currentMonthText: String
    @Binding var scrollToToday: Bool
    @Binding var selectedDate: Date?
    @Binding var refreshVisibleMonths: Bool


    
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
        
        
        vc.onDateSelected = { date in
            DispatchQueue.main.async {
                self.selectedDate = date
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
        
        if refreshVisibleMonths {
            uiViewController.reloadVisibleMonths()
            DispatchQueue.main.async {
                self.refreshVisibleMonths = false
            }
        }
    }
}
