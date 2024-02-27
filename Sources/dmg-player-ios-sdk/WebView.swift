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
    
    public init(trackPlayerSDK: TrackPlayerSDK, numberOfWebViews: Int) {
        self.trackPlayerSDK = trackPlayerSDK
        self.numberOfWebViews = numberOfWebViews
    }

    // While the struct is public, the initializer is internal by default.
    // SwiftUI views benefit from memberwise initializers created automatically,
    // which are internal. You don't usually need to define a public initializer.
    
    public var body: some View {
        VStack {
            ForEach(0..<numberOfWebViews, id: \.self) { index in
                if index == 0 {
                    // First WebView shows the nowPlaying
                    if let nowPlaying = trackPlayerSDK.nowPlaying {
                        WebView(isrc: nowPlaying, sdk: trackPlayerSDK).frame(width: 200, height: 60)
                    }
                } else {
                    // Other WebViews show the queued items
                    let queueIndex = index - 1
                    if queueIndex < trackPlayerSDK.queue.count {
                        WebView(isrc: trackPlayerSDK.queue[queueIndex], sdk: trackPlayerSDK).frame(width: 200, height: 60)
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
