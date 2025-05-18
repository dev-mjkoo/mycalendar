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
}
