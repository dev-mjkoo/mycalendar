import UIKit
import EventKit

class CalendarViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    var collectionView: UICollectionView!
    var baseDate: Date = Date()
    var visibleMonths: [Date] = []
    let calendar = Calendar.current
    let totalVisible = 1000
    var onMonthChange: ((String, Date) -> Void)?
    private var lastReportedMonth: String?
    var monthHeights: [IndexPath: CGFloat] = [:]
    var selectedDate: Date?
    var onDateSelected: ((Date) -> Void)?
    
    var eventsByMonth: [Date: [Event]] = [:]  // ✅ Event 모델 사용

    private var preloadWorkItem: DispatchWorkItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupMonths()
        setupCollectionView()
    }

    func setEvents(for month: Date, events: [Event]) {
        eventsByMonth[calendar.startOfMonth(for: month)] = events
        collectionView.reloadData()
    }

    func setupMonths() {
        let mid = totalVisible / 2
        visibleMonths = (0..<totalVisible).compactMap {
            calendar.date(byAdding: .month, value: $0 - mid, to: baseDate)
        }
    }

    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 12

        let dayCellHeight = CalendarLayout.dayCellHeight
        let rowSpacing = CalendarLayout.rowSpacing
        let rows = CalendarLayout.rowsPerMonth
        let titleHeight = CalendarLayout.monthTitleHeight
        let padding = CalendarLayout.verticalPadding

        let calendarHeight = CGFloat(rows) * dayCellHeight + CGFloat(rows - 1) * rowSpacing

        layout.itemSize = CGSize(
            width: view.bounds.width,
            height: titleHeight + calendarHeight + padding
        )

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(MonthCell.self, forCellWithReuseIdentifier: "MonthCell")
        collectionView.prefetchDataSource = self
        view.addSubview(collectionView)

        collectionView.scrollToItem(at: IndexPath(item: totalVisible / 2, section: 0), at: .centeredVertically, animated: false)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        visibleMonths.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MonthCell", for: indexPath) as! MonthCell
        let monthDate = visibleMonths[indexPath.item]
        let events = eventsByMonth[calendar.startOfMonth(for: monthDate)] ?? []
        cell.configure(with: monthDate, selected: selectedDate, events: events)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let cached = monthHeights[indexPath] {
            return CGSize(width: collectionView.bounds.width, height: cached)
        }

        let date = visibleMonths[indexPath.item]
        let weekCount = calculateWeekCount(for: date)

        let dayCellHeight = CalendarLayout.dayCellHeight
        let spacing = CalendarLayout.rowSpacing
        let titleHeight = CalendarLayout.monthTitleHeight
        let padding = CalendarLayout.verticalPadding

        let calendarHeight = CGFloat(weekCount) * dayCellHeight + CGFloat(weekCount - 1) * spacing
        let totalHeight = titleHeight + calendarHeight + padding

        monthHeights[indexPath] = totalHeight
        return CGSize(width: collectionView.bounds.width, height: totalHeight)
    }
    
    func calculateWeekCount(for date: Date) -> Int {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: date),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else {
            return 6
        }

        let weekday = calendar.component(.weekday, from: firstOfMonth)
        let offset = (weekday - calendar.firstWeekday + 7) % 7
        let totalDays = offset + range.count

        return Int(ceil(Double(totalDays) / 7.0))
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateCurrentMonth()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            updateCurrentMonth()
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCurrentMonth()

        preloadWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.preloadEventsAroundVisibleMonths()
        }
        preloadWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
    }
    
    private func preloadEventsAroundVisibleMonths() {
        let visibleIndexPaths = collectionView.indexPathsForVisibleItems
        guard !visibleIndexPaths.isEmpty else { return }

        let visibleItems = visibleIndexPaths.map { $0.item }
        let minIndex = max((visibleItems.min() ?? 0) - 1, 0)
        let maxIndex = min((visibleItems.max() ?? 0) + 1, visibleMonths.count - 1)

        for index in minIndex...maxIndex {
            let month = visibleMonths[index]
            let key = calendar.startOfMonth(for: month)

            guard eventsByMonth[key] == nil else { continue }

            EventKitManager.shared.fetchEvents(for: month) { events in
                DispatchQueue.main.async {
                    self.setEvents(for: month, events: events)  // ✅ 이미 [Event]
                }
            }
        }
    }

    func updateCurrentMonth() {
        let visibleCenter = CGPoint(
            x: collectionView.contentOffset.x + collectionView.bounds.width / 2,
            y: collectionView.contentOffset.y + collectionView.bounds.height / 2
        )

        guard let indexPath = collectionView.indexPathForItem(at: visibleCenter) else { return }

        let date = visibleMonths[indexPath.item]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        let newMonth = formatter.string(from: date)

        if newMonth != lastReportedMonth {
            lastReportedMonth = newMonth
            onMonthChange?(newMonth, date)
        }
    }
    
    func scrollToToday() {
        guard let todayIndex = visibleMonths.firstIndex(where: {
            calendar.isDate($0, equalTo: Date(), toGranularity: .month)
        }) else { return }

        let indexPath = IndexPath(item: todayIndex, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
    }
    
    func reloadVisibleMonths() {
        let visiblePaths = collectionView.indexPathsForVisibleItems.sorted(by: { $0.item < $1.item })

        for path in visiblePaths {
            let month = visibleMonths[path.item]
            EventKitManager.shared.fetchEvents(for: month) { events in
                DispatchQueue.main.async {
                    self.setEvents(for: month, events: events)
                }
            }
        }
    }
}

extension CalendarViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let month = visibleMonths[indexPath.item]
            let key = calendar.startOfMonth(for: month)

            guard eventsByMonth[key] == nil else { continue }

            EventKitManager.shared.fetchEvents(for: month) { events in
                DispatchQueue.main.async {
                    self.setEvents(for: month, events: events)
                }
            }
        }
    }
}
