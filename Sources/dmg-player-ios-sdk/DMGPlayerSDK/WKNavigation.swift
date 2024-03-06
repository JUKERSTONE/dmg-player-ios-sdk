// WKNavigation.swift

import SwiftUI
import WebKit

@available(iOS 13.0, *)
extension DMGPlayerSDK: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let jsCodeCommon = buildCommonJavaScript()
        
        guard UIApplication.shared.applicationState == .active else {
            // If the app is in the background, load the web view in an inactive state
            if webView == bkPrimaryWebView || webView == bkSecondaryWebView {
                let jsCodeInactive = buildCommonJavaScript() + buildInactiveJavaScript()
                webView.evaluateJavaScript(jsCodeInactive, completionHandler: nil)
            }
            return // Return early if app is in background
        }
        
        if self.isPrimaryActive && webView == primaryWebView {
            webView.evaluateJavaScript(buildCommonJavaScript() + buildActiveJavaScript(), completionHandler: nil)
        } else if self.isPrimaryActive && webView == secondaryWebView {
            webView.evaluateJavaScript(buildCommonJavaScript() + buildInactiveJavaScript(), completionHandler: nil)
        } else if !self.isPrimaryActive && webView == primaryWebView {
            webView.evaluateJavaScript(buildCommonJavaScript() + buildInactiveJavaScript(), completionHandler: nil)
        } else if !self.isPrimaryActive && webView == secondaryWebView {
            webView.evaluateJavaScript(buildCommonJavaScript() + buildActiveJavaScript(), completionHandler: nil)
        }
    }
}
