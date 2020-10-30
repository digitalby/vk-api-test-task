//
//  VKImageDownloader.swift
//  VkTest
//
//  Created by Digital on 30.10.2020.
//

import UIKit
import Alamofire

class VKImageDownloader {
    let session = Session()

    func downloadAvatarImage(from url: URL, then: @escaping (Result<UIImage, Error>)->()) {
        session.download(url).validate().responseData { response in
            if let error = response.error {
                then(.failure(error))
            } else if let value = response.value,
                      let image = UIImage(data: value) {
                then(.success(image))
            } else {
                then(.failure(VKGenericError.noResponse))
            }
        }
    }
}
