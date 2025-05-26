//
//  DailyEventSheetView.swift
//  mycalendar
//
//  Created by 구민준 on 5/18/25.
//
import SwiftUI
import FloatingPanel
import EventKit

struct DailyEventSheetView: View {
    let proxy: FloatingPanelProxy
    @ObservedObject var viewModel: DailyEventSheetViewModel
    @Binding var refreshTrigger: Bool
    
    
    @State private var contentHeight: CGFloat = 0
    @State private var availableHeight: CGFloat = 0
    @State private var selectedEvent: EventWrapper?
    @State private var showEventDetail = false
    
    var body: some View {
        VStack {
            HStack(spacing: 4) {
                Text(viewModel.date.completeFormattedDate)
                    .font(.system(size: 20, weight: .semibold))
                
                if Calendar.current.isDateInToday(viewModel.date) {
                    Text("오늘")
                        .foregroundColor(.gray)
                        .font(.system(size: 20, weight: .semibold))
                }
                
                Spacer()
            }
            .padding(EdgeInsets(top: 24, leading: 16, bottom: 0, trailing: 16))
            
            Divider()
            if viewModel.events.isEmpty {
                EmptyView()
            } else {
                Group {
                    List {
                        ForEach(viewModel.events) { event in
                            EventRowView(
                                event: event,
                                color: Color(event.ekEvent.calendar.cgColor ?? UIColor.systemGray.cgColor)  // fallback 필수!
                            )
                            .listRowBackground(Color.clear)  // ✨ 이 한 줄이 핵심!
                            .listRowSeparator(.hidden)  // ← 요 줄 추가!

                            .onTapGesture {
                                self.selectedEvent = EventWrapper(event: event.ekEvent)
                            }
                            
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)  // iOS 16+
                    
                    .background(Color.clear) // 리스트 자체도 투명하게!

                }
                .modifier(
                    FloatingPanelScrollResettableModifier(dateID: viewModel.date, proxy: proxy)
                )
                
            }
            
            Spacer(minLength: 0)
        }
        .presentationDetents([.medium, .large])
        .sheet(item: $selectedEvent) { wrapper in
            EKEventViewControllerRepresentable(event: wrapper.event)
        }
    }
}

struct FloatingPanelScrollResettableModifier: ViewModifier {
    let dateID: Date
    let proxy: FloatingPanelProxy
    
    func body(content: Content) -> some View {
        content
            .id(dateID) // modifier 레벨에서 강제 리셋
            .floatingPanelScrollTracking(proxy: proxy)
    }
}

struct EventWrapper: Identifiable {
    let id = UUID()
    let event: EKEvent
}
