//
//  GroupsViewController.swift
//  VkTest
//
//  Created by Digital on 30.10.2020.
//

import UIKit

class GroupsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView?

    let refreshControl = UIRefreshControl()

    lazy var tableViewHandler = LazyTableViewHandler { (item: GroupWrapper) -> UITableViewCell in
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "GroupCell")
        cell.textLabel?.numberOfLines = 1
        switch item {
        case .error:
            cell.textLabel?.text = "<error>"
            cell.detailTextLabel?.text = ""
        case .persistent(let group):
            cell.textLabel?.text = group.name
        case .struct(let group):
            cell.textLabel?.text = group.name
        }
        return cell
    } onLazyLoad: { _ in
        self.refreshGroups(resetExisting: false)
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
        refreshGroups()
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
                case .persistent(let group):
                    let payload = VKGroupPayload(
                        name: group.name
                    )
                    try self.realmClient.deleteGroup(group)
                    tableView?.beginUpdates()
                    tableViewHandler.items[i] = .struct(payload)
                    tableView?.reloadRows(at: [IndexPath(row: i, section: 0)], with: .automatic)
                    tableView?.endUpdates()
                case .struct(let group):
                    guard let newGroup = try self.realmClient.persistGroup(group) else {
                        return
                    }
                    tableView?.beginUpdates()
                    tableViewHandler.items[i] = .persistent(newGroup)
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
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tabBarController?.navigationItem.rightBarButtonItems = []
    }

}

//MARK: - Control views
extension GroupsViewController {
    @objc func didPullToRefresh(_ sender: Any?) {
        refreshGroups()
    }
}

//MARK: - Get data
extension GroupsViewController {
    func loadPersistentData() {
        let groups = realmClient.loadGroups()
        tableView?.beginUpdates()
        for group in groups {
            let nextRow = tableViewHandler.items.count
            tableViewHandler.items.append(.persistent(group))
            tableView?.insertRows(at: [IndexPath(row: nextRow, section: 0)], with: .automatic)
        }
        tableView?.endUpdates()
    }

    func processNewPayloads(_ payloads: [VKGroupPayload], resetExisting: Bool) {
        var groupsCount = tableViewHandler.items.count

        tableView?.beginUpdates()
        if resetExisting {
            tableViewHandler.items = []
            for i in 0..<groupsCount {
                tableView?.deleteRows(at: [IndexPath(row: i, section: 0)], with: .automatic)
            }
            groupsCount = 0
        }
        for i in 0..<payloads.count {
            let item = payloads[i]
            let nextRow = tableViewHandler.items.count
            tableViewHandler.items.append(.struct(item))
            tableView?.insertRows(at: [IndexPath(row: nextRow, section: 0)], with: .automatic)
        }
        tableView?.endUpdates()
    }

    func refreshGroups(resetExisting: Bool = true) {
        vkClient.requester.session.cancelAllRequests()
        refreshControl.beginRefreshing()
        vkClient.requestVKGroupsForCurrentUser(
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

//MARK: - Observer
extension GroupsViewController {
    @objc func onCredentialsChanged(_ notification: Notification?) {
        if notification?.object as? VKAuthPayload != nil {
            refreshGroups()
        } else {
            tableViewHandler.items = []
            tableView?.reloadData()
            do {
                try realmClient.deleteAllGroups()
            } catch {
                print("Couldn't delete all groups: \(error)")
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
