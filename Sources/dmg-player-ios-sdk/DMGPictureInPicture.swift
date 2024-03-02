import SwiftUI
import WebKit

@available(iOS 13.0, *)
public struct DMGPictureLicense: UIViewRepresentable {
    @ObservedObject var sdk: DMGPlayerSDK

    public init(sdk: DMGPlayerSDK) {
        self.sdk = sdk
    }

    public func makeUIView(context: Context) -> UIView {
        let containerView = UIView(frame: CGRect.zero) // Use CGRect.zero to keep it off-screen
        
        // Configure primary WebView
        let primaryWebView = sdk.primaryWebView
        primaryWebView.translatesAutoresizingMaskIntoConstraints = false
        primaryWebView.isHidden = true // WebView is hidden but active
        UIApplication.shared.keyWindow?.addSubview(primaryWebView) // Add to keyWindow to ensure it is 'active'

        // Configure secondary WebView
        let secondaryWebView = sdk.secondaryWebView
        secondaryWebView.translatesAutoresizingMaskIntoConstraints = false
        secondaryWebView.isHidden = true // WebView is hidden but active
        UIApplication.shared.keyWindow?.addSubview(secondaryWebView) // Add to keyWindow to ensure it is 'active'
        
        return containerView
    }

    public func updateUIView(_ uiView: UIView, context: Context) {
        // Logic remains the same
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
}
