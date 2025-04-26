import Foundation
import SwiftData
import EventKit

@Model
final class Event {
    @Attribute(.unique) var id: String  // EKEvent의 eventIdentifier를 unique key로 설정
    var title: String              // 이벤트 제목
    var startDate: Date            // 시작 시간
    var endDate: Date              // 종료 시간
    var isAllDay: Bool             // 종일 이벤트 여부
    var location: String?          // 위치
    var notes: String?             // 메모
    var url: URL?                  // 관련 URL
    var calendar: String           // 캘린더 제목
    var calendarId: String         // 캘린더 ID
    var availability: Int          // 일정 가능 여부 (0: free, 1: tentative, 2: busy, 3: unavailable)
    var creationDate: Date?        // 생성일
    var lastModifiedDate: Date?    // 최종 수정일
    var timeZone: String?          // 타임존
    var recurrenceRules: [String]? // 반복 규칙
    var alarms: [String]?          // 알림 설정
    
    init(ekEvent: EKEvent) {
        self.id = ekEvent.eventIdentifier
        self.title = ekEvent.title
        self.startDate = ekEvent.startDate
        self.endDate = ekEvent.endDate
        self.isAllDay = ekEvent.isAllDay
        self.location = ekEvent.location
        self.notes = ekEvent.notes
        self.url = ekEvent.url
        self.calendar = ekEvent.calendar.title
        self.calendarId = ekEvent.calendar.calendarIdentifier
        self.availability = ekEvent.availability.rawValue
        self.creationDate = ekEvent.creationDate
        self.lastModifiedDate = ekEvent.lastModifiedDate
        self.timeZone = ekEvent.timeZone?.identifier
        
        // 반복 규칙 변환
        if let recurrenceRules = ekEvent.recurrenceRules {
            self.recurrenceRules = recurrenceRules.map { rule in
                return rule.description // EKRecurrenceRule을 문자열로 저장
            }
        }
        
        // 알림 설정 변환
        if let alarms = ekEvent.alarms {
            self.alarms = alarms.map { alarm in
                return "\(alarm.absoluteDate?.description ?? "")|\(alarm.relativeOffset)" // EKAlarm 정보를 문자열로 저장
            }
        }
    }
    
    init(id: String, title: String, startDate: Date, endDate: Date) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = false
        self.calendar = ""
        self.calendarId = ""
        self.availability = 0
    }
} 