// WebView.swift

import Foundation
import SwiftUI
import WebKit


@available(iOS 13.0, *)
public struct WebView: UIViewRepresentable {
    private let sdk: TrackPlayerSDK

    public init(sdk: TrackPlayerSDK) {
        self.sdk = sdk
    }

    public func makeUIView(context: Context) -> WKWebView {
        return sdk.webView
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {
        // Leave this empty if you don't need to update the view
    }
}
