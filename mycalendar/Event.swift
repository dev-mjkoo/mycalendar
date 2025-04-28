import Foundation
import SwiftData
import EventKit

@Model
final class Event {
    @Attribute(.unique) var id: String  // EKEvent의 eventIdentifier를 저장
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
    var isDetachedOccurrence: Bool // detached occurrence 여부
    var seriesIdentifier: String?  // 반복 이벤트 시리즈의 식별자
    
    init(ekEvent: EKEvent) {
        // eventIdentifier를 ID로 사용
        self.id = ekEvent.eventIdentifier
        
        // 반복 이벤트 시리즈 식별자 설정
        if let recurrenceRules = ekEvent.recurrenceRules, !recurrenceRules.isEmpty {
            // 반복 이벤트의 경우, 시리즈 식별자를 생성
            // 시작일과 반복 규칙을 기반으로 고유한 식별자 생성
            let seriesKey = "\(ekEvent.startDate.timeIntervalSince1970)_\(recurrenceRules.first?.description ?? "")"
            self.seriesIdentifier = seriesKey
            // detached occurrence 여부는 나중에 동기화 과정에서 판단
            self.isDetachedOccurrence = false
        } else {
            self.seriesIdentifier = nil
            self.isDetachedOccurrence = false
        }
        
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
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = false
        self.calendar = ""
        self.calendarId = ""
        self.availability = 0
        self.isDetachedOccurrence = false
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
    
    // MARK: - 이벤트 동기화 관련 메서드
    
    /// EKEvent로부터 Event를 생성하거나 업데이트
    static func syncWithEKEvent(_ ekEvent: EKEvent, in context: ModelContext) -> Event {
        // 1. eventIdentifier로 기존 이벤트 검색
        guard let eventIdentifier = ekEvent.eventIdentifier else {
            // eventIdentifier가 없는 경우 새로운 이벤트 생성
            let newEvent = Event(ekEvent: ekEvent)
            context.insert(newEvent)
            return newEvent
        }
        
        // 2. 기존 이벤트 검색
        let fetchDescriptor = FetchDescriptor<Event>(
            predicate: #Predicate<Event> { event in
                event.id == eventIdentifier
            }
        )
        
        do {
            // 3. 기존 이벤트가 있는지 확인
            if let existingEvent = try context.fetch(fetchDescriptor).first {
                // 4. 기존 이벤트 업데이트
                existingEvent.update(from: ekEvent)
                return existingEvent
            } else {
                // 5. 새로운 이벤트 생성
                let newEvent = Event(ekEvent: ekEvent)
                context.insert(newEvent)
                return newEvent
            }
        } catch {
            print("이벤트 동기화 중 오류 발생: \(error.localizedDescription)")
            // 오류 발생 시 새로운 이벤트 생성
            let newEvent = Event(ekEvent: ekEvent)
            context.insert(newEvent)
            return newEvent
        }
    }
    
    /// EKEvent의 데이터로 현재 이벤트 업데이트
    private func update(from ekEvent: EKEvent) {
        // 기본 정보 업데이트
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
        
        // 반복 규칙 업데이트
        if let recurrenceRules = ekEvent.recurrenceRules {
            let rulesArray = recurrenceRules.map { rule in
                return rule.description
            }
            self.recurrenceRulesString = try? JSONEncoder().encode(rulesArray).base64EncodedString()
            
            // seriesIdentifier 업데이트
            let seriesKey = "\(ekEvent.startDate.timeIntervalSince1970)_\(recurrenceRules.first?.description ?? "")"
            self.seriesIdentifier = seriesKey
        } else {
            self.recurrenceRulesString = nil
            self.seriesIdentifier = nil
        }
        
        // 알림 설정 업데이트
        if let alarms = ekEvent.alarms {
            let alarmsArray = alarms.map { alarm in
                return "\(alarm.absoluteDate?.description ?? "")|\(alarm.relativeOffset)"
            }
            self.alarmsString = try? JSONEncoder().encode(alarmsArray).base64EncodedString()
        }
    }
    
    // MARK: - 반복 이벤트 시리즈 관련 메서드
    
    /// 같은 시리즈의 모든 이벤트 가져오기
    static func eventsInSeries(_ seriesIdentifier: String, in context: ModelContext) -> [Event] {
        let fetchDescriptor = FetchDescriptor<Event>(
            predicate: #Predicate<Event> { event in
                event.seriesIdentifier == seriesIdentifier
            }
        )
        
        do {
            return try context.fetch(fetchDescriptor)
        } catch {
            print("시리즈 이벤트 조회 중 오류 발생: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Detached occurrence 여부 확인 및 업데이트
    func updateDetachedOccurrenceStatus(in context: ModelContext) {
        guard let seriesId = self.seriesIdentifier else { return }
        
        let seriesEvents = Event.eventsInSeries(seriesId, in: context)
        let standardEvent = seriesEvents.first { !$0.isDetachedOccurrence }
        
        if let standard = standardEvent {
            // 기본 이벤트와 비교하여 detached occurrence 여부 판단
            self.isDetachedOccurrence = self.startDate != standard.startDate ||
                                       self.endDate != standard.endDate ||
                                       self.title != standard.title ||
                                       self.location != standard.location ||
                                       self.notes != standard.notes
        }
    }
} 