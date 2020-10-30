//
//  LazyTableViewHandler.swift
//  VkTest
//
//  Created by Digital on 30.10.2020.
//

import UIKit

class LazyTableViewHandler<T>: NSObject, UITableViewDataSource, UITableViewDelegate where T: Equatable {
    var items = [T]()

    var lazyLoadThreshold = 20

    //First argument is number of items
    private var onLazyLoad: (Int)->()
    //Argument is indexPath.row
    var onCellTap: (Int)->() = { _ in }
    //Argument is indexPath.row
    lazy var lazyLoadCondition: (Int)->(Bool) = {
        $0 + 1 == self.items.count
    }
    //Argument is item for cell
    private var cellBuilder: (T)->(UITableViewCell)

    init(cellBuilder: @escaping (T)->(UITableViewCell), onLazyLoad: @escaping (Int)->()) {
        self.cellBuilder = cellBuilder
        self.onLazyLoad = onLazyLoad
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        let cell = cellBuilder(item)

        if lazyLoadCondition(indexPath.row) {
            onLazyLoad(lazyLoadThreshold)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        onCellTap(indexPath.row)
    }
}
