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

        if (try? userCredentialsHelper.loadOAuthPayload()) == nil {
            navigationController?.performSegue(withIdentifier: "PresentLogin", sender: self)
        }
    }
}
