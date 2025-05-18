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
            Text(viewModel.date.formatted(date: .long, time: .omitted))
                .font(.title)
                .padding()
            
            if viewModel.events.isEmpty {
                EmptyView()
            } else {
                Group {
                    List {
                        ForEach(viewModel.events) { event in
                            VStack(alignment: .leading) {
                                Text(event.ekEvent.title ?? "(제목 없음)")
                                    .font(.headline)
                                if let startDate = event.ekEvent.startDate {
                                    Text(startDate.formatted(date: .omitted, time: .shortened))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
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
