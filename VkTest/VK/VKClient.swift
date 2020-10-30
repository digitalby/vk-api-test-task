//
//  VKClient.swift
//  VkTest
//
//  Created by Digital on 30.10.2020.
//

import Foundation
import Alamofire
import SwiftyJSON

class VKClient {
    let requester: VKRequester

    typealias VKUserRequestResult = Result<VKUserPayload, Error>

    init(requester: VKRequester) {
        self.requester = requester
    }

    func requestVKCurrentUserInfo(then: @escaping (VKUserRequestResult)->()) {
        let userID: Int
        do {
            guard let payload = try requester.userCredentialsHelper.loadOAuthPayload(),
                  let theUserID = payload.userId else {
                throw VKAuthHelperError.userIDError
            }
            userID = theUserID
        } catch {
            then(.failure(error))
            return
        }
        requestVKUserInfo(for: userID, then: then)
    }

    func requestVKUserInfo(for id: Int, then: @escaping (VKUserRequestResult)->()) {
        requester.performRequestForVKFunction(
            VKRequestConstants.kUsersGetFunction,
            extras: [
                VKRequestConstants.kUserIDsQueryItem : String(id),
                VKRequestConstants.kFieldsQueryItem : VKRequestConstants.kProfileFieldsValuePhoto_200
            ]
        ) { result in
            switch result {
            case .failure(let error):
                then(.failure(error))
            case .success(let json):
                if let error = Self.getVKErrorPayload(from: json) {
                    then(.failure(error))
                    return
                }
                let jsonResponse = json[VKRequestConstants.kJSONResponseKey][0]
                if let firstName = jsonResponse[VKRequestConstants.kUserPayloadFirstNameKey].string,
                   let lastName = jsonResponse[VKRequestConstants.kUserPayloadLastNameKey].string {
                    let pictureURL = jsonResponse[VKRequestConstants.kUserPayloadPhoto200Key].url
                    let user = VKUserPayload(firstName: firstName, lastName: lastName, photo200URL: pictureURL)
                    then(.success(user))
                    return
                }
                then(.failure(VKGenericError.noResponse))
            }
        }
    }

    static func getVKErrorPayload(from json: JSON) -> VKError? {
        if let jsonErrorCode = json[VKRequestConstants.kJSONErrorKey][VKRequestConstants.kJSONErrorCodeKey].int,
           let jsonErrorMessage = json[VKRequestConstants.kJSONErrorKey][VKRequestConstants.kJSONErrorMessageKey].string {
            return VKError(code: jsonErrorCode, message: jsonErrorMessage)
        }
        return nil
    }
}
