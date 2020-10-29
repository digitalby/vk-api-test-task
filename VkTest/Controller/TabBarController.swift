//
//  TabBarController.swift
//  VkTest
//
//  Created by Digital on 29.10.2020.
//

import UIKit

class TabBarController: UITabBarController {

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

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self
        if (try? userCredentialsHelper.loadOAuthPayload()) == nil {
            presentLogin()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        updateTitle()
    }

    private func updateTitle() {
        title = selectedViewController?.title
    }
}

//MARK: - Login
extension TabBarController {
    func presentLogin() {
        navigationController?.performSegue(withIdentifier: "PresentLogin", sender: self)
    }
}

//MARK: - Observer
extension TabBarController {
    @objc func onCredentialsChanged(_ notification: Notification?) {
        if notification?.object == nil {
            presentLogin()
        }
    }

    func setupObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(onCredentialsChanged), name: .credentialsDidChangeNotification, object: nil)
    }

    func tearDownObserver() {
        NotificationCenter.default.removeObserver(self)
    }
}

//MARK: - Tab bar delegate
extension TabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        updateTitle()
    }
}
