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
    private static let defaultDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    lazy var tableViewHandler = LazyTableViewHandler { (item: PostWrapper) -> UITableViewCell in
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "PostCell")
        cell.textLabel?.numberOfLines = 8
        switch item {
        case .error:
            cell.textLabel?.text = "<error>"
            cell.detailTextLabel?.text = ""
        case .persistent(let post):
            cell.textLabel?.text = post.text?.count == 0 ? "<empty post>" : post.text
            cell.detailTextLabel?.text = "\(Self.defaultDateFormatter.string(from: post.postDate)) | Tap to unsave"
        case .struct(let post):
            cell.textLabel?.text = post.text?.count == 0 ? "<empty post>" : post.text
            cell.detailTextLabel?.text = "\(Self.defaultDateFormatter.string(from: post.postDate)) | Tap to save"
        }
        return cell
    } onLazyLoad: { _ in
        self.refreshPosts(resetExisting: false)
    }

    let vkClient = VKClient(
        requester: VKRequester(
            userCredentialsHelper: UserCredentialsHelper()
        )
    )
    let realmClient = RealmClient()

    override func awakeFromNib() {
        super.awakeFromNib()
        loadPersistentData()
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

        tableViewHandler.lazyLoadCondition = { [self] i in
            let numberOfNonPersistentItems = self.tableViewHandler.items.filter {
                if case .struct(_) = $0 {
                    return true
                }
                return false
            }.count
            return i + 1 == numberOfNonPersistentItems
        }
        tableViewHandler.onCellTap = { [self] i in
            do {
                switch tableViewHandler.items[i] {
                case .persistent(let post):
                    let payload = VKPostPayload(
                        text: post.text,
                        postID: post.postID,
                        postDate: post.postDate
                    )
                    try self.realmClient.deletePost(post)
                    tableView?.beginUpdates()
                    tableViewHandler.items[i] = .struct(payload)
                    tableView?.reloadRows(at: [IndexPath(row: i, section: 0)], with: .automatic)
                    tableView?.endUpdates()
                case .struct(let post):
                    guard let newPost = try self.realmClient.persistPost(post) else {
                        return
                    }
                    tableView?.beginUpdates()
                    tableViewHandler.items[i] = .persistent(newPost)
                    let indexPath = IndexPath(row: i, section: 0)
                    tableView?.reloadRows(at: [indexPath], with: .fade)
                    tableView?.endUpdates()
                default:
                    break
                }
            } catch {
                print("Realm error \(error)")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                tableView?.beginUpdates()
                tableView?.endUpdates()
            }
        }
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
        vkClient.requester.session.cancelAllRequests()
        vkClient.createVKPostForCurrentUser(message: text) { result in
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
    func loadPersistentData() {
        let posts = realmClient.loadPosts()
        tableView?.beginUpdates()
        for post in posts {
            let nextRow = tableViewHandler.items.count
            tableViewHandler.items.append(.persistent(post))
            tableView?.insertRows(at: [IndexPath(row: nextRow, section: 0)], with: .automatic)
        }
        tableView?.endUpdates()
    }

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
            let nextRow = tableViewHandler.items.count
            tableViewHandler.items.append(.struct(item))
            tableView?.insertRows(at: [IndexPath(row: nextRow, section: 0)], with: .automatic)
        }
        tableView?.endUpdates()
    }

    func refreshPosts(resetExisting: Bool = true) {
        vkClient.requester.session.cancelAllRequests()
        refreshControl.beginRefreshing()
        vkClient.requestVKPostsForCurrentUser(
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
            do {
                try realmClient.deleteAllPosts()
            } catch {
                print("Couldn't delete all posts: \(error)")
            }
        }
    }

    private func setupObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(onCredentialsChanged), name: .credentialsDidChangeNotification, object: nil)
    }

    private func tearDownObserver() {
        NotificationCenter.default.removeObserver(self)
    }
}
