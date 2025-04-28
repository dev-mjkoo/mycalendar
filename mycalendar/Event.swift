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
    var recurrenceRulesString: String? // 반복 규칙을 JSON 문자열로 저장
    var alarmsString: String?      // 알림 설정을 JSON 문자열로 저장
    
    init(ekEvent: EKEvent) {
        self.id = UUID().uuidString  // UUID를 사용하여 고유한 ID 생성
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
            let rulesArray = recurrenceRules.map { rule in
                return rule.description
            }
            self.recurrenceRulesString = try? JSONEncoder().encode(rulesArray).base64EncodedString()
        }
        
        // 알림 설정 변환
        if let alarms = ekEvent.alarms {
            let alarmsArray = alarms.map { alarm in
                return "\(alarm.absoluteDate?.description ?? "")|\(alarm.relativeOffset)"
            }
            self.alarmsString = try? JSONEncoder().encode(alarmsArray).base64EncodedString()
        }
    }
    
    init(id: String, title: String, startDate: Date, endDate: Date) {
        self.id = UUID().uuidString  // UUID를 사용하여 고유한 ID 생성
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = false
        self.calendar = ""
        self.calendarId = ""
        self.availability = 0
    }
    
    // 반복 규칙을 배열로 가져오는 계산 속성
    var recurrenceRules: [String]? {
        guard let rulesString = recurrenceRulesString,
              let data = Data(base64Encoded: rulesString),
              let rules = try? JSONDecoder().decode([String].self, from: data) else {
            return nil
        }
        return rules
    }
    
    // 알림 설정을 배열로 가져오는 계산 속성
    var alarms: [String]? {
        guard let alarmsString = alarmsString,
              let data = Data(base64Encoded: alarmsString),
              let alarms = try? JSONDecoder().decode([String].self, from: data) else {
            return nil
        }
        return alarms
    }
} 