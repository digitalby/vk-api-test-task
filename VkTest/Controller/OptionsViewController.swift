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
    @IBOutlet weak var maxPostsStepper: UIStepper?
    @IBOutlet weak var maxPostsStepperLabel: UILabel?

    let signOutBarButtonItem = UIBarButtonItem(title: "Sign Out", style: .plain, target: nil, action: nil)

    let imageDownloader = VKImageDownloader()
    let userDefaultsClient = UserDefaultsClient()
    let vkClient = VKClient(
        requester: VKRequester(
            userCredentialsHelper: UserCredentialsHelper()
        )
    )

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
        updateStepperState()
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

//MARK: - Data constraints
extension OptionsViewController {
    @IBAction func didChangePostsStepperValue(_ sender: Any) {
        let stepperValue = Int(maxPostsStepper?.value ?? 0)
        userDefaultsClient.saveMaxPostsValue(stepperValue)
        updateStepperState()
    }

    func updateStepperState() {
        let value = userDefaultsClient.loadMaxPostsValue()
        maxPostsStepper?.value = Double(value)
        maxPostsStepperLabel?.text = "\(value) Max Posts (0 = no limit)"
    }
}

//MARK: - Retrieve data
extension OptionsViewController {
    func refresh() {
        vkClient.requestVKCurrentUserInfo { result in
            switch result {
            case .failure(let error):
                print(#function, #line, error)
            case .success(let payload):
                DispatchQueue.main.async { [weak self] in
                    self?.setNameComponents(firstName: payload.firstName, lastName: payload.lastName)
                    if let url = payload.photo200URL {
                        self?.downloadAvatarImage(from: url)
                    }
                }
            }
        }
    }

    func downloadAvatarImage(from url: URL) {
        imageDownloader.downloadAvatarImage(from: url) { result in
            switch result {
            case .failure(let error):
                print(#function, #line, error)
            case .success(let image):
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
        if notification?.object as? VKAuthPayload != nil {
            refresh()
        } else {
            setNameComponents(firstName: nil, lastName: nil)
            setAvatarImage(nil)
            userDefaultsClient.saveMaxPostsValue(0)
            updateStepperState()
        }
    }

    private func setupObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(onCredentialsChanged), name: .credentialsDidChangeNotification, object: nil)
    }

    private func tearDownObserver() {
        NotificationCenter.default.removeObserver(self)
    }
}
