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
    typealias VKPostsRequestResult = Result<[VKPostPayload], Error>
    typealias VKCreatePostResult = Result<Int, Error>
    typealias VKGroupsRequestResult = Result<[VKGroupPayload], Error>

    init(requester: VKRequester) {
        self.requester = requester
    }

    func createVKPostForCurrentUser(message: String, then: @escaping (VKCreatePostResult)->()) {
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
        requester.performRequestForVKFunction(
            VKRequestConstants.kWallPostFunction,
            extras: [
                VKRequestConstants.kOwnerIDQueryItem : String(userID),
                VKRequestConstants.kMessageQueryItem : message,
            ]) { result in
            switch result {
            case .failure(let error):
                then(.failure(error))
            case .success(let json):
                if let error = Self.getVKErrorPayload(from: json) {
                    then(.failure(error))
                    return
                }
                let jsonResponse = json[VKRequestConstants.kJSONResponseKey]
                if let postID = jsonResponse[VKRequestConstants.kPostsPayloadPostIDKey].int {
                    then(.success(postID))
                } else {
                    then(.failure(VKGenericError.noResponse))
                }
            }
        }
    }

    func requestVKGroupsForCurrentUser(amount: Int, offset: Int, then: @escaping (VKGroupsRequestResult)->()) {
//        requestVKGroupsForSampleID(amount: amount, offset: offset, then: then)
//        return;
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
        requestVKGroups(for: userID, amount: amount, offset: offset, then: then)
    }

    func requestVKGroupsForSampleID(amount: Int, offset: Int, then: @escaping (VKGroupsRequestResult)->()) {
        requestVKGroups(for: 66748, amount: amount, offset: offset, then: then)
    }

    func requestVKGroups(for userID: Int, amount: Int, offset: Int, then: @escaping (VKGroupsRequestResult)->()) {
        requester.performRequestForVKFunction(
            VKRequestConstants.kGroupsGetFunction,
            extras: [
                VKRequestConstants.kUserIDQueryItem : String(userID),
                VKRequestConstants.kCountQueryItem : String(amount),
                VKRequestConstants.kOffsetQueryItem : String(offset),
                VKRequestConstants.kExtendedQueryItem : String("1"),
        ]) { result in
            switch result {
            case .failure(let error):
                then(.failure(error))
            case .success(let json):
                if let error = Self.getVKErrorPayload(from: json) {
                    then(.failure(error))
                    return
                }
                let jsonResponse = json[VKRequestConstants.kJSONResponseKey]
                let jsonItems = jsonResponse[VKRequestConstants.kJSONItemsKey].array ?? []
                var payloads = [VKGroupPayload]()
                for jsonItem in jsonItems {
                    if jsonItem[VKRequestConstants.kUserPayloadFirstNameKey].string != nil ||
                        jsonItem[VKRequestConstants.kUserPayloadLastNameKey].string != nil {
                        continue
                    }
                    payloads.append(
                        VKGroupPayload(
                            name: jsonItem[VKRequestConstants.kGroupsPayloadGroupNameKey].string ?? "",
                            id: jsonItem[VKRequestConstants.kGroupsPayloadGroupIDKey].int
                        )
                    )
                }
                then(.success(payloads))
            }

        }
    }

    func requestVKPostsForCurrentUser(amount: Int, offset: Int, then: @escaping (VKPostsRequestResult)->()) {
//        requestVKPostsForDurov(amount: amount, offset: offset, then: then)
//        return;
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
        requestVKPosts(for: userID, amount: amount, offset: offset, then: then)
    }

    func requestVKPostsForDurov(amount: Int, offset: Int, then: @escaping (VKPostsRequestResult)->()) {
        requestVKPosts(for: 1, amount: amount, offset: offset, then: then)
    }

    func requestVKPosts(for userID: Int, amount: Int, offset: Int, then: @escaping (VKPostsRequestResult)->()) {
        requester.performRequestForVKFunction(
            VKRequestConstants.kWallGetFunction,
            extras: [
                VKRequestConstants.kOwnerIDQueryItem : String(userID),
                VKRequestConstants.kCountQueryItem : String(amount),
                VKRequestConstants.kOffsetQueryItem : String(offset),
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
                let jsonResponse = json[VKRequestConstants.kJSONResponseKey]
                let jsonItems = jsonResponse[VKRequestConstants.kJSONItemsKey].array ?? []
                let payloads = jsonItems.map { (jsonArrayItem) -> VKPostPayload in
                    let date: Date
                    if let dateInt = jsonArrayItem[VKRequestConstants.kPostsPayloadPostDateKey].int {
                        date = Date(timeIntervalSince1970: Double(dateInt))
                    } else {
                        date = Date()
                    }
                    return VKPostPayload(
                        text: jsonArrayItem[VKRequestConstants.kPostsPayloadPostTextKey].string,
                        postID: jsonArrayItem[VKRequestConstants.kPostsPayloadPostIDKey].int,
                        postDate: date
                    )
                }
                then(.success(payloads))
            }
        }
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
