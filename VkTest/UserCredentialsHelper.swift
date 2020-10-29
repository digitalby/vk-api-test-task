//
//  UserCredentialsHelper.swift
//  VkTest
//
//  Created by Digital on 29.10.2020.
//

import Foundation
import SwiftKeychainWrapper

class UserCredentialsHelper {
    var keychainWrapper: KeychainWrapper

    init(keychainWrapper: KeychainWrapper) {
        self.keychainWrapper = keychainWrapper
    }

    convenience init() {
        self.init(keychainWrapper: KeychainWrapper.standard)
    }

    func loadOAuthPayload() throws -> VKAuthPayload? {
        guard let payloadData = keychainWrapper.data(forKey: "oAuthPayload") else {
            return nil
        }
        let decoder = JSONDecoder()
        let payload = try decoder.decode(VKAuthPayload.self, from: payloadData)
        return payload
    }

    func saveOAuthPayload(_ payload: VKAuthPayload) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(payload)
        keychainWrapper.set(data, forKey: "oAuthPayload")
    }
}
