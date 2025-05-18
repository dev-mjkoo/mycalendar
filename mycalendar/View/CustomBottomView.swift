//
//  CustomBottomView.swift
//  mycalendar
//
//  Created by 구민준 on 5/16/25.
//

import SwiftUI

struct CustomBottomView: View {
    var body: some View {
        HStack {
            Text("하단 고정 바")
                .font(.headline)
                .foregroundColor(.white)
            Spacer()
            Button(action: {
                log("✅ 하단 버튼 클릭")
            }) {
                Text("액션")
                    .bold()
            }
        }
        .padding()
        .frame(height: 50) // ✅ 고정 높이
        .background(Color(UIColor.secondarySystemBackground))
        
        //        .cornerRadius(12)
//        .padding(.horizontal, 16)
        .shadow(radius: 4)
    }
}
