//
//  UserDefaultsClient.swift
//  VkTest
//
//  Created by Digital on 30.10.2020.
//

import Foundation

class UserDefaultsClient {
    static let kMaxPostsKey = "MaxPosts"

    let userDefaults: UserDefaults

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    convenience init() {
        self.init(userDefaults: UserDefaults.standard)
    }

    func saveMaxPostsValue(_ value: Int) {
        userDefaults.set(value, forKey: Self.kMaxPostsKey)
    }

    func loadMaxPostsValue() -> Int {
        userDefaults.integer(forKey: Self.kMaxPostsKey)
    }
}
