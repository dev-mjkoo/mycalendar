import SwiftUI
import EventKit

struct EventRowView: View {
    let event: Event
    let color: Color
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 8) {
            // ✅ 메인 콘텐츠
            VStack(alignment: .leading, spacing: 2) {
                Text(event.ekEvent.title ?? "(제목 없음)")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(
                        colorScheme == .dark ? color : .primary // 다크모드면 캘린더색, 아니면 기본색
                    )
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
                    Text(" ")
                        .font(.subheadline)
                        .hidden()
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if isAllDayOrMultiDay {
                    Text(event.ekEvent.startDate.localeSmartFormattedDateYYYYMMDD)
                        .font(.subheadline)
                    Text(event.ekEvent.endDate.localeSmartFormattedDateYYYYMMDD)
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
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
        )
    }

    var backgroundColor: Color {
        if colorScheme == .dark {
            return Color(UIColor.systemGray5) // 다크모드용 밝은 회색
        } else {
            return color.opacity(0.15) // 라이트 모드: 일정별 색상 연하게
        }
    }

    var isAllDayOrMultiDay: Bool {
        event.ekEvent.isAllDay ||
        (event.ekEvent.startDate != nil && event.ekEvent.endDate != nil &&
         !Calendar.current.isDate(event.ekEvent.startDate!, inSameDayAs: event.ekEvent.endDate!))
    }

    func formattedTime(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
