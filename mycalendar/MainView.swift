import SwiftUI
import EventKit
import FloatingPanel

struct MainView: View {
    @State private var scrollToToday: Bool = false
    @State private var hasAppeared = false
    @State private var currentMonthText: String = "캘린더"
    @State private var selectedDate: Date? = nil
    
    @StateObject private var eventKitManager = EventKitManager.shared
    @State private var currentMonth = Date()
    @Environment(\.scenePhase) private var scenePhase
    @State private var refreshVisibleMonths: Bool = false
    
    
    @State private var panelLayout: FloatingPanelLayout? = MyFloatingPanelLayout()
    @State private var panelState: FloatingPanelState?
    @State private var panelDate = Date()
    
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                weekdayHeader
                UIKitCalendarView(
                    currentMonthText: $currentMonthText,
                    scrollToToday: $scrollToToday,
                    selectedDate: $selectedDate,
                    refreshVisibleMonths: $refreshVisibleMonths
                )
            }
        }
//        .ignoresSafeArea()
        .floatingPanel(
            coordinator: MyPanelCoordinator.self
        ) { proxy in
            DailyEventSheetView(proxy: proxy, date: $panelDate)
        }
//        .floatingPanelSurfaceAppearance(.transparent())
        .floatingPanelLayout(panelLayout)
        .floatingPanelState($panelState)
        
        .navigationTitle(currentMonthText)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button("오늘") {
                    scrollToToday.toggle()
                }
                
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gear")
                }
            }
        }
        .onChange(of: selectedDate) { newValue in
            log("📅 selectedDate 변경됨: \(String(describing: newValue))")
            if let newValue {
                panelDate = newValue
                panelState = .half
            }
        }
        .onChange(of: scenePhase) {
            EventKitManager.shared.clearCache()
            refreshVisibleMonths = true
            if scenePhase == .active {
                Task {
                    await eventKitManager.checkCalendarAccess()
                }
            }
        }
        .onAppear {
            if !hasAppeared {
                hasAppeared = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    scrollToToday = true
                }
            }
            
            Task {
                await eventKitManager.checkCalendarAccess()
                
                if eventKitManager.isCalendarAccessGranted {
                    EventKitManager.shared.fetchEvents(for: currentMonth) { events in
                        for event in events {
                            let occurrences = event.occurrences(in: currentMonth)
                            for occurrenceDate in occurrences {
                                let dateStr = DateFormatter.localizedString(from: occurrenceDate, dateStyle: .short, timeStyle: .none)
                                log("📅 \(dateStr): \(event.ekEvent.title ?? "(제목 없음)")")
                            }
                        }
                    }
                } else {
                    log("❗️캘린더 권한이 없어서 이벤트를 불러올 수 없음")
                }
            }
        }
    }
    
    var weekdayHeader: some View {
        HStack {
            ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { day in
                Text(day)
                    .foregroundColor(day == "일" ? .red : day == "토" ? .blue : .primary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 4)
    }
}

struct DailyEventSheetView: View {
    let proxy: FloatingPanelProxy
    @Binding var date: Date

    @State private var events: [Event] = []
    
    var body: some View {
        VStack {
            Text(date.formatted(date: .long, time: .omitted))
                .font(.title)
                .padding()
            
            if events.isEmpty {
                Text("이벤트 없음")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List(events) { event in
                    VStack(alignment: .leading) {
                        Text(event.ekEvent.title ?? "(제목 없음)")
                            .font(.headline)
                        if let startDate = event.ekEvent.startDate {
                            Text(startDate.formatted(date: .omitted, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            loadEvents()
        }
        .onChange(of: date) { _ in
            loadEvents()
        }
    }
    
    private func loadEvents() {
        events = EventKitManager.shared.events(for: date)
        log("📅 \(date.formatted(date: .long, time: .omitted)) -> \(events.count)개 이벤트")
    }
}
