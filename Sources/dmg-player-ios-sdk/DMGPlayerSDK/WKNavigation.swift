// WKNavigation.swift

import SwiftUI
import WebKit

@available(iOS 13.0, *)
extension DMGPlayerSDK: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let jsCodeCommon = buildCommonJavaScript()
        
        guard self.isForeground else {
            // The app is in the background, do nothing or handle the background state
            webView.evaluateJavaScript(buildInactiveJavaScript(), completionHandler: nil)
            return
        }
       
        guard webView != bkPrimaryWebView else {
            print("bk prim")
            webView.evaluateJavaScript(buildCommonJavaScript() + buildInactiveJavaScript(), completionHandler: nil)
            return
        }
        
        if self.isPrimaryActive && webView == primaryWebView {
            print("WHYY", webView)
            webView.evaluateJavaScript(buildCommonJavaScript() + buildActiveJavaScript(), completionHandler: nil)
        } else if self.isPrimaryActive && webView == secondaryWebView {
            print("WHYY1", webView)
            webView.evaluateJavaScript(buildCommonJavaScript() + buildInactiveJavaScript(), completionHandler: nil)
        } else if !self.isPrimaryActive && webView == primaryWebView {
            print("WHYY2", webView)
            webView.evaluateJavaScript(buildCommonJavaScript() + buildInactiveJavaScript(), completionHandler: nil)
        } else if !self.isPrimaryActive && webView == secondaryWebView {
            print("WHYY3", webView)
            webView.evaluateJavaScript(buildCommonJavaScript() + buildActiveJavaScript(), completionHandler: nil)
        }
    }
}
