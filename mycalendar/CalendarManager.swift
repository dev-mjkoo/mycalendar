import Foundation
import EventKit

class CalendarManager: ObservableObject {
    static let shared = CalendarManager()
    
    @Published var isCalendarAccessGranted = false
    private let eventStore = EKEventStore()
    
    private init() {
        Task {
            await checkCalendarAccess()
        }
    }
    
    func checkCalendarAccess() async {
        let status = EKEventStore.authorizationStatus(for: .event)
        await MainActor.run {
            isCalendarAccessGranted = status == .fullAccess
        }
    }
    
    func requestCalendarAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            await MainActor.run {
                isCalendarAccessGranted = granted
            }
            return granted
        } catch {
            print("Error requesting calendar access: \(error.localizedDescription)")
            return false
        }
    }
    
    func fetchEvents(for date: Date) async -> [EKEvent] {
        guard isCalendarAccessGranted else { return [] }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = eventStore.predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: nil
        )
        
        return eventStore.events(matching: predicate)
    }
} 