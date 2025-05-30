import UIKit
import EventKit

class MonthCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    private let titleLabel = UILabel()
    private let monthTitleContainerView = UIView()
    private var collectionView: UICollectionView!
    private var overlayView = UIView()

    private var days: [Date] = []
    private var events: [Event] = []
    private let calendar = Calendar.current
    private var monthDate: Date = Date()
    
    var onDateSelected: ((Date) -> Void)?
    private var monthTitleLeadingConstraint: NSLayoutConstraint?
    
    private var selectedDate: Date?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupTitleLabel()
        setupMonthTitleContainerView()
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
        self.selectedDate = selected


        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "MMMM"
        titleLabel.text = formatter.string(from: date)

        generateDays(for: date)
        collectionView.reloadData()
        layoutOverlayEvents()
        updateMonthTitlePosition()
    }
    
    private func setupLayout() {
        monthTitleLeadingConstraint = monthTitleContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)

        contentView.addSubview(monthTitleContainerView)
        contentView.addSubview(collectionView)
        contentView.addSubview(overlayView)

        NSLayoutConstraint.activate([
            monthTitleLeadingConstraint!,
            monthTitleContainerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            monthTitleContainerView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 1.0 / 7.0),
            monthTitleContainerView.heightAnchor.constraint(equalToConstant: CalendarLayout.monthTitleHeight) // 👈 안정적인 높이
        ])

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: monthTitleContainerView.bottomAnchor, constant: 0), // 👈 여백 줄이기
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            overlayView.topAnchor.constraint(equalTo: monthTitleContainerView.bottomAnchor, constant: 4),
            overlayView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    private func updateMonthTitlePosition() {
        guard let firstValidIndex = days.firstIndex(where: { $0 != Date.distantPast }) else { return }
        let column = firstValidIndex % 7
        let columnWidth = bounds.width / CalendarLayout.dayCellWidthDivider
        monthTitleLeadingConstraint?.constant = columnWidth * CGFloat(column)
    }

    private func layoutOverlayEvents() {
        overlayView.subviews.forEach { $0.removeFromSuperview() }

        var blocksByWeek: [Date: [EventBlock]] = [:]

        for event in events {
            let slices: [EventBlock]
            if let _ = event.recurrenceRule {
                slices = event.occurrences(in: monthDate).flatMap { occurrenceDate -> [EventBlock] in
                    if let adjustedEndDate = adjustedEndDate(for: event.ekEvent) {
                        return sliceEventByWeek(event: event.ekEvent, from: occurrenceDate, to: adjustedEndDate)
                    } else {
                        return []
                    }
                }
            } else {
                guard let start = event.ekEvent.startDate,
                      let adjustedEnd = adjustedEndDate(for: event.ekEvent) else { continue }

                let monthStart = calendar.startOfMonth(for: monthDate)
                let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)?.addingTimeInterval(-1) ?? monthStart

                if adjustedEnd >= monthStart && start <= monthEnd {
                    let blockStart = max(start, monthStart)
                    let blockEnd = min(adjustedEnd, monthEnd)
                    slices = sliceEventByWeek(event: event.ekEvent, from: blockStart, to: blockEnd)
                } else {
                    continue
                }
            }

            for block in slices {
                let weekStart = calendar.startOfWeek(for: block.startDate)
                blocksByWeek[weekStart, default: []].append(block)
            }
        }

        var blocks: [EventBlock] = []

        for (_, weekBlocks) in blocksByWeek {
            let lineManager = LineManager()
            let sortedWeekBlocks = weekBlocks.sorted { $0.daysBetween().count > $1.daysBetween().count }
            for block in sortedWeekBlocks {
                var mutableBlock = block
                mutableBlock.lineIndex = lineManager.assignLineIndex(for: mutableBlock)
                blocks.append(mutableBlock)
            }
        }

        var overflowEventsByDay: [Date: [EventBlock]] = [:]

        for block in blocks {
            if block.lineIndex < CalendarLayout.maxVisibleLines {
                renderEventBlock(block)
            } else {
                for day in block.daysBetween() {
                    overflowEventsByDay[day, default: []].append(block)
                }
            }
        }

        for (day, overflows) in overflowEventsByDay {
            if overflows.count == 1 {
                let block = overflows.first!

                let isSafeToShowDirectly = block.daysBetween().allSatisfy { blockDay in
                    let sameDayOverflows = overflowEventsByDay[blockDay] ?? []
                    return sameDayOverflows.count == 1
                }

                if isSafeToShowDirectly {
                    renderEventBlock(block)
                } else {
                    renderOverflowDots(for: day, eventBlocks: overflows)
                }
            } else if overflows.count > 1 {
                renderOverflowDots(for: day, eventBlocks: overflows)
            }
        }
    }


    private func renderEventBlock(_ block: EventBlock) {
        guard let startIndex = days.firstIndex(where: { calendar.isDate($0, inSameDayAs: block.startDate) }),
              let endIndex = days.firstIndex(where: { calendar.isDate($0, inSameDayAs: block.endDate) }) else { return }

        let startColumn = startIndex % 7
        let startRow = startIndex / 7
        let endColumn = endIndex % 7

        let startX = CGFloat(startColumn) * (bounds.width / CalendarLayout.dayCellWidthDivider)
        let endX = CGFloat(endColumn + 1) * (bounds.width / CalendarLayout.dayCellWidthDivider)

        let startY = CalendarLayout.monthTitleHeight + CalendarLayout.verticalPadding + CGFloat(startRow) * (CalendarLayout.dayCellHeight + CalendarLayout.rowSpacing) + CalendarLayout.eventBlockGap
        let blockY = startY + CGFloat(block.lineIndex) * CalendarLayout.eventLineHeight + CalendarLayout.eventBlockYMargin

        let width = endX - startX - (CalendarLayout.eventHorizontalInset * 2)
        let height = CalendarLayout.eventBlockHeight

        guard let baseCGColor = block.event.calendar.cgColor else { return }

        let eventView = UILabel()
        eventView.text = " \(block.event.title ?? "(제목 없음)") "
        eventView.font = CalendarFont.eventFont
        eventView.textColor = CalendarColor.eventTextColor(from: baseCGColor)
        eventView.backgroundColor = CalendarColor.eventBackgroundColor(from: baseCGColor)
        eventView.layer.cornerRadius = 4
        eventView.clipsToBounds = true

        eventView.frame = CGRect(x: startX + CalendarLayout.eventHorizontalInset, y: blockY, width: width, height: height)
        overlayView.addSubview(eventView)
    }


    private func adjustedEndDate(for event: EKEvent) -> Date? {
        guard let _ = event.startDate, let endDate = event.endDate else { return nil }

        let endComponents = calendar.dateComponents(in: TimeZone.current, from: endDate)
        if endComponents.hour == 0 && endComponents.minute == 0 && endComponents.second == 0 {
            let dayBefore = calendar.date(byAdding: .day, value: -1, to: endDate)!
            return calendar.date(bySettingHour: 23, minute: 59, second: 59, of: dayBefore)
        } else {
            return endDate
        }
    }

    private func renderOverflowDots(for day: Date, eventBlocks: [EventBlock]) {
        guard let dayIndex = days.firstIndex(where: { calendar.isDate($0, inSameDayAs: day) }) else { return }

        let column = dayIndex % 7
        let row = dayIndex / 7

        let cellWidth = bounds.width / CalendarLayout.dayCellWidthDivider
        let x = CGFloat(column) * cellWidth
        let y = CalendarLayout.monthTitleHeight + CalendarLayout.verticalPadding + CGFloat(row) * (CalendarLayout.dayCellHeight + CalendarLayout.rowSpacing)
        let barY = y + CGFloat(CalendarLayout.maxVisibleLines) * CalendarLayout.eventLineHeight + CalendarLayout.eventBlockYMargin + CalendarLayout.eventBlockGap

        // 막대 설정
        let barWidth: CGFloat = 8.0
        let barHeight: CGFloat = CalendarLayout.eventBlockHeight - 2
        let spacing: CGFloat = 2.0

        // 고유 캘린더 추출 및 정렬
        let uniqueCalendars = Array(Set(eventBlocks.compactMap { $0.event.calendar })).sorted { $0.title < $1.title }
        let maxBars = min(uniqueCalendars.count, 5)
        let totalWidth = CGFloat(maxBars) * barWidth + CGFloat(maxBars - 1) * spacing
        let startX = x + (cellWidth - totalWidth) / 2.0

        for (index, calendar) in uniqueCalendars.prefix(maxBars).enumerated() {
            // 해당 캘린더의 이벤트 수 계산
            let count = eventBlocks.filter { $0.event.calendar == calendar }.count

            // 막대 뷰
            let barView = UIView(frame: CGRect(
                x: startX + CGFloat(index) * (barWidth + spacing),
                y: barY,
                width: barWidth,
                height: barHeight
            ))
            barView.layer.cornerRadius = 1.0
//            barView.backgroundColor = UIColor(cgColor: calendar.cgColor ?? UIColor.systemGray.cgColor).withAlphaComponent(0.9)
            barView.backgroundColor = CalendarColor.eventBackgroundColor(from: calendar.cgColor)

            // 숫자 라벨
            let label = UILabel(frame: barView.bounds)
            label.text = "\(count)"
            label.font = UIFont.systemFont(ofSize: 10)
            label.textColor = CalendarColor.eventTextColor(from: calendar.cgColor)
            label.textAlignment = .center
            label.adjustsFontSizeToFitWidth = true

            barView.addSubview(label)
            overlayView.addSubview(barView)
        }
    }
    

    private func sliceEventByWeek(event: EKEvent, from startDate: Date, to endDate: Date) -> [EventBlock] {
        var result: [EventBlock] = []
        var currentStart = startDate

        while currentStart <= endDate {
            guard let weekEnd = calendar.date(byAdding: .day, value: 6 - ((calendar.component(.weekday, from: currentStart) - 1) % 7), to: currentStart) else { break }
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
        titleLabel.font = CalendarFont.titleFont
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupMonthTitleContainerView() {
        monthTitleContainerView.translatesAutoresizingMaskIntoConstraints = false
        monthTitleContainerView.backgroundColor = .clear
        monthTitleContainerView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: monthTitleContainerView.topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: monthTitleContainerView.bottomAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: monthTitleContainerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: monthTitleContainerView.centerYAnchor)
        ])
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


    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        days.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DayCell", for: indexPath) as! DayCell
        let date = days[indexPath.item]
        let weekdayIndex = indexPath.item % 7  // 0 ~ 6

        if date == Date.distantPast {
            cell.configure(day: "", isToday: false, isSelected: false, index: weekdayIndex)

        } else {
            let isToday = calendar.isDateInToday(date)
            let day = calendar.component(.day, from: date)
            
            let isSelected = selectedDate != nil && calendar.isDate(date, inSameDayAs: selectedDate!)

            
            cell.configure(day: "\(day)", isToday: isToday, isSelected: isSelected, index: weekdayIndex)
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width / CalendarLayout.dayCellWidthDivider
        return CGSize(width: width, height: CalendarLayout.dayCellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        HapticFeedbackManager.triggerNotification(.success)

        let date = days[indexPath.item]
        guard date != Date.distantPast else { return }

        // ✅ 선택된 날짜 저장
        selectedDate = date

        // ✅ 선택 콜백 실행
        onDateSelected?(date)

        // ✅ 선택 시 전체 셀 다시 그리기 (선택 원 표시 위해)
        collectionView.reloadData()
    }
}
