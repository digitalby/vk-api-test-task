//
//  OptionsViewController.swift
//  VkTest
//
//  Created by Digital on 29.10.2020.
//

import UIKit
import Alamofire
import SwiftyJSON

class OptionsViewController: UIViewController {

    @IBOutlet weak var avatarView: AvatarView?
    @IBOutlet weak var nameLabel: UILabel?
    let signOutBarButtonItem = UIBarButtonItem(title: "Sign Out", style: .plain, target: nil, action: nil)
    let session = Session()

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
        if let payload = try? userCredentialsHelper.loadOAuthPayload() {
            refreshWithAuth(payload)
        }
    }

    @objc func didTapSignOut(_ sender: Any?) {
        userCredentialsHelper.deleteOAuthPayload()
        NotificationCenter.default.post(Notification(name: .credentialsDidChangeNotification, object: nil, userInfo: nil))
    }
}

//MARK: - Retrieve data
extension OptionsViewController {
    func refreshWithAuth(_ payload: VKAuthPayload) {
        guard let userID = payload.userId else {
            return
        }
        var components = URLComponents(string: #"https://api.vk.com/method/users.get"#)!
        components.queryItems = [
            URLQueryItem(name: "v", value: "5.52"),
            URLQueryItem(name: "access_token", value: payload.accessToken),
            URLQueryItem(name: "user_ids", value: String(userID)),
            URLQueryItem(name: "fields", value: "photo_200"),
        ]
        let url: URL
        do {
            url = try components.asURL()
        } catch {
            return
        }
        session.request(url).validate().responseJSON { [weak self] response in
            if let error = response.error {
                print("Request error \(error)")
            } else if let value = response.value {
                let json = JSON(value)
                let jsonResponse = json["response"][0]
                if let firstName = jsonResponse["first_name"].string,
                   let lastName = jsonResponse["last_name"].string {
                    DispatchQueue.main.async {
                        self?.setNameComponents(firstName: firstName, lastName: lastName)
                    }
                }
                if let pictureURL = jsonResponse["photo_200"].url {
                    self?.downloadAvatarImage(from: pictureURL)
                }
            }
        }
    }

    func downloadAvatarImage(from url: URL) {
        session.download(url).validate().responseData { response in
            if let error = response.error {
                print("Request error \(error)")
            } else if let value = response.value,
                      let image = UIImage(data: value) {
                DispatchQueue.main.async { [weak self] in
                    self?.setAvatarImage(image)
                }
            }
        }
    }

    func setNameComponents(firstName: String?, lastName: String?) {
        if let firstName = firstName, let lastName = lastName {
            nameLabel?.text = "\(firstName) \(lastName)"
        } else {
            nameLabel?.text = "--"
        }
    }

    func setAvatarImage(_ image: UIImage?) {
        if let image = image {
            avatarView?.image = image
        } else {
            avatarView?.image = UIImage(systemName: "person.circle.fill") ?? UIImage()
        }
    }
}

//MARK: - Observer
extension OptionsViewController {
    @objc func onCredentialsChanged(_ notification: Notification?) {
        if let payload = notification?.object as? VKAuthPayload {
            refreshWithAuth(payload)
        } else {
            setNameComponents(firstName: nil, lastName: nil)
            setAvatarImage(nil)
        }
    }

    private func setupObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(onCredentialsChanged), name: .credentialsDidChangeNotification, object: nil)
    }

    private func tearDownObserver() {
        NotificationCenter.default.removeObserver(self)
    }
}
