import UIKit
import EventKit

class MonthCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    private let titleLabel = UILabel()
    private var collectionView: UICollectionView!
    private var overlayView = UIView()  // 🔥 overlayView 추가

    private var days: [Date] = []
    private var eventsByDate: [Date: [EKEvent]] = [:]
    private let calendar = Calendar.current

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

    func configure(with date: Date, selected: Date?, events: [Date: [EKEvent]] = [:]) {
        self.eventsByDate = events

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "MMMM yyyy"
        titleLabel.text = formatter.string(from: date)

        generateDays(for: date)
        collectionView.reloadData()
        layoutOverlayEvents()  // 🔥 이벤트 레이아웃 호출
    }

    private func setupOverlayView() {
        overlayView.isUserInteractionEnabled = false
        overlayView.backgroundColor = .clear
        overlayView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func layoutOverlayEvents() {
        overlayView.subviews.forEach { $0.removeFromSuperview() }

        var blocks: [EventBlock] = []
        let lineManager = LineManager()

        // ✅ 유니크 이벤트 리스트 확보
        let allEvents = eventsByDate.flatMap { $0.value }
        let uniqueEvents = Dictionary(grouping: allEvents, by: { $0.eventIdentifier }).compactMap { $0.value.first }

        for event in uniqueEvents
            .sorted(by: {
                guard let s1 = $0.startDate, let s2 = $1.startDate else { return false }
                if s1 != s2 {
                    return s1 < s2
                } else {
                    let duration1 = $0.endDate?.timeIntervalSince($0.startDate ?? Date()) ?? 0
                    let duration2 = $1.endDate?.timeIntervalSince($1.startDate ?? Date()) ?? 0
                    return duration1 > duration2
                }
            }) {

            let slicedBlocks = sliceEventByWeek(event: event)
            for block in slicedBlocks {
                var mutableBlock = block
                mutableBlock.lineIndex = lineManager.assignLineIndex(for: block)
                blocks.append(mutableBlock)
            }
        }

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

    // ✅ 이벤트를 주 단위로 쪼개는 함수
    private func sliceEventByWeek(event: EKEvent) -> [EventBlock] {
        guard let startDate = event.startDate, let rawEndDate = event.endDate else {
            return []
        }

        // 🔥 로컬 타임존으로 변환해서 정확하게 판단
        let adjustedEndDate: Date = {
            let endComponents = calendar.dateComponents(in: TimeZone.current, from: rawEndDate)
            if endComponents.hour == 0, endComponents.minute == 0, endComponents.second == 0,
               !calendar.isDate(startDate, inSameDayAs: rawEndDate) {
                // 하루 빼기
                return calendar.date(byAdding: .day, value: -1, to: rawEndDate) ?? rawEndDate
            } else {
                return rawEndDate
            }
        }()

        var result: [EventBlock] = []
        var currentStart = startDate

        while currentStart <= adjustedEndDate {
            guard let weekday = calendar.dateComponents(in: TimeZone.current, from: currentStart).weekday,
                  let weekEnd = calendar.date(byAdding: .day, value: 6 - (weekday - calendar.firstWeekday + 7) % 7, to: currentStart) else {
                break
            }

            let sliceEnd = min(adjustedEndDate, weekEnd)
            result.append(EventBlock(startDate: currentStart, endDate: sliceEnd, event: event))

            guard let nextStart = calendar.date(byAdding: .day, value: 1, to: sliceEnd) else { break }
            currentStart = nextStart
        }

        return result
    }
    
    private func adjustedEndDate(for event: EKEvent) -> Date? {
        guard let startDate = event.startDate, let endDate = event.endDate else { return nil }
        let components = calendar.dateComponents([.hour, .minute, .second], from: endDate)
        if components.hour == 0 && components.minute == 0 && components.second == 0 {
            // 종료일과 시작일이 같은 날이면 그대로 사용
            if calendar.isDate(startDate, inSameDayAs: endDate) {
                return endDate
            } else {
                // 아니면 하루 빼기
                return calendar.date(byAdding: .day, value: -1, to: endDate)
            }
        } else {
            return endDate
        }
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
        contentView.addSubview(overlayView)  // 🔥 overlayView 추가

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
