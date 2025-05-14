import UIKit
import EventKit

class MonthCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    private let titleLabel = UILabel()
    private var collectionView: UICollectionView!
    private var overlayView = UIView()

    private var days: [Date] = []
    private var events: [Event] = [] // ✅ 변경된 부분
    private let calendar = Calendar.current
    private var monthDate: Date = Date()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupTitleLabel()
        setupCollectionView()
        setupOverlayView()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with date: Date, selected: Date?, events: [Event]) {
        self.monthDate = date
        self.events = events

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "MMMM yyyy"
        titleLabel.text = formatter.string(from: date)

        generateDays(for: date)
        collectionView.reloadData()
        layoutOverlayEvents()
    }

    private func layoutOverlayEvents() {
        overlayView.subviews.forEach { $0.removeFromSuperview() }

        let lineManager = LineManager()
        var blocks: [EventBlock] = []

        for event in events {
            if let _ = event.recurrenceRule {
                // 🔥 반복일정 → 발생일마다 adjustedEndDate 적용
                let occurrences = event.occurrences(in: monthDate)
                for occurrenceDate in occurrences {
                    guard let adjustedEndDate = adjustedEndDate(for: event.ekEvent) else { continue }
                    let slicedBlocks = sliceEventByWeek(event: event.ekEvent, from: occurrenceDate, to: adjustedEndDate)
                    for block in slicedBlocks {
                        var mutableBlock = block
                        mutableBlock.lineIndex = lineManager.assignLineIndex(for: mutableBlock)
                        blocks.append(mutableBlock)
                    }
                }
            } else {
                // 🔥 일반 일정 → adjustedEndDate 기준 block
                guard let start = event.ekEvent.startDate,
                      let rawEnd = event.ekEvent.endDate,
                      let adjustedEnd = adjustedEndDate(for: event.ekEvent) else { continue }

                let monthStart = calendar.startOfMonth(for: monthDate)
                let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)?.addingTimeInterval(-1) ?? monthStart

                if adjustedEnd >= monthStart && start <= monthEnd {
                    let blockStart = max(start, monthStart)
                    let blockEnd = min(adjustedEnd, monthEnd)

                    let slicedBlocks = sliceEventByWeek(event: event.ekEvent, from: blockStart, to: blockEnd)
                    for block in slicedBlocks {
                        var mutableBlock = block
                        mutableBlock.lineIndex = lineManager.assignLineIndex(for: mutableBlock)
                        blocks.append(mutableBlock)
                    }
                }
            }
        }

        // ✅ 이후 block 렌더링은 동일 (변경 없음)
        for block in blocks {
            guard let startIndex = days.firstIndex(where: { calendar.isDate($0, inSameDayAs: block.startDate) }),
                  let endIndex = days.firstIndex(where: { calendar.isDate($0, inSameDayAs: block.endDate) }) else { continue }

            let startColumn = startIndex % 7
            let startRow = startIndex / 7
            let endColumn = endIndex % 7
            let endRow = endIndex / 7

            let startX = CGFloat(startColumn) * (bounds.width / CalendarLayout.dayCellWidthDivider)
            let endX = CGFloat(endColumn) * (bounds.width / CalendarLayout.dayCellWidthDivider) + (bounds.width / CalendarLayout.dayCellWidthDivider)

            let startY = CalendarLayout.monthTitleHeight + CalendarLayout.verticalPadding + CGFloat(startRow) * (CalendarLayout.dayCellHeight + CalendarLayout.rowSpacing)
            let blockY = startY + CGFloat(block.lineIndex) * 16 + 2

            let width = endX - startX - 4
            let height: CGFloat = 14

            let eventView = UILabel()
            eventView.text = " \(block.event.title ?? "(제목 없음)") "
            eventView.font = .systemFont(ofSize: 10, weight: .medium)
            eventView.textColor = .white
            eventView.backgroundColor = UIColor(cgColor: block.event.calendar.cgColor).withAlphaComponent(0.8)
            eventView.layer.cornerRadius = 4
            eventView.clipsToBounds = true

            eventView.frame = CGRect(x: startX + 2, y: blockY, width: width, height: height)

            overlayView.addSubview(eventView)
        }
    }
    private func adjustedEndDate(for event: EKEvent) -> Date? {
        guard let startDate = event.startDate, let endDate = event.endDate else { return nil }

        let endComponents = calendar.dateComponents(in: TimeZone.current, from: endDate)

        if endComponents.hour == 0 && endComponents.minute == 0 && endComponents.second == 0 {
            // ✅ 무조건 하루 빼서 23:59:59로 (startDate와 같은 날 여부 무시)
            let dayBefore = calendar.date(byAdding: .day, value: -1, to: endDate)!
            return calendar.date(bySettingHour: 23, minute: 59, second: 59, of: dayBefore)
        } else {
            return endDate
        }
    }
    private func sliceEventByWeek(event: EKEvent, from startDate: Date, to endDate: Date) -> [EventBlock] {
        var result: [EventBlock] = []
        var currentStart = startDate

        while currentStart <= endDate {
            guard let weekday = calendar.dateComponents(in: TimeZone.current, from: currentStart).weekday,
                  let weekEnd = calendar.date(byAdding: .day, value: 6 - (weekday - calendar.firstWeekday + 7) % 7, to: currentStart) else {
                break
            }

            let sliceEnd = min(endDate, weekEnd)
            result.append(EventBlock(startDate: currentStart, endDate: sliceEnd, event: event))

            guard let nextStart = calendar.date(byAdding: .day, value: 1, to: sliceEnd) else { break }
            currentStart = nextStart
        }

        return result
    }

    private func generateDays(for date: Date) {
        days.removeAll()

        let range = calendar.range(of: .day, in: .month, for: date)!
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let weekdayOffset = (calendar.component(.weekday, from: firstOfMonth) - calendar.firstWeekday + 7) % 7

        for _ in 0..<weekdayOffset {
            days.append(Date.distantPast)
        }

        for day in range {
            if let dayDate = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(dayDate)
            }
        }
    }

    private func setupTitleLabel() {
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupOverlayView() {
        overlayView.isUserInteractionEnabled = false
        overlayView.backgroundColor = .clear
        overlayView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = CalendarLayout.rowSpacing

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(DayCell.self, forCellWithReuseIdentifier: "DayCell")
        collectionView.isScrollEnabled = false
        collectionView.backgroundColor = .clear
    }

    private func setupLayout() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(collectionView)
        contentView.addSubview(overlayView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            overlayView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            overlayView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
        ])
    }

    // MARK: - CollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        days.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DayCell", for: indexPath) as! DayCell
        let date = days[indexPath.item]

        if date == Date.distantPast {
            cell.configure(day: "", isToday: false, isSelected: false)
        } else {
            let isToday = calendar.isDateInToday(date)
            let day = calendar.component(.day, from: date)
            cell.configure(day: "\(day)", isToday: isToday)
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width / CalendarLayout.dayCellWidthDivider
        return CGSize(width: width, height: CalendarLayout.dayCellHeight)
    }
}
