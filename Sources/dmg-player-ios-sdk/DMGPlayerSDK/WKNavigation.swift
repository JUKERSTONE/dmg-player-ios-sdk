// WKNavigation.swift

import SwiftUI
import WebKit

@available(iOS 13.0, *)
extension DMGPlayerSDK: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if self.isForeground {
            if self.isPrimaryActive && webView == foregroundPrimaryBuffer {
                print("WHYY", webView)
                webView.evaluateJavaScript(buildCommonJavaScript() + buildActiveJavaScript(), completionHandler: nil)
            } else if self.isPrimaryActive && webView == foregroundSecondaryBuffer {
                print("WHYY1", webView)
                webView.evaluateJavaScript(buildCommonJavaScript() + buildInactiveJavaScript(), completionHandler: nil)
            } else if !self.isPrimaryActive && webView == foregroundPrimaryBuffer {
                print("WHYY2", webView)
                webView.evaluateJavaScript(buildCommonJavaScript() + buildInactiveJavaScript(), completionHandler: nil)
            } else if !self.isPrimaryActive && webView == foregroundSecondaryBuffer {
                print("WHYY3", webView)
                webView.evaluateJavaScript(buildCommonJavaScript() + buildActiveJavaScript(), completionHandler: nil)
            } else if webView == backgroundPrimaryBuffer {
                print("Background bkPrimaryWebView loaded")
                webView.evaluateJavaScript(buildCommonJavaScript() + buildInactiveJavaScript(), completionHandler: nil)
            }
        } else {
            if webView == backgroundPrimaryBuffer {
                print("WHYY", webView)
                webView.evaluateJavaScript(buildCommonJavaScript() + buildInactiveJavaScript(), completionHandler: nil)
            } else if webView == freeloadingBuffer {
                webView.evaluateJavaScript(buildCommonJavaScript() + buildActiveJavaScript(), completionHandler: nil)
            }
        }
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Navigation error on webView: \(webView) with error: \(error)")
    }

    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("Provisional navigation error on webView: \(webView) with error: \(error)")
    }
}

