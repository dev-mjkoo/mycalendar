import SwiftUI
import Combine
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
    @State private var panelState: FloatingPanelState? = .tip
    @StateObject private var eventSheetViewModel = DailyEventSheetViewModel()
    @State private var showPanel = false
    @State private var showSettings = false
    
    
    var body: some View {
        VStack {
            ZStack {
                VStack(spacing: 0) {
                    CustomHeaderView(
                        currentMonthText: $currentMonthText,
                        onTodayTap: {
                            scrollToToday.toggle()
                        },
                        onSettingsTap: {
                            showSettings = true
                            log("⚙️ 설정 버튼 눌림")
                        }
                    )
                    
                    weekdayHeader
                    UIKitCalendarView(
                        currentMonthText: $currentMonthText,
                        scrollToToday: $scrollToToday,
                        selectedDate: $selectedDate,
                        panelState: $panelState,
                        refreshVisibleMonths: $refreshVisibleMonths,
                        onScroll: {
                            log("📱 CalendarView 스크롤 시작됨 -> 패널 TIP으로")
                                withAnimation(.easeOut(duration: 0.1)) {
                                    panelState = .tip
                                }
                        }
                    )
                }
            }
            .floatingPanel(
                coordinator: MyPanelCoordinator.self
            ) { proxy in
                DailyEventSheetView(
                    proxy: proxy,
                    viewModel: eventSheetViewModel,
                    refreshTrigger: $refreshVisibleMonths
                )
            }
            
            .floatingPanelSurfaceAppearance(
                {
                    let appearance = SurfaceAppearance()
                    appearance.cornerRadius = 24
                    appearance.backgroundColor = .secondarySystemBackground
                    return appearance
                }()
            )
            .floatingPanelBehavior(FloatingPanelStocksBehavior())
            .floatingPanelLayout(panelLayout)
            .floatingPanelState($panelState)
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .presentationDetents([.medium, .large]) // 💡 iOS 16+이면 높이 제어 가능
            }
            .onChange(of: selectedDate) { newValue in
                if let date = newValue {
                    eventSheetViewModel.setDate(date) // ✅ 메서드를 통해서 안전하게 변경
                }
            }
            .onChange(of: panelState) { newValue in
                if let state = newValue {
                    panelState = state
                }
                
            }
            .onChange(of: currentMonthText, { oldValue, newValue in
                HapticFeedbackManager.trigger()
            })
            // ✅ scenePhase가 active 될 때 권한만 체크
            .onChange(of: scenePhase) { newValue in
                if newValue == .active {
                    Task {
                        await eventKitManager.checkCalendarAccess()
                    }
                }
            }

            // ✅ EventKitManager가 캐시 invalidate 할 때만 캘린더 화면 리프레시
            .onChange(of: eventKitManager.cacheVersion) { _ in
                refreshVisibleMonths = true
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
                        await MainActor.run {
                            selectedDate = Date()
                            eventSheetViewModel.setDate(selectedDate!) // ✅ 안전하게 date 변경 및 이벤트 로딩
                            panelState = .tip
                        }
                    } else {
                        log("❗️캘린더 권한이 없어서 이벤트를 불러올 수 없음")
                    }
                }
            }
            
            CustomBottomView()
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




