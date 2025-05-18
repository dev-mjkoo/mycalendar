//
//  EventRowView.swift
//  mycalendar
//
//  Created by 구민준 on 5/19/25.
//
import SwiftUI
import EventKit

struct EventRowView: View {
    let event: Event
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            // ✅ 색상 바
            Rectangle()
                .fill(color)
                .frame(width: 4)
                .cornerRadius(2)

            // ✅ 텍스트 정보 (타이틀 + 주소)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.ekEvent.title ?? "(제목 없음)")
                    .font(.body)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                if let location = event.ekEvent.location, !location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "location.circle")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(location)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                } else {
                    // 공간 유지 (정렬 깨지지 않게)
                    Text(" ")
                        .font(.subheadline)
                        .hidden()
                }
            }

            Spacer()

            // ✅ 오른쪽: 시간 or 날짜
            VStack(alignment: .trailing, spacing: 2) {
                if isAllDayOrMultiDay {
                    Text(formattedDate(event.ekEvent.startDate))
                        .font(.subheadline)
                    Text(formattedDate(event.ekEvent.endDate))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text(formattedTime(event.ekEvent.startDate))
                        .font(.subheadline)
                    Text(formattedTime(event.ekEvent.endDate))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 0)
    }

    var isAllDayOrMultiDay: Bool {
        event.ekEvent.isAllDay ||
        (event.ekEvent.startDate != nil && event.ekEvent.endDate != nil &&
         !Calendar.current.isDate(event.ekEvent.startDate!, inSameDayAs: event.ekEvent.endDate!))
    }

    func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy. M. d."
        return formatter.string(from: date)
    }

    func formattedTime(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

