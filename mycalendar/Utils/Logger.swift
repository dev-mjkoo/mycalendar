//
//  Logger.swift
//  mycalendar
//
//  Created by 구민준 on 5/9/25.
//

// Logger.swift
import Foundation

func log(_ message: String) {
#if DEBUG
    print("🪵", message)
#endif
}
