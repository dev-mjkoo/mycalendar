import SwiftUI
import EventKit

#if canImport(UIKit)
import UIKit
#endif

#if canImport(ActivityKit)
import ActivityKit
#endif

private let openSettingsURLString = "app-settings:"

struct SettingsView: View {
    @StateObject private var eventKitManager = EventKitManager.shared
    @StateObject private var liveActivityManager = LiveActivityManager.shared
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    @State private var showingSettingsAlert = false
    @State private var disableCalendarToggle = false

    var body: some View {
        List {
            Section {
                Toggle(isOn: Binding(
                    get: { liveActivityManager.isLiveActivityEnabled },
                    set: { newValue in
                        Task { @MainActor in
                            await liveActivityManager.toggleLiveActivity()
                        }
                    }
                )) {
                    Text("캘린더 Live Activity")
                        .font(.headline)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Toggle(isOn: Binding(
                        get: { eventKitManager.isCalendarAccessGranted },
                        set: { newValue in
                            if newValue {
                                Task {
                                    let granted = await eventKitManager.requestAccess()
                                    if !granted {
                                        showingSettingsAlert = true
                                        eventKitManager.revokeAccessFlagOnly()
                                    }
                                }
                            } else {
                                showingSettingsAlert = true
                            }
                        }
                    )) {
                        Text("캘린더 연동")
                    }
                    .disabled(disableCalendarToggle)

                    if disableCalendarToggle {
                        Text("캘린더 권한은 시스템 설정에서만 끌 수 있습니다.\niPhone 설정 앱 > mycalendar에서 변경하세요.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.leading, 4)
                    }
                }
            }
        }
        .navigationTitle("설정")
        .alert("캘린더 접근 권한이 필요합니다", isPresented: $showingSettingsAlert) {
            Button("설정으로 이동") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("설정에서 캘린더 접근을 허용하거나 해제할 수 있습니다.")
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                Task {
                    await updateToggleAvailability()
                }
            }
        }
        .onAppear {
            Task {
                await updateToggleAvailability()
            }
        }
    }

    private func updateToggleAvailability() async {
        await eventKitManager.checkCalendarAccess()
        let status = EKEventStore.authorizationStatus(for: .event)
        disableCalendarToggle = (status == .fullAccess)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
        }
    }
}
