//
//  DailyEventSheetView.swift
//  mycalendar
//
//  Created by 구민준 on 5/18/25.
//
import SwiftUI
import FloatingPanel

struct DailyEventSheetView: View {
    let proxy: FloatingPanelProxy
    @ObservedObject var viewModel: DailyEventSheetViewModel
    @Binding var refreshTrigger: Bool
    
    
    @State private var contentHeight: CGFloat = 0
    @State private var availableHeight: CGFloat = 0
    
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
            }
            .padding()
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
