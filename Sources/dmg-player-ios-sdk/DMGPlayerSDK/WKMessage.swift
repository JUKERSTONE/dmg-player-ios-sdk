// WKMessage.swift

import Foundation
import WebKit

@available(iOS 13.0, *)
extension DMGPlayerSDK {

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "player" {
            guard let messageString = message.body as? String else {
                print("The message body is not a string.")
                return
            }

            guard let jsonData = messageString.data(using: .utf8) else {
                print("Could not convert message string to Data.")
                return
            }

            guard let messageDict = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
                print("Failed to deserialize JSON string into a dictionary.")
                return
            }

            guard let eventType = messageDict["eventType"] as? String else {
                print("The 'eventType' is not a string or not present in the message body.")
                return
            }

            switch eventType {
            case "videoProgress":
                if let progressData = messageDict["data"] as? Double {
                    if progressData > 80.0 && queue.count <= 1 && !self.hasPreloadedNextWebview {
                        self.preloadNextWebView()
                        self.hasPreloadedNextWebview = true
                    }
                } else {
                    print("The 'data' for 'videoProgress' is not a Double or not present in the message body.")
                }
            case "enablePiP":
                if let data = messageDict["data"] as? Double {
                    print("data")
                } else {
                    print("Error PiP")
                }
            case "videoEnded":
                print("start")
                if self.hasPreloadedNextWebview {
                    if self.isPrimaryActive == true {
                        print("why11o")
                        self.isPrimaryActive = false
                        self.hasPreloadedNextWebview = false
                        print("why1o")
                        self.play(webView: self.secondaryWebView)
                    } else if self.isPrimaryActive == false {
                        print("why22o")
                        self.isPrimaryActive = true
                        self.hasPreloadedNextWebview = false
                        print("why2o")
                        self.play(webView: self.secondaryWebView)
                    }
                } else {
                    if self.isPrimaryActive == true {
                        print("why33o")
                        self.isPrimaryActive = false
                        print("why3o")
                        self.play(webView: self.secondaryWebView)
                    } else if self.isPrimaryActive == false {
                        print("why44o")
                        self.isPrimaryActive = true
                        print("why4o")
                        self.play(webView: self.secondaryWebView)
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
