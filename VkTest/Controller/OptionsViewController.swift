//
//  OptionsViewController.swift
//  VkTest
//
//  Created by Digital on 29.10.2020.
//

import UIKit

class OptionsViewController: UIViewController {

    @IBOutlet weak var avatarView: AvatarView?
    @IBOutlet weak var nameLabel: UILabel?
    let signOutBarButtonItem = UIBarButtonItem(title: "Sign Out", style: .plain, target: nil, action: nil)

    let userCredentialsHelper = UserCredentialsHelper()

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setupObserver()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupObserver()
    }

    deinit {
        tearDownObserver()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        signOutBarButtonItem.target = self
        signOutBarButtonItem.action = #selector(didTapSignOut)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tabBarController?.navigationItem.rightBarButtonItems = [signOutBarButtonItem]
        refresh()
    }

    @objc func didTapSignOut(_ sender: Any?) {
        userCredentialsHelper.deleteOAuthPayload()
        NotificationCenter.default.post(Notification(name: .credentialsDidChangeNotification, object: nil, userInfo: nil))
    }
}

//MARK: - Retrieve data
extension OptionsViewController {
    func refresh() {

    }
}

//MARK: - Observer
extension OptionsViewController {
    @objc func onCredentialsChanged(_ notification: Notification?) {
        if let payload = notification?.object as? VKAuthPayload {
        }
    }

    private func setupObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(onCredentialsChanged), name: .credentialsDidChangeNotification, object: nil)
    }

    private func tearDownObserver() {
        NotificationCenter.default.removeObserver(self)
    }
}
