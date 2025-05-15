//
//  MyPanelCoordinator.swift
//  mycalendar
//
//  Created by 구민준 on 5/15/25.
//
import SwiftUI
import FloatingPanel

// A custom coordinator object which handles panel context updates and setting up `FloatingPanelControllerDelegate` methods
class MyPanelCoordinator: FloatingPanelCoordinator {
    enum Event {}

    let action: (Event) -> Void
    let proxy: FloatingPanelProxy

    required init(action: @escaping (MyPanelCoordinator.Event) -> Void) {
        self.action = action
        self.proxy = .init(controller: FloatingPanelController())
    }

    func setupFloatingPanel<Main, Content>(
        mainHostingController: UIHostingController<Main>,
        contentHostingController: UIHostingController<Content>
    ) where Main: View, Content: View {
        // Set this as the delegate object
        controller.delegate = self

        // Set up the content
        contentHostingController.view.backgroundColor = .clear
        controller.set(contentViewController: contentHostingController)

        // Show the panel
        controller.addPanel(toParent: mainHostingController, animated: false)
    }

    func onUpdate<Representable>(
        context: UIViewControllerRepresentableContext<Representable>
    ) where Representable: UIViewControllerRepresentable {}
}

extension MyPanelCoordinator: FloatingPanelControllerDelegate {
    func floatingPanelDidChangeState(_ fpc: FloatingPanelController) {
        // NOTE: This timing is difference from one of the change of the binding value
        // to `floatingPanelState(_:)` modifier
    }
}
