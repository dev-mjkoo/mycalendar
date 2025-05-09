//
//  MonthCell.swift
//  mycalendar
//
//  Created by 구민준 on 5/9/25.
//

//
//  MonthCell.swift
//  mycalendar
//
//  Created by 구민준 on 5/9/25.
//

import UIKit

class MonthCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    // MARK: - UI 요소

    private let titleLabel = UILabel() // 월 타이틀 (예: "April 2025")
    private var collectionView: UICollectionView! // 날짜들을 표시할 컬렉션 뷰
    private var days: [Date] = []
    private var calendar = Calendar.current
    /// 계산된 줄 수 (최대 6)
    var weekCount: Int {
        return Int(ceil(Double(days.count) / 7.0))
    }
    //✅ 1. MonthCell에 선택된 날짜 전달 & 저장
    var selectedDate: Date?
    var onDateSelected: ((Date) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupTitleLabel()
        setupCollectionView()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 구성 메서드

    func configure(with date: Date, selected: Date?) {
        self.selectedDate = selected

        // 타이틀 설정
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "MMMM yyyy"
        titleLabel.text = formatter.string(from: date)

        // 일자 배열 생성
        generateDays(for: date)

        // 날짜 갱신
        collectionView.reloadData()
    }

    // MARK: - 날짜 생성

    private func generateDays(for date: Date) {
        days = []

        let range = calendar.range(of: .day, in: .month, for: date)!
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let weekdayOffset = calendar.component(.weekday, from: firstOfMonth) - calendar.firstWeekday

        // 앞의 공백 (빈 날짜) 채우기
        for _ in 0..<((weekdayOffset + 7) % 7) {
            days.append(Date.distantPast) // 구분자 역할
        }

        // 실제 날짜 채우기
        for day in range {
            if let dayDate = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(dayDate)
            }
        }
    }

    // MARK: - 컬렉션 뷰 레이아웃 및 셀 설정
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let date = days[indexPath.item]
        guard date != Date.distantPast else { return }

        selectedDate = date
        onDateSelected?(date)
        collectionView.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return days.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DayCell", for: indexPath) as! DayCell

        cell.layer.borderWidth = 0.5
        cell.layer.borderColor = UIColor.lightGray.cgColor

        let date = days[indexPath.item]
        if date == Date.distantPast {
            cell.configure(day: "", isToday: false, isSelected: false)
        } else {
            let day = calendar.component(.day, from: date)
            let isToday = calendar.isDate(date, inSameDayAs: Date())
            let isSelected = selectedDate != nil && calendar.isDate(date, inSameDayAs: selectedDate!)
            
            cell.configure(day: "\(day)", isToday: isToday, isSelected: isSelected)
        }

        
        return cell
    }

    // 날짜 셀 크기 설정 (정사각형)
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width / 7
        return CGSize(width: width, height: width) // 정사각형
    }

    // MARK: - UI 설정

    private func setupTitleLabel() {
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 8 // 주차 간 간격

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(DayCell.self, forCellWithReuseIdentifier: "DayCell")
        collectionView.isScrollEnabled = false // MonthCell 안에서 스크롤 막기
        collectionView.backgroundColor = .clear
    }

    private func setupLayout() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(collectionView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8) // ✅ 이거만 남기자!
        ])
    }
}
