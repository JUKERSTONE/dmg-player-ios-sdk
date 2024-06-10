/**
 WKNavigation.swift
 © 2024 Jukerstone. All rights reserved.
 */

import SwiftUI
import WebKit

@available(iOS 13.0, *)
extension DMGPlayerSDK: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript(buildCommonJavaScript() + buildActiveJavaScript(), completionHandler: nil)
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Navigation error on webView: \(webView) with error: \(error)")
    }

    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("Provisional navigation error on webView: \(webView) with error: \(error)")
    }
}

