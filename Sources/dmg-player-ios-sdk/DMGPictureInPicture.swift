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
        
        
//        if let keyWindow = UIApplication.shared.windows.filter({$0.isKeyWindow}).first {
//            let webViewConfig = WKWebViewConfiguration()
//            // Configure your WKWebView as needed
//            let webView = WKWebView(frame: CGRect.zero, configuration: webViewConfig)
//            keyWindow.addSubview(webView)
//            // Now you can load a request or perform other operations on the webView
//        }
        
        let bkPrimaryWebView = createBackgroundWebView()
        containerView.addSubview(bkPrimaryWebView)
        sdk.bkPrimaryWebView = bkPrimaryWebView
                
                // Adding bkSecondaryWebView to the key window
        let bkSecondaryWebView = createBackgroundWebView()
        containerView.addSubview(bkSecondaryWebView)
        sdk.bkSecondaryWebView = bkSecondaryWebView
        
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
            guard let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else {
                fatalError("No key window")
            }
            
            let webViewConfig = WKWebViewConfiguration()
            // Configure your WKWebView as needed
            
            let webView = WKWebView(frame: CGRect.zero, configuration: webViewConfig)
            webView.translatesAutoresizingMaskIntoConstraints = false
            webView.isHidden = true  // Keep the web view hidden
            
            keyWindow.addSubview(webView)
            
            NSLayoutConstraint.activate([
                webView.topAnchor.constraint(equalTo: keyWindow.topAnchor),
                webView.leadingAnchor.constraint(equalTo: keyWindow.leadingAnchor),
                webView.widthAnchor.constraint(equalToConstant: 1),
                webView.heightAnchor.constraint(equalToConstant: 1),
            ])
            
            return webView
        }

}

