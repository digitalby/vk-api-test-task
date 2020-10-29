//
//  TabBarController.swift
//  VkTest
//
//  Created by Digital on 29.10.2020.
//

import UIKit

class TabBarController: UITabBarController {

    let userCredentialsHelper = UserCredentialsHelper()

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self
        if (try? userCredentialsHelper.loadOAuthPayload()) == nil {
            navigationController?.performSegue(withIdentifier: "PresentLogin", sender: self)
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

//MARK: - Tab bar delegate
extension TabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        updateTitle()
    }
}
