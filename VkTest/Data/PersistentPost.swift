//
//  PersistentPost.swift
//  VkTest
//
//  Created by Digital on 30.10.2020.
//

import Foundation
import RealmSwift

@objcMembers class PersistentPost: Object {
    dynamic var text: String?
    dynamic var postID: Int?
    dynamic var postDate: Date = Date()
}
