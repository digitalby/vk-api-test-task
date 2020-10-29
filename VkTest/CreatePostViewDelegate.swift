//
//  CreatePostViewDelegate.swift
//  VkTest
//
//  Created by Digital on 30.10.2020.
//

import Foundation

protocol CreatePostViewDelegate: NSObject {
    func createPostView(_ createPostView: CreatePostView, didTapSendButtonWith text: String)
}
