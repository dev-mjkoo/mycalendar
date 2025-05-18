//
//  MyPanelCoordinator+Extensions.swift
//  mycalendar
//
//  Created by 구민준 on 5/18/25.
//
import SwiftUI
import FloatingPanel

extension MyPanelCoordinator: FloatingPanelControllerDelegate {
    func floatingPanelDidChangeState(_ fpc: FloatingPanelController) {
        // NOTE: This timing is difference from one of the change of the binding value
        // to `floatingPanelState(_:)` modifier
    }
}
