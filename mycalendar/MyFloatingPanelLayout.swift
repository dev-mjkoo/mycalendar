//
//  MyFloatingPanelLayout.swift
//  mycalendar
//
//  Created by 구민준 on 5/15/25.
//
import UIKit
import FloatingPanel

// A custom layout object
class MyFloatingPanelLayout: FloatingPanelLayout {
    let position: FloatingPanelPosition = .bottom
    let initialState: FloatingPanelState = .tip
    let anchors: [FloatingPanelState: FloatingPanelLayoutAnchoring] = [
        // todo : 위치 수정
        .full: FloatingPanelLayoutAnchor(absoluteInset: 200.0, edge: .top, referenceGuide: .safeArea),
        .half: FloatingPanelLayoutAnchor(fractionalInset: 0.4, edge: .bottom, referenceGuide: .safeArea),
        .tip: FloatingPanelLayoutAnchor(absoluteInset: 110.0, edge: .bottom, referenceGuide: .safeArea),
    ]
}
