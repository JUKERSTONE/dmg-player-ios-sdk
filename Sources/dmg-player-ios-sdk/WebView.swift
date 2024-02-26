// WebView.swift

import Foundation
import SwiftUI
import WebKit

@available(iOS 13.0, *)
public struct WebView: UIViewRepresentable {
    let isrc: String
    let sdk: TrackPlayerSDK

    public func makeUIView(context: Context) -> WKWebView {
        return sdk.webView
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {
        // Here you would load the content based on the isrc passed to the WebView
        // For example, you might tell the sdk to load the video based on the isrc
        sdk.playNow(isrc: isrc)
    }
}


// WebViewContainer.swift
@available(iOS 13.0, *)
public struct WebViewContainer: View {
    @ObservedObject var trackPlayerSDK: TrackPlayerSDK
    let numberOfWebViews: Int

    public var body: some View {
        VStack {
            ForEach(0..<numberOfWebViews, id: \.self) { index in
                if index == 0 {
                    // First WebView shows the nowPlaying
                    if let nowPlaying = trackPlayerSDK.nowPlaying {
                        WebView(isrc: nowPlaying, sdk: trackPlayerSDK)
                    }
                } else {
                    // Other WebViews show the queued items
                    let queueIndex = index - 1
                    if queueIndex < trackPlayerSDK.queue.count {
                        WebView(isrc: trackPlayerSDK.queue[queueIndex], sdk: trackPlayerSDK)
                    }
                }
            }
        }
    }
}

