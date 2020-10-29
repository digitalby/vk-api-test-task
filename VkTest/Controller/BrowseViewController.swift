//
//  BrowseViewController.swift
//  VkTest
//
//  Created by Digital on 29.10.2020.
//

import UIKit

class BrowseViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tabBarController?.navigationItem.rightBarButtonItems = []
    }
}
