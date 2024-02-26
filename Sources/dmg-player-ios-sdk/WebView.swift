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

// WebViewContainer.swift
@available(iOS 13.0, *)
struct WebViewContainer: View {
    @ObservedObject var trackPlayerSDK: TrackPlayerSDK
    let numberOfWebViews: Int

    var body: some View {
        VStack {
            ForEach(0..<numberOfWebViews, id: \.self) { index in
                Group { // Wrap the conditional content in a Group to ensure a View is always returned
                    if index == 0 {
                        // First WebView shows the nowPlaying
                        WebView(sdk: trackPlayerSDK) // Assuming this is the correct initializer usage
                    } else {
                        // Other WebViews show the queued items
                        let queueIndex = index - 1
                        if queueIndex < trackPlayerSDK.queue.count {
                            WebView(sdk: trackPlayerSDK) // Assuming this is the correct initializer usage
                        }
                    }
                }
            }
        }
        .onReceive(trackPlayerSDK.$nowPlaying) { _ in
            // Handle nowPlaying update if needed
        }
        .onReceive(trackPlayerSDK.$queue) { _ in
            // Handle queue update if needed
        }
    }
}

