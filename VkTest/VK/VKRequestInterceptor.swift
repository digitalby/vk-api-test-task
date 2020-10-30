//
//  VKRequestInterceptor.swift
//  VkTest
//
//  Created by Digital on 30.10.2020.
//

import Foundation
import Alamofire

class VKRequestInterceptor: RequestInterceptor {
    private let userCredentialsHelper: UserCredentialsHelper

    init(userCredentialsHelper: UserCredentialsHelper) {
        self.userCredentialsHelper = userCredentialsHelper
    }

    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var request = urlRequest
        let authPayload: VKAuthPayload
        do {
            guard let persistentPayload = try userCredentialsHelper.loadOAuthPayload() else {
                throw VKAuthHelperError.oAuthCodeError
            }
            authPayload = persistentPayload
        } catch {
            completion(.failure(error))
            return
        }
        guard let urlString = urlRequest.url?.absoluteString,
              var components = URLComponents(string: urlString) else {
            completion(.failure(AFError.invalidURL(url: urlRequest.url ?? "")))
            return
        }
        if components.queryItems == nil {
            components.queryItems = []
        }
        if !(components.queryItems?.contains(where: { $0.name == VKRequestConstants.kVersionQueryItem }) ?? false) {
            components.queryItems?.append(
                URLQueryItem(
                    name: VKRequestConstants.kVersionQueryItem,
                    value: VKRequestConstants.kVersionValue5_52
                )
            )
        }
        if !(components.queryItems?.contains(where: {$0.name == VKRequestConstants.kAccessTokenQueryItem}) ?? false) {
            components.queryItems?.append(
                URLQueryItem(
                    name: VKRequestConstants.kAccessTokenQueryItem,
                    value: authPayload.accessToken
                )
            )
        }
        do {
            let newURL = try components.asURL()
            request.url = newURL
            completion(.success(request))
        } catch {
            completion(.failure(error))
            return
        }
    }

    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        completion(.retryWithDelay(2.0))
    }
}
