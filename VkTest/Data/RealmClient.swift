//
//  RealmClient.swift
//  VkTest
//
//  Created by Digital on 30.10.2020.
//

import Foundation
import RealmSwift

enum RealmClientError: Error, LocalizedError {
    var errorDescription: String? {
        switch self {
        case .itemLimitExceeded:
            return "You can't save any more items!"
//        @unknown default:
//            return nil
        }
    }
    case itemLimitExceeded
}

class RealmClient {
    let realm: Realm?
    private let userDefaultsClient: UserDefaultsClient

    init(realm: Realm?, userDefaults: UserDefaults) {
        self.realm = realm
        self.userDefaultsClient = UserDefaultsClient(userDefaults: userDefaults)
    }

    convenience init() {
        self.init(realm: AppDelegate.defaultRealm, userDefaults: UserDefaults.standard)
    }

    @discardableResult func persistPost(_ post: VKPostPayload) throws -> PersistentPost? {
        let maxPosts = userDefaultsClient.loadMaxPostsValue()
        if maxPosts > 0, loadPosts().count >= maxPosts {
            throw RealmClientError.itemLimitExceeded
        }
        let persistentPost = PersistentPost()
        persistentPost.text = post.text
        persistentPost.postID = post.postID
        persistentPost.postDate = post.postDate
        try realm?.write {
            realm?.add(persistentPost)
        }
        return persistentPost
    }

    func loadPosts() -> [PersistentPost] {
        if let objects = realm?.objects(PersistentPost.self).sorted(byKeyPath: #keyPath(PersistentPost.postDate), ascending: false) {
            return Array(objects)
        } else {
            return []
        }
    }

    func loadPostWithId(_ id: Int) -> PersistentPost? {
        realm?.objects(PersistentPost.self).filter("(id=%@)", id as Any).first
    }

    func deletePostWithId(_ id: Int) throws {
        guard let object = loadPostWithId(id) else {
            return
        }

        try deletePost(object)
    }

    func deletePost(_ post: PersistentPost) throws {
        try realm?.write {
            realm?.delete(post)
        }
    }

    func deleteAllPosts() throws {
        try realm?.write {
            realm?.delete(loadPosts())
        }
    }

    @discardableResult func persistGroup(_ payload: VKGroupPayload) throws -> PersistentGroup? {
        let maxGroups = userDefaultsClient.loadMaxGroupsValue()
        if maxGroups > 0, loadGroups().count >= maxGroups {
            throw RealmClientError.itemLimitExceeded
        }
        let persistentGroup = PersistentGroup()
        persistentGroup.name = payload.name
        persistentGroup.id = payload.id
        try realm?.write {
            realm?.add(persistentGroup)
        }
        return persistentGroup
    }

    func loadGroups() -> [PersistentGroup] {
        if let objects = realm?.objects(PersistentGroup.self) {
            return Array(objects)
        } else {
            return []
        }
    }

    func loadGroupWithId(_ id: Int) -> PersistentGroup? {
        realm?.objects(PersistentGroup.self).filter("(id=%@)", id as Any).first
    }

    func deleteGroupWithId(_ id: Int) throws {
        guard let object = loadGroupWithId(id) else {
            return
        }

        try deleteGroup(object)
    }

    func deleteGroup(_ group: PersistentGroup) throws {
        try realm?.write {
            realm?.delete(group)
        }
    }

    func deleteAllGroups() throws {
        try realm?.write {
            realm?.delete(loadGroups())
        }
    }
}
