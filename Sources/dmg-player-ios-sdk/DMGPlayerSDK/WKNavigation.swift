// WKNavigation.swift

import SwiftUI
import WebKit

@available(iOS 13.0, *)
extension DMGPlayerSDK: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let jsCodeCommon = buildCommonJavaScript()

        if webView !== bkPrimaryWebView || webView !== bkSecondaryWebView {
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
}
