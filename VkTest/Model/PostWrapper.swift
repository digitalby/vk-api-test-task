//
//  PostWrapper.swift
//  VkTest
//
//  Created by Digital on 30.10.2020.
//

import Foundation

enum PostWrapper: Equatable {
    case `struct`(VKPostPayload)
    case persistent(PersistentPost)
    case error
}
