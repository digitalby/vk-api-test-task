//
//  PersistentGroup.swift
//  VkTest
//
//  Created by Digital on 30.10.2020.
//

import Foundation
import RealmSwift

@objcMembers class PersistentGroup: Object {
    dynamic var name: String = ""
    dynamic var id: Int?
}
