//
//  CreatePostView.swift
//  VkTest
//
//  Created by Digital on 30.10.2020.
//

import UIKit

@IBDesignable class CreatePostView: UIView {

    @IBOutlet weak var contentView: UIView?
    @IBOutlet weak var textView: UITextView?
    @IBOutlet weak var sendButton: UIButton?

    weak var delegate: CreatePostViewDelegate? = nil

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupView()
        contentView?.prepareForInterfaceBuilder()
    }

    private func setupView() {
        let theType = type(of: self)
        let name = String(describing: theType)
        let bundle = Bundle(for: theType)
        bundle.loadNibNamed(name, owner: self, options: nil)
        guard let contentView = contentView else {
            return
        }
        addSubview(contentView)
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.layer.borderColor = UIColor.systemGray.cgColor
        contentView.layer.borderWidth = 1.0

        textView?.clipsToBounds = true
        textView?.layer.borderWidth = 1.0
        textView?.layer.borderColor = UIColor.systemGray.cgColor
        textView?.layer.cornerRadius = 8.0
        textView?.delegate = self
        updateSendButtonState()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    @IBAction func didTapSendButton(_ sender: Any) {
        guard let text = textView?.text, !isTextViewEmpty else {
            updateSendButtonState()
            return
        }
        delegate?.createPostView(self, didTapSendButtonWith: text)
    }

    private var isTextViewEmpty: Bool {
        textView?.text.trimmingCharacters(in: .whitespacesAndNewlines).count == 0
    }

    private func updateSendButtonState() {
        if isTextViewEmpty {
            sendButton?.isEnabled = false
        } else {
            sendButton?.isEnabled = true
        }
    }
}

//MARK: - Text view delegate
extension CreatePostView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updateSendButtonState()
    }
}
