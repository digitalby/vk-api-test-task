//
//  GroupWrapper.swift
//  VkTest
//
//  Created by Digital on 30.10.2020.
//

import Foundation

enum GroupWrapper: Equatable {
    case `struct`(VKGroupPayload)
    case persistent(PersistentGroup)
    case error
}
