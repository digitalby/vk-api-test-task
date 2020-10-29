//
//  VKAuthPayload.swift
//  VkTest
//
//  Created by Digital on 29.10.2020.
//

import Foundation

struct VKAuthPayload: Codable, Equatable, Hashable {
    let accessToken: String
    let expiresIn: Int?
    let userId: Int?
}
