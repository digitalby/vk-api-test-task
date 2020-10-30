//
//  LoginViewController.swift
//  VkTest
//
//  Created by Digital on 29.10.2020.
//

import UIKit
import Alamofire
import WebKit

class LoginViewController: UIViewController {
    @IBOutlet weak var webView: WKWebView?
    @IBOutlet var backButton: UIBarButtonItem!
    @IBOutlet var refreshButton: UIBarButtonItem!

    let authHelper = VKAuthHelper()
    let credentialsHelper = UserCredentialsHelper()

    override func viewDidLoad() {
        super.viewDidLoad()
        webView?.navigationDelegate = self
        signInWithVK()
    }

    private let permissionsBitmaskString: String = {
        let wallPermission = 1 << 13
        let groupsPermission = 1 << 18

        let permissionsBitmask = wallPermission + groupsPermission

        return String(permissionsBitmask)
    }()

    private func updateBackButtonState() {
        backButton.isEnabled = webView?.canGoBack ?? false
    }

    @IBAction func didTapBackButton(_ sender: Any) {
        webView?.goBack()
    }

    @IBAction func didTapRefreshButton(_ sender: Any) {
        webView?.reload()
    }

    func signInWithVK() {
//        authHelper.fetchAccessCodeWithOAuth(presentFrom: self) {
//            print("Done")
//        }
        updateBackButtonState()
        let callbackURL = #""#

        var components = URLComponents(string: #"https://oauth.vk.com/authorize"#)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: "7644371"),
            URLQueryItem(name: "scope", value: permissionsBitmaskString),
            URLQueryItem(name: "redirect_uri", value: callbackURL),
            URLQueryItem(name: "response_type", value: "token"),
            URLQueryItem(name: "revoke", value: "1"),
        ]
        let url: URL
        do {
            url = try components.asURL()
        } catch {
            return
        }
        let request = URLRequest(url: url)
        webView?.load(request)
    }
}

//MARK: - WKWebView
extension LoginViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url, let components = URLComponents(string: url.absoluteString) else {
            decisionHandler(.cancel)
            return
        }
        if components.path.contains("blank.html") {
            authHelper.verifyVKSignIn(for: components) { [self] payload in
                do {
                    try credentialsHelper.saveOAuthPayload(payload)
                } catch {
                }
                dismiss(animated: true, completion: nil)
            } error: { error in
                print("Error: \(error)")
            }
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        updateBackButtonState()
    }
}
