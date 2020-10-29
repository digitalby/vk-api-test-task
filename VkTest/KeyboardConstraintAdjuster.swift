//
//  KeyboardConstraintAdjuster.swift
//  VkTest
//
//  Created by Digital on 30.10.2020.
//

import UIKit

/// Responsible for adjusting the Auto Layout bottom constraint of a view
/// when the on-screen keyboard appears or disappears.
/// - Copyright: digitalby
class KeyboardConstraintAdjuster {
    /// The default duration of the constraint adjustment animation.
/// - Copyright: digitalby
    let defaultDuration = 0.25

    /// The Auto Layout bottom anchor constraint to be adjusted.
    /// - Copyright: digitalby
    var bottomConstraint: NSLayoutConstraint!
    /// The view that contains the Auto Layout constraint to adjust.
    /// - Copyright: digitalby
    var viewToAdjust: UIView!
    /// The delta value to be added to the adjusted constraint constant value.
    /// - Copyright: digitalby
    var offset: CGFloat = 0.0
    /// The constraint constant value before the adjustment operation.
    /// - Copyright: digitalby
    private var originalConstraintConstant: CGFloat!

    /// - Important: All observer references are removed in the deinitializer.
    /// - Copyright: digitalby
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}

//MARK: - Setup
extension KeyboardConstraintAdjuster {
    /// Initializes the adjuster, then calls the `setup` method with the specified parameters.
    /// - Parameters:
    ///   - bottomConstraint: The bottom constraint to be adjusted.
    ///   - viewToAdjust: The view that contains the bottom constraint.
    ///   - offset: The constant's delta to use.
    /// - Copyright: digitalby
    convenience init(bottomConstraint: NSLayoutConstraint, viewToAdjust: UIView, offset: CGFloat = 0.0) {
        self.init()
        setup(bottomConstraint: bottomConstraint, viewToAdjust: viewToAdjust, offset: offset)
    }

    /// Configures the adjuster with the specified parameters
    /// while preparing it for listening to keyboard appearing/disappearing events.
    /// - Parameters:
    ///   - bottomConstraint: The bottom constraint to be adjusted.
    ///   - viewToAdjust: The view that contains the bottom constraint.
    ///   - offset: The constant's delta to use.
    /// - Copyright: digitalby
    func setup(bottomConstraint: NSLayoutConstraint, viewToAdjust: UIView, offset: CGFloat = 0.0) {
        self.bottomConstraint = bottomConstraint
        self.viewToAdjust = viewToAdjust
        self.offset = offset
        originalConstraintConstant = bottomConstraint.constant

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}

//MARK: - Obj-C constraint adjustment methods
extension KeyboardConstraintAdjuster {
    @objc func keyboardWillShow(_ notification: Notification) {
        guard let info = notification.userInfo else { return }
        guard let keyboardFrame = info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let duration = (info[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? defaultDuration
        let frame = keyboardFrame.cgRectValue
        let newConstraintConstant = abs(originalConstraintConstant) + frame.size.height + offset
        bottomConstraint.constant = newConstraintConstant

        UIView.animate(withDuration: duration) {
            self.viewToAdjust.layoutIfNeeded()
        }
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        bottomConstraint.constant = originalConstraintConstant

        UIView.animate(withDuration: defaultDuration) {
            self.viewToAdjust.layoutIfNeeded()
        }
    }
}
