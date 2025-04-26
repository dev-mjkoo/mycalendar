//
//  Array+Extensions.swift
//  mycalendar
//
//  Created by 구민준 on 4/26/25.
//
import Foundation

// Array extension for safe index access
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
