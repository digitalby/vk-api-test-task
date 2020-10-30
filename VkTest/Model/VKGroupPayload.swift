//
//  VKGroupPayload.swift
//  VkTest
//
//  Created by Digital on 30.10.2020.
//

import Foundation

struct VKGroupPayload: Codable, Equatable, Hashable {
    let name: String
    var id: Int?
}
