/**
 WKNavigation.swift
 © 2024 Jukerstone. All rights reserved.
 */

import SwiftUI
import WebKit

@available(iOS 13.0, *)
extension DMGPlayerSDK: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if self.isForeground {
            if self.isPrimaryActive && webView == foregroundPrimaryBuffer {
                webView.evaluateJavaScript(buildCommonJavaScript() + buildActiveJavaScript(), completionHandler: nil)
            } else if self.isPrimaryActive && webView == foregroundSecondaryBuffer {
                webView.evaluateJavaScript(buildCommonJavaScript() + buildInactiveJavaScript(), completionHandler: nil)
            } else if !self.isPrimaryActive && webView == foregroundPrimaryBuffer {
                webView.evaluateJavaScript(buildCommonJavaScript() + buildInactiveJavaScript(), completionHandler: nil)
            } else if !self.isPrimaryActive && webView == foregroundSecondaryBuffer {
                webView.evaluateJavaScript(buildCommonJavaScript() + buildActiveJavaScript(), completionHandler: nil)
            } else if webView == backgroundBuffer {
                webView.evaluateJavaScript(buildCommonJavaScript() + buildInactiveJavaScript(), completionHandler: nil)
            } else if webView == pictureBuffer {
                webView.evaluateJavaScript(buildCommonJavaScript() + buildInactiveJavaScript(), completionHandler: nil)
            }
        } else {
            if webView == backgroundBuffer {
                webView.evaluateJavaScript(buildCommonJavaScript() + buildInactiveJavaScript(), completionHandler: nil)
            } else if webView == backgroundRunningPrimaryBuffer {
                webView.evaluateJavaScript(buildCommonJavaScript() + buildActiveJavaScript(), completionHandler: nil)
            } else if webView == backgroundRunningSecondaryBuffer {
                webView.evaluateJavaScript(buildCommonJavaScript() + buildActiveJavaScript(), completionHandler: nil)
            } else if webView == pictureBuffer {
                webView.evaluateJavaScript(buildCommonJavaScript() + buildInactiveJavaScript(), completionHandler: nil)
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

