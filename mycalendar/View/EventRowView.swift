import SwiftUI
import EventKit

struct EventRowView: View {
    let event: Event
    let color: Color
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // ✅ 이벤트 타이틀
            Text(event.ekEvent.title ?? "(제목 없음)")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(color) // 캘린더 색

            // ✅ 위치 (있을 경우에만)
            if let location = event.ekEvent.location, !location.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "location.circle")
                        .font(.footnote)
                    Text(location)
                }
                .font(.footnote)
                .foregroundColor(.gray)
            }

            // ✅ 시작 - 종료 시간 (날짜 또는 시간)
            Text(dateRangeText)
                .font(.subheadline)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(color, lineWidth: 1.5) // 외곽선 강조
        )
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(backgroundColor)
        )
    }

    var backgroundColor: Color {
        colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white
    }

    var isAllDayOrMultiDay: Bool {
        event.ekEvent.isAllDay ||
        (event.ekEvent.startDate != nil && event.ekEvent.endDate != nil &&
         !Calendar.current.isDate(event.ekEvent.startDate!, inSameDayAs: event.ekEvent.endDate!))
    }

    var dateRangeText: String {
        let start = event.ekEvent.startDate
        let end = event.ekEvent.endDate
        guard let start = start, let end = end else { return "" }

        if isAllDayOrMultiDay {
            return "\(start.localeSmartFormattedDateYYYYMMDD) - \(end.localeSmartFormattedDateYYYYMMDD)"
        } else {
            return "\(formattedTime(start)) - \(formattedTime(end))"
        }
    }

    func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
