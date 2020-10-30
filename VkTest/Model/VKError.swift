//
//  VKError.swift
//  VkTest
//
//  Created by Digital on 30.10.2020.
//

import Foundation

struct VKError: Error, CustomNSError, LocalizedError {
    static let errorDomain: String = "me.digitalby.VkTest.VKError"

    var code: Int
    var message: String

    var errorCode: Int {
        code
    }

    var errorUserInfo: [String : Any] {
        [NSLocalizedDescriptionKey : message]
    }

    var errorDescription: String? {
        message
    }
}

enum VKGenericError: Error {
    case noResponse
    case badPostID
}
