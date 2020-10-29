//
//  OptionsViewController.swift
//  VkTest
//
//  Created by Digital on 29.10.2020.
//

import UIKit

class OptionsViewController: UIViewController {

    @IBOutlet weak var avatarView: AvatarView?
    @IBOutlet weak var nameLabel: UILabel!

    let signOutBarButtonItem = UIBarButtonItem(title: "Sign Out", style: .plain, target: self, action: #selector(didTapSignOut))

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tabBarController?.navigationItem.rightBarButtonItems = [signOutBarButtonItem]
    }

    @objc func didTapSignOut(_ sender: Any?) {
        print("Sign Out")
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
