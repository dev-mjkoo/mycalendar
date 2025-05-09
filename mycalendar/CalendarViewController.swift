//
//  CalendarViewController.swift
//  mycalendar
//
//  Created by 구민준 on 5/9/25.
//

import UIKit

class CalendarViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    var collectionView: UICollectionView!
    var baseDate: Date = Date()
    var visibleMonths: [Date] = []
    let calendar = Calendar.current
    let totalVisible = 1000  // 과거 500 ~ 미래 500개월

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupMonths()
        setupCollectionView()
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
        layout.itemSize = CGSize(width: view.bounds.width, height: 300)
        layout.minimumLineSpacing = 0

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(MonthCell.self, forCellWithReuseIdentifier: "MonthCell")
        view.addSubview(collectionView)

        collectionView.scrollToItem(at: IndexPath(item: totalVisible / 2, section: 0), at: .centeredVertically, animated: false)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return visibleMonths.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MonthCell", for: indexPath) as! MonthCell
        cell.configure(with: visibleMonths[indexPath.item])
        return cell
    }
}
