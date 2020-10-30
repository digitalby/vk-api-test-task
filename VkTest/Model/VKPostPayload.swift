//
//  VKPostPayload.swift
//  VkTest
//
//  Created by Digital on 30.10.2020.
//

import Foundation

struct VKPostPayload: Equatable, Hashable, Codable {
    let text: String?
    let postID: Int?
    let postDate: Date
}
