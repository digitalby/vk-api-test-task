//
//  TabBarController.swift
//  VkTest
//
//  Created by Digital on 29.10.2020.
//

import UIKit

class TabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.performSegue(withIdentifier: "PresentLogin", sender: self)
    }
}
