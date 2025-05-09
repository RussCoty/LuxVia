//
//  OrderOfServiceViewController.swift
//  FuneralMusic
//
//  Created by Russell Cottier on 05/05/2025.
//

import Foundation
import UIKit
import WebKit

class OrderOfServiceViewController: UIViewController {
    
    var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Order of Service"

        webView = WKWebView(frame: self.view.bounds)
        view.addSubview(webView)

        if let url = URL(string: "https://funeralmusic.co.uk/order-of-service-creator-127/") {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
}
