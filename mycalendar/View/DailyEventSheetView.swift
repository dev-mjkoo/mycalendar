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
                GeometryReader { geo in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
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
                                .padding(.horizontal)
                            }
                        }
                        .background(
                            GeometryReader { contentGeo in
                                Color.clear
                                    .onAppear {
                                        contentHeight = contentGeo.size.height
                                        availableHeight = geo.size.height
                                    }
                                    .onChange(of: viewModel.events.count) { _ in
                                        contentHeight = contentGeo.size.height
                                        availableHeight = geo.size.height
                                    }
                            }
                        )
                        .padding(.bottom, 32)
                    }
                    .scrollIndicators(.hidden)
                    .disabled(contentHeight <= geo.size.height) // ✅ 여기서 자동 스크롤 on/off
                }
            }
            
            Spacer(minLength: 0)
        }
        .presentationDetents([.medium, .large])
    }
}
