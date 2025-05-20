//
//  CustomBottomView.swift
//  mycalendar
//
//  Created by 구민준 on 5/16/25.
//

import SwiftUI

struct CustomBottomView: View {
    var onTodayTap: () -> Void

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
                log("✅ 하단 버튼 클릭")
            }) {
                Image(systemName: "plus")
                    .imageScale(.large)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .frame(height: 50) // ✅ 고정 높이
        .background(Color(UIColor.secondarySystemBackground))
        
        //        .cornerRadius(12)
//        .padding(.horizontal, 16)
//        .shadow(radius: 4)
    }
}
