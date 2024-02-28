// DMGPlayerSDK+MessageHandling.swift

import Foundation
import WebKit

// MARK: - WKScriptMessageHandler
@available(iOS 13.0, *)
extension DMGPlayerSDK {

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "player" {
            // Attempt to convert the message body directly into a String
            guard let messageString = message.body as? String else {
                print("The message body is not a string.")
                return
            }

            // Attempt to convert the string to Data
            guard let jsonData = messageString.data(using: .utf8) else {
                print("Could not convert message string to Data.")
                return
            }

            // Attempt to deserialize the JSON string into a dictionary
            guard let messageDict = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
                print("Failed to deserialize JSON string into a dictionary.")
                return
            }

            // Now we can safely check for the eventType
            guard let eventType = messageDict["eventType"] as? String else {
                print("The 'eventType' is not a string or not present in the message body.")
                return
            }

            // Handle known events
            switch eventType {
            case "videoProgress":
                // Check if the progress data is a Double
                if let progressData = messageDict["data"] as? Double {
                    // Process the progress data
                    if progressData > 80.0 && !self.hasPreloadedNextWebview {
                        self.preloadNextWebView() // Call your preload function here
                        self.hasPreloadedNextWebview = true // Set the flag to true after preloading
                    }
                } else {
                    print("The 'data' for 'videoProgress' is not a Double or not present in the message body.")
                }
            case "videoEnded":
                if self.isPrimaryActive == true && self.hasPreloadedNextWebview {
                    primaryWebView.loadHTMLString("<html><html>", baseURL: nil)
                    isPrimaryActive = false
                    hasPreloadedNextWebview = false
                    
                    self.play(webView: self.secondaryWebView)
                    
                    if !self.queue.isEmpty {
                        self.queue.removeFirst()
                    }
                } else if self.isPrimaryActive == false && self.hasPreloadedNextWebview {
                    secondaryWebView.loadHTMLString("<html><html>", baseURL: nil)
                    isPrimaryActive = true
                    hasPreloadedNextWebview = false
                    
                    self.play(webView: self.primaryWebView)
                    
                    if !self.queue.isEmpty {
                        self.queue.removeFirst()
                    }
                }
                
               
            default:
                print("Unknown event type received: \(eventType)")
            }
        } else {
            print("Received a message from an unexpected handler: \(message.name)")
        }
    }
    
}
