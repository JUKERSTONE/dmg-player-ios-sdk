// WKNavigation.swift

import SwiftUI
import WebKit

@available(iOS 13.0, *)
extension DMGPlayerSDK: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        print("didFinish")
        
        if self.isForeground && webView != self.bkWebViews[index] {
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
            } else if webView == self.bkWebViews[index] {
                print("Background bkPrimaryWebView loaded")
                webView.evaluateJavaScript(buildCommonJavaScript() + buildInactiveJavaScript(), completionHandler: nil)
            }
        } else {
            // Background behavior
//            if webView == bkPrimaryWebView {
//                print("Background bkPrimaryWebView loaded")
//                webView.evaluateJavaScript(buildCommonJavaScript() + buildInactiveJavaScript(), completionHandler: nil)
//            }
            // You can add more background-related conditions here if needed.
            print("isFree: ", self.isFreeloading)
            if self.isFreeloading == true && webView == self.bkWebViews[index] {
                print("WHYY FREE", webView)
                self.bkWebViews[index].evaluateJavaScript(buildPlayJavaScript(), completionHandler: nil)
            } else if !self.isFreeloading && webView == self.bkWebViews[index] {
                print("WHYY", webView)
                webView.evaluateJavaScript(buildCommonJavaScript() + buildInactiveJavaScript(), completionHandler: nil)
            }
//            else if webView == bkSecondaryWebView {
//                print("WHYY1", webView)
//                webView.evaluateJavaScript(buildCommonJavaScript() + buildActiveJavaScript(), completionHandler: nil)
//            }
//            else if !self.isBkPrimaryActive && webView == bkPrimaryWebView {
//                print("WHYY2", webView)
//                webView.evaluateJavaScript(buildCommonJavaScript() + buildActiveJavaScript(), completionHandler: nil)
//            } else if !self.isBkPrimaryActive && webView == bkSecondaryWebView {
//                print("WHYY3", webView)
//                webView.evaluateJavaScript(buildCommonJavaScript() + buildInactiveJavaScript(), completionHandler: nil)
//            }
//            else if webView == bkPrimaryWebView {
//                print("Background bkPrimaryWebView loaded")
//                webView.evaluateJavaScript(buildCommonJavaScript() + buildInactiveJavaScript(), completionHandler: nil)
//            }
        }
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        // Handle navigation failure
        print("Navigation error on webView: \(webView) with error: \(error)")
        // You can add more specific error handling here
    }

    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        // Handle failure of a provisional navigation
        print("Provisional navigation error on webView: \(webView) with error: \(error)")
        // You can add more specific error handling here
    }
}

