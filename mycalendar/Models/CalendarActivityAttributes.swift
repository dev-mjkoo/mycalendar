import Foundation
import ActivityKit

struct CalendarActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var day: Int
        var month: Int
        var weekday: String
        var weekdayInt: Int
        var fullDate: String
    }
    
    var name: String
} 