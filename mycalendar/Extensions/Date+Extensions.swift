//
//  Date+Extension.swift
//  mycalendar
//
//  Created by 구민준 on 5/14/25.
//
import Foundation

/// Date를 Identifiable하게 만드는 트릭
extension Date: @retroactive Identifiable {
    public var id: String { self.iso8601String }
    
    var iso8601String: String {
        ISO8601DateFormatter().string(from: self)
    }
    
    var completeFormattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        
        if let userPreferredLang = Locale.preferredLanguages.first {
            formatter.locale = Locale(identifier: userPreferredLang)
        } else {
            formatter.locale = .current
        }
        
        return formatter.string(from: self)
    }
    
    var localeSmartFormattedDateYYYYMMDD: String {
        let formatter = DateFormatter()
        
        // 현재 언어 코드 (예: "ko", "en", "fr", ...)
        let languageCode = Locale.preferredLanguages.first.flatMap { Locale(identifier: $0).languageCode } ?? "en"
        
        // 기본 포맷
        var dateFormat = "MMM d, yyyy"
        
        switch languageCode {
        case "ko", "ja", "zh":
            dateFormat = "yyyy.MM.dd"
        case "fr", "de", "es", "it", "pt", "tr":
            dateFormat = "dd/MM/yyyy"
        default:
            dateFormat = "MMM d, yyyy"
        }
        
        formatter.locale = Locale(identifier: languageCode)
        formatter.dateFormat = dateFormat
        
        return formatter.string(from: self)
    }
    
    var localeSmartFormattedDateYYYYMM: String {
        let formatter = DateFormatter()
        
        let localeIdentifier = Locale.preferredLanguages.first ?? "en"
        let locale = Locale(identifier: localeIdentifier)
        let languageCode = Locale.preferredLanguages.first.flatMap { Locale(identifier: $0).languageCode } ?? "en"
        
        formatter.locale = locale
        
        switch languageCode {
        case "ko":
            formatter.dateFormat = "yyyy년 M월"
        case "ja", "zh":
            formatter.dateFormat = "yyyy年 M月" // 한자 월/년
        default:
            formatter.dateFormat = "MMM, yyyy" // ex: "Mar, 2025"
        }
        
        return formatter.string(from: self)
    }
}
