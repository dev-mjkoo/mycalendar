//
//  CustomHeaderView.swift
//  mycalendar
//
//  Created by 구민준 on 5/16/25.
//
import SwiftUI

struct CustomHeaderView: View {
    @Binding var currentMonthText: String
    var onSettingsTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0){
            HStack {
                Text(currentMonthText)
                    .font(.system(size: 24, weight: .bold))
                
                
                Spacer()
                
                Button {
                    onSettingsTap()
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .imageScale(.large)
                        .foregroundColor(.red)
                    
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            weekdayHeader
        }
    }
    
    var weekdayHeader: some View {
        HStack {
            // todo 이것도 local화 하기
            ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { day in
                Text(day)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(day == "일" ? .red : day == "토" ? .blue : .primary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 4)
    }
}
