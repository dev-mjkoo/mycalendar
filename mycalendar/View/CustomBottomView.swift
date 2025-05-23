//
//  CustomBottomView.swift
//  mycalendar
//
//  Created by 구민준 on 5/16/25.
//

import SwiftUI
import EventKit

struct CustomBottomView: View {
    var onTodayTap: () -> Void
    @State private var showEventEditor = false
    @State private var showPermissionAlert = false
    
    var body: some View {
        HStack {
            Button(action: {
                log("✅ 하단 버튼 클릭")
            }) {
                Image(systemName: "calendar")
                    .imageScale(.large)
                    .foregroundColor(.red)
            }
            Spacer()
            
            Button(action: {
                onTodayTap()
                HapticFeedbackManager.trigger()
            }) {
                Text("오늘")
                    .font(.headline)
                    .foregroundColor(.red)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.red, lineWidth: 1)
                    )
            }
            
            Spacer()
            Button(action: {
                checkCalendarPermission()
            }) {
                Image(systemName: "plus")
                    .imageScale(.large)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .frame(height: 50)
        .background(Color(UIColor.secondarySystemBackground))
        .sheet(isPresented: $showEventEditor) {
            EventEditView()
        }
        .alert(isPresented: $showPermissionAlert) {
            Alert(
                title: Text("캘린더 권한 필요"),
                message: Text("캘린더에 이벤트를 추가하려면 권한이 필요합니다. 설정에서 권한을 변경해주세요."),
                primaryButton: .default(Text("설정 열기"), action: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }),
                secondaryButton: .cancel(Text("취소"))
            )
        }
    }
    
    private func checkCalendarPermission() {
        let status = EKEventStore.authorizationStatus(for: .event)
        
        switch status {
        case .fullAccess:
            showEventEditor = true
        case .writeOnly:
            showEventEditor = true
        case .notDetermined:
            EKEventStore().requestFullAccessToEvents { granted, _ in
                DispatchQueue.main.async {
                    if granted {
                        showEventEditor = true
                    } else {
                        showPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            showPermissionAlert = true
        @unknown default:
            showPermissionAlert = true
        }
    }
}
