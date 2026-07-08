import SwiftUI
import UIKit

struct KeyboardDismissalLayer: UIViewControllerRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> HostingController {
        let controller = HostingController()
        controller.onViewDidAppear = { [weak coordinator = context.coordinator] view in
            coordinator?.installIfNeeded(in: view.window)
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: HostingController, context: Context) {
        context.coordinator.installIfNeeded(in: uiViewController.view.window)
    }

    static func dismantleUIViewController(_ uiViewController: HostingController, coordinator: Coordinator) {
        coordinator.uninstall()
    }

    final class HostingController: UIViewController {
        var onViewDidAppear: ((UIView) -> Void)?

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            onViewDidAppear?(view)
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private weak var window: UIWindow?
        private weak var recognizer: UITapGestureRecognizer?

        func installIfNeeded(in window: UIWindow?) {
            guard let window, self.window !== window else { return }
            uninstall()

            let recognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
            recognizer.cancelsTouchesInView = false
            recognizer.delegate = self
            window.addGestureRecognizer(recognizer)

            self.window = window
            self.recognizer = recognizer
        }

        func uninstall() {
            if let recognizer {
                window?.removeGestureRecognizer(recognizer)
            }
            recognizer = nil
            window = nil
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            !isInsideTextInput(touch.view)
        }

        @objc private func dismissKeyboard() {
            window?.endEditing(true)
        }

        private func isInsideTextInput(_ view: UIView?) -> Bool {
            var candidate = view
            while let current = candidate {
                if current is UITextField || current is UITextView {
                    return true
                }
                candidate = current.superview
            }
            return false
        }
    }
}
