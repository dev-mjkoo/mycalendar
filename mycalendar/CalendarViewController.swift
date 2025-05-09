//
//  CalendarViewController.swift
//  mycalendar
//
//  Created by 구민준 on 5/9/25.
//

import UIKit

class CalendarViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    // MARK: - Properties

    var collectionView: UICollectionView!
    var baseDate: Date = Date()
    var visibleMonths: [Date] = []
    let calendar = Calendar.current
    let totalVisible = 1000  // 과거 500 ~ 미래 500개월
    var onMonthChange: ((String) -> Void)?
    private var lastReportedMonth: String?
    var monthHeights: [IndexPath: CGFloat] = [:]
    
    
    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupMonths()
        setupCollectionView()
    }

    // MARK: - Setup Methods

    /// 월 데이터 생성 (기준 날짜로부터 과거/미래 포함 총 1000개월)
    func setupMonths() {
        let mid = totalVisible / 2
        visibleMonths = (0..<totalVisible).compactMap {
            calendar.date(byAdding: .month, value: $0 - mid, to: baseDate)
        }
    }

    /// 컬렉션 뷰 초기화 및 레이아웃 설정
    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 12

        // 정확한 MonthCell 높이 계산
        let dayCellHeight = UIScreen.main.bounds.width / 7
        let rowSpacing: CGFloat = 8
        let rows = 6
        let calendarHeight = CGFloat(rows) * dayCellHeight + CGFloat(rows - 1) * rowSpacing
        let titleHeight: CGFloat = 40 // 타이틀 + 여백

        layout.itemSize = CGSize(width: view.bounds.width, height: titleHeight + calendarHeight + 16) // top 8 + bottom 

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(MonthCell.self, forCellWithReuseIdentifier: "MonthCell")
        view.addSubview(collectionView)

        // 시작 위치: 기준 월을 가운데로
        collectionView.scrollToItem(at: IndexPath(item: totalVisible / 2, section: 0), at: .centeredVertically, animated: false)
    }

    // MARK: - Collection View Data Source

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return visibleMonths.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MonthCell", for: indexPath) as! MonthCell
        cell.configure(with: visibleMonths[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let cached = monthHeights[indexPath] {
            return CGSize(width: collectionView.bounds.width, height: cached)
        }

        let date = visibleMonths[indexPath.item]
        let weekCount = calculateWeekCount(for: date)
        let dayCellHeight = collectionView.bounds.width / 7
        let spacing: CGFloat = 8
        let titleHeight: CGFloat = 40

        let calendarHeight = CGFloat(weekCount) * dayCellHeight + CGFloat(weekCount - 1) * spacing
        let totalHeight = titleHeight + calendarHeight + 16

        monthHeights[indexPath] = totalHeight
        return CGSize(width: collectionView.bounds.width, height: totalHeight)
    }
    
    func calculateWeekCount(for date: Date) -> Int {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: date),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else {
            return 6
        }

        let weekdayOffset = calendar.component(.weekday, from: firstOfMonth) - calendar.firstWeekday
        let totalDays = ((weekdayOffset + 7) % 7) + range.count
        return Int(ceil(Double(totalDays) / 7.0))
    }

    // MARK: - Scroll Tracking

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
    }

    /// 현재 화면 중앙에 보이는 MonthCell의 날짜 기반으로 타이틀 업데이트
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

        // 중복 호출 방지
        if newMonth != lastReportedMonth {
            lastReportedMonth = newMonth
            onMonthChange?(newMonth)
        }
    }
    
    func scrollToToday() {
        guard let todayIndex = visibleMonths.firstIndex(where: {
            calendar.isDate($0, equalTo: Date(), toGranularity: .month)
        }) else { return }

        let indexPath = IndexPath(item: todayIndex, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
    }
}
