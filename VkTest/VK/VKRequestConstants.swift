//
//  VKRequestConstants.swift
//  VkTest
//
//  Created by Digital on 30.10.2020.
//

import Foundation

struct VKRequestConstants {
    //MARK: Functions
    static let kWallGetFunction = "wall.get"
    static let kWallPostFunction = "wall.post"
    static let kUsersGetFunction = "users.get"

    //MARK: Query params
    static let kVersionQueryItem = "v"
    static let kAccessTokenQueryItem = "access_token"
    static let kOwnerIDQueryItem = "owner_id"
    static let kCountQueryItem = "count"
    static let kOffsetQueryItem = "offset"
    static let kUserIDsQueryItem = "user_ids"
    static let kFieldsQueryItem = "fields"

    //MARK: Query values
    static let kVersionValue5_52 = "5.52"
    static let kProfileFieldsValuePhoto_200 = "photo_200"

    //MARK: Response
    static let kJSONResponseKey = "response"

    //MARK: Error
    static let kJSONErrorKey = "error"
    static let kJSONErrorCodeKey = "error_code"
    static let kJSONErrorMessageKey = "error_msg"

    //MARK: User payload
    static let kUserPayloadFirstNameKey = "first_name"
    static let kUserPayloadLastNameKey = "last_name"
    static let kUserPayloadPhoto200Key = "photo_200"
}
