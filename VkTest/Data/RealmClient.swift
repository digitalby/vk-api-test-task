//
//  RealmClient.swift
//  VkTest
//
//  Created by Digital on 30.10.2020.
//

import Foundation
import RealmSwift

enum RealmClientError {
    case itemLimitExceeded
}

class RealmClient {
    let realm: Realm?

    init(realm: Realm?) {
        self.realm = realm
    }

    convenience init() {
        self.init(realm: AppDelegate.defaultRealm)
    }

    @discardableResult func persistPost(_ post: VKPostPayload) throws -> PersistentPost? {
        let persistentPost = PersistentPost()
        persistentPost.text = post.text
        persistentPost.postID = post.postID
        try realm?.write {
            realm?.add(persistentPost)
        }
        return persistentPost
    }

    func loadPosts() -> [PersistentPost] {
        if let objects = realm?.objects(PersistentPost.self) {
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
}
