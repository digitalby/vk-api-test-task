//
//  BrowseViewController.swift
//  VkTest
//
//  Created by Digital on 29.10.2020.
//

import UIKit
import Alamofire
import SwiftyJSON

class BrowseViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView?
    @IBOutlet weak var createPostView: CreatePostView?
    @IBOutlet weak var adjustableBottomConstraint: NSLayoutConstraint?
    let refreshControl = UIRefreshControl()

    private(set) var keyboardConstraintAdjuster: KeyboardConstraintAdjuster!

    let userCredentialsHelper = UserCredentialsHelper()

    let session = Session()

    private(set) var posts = [String]()

    override func awakeFromNib() {
        super.awakeFromNib()
        refreshPostsWithDefaultAuthPayload()
    }

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
        tableView?.refreshControl = refreshControl
        tableView?.dataSource = self
        tableView?.delegate = self
        refreshControl.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)
        guard let createPostView = createPostView else {
            return
        }
        createPostView.delegate = self
        if let constraint = adjustableBottomConstraint {
            keyboardConstraintAdjuster = KeyboardConstraintAdjuster(
                bottomConstraint: constraint,
                viewToAdjust: createPostView,
                offset: -(tabBarController?.tabBar.bounds.height ?? 0.0)
            )
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tabBarController?.navigationItem.rightBarButtonItems = []
    }

}

//MARK: - Control views
extension BrowseViewController {
    @objc func didPullToRefresh(_ sender: Any?) {
        refreshPostsWithDefaultAuthPayload()
    }
}

//MARK: - Get data
extension BrowseViewController {
    func refreshPostsWithDefaultAuthPayload(resetExisting: Bool = true) {
        if let payload = try? userCredentialsHelper.loadOAuthPayload() {
            refreshPostsWithAuthPayload(payload, resetExisting: resetExisting)
        }
    }

    func refreshPostsWithAuthPayload(_ authPayload: VKAuthPayload, resetExisting: Bool = true) {
        session.cancelAllRequests()
        refreshControl.beginRefreshing()
        guard let userID = authPayload.userId else {
            refreshControl.endRefreshing()
            return
        }
        var components = URLComponents(string: #"https://api.vk.com/method/wall.get"#)!
        components.queryItems = [
            URLQueryItem(name: "v", value: "5.52"),
            URLQueryItem(name: "access_token", value: authPayload.accessToken),
//            URLQueryItem(name: "owner_id", value: String(userID)),
            URLQueryItem(name: "owner_id", value: "1"),
            URLQueryItem(name: "count", value: "20"),
            URLQueryItem(name: "offset", value: resetExisting ? "0" : "\(posts.count)")
        ]
        let url: URL
        do {
            url = try components.asURL()
        } catch {
            refreshControl.endRefreshing()
            return
        }
        session.request(url).validate().responseJSON { [weak self] response in
            defer {
                self?.refreshControl.endRefreshing()
            }
            if let error = response.error {
                print("Request error \(error)")
            } else if let value = response.value {
                DispatchQueue.main.async {
                    let json = JSON(value)
                    let jsonResponse = json["response"]
                    let jsonItems = jsonResponse["items"].array ?? []
                    var postsCount = self?.posts.count ?? 0

                    guard let self = self else {
                        return
                    }
                    self.tableView?.beginUpdates()
                    if resetExisting {
                        self.posts = []
                        for i in 0..<postsCount {
                            self.tableView?.deleteRows(at: [IndexPath(row: i, section: 0)], with: .automatic)
                        }
                        postsCount = 0
                    }
                    for i in 0..<jsonItems.count {
                        let item = jsonItems[i]
                        let postText = item["text"].string ?? "<error>"
                        let nextRow = self.posts.count
                        self.posts.append(postText)
                        self.tableView?.insertRows(at: [IndexPath(row: nextRow, section: 0)], with: .automatic)
                    }
                    self.tableView?.endUpdates()
                }
            }
        }
    }
}

//MARK: - Table View Data Source + Delegate
extension BrowseViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        posts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.numberOfLines = 8
        cell.textLabel?.text = posts[indexPath.row]

        if indexPath.row + 1 == posts.count {
            refreshPostsWithDefaultAuthPayload(resetExisting: false)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
}

//MARK: - Create Post View Delegate
extension BrowseViewController: CreatePostViewDelegate {
    func createPostView(_ createPostView: CreatePostView, didTapSendButtonWith text: String) {
        print(text)
    }
}

//MARK: - Observer
extension BrowseViewController {
    @objc func onCredentialsChanged(_ notification: Notification?) {
        if let payload = notification?.object as? VKAuthPayload {
            refreshPostsWithAuthPayload(payload)
        } else {
            posts = []
            tableView?.reloadData()
        }
    }

    private func setupObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(onCredentialsChanged), name: .credentialsDidChangeNotification, object: nil)
    }

    private func tearDownObserver() {
        NotificationCenter.default.removeObserver(self)
    }
}
