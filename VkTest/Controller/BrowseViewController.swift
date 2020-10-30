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

    lazy var tableViewHandler = LazyTableViewHandler { (item: String) -> UITableViewCell in
        let cell = UITableViewCell()
        cell.textLabel?.numberOfLines = 8
        cell.textLabel?.text = item
        return cell
    } onLazyLoad: { _ in
        self.refreshPosts(resetExisting: false)
    }

    let client = VKClient(
        requester: VKRequester(
            userCredentialsHelper: UserCredentialsHelper()
        )
    )

    override func awakeFromNib() {
        super.awakeFromNib()
        refreshPosts()
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
        tableView?.dataSource = tableViewHandler
        tableView?.delegate = tableViewHandler
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
        refreshPosts()
    }
}

//MARK: - Create posts
extension BrowseViewController {
    func createTextPost(_ text: String) {
        client.requester.session.cancelAllRequests()
        client.createVKPostForCurrentUser(message: text) { result in
            switch result {
            case .failure(let error):
                print("Create post error \(error)")
            case .success(_):
                DispatchQueue.main.async { [weak self] in
                    self?.refreshPosts(resetExisting: true)
                }
            }
        }
    }
}

//MARK: - Get data
extension BrowseViewController {

    func processNewPayloads(_ payloads: [VKPostPayload], resetExisting: Bool) {
        var postsCount = tableViewHandler.items.count

        tableView?.beginUpdates()
        if resetExisting {
            tableViewHandler.items = []
            for i in 0..<postsCount {
                tableView?.deleteRows(at: [IndexPath(row: i, section: 0)], with: .automatic)
            }
            postsCount = 0
        }
        for i in 0..<payloads.count {
            let item = payloads[i]
            let postText = item.text ?? "<error>"
            let nextRow = tableViewHandler.items.count
            tableViewHandler.items.append(postText)
            tableView?.insertRows(at: [IndexPath(row: nextRow, section: 0)], with: .automatic)
        }
        tableView?.endUpdates()
    }

    func refreshPosts(resetExisting: Bool = true) {
        client.requester.session.cancelAllRequests()
        refreshControl.beginRefreshing()
        client.requestVKPostsForCurrentUser(
            amount: 20,
            offset: resetExisting ? 0 : tableViewHandler.items.count
        ) { result in
            DispatchQueue.main.async { [weak self] in
                self?.refreshControl.endRefreshing()
                switch result {
                case .failure(let error):
                    print("Refresh posts error \(error)")
                case .success(let payloads):
                    DispatchQueue.main.async {
                        self?.processNewPayloads(payloads, resetExisting: resetExisting)
                    }
                }
            }
        }
    }
}

//MARK: - Create Post View Delegate
extension BrowseViewController: CreatePostViewDelegate {
    func createPostView(_ createPostView: CreatePostView, didTapSendButtonWith text: String) {
        createPostView.textView?.text = ""

        createTextPost(text)
    }
}

//MARK: - Observer
extension BrowseViewController {
    @objc func onCredentialsChanged(_ notification: Notification?) {
        if notification?.object as? VKAuthPayload != nil {
            refreshPosts()
        } else {
            tableViewHandler.items = []
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
