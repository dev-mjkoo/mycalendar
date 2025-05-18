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
        HStack {
            Text(currentMonthText)
                .font(.title2.bold())

            Spacer()

            Button {
                onSettingsTap()
            } label: {
                Image(systemName: "gear")
                    .imageScale(.large)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
