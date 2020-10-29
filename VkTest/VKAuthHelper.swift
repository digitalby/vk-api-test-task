//
//  VKAuthHelper.swift
//  VkTest
//
//  Created by Digital on 29.10.2020.
//

import Foundation

enum VKAuthHelperError: Error {
    case fragmentError
    case responseError(description: String)
    case oAuthCodeError
}

class VKAuthHelper {
    func verifyVKSignIn(for components: URLComponents, then: (VKAuthPayload)->(), error: (Error)->()) {
        guard let fragment = components.fragment else {
            error(VKAuthHelperError.fragmentError)
            return
        }
        let responseDictionary = convertFragmentToDictionary(fragment)
        if let errorKey = responseDictionary["error"],
           let errorDescription = responseDictionary["error_description"] {
            let errorObject = VKAuthHelperError.responseError(description: "\(errorKey): \(errorDescription)")
            error(errorObject)
            return
        }
        guard let accessToken = responseDictionary["access_token"] else {
            error(VKAuthHelperError.oAuthCodeError)
            return
        }

        let expiresIn = responseDictionary["expires_in"]
        let userId = responseDictionary["user_id"]
        let payload = VKAuthPayload(
            accessToken: accessToken,
            expiresIn: Int(expiresIn ?? ""),
            userId: Int(userId ?? "")
        )
        then(payload)
    }

    private func convertFragmentToDictionary(_ fragment: String) -> [String : String] {
        let fragmentComponents = fragment.split(separator: "&")
        var dictionary = [String : String]()
        for fragmentComponent in fragmentComponents {
            let split = fragmentComponent.split(separator: "=")
            guard split.count == 2 else {
                continue
            }
            dictionary[String(split[0])] = String(split[1])
        }
        return dictionary
    }
}
