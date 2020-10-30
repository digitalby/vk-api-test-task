//
//  VKRequester.swift
//  VkTest
//
//  Created by Digital on 30.10.2020.
//

import Foundation
import Alamofire
import SwiftyJSON

class VKRequester: RequestInterceptor {

    var session: Session
    let userCredentialsHelper: UserCredentialsHelper

    init(session: Session, userCredentialsHelper: UserCredentialsHelper) {
        self.session = session
        self.userCredentialsHelper = userCredentialsHelper
    }

    convenience init(userCredentialsHelper: UserCredentialsHelper) {
        let interceptor = VKRequestInterceptor(userCredentialsHelper: userCredentialsHelper)
        self.init(
            session: Session(
                interceptor: interceptor
            ),
            userCredentialsHelper: userCredentialsHelper
        )
    }

    func performRequestForVKFunction(_ function: String, extras: [String : String], then: @escaping (Result<JSON, Error>)->()) {
        var components = URLComponents(string: "https://api.vk.com/method/\(function)")!
        if extras.count > 0 {
            components.queryItems = []
        }
        extras.forEach {
            components.queryItems?.append(
                URLQueryItem(
                    name: $0,
                    value: $1
                )
            )
        }
        let url: URL
        do {
            url = try components.asURL()
        } catch {
            then(.failure(error))
            return
        }
        session.request(url).validate().responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                then(.success(json))
            case .failure(let error):
                then(.failure(error))
            }
        }
    }
}
