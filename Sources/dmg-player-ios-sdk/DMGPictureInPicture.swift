// DMGPictureInPicture.swift

import SwiftUI
import WebKit

@available(iOS 13.0, *)
public struct DMGPictureLicense: UIViewRepresentable {
    @ObservedObject var sdk: DMGPlayerSDK
    
    public init(sdk: DMGPlayerSDK) {
            self.sdk = sdk
        }
    
    public func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        
        let freeloaderWebView = sdk.freeloaderWebView
        containerView.addSubview(freeloaderWebView)
        freeloaderWebView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            freeloaderWebView.topAnchor.constraint(equalTo: containerView.topAnchor),
            freeloaderWebView.widthAnchor.constraint(equalToConstant: 300),
            freeloaderWebView.heightAnchor.constraint(equalToConstant: 80),
            freeloaderWebView.centerXAnchor.constraint(equalTo: containerView.leadingAnchor)
        ])
        
        let bkWebView = sdk.bkWebView
        containerView.addSubview(bkWebView)
        bkWebView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bkWebView.topAnchor.constraint(equalTo: containerView.topAnchor),
            bkWebView.widthAnchor.constraint(equalToConstant: 300),
            bkWebView.heightAnchor.constraint(equalToConstant: 80),
            bkWebView.centerXAnchor.constraint(equalTo: containerView.leadingAnchor)
        ])
        
        let primaryWebView = sdk.primaryWebView
        containerView.addSubview(primaryWebView)
        primaryWebView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            primaryWebView.topAnchor.constraint(equalTo: containerView.topAnchor),
            primaryWebView.widthAnchor.constraint(equalToConstant: 1),
            primaryWebView.heightAnchor.constraint(equalToConstant: 1),
            primaryWebView.centerXAnchor.constraint(equalTo: containerView.leadingAnchor)
        ])

        let secondaryWebView = sdk.secondaryWebView
        containerView.addSubview(secondaryWebView)
        secondaryWebView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            secondaryWebView.topAnchor.constraint(equalTo: secondaryWebView.topAnchor),
            secondaryWebView.widthAnchor.constraint(equalToConstant: 1),
            secondaryWebView.heightAnchor.constraint(equalToConstant: 1),
            secondaryWebView.centerXAnchor.constraint(equalTo: containerView.leadingAnchor)
        ])
        
        return containerView
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {
        let queuePublisher = sdk.$queue

        queuePublisher.sink { [weak sdk] updatedQueue in
            guard let sdk = sdk else { return }
            
            if sdk.index + 1 < updatedQueue.count {
                let nextUp = updatedQueue[sdk.index + 1]
                sdk.updatedPreload(isrc: nextUp)
            } else {
                print("No next item to preload")
            }
        }
    }

    private func createBackgroundWebView() -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptEnabled = true
        let webView = WKWebView(frame: .zero, configuration: config)

        // This makes sure the webView isn't visible, even if it is technically part of the view hierarchy.
        webView.isHidden = true

        // By setting these constraints, the webView will be sized to be practically invisible
        // and positioned off the bounds of the screen.
        webView.translatesAutoresizingMaskIntoConstraints = false
        if let keyWindow = UIApplication.shared.keyWindow {
            keyWindow.addSubview(webView)

            NSLayoutConstraint.activate([
                webView.centerXAnchor.constraint(equalTo: webView.leadingAnchor)
            ])
        } else {
            // Handle the error case where the key window is not available
            print("Failed to access the key window.")
        }

        return webView
    }
}

