//
//  DailyEventSheetViewModel.swift
//  mycalendar
//
//  Created by 구민준 on 5/18/25.
//
import Foundation
import SwiftUI
import EventKit
import Combine

class DailyEventSheetViewModel: ObservableObject {
    @Published private(set) var date: Date = Date()
    @Published var events: [Event] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        NotificationCenter.default.publisher(for: .eventKitCacheInvalidated)
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task { @MainActor in
                    log("🔄 [DailyEventSheetViewModel] EventKitCacheInvalidated 감지 → 이벤트 리로드")
                    self.loadEvents(for: self.date)
                }
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    func setDate(_ newDate: Date) {
        self.date = newDate
        loadEvents(for: newDate)
    }
    
    @MainActor
    private func loadEvents(for date: Date) {
        let result = EventKitManager.shared.events(for: date)

        if result.isEmpty {
            // 캐시가 없어서 비었을 가능성 → fetch 걸리고 있음
            let startOfMonth = Calendar.current.startOfMonth(for: date)
            EventKitManager.shared.fetchEvents(for: startOfMonth) { [weak self] _ in
                Task { @MainActor in
                    guard let self = self else { return }
                    let refreshed = EventKitManager.shared.events(for: date)
                    self.events = refreshed
                    log("📅 [ViewModel] \(date.formatted(date: .long, time: .omitted)) -> \(refreshed.count)개 이벤트 (fetch 후 갱신)")
                }
            }
        } else {
            // 캐시 있으면 바로 세팅
            self.events = result
            log("📅 [ViewModel] \(date.formatted(date: .long, time: .omitted)) -> \(result.count)개 이벤트 (캐시 hit)")
        }
    }
}
