import SwiftUI
import WebKit


// TrackPlayerSDK.swift
public class TrackPlayerSDK: NSObject {
    public var webView: WKWebView
    private var queue: [Track] = []
    
    public override init() {
        let config = WKWebViewConfiguration()
        self.webView = WKWebView(frame: .zero, configuration: config)
        super.init()
        self.webView.navigationDelegate = self
    }
    
    public func playNow(isrc: String) {
        let apiService = APIService.shared
        let urlString = "https://europe-west1-trx-traklist.cloudfunctions.net/TRX_DEVELOPER/trx/music/\(isrc)"
            
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        apiService.fetchData(from: url) { result in
                switch result {
                case .success(let data):
                    // Handle successful data retrieval
                    do {
                           // Decode the data into your structured model
                           let responseData = try JSONDecoder().decode(ResponseData.self, from: data)
                           let url = responseData.trak.youtube
                            self.webView.load(URLRequest(url: url))
                           } catch {
                               // Handle decoding error
                               print("Error decoding data: \(error)")
                           }
                case .failure(let error):
                    // Handle error
                    print("Error fetching data: \(error)")
                }
            }
        
        
    }
    
    public func queueNext(track: Track) {
        queue.insert(track, at: 0)
    }
    
    public func queue(track: Track) {
        queue.append(track)
    }
    
//    public func removeFromQueue(track: Track) {
//        webView.load(URLRequest(url: track.url))
//    }
}

// Make sure to conform to WKNavigationDelegate if needed.
extension TrackPlayerSDK: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Inject JavaScript here after page load
        let jsCode = """
        if (!window.trakStarVideo) {
                window.trakStarVideo = document.getElementsByTagName('video')[0];
              }
              
              if (window.trakStarVideo) {
                window.trakStarVideo.requestPictureInPicture().then(() => {
                  const message = {
                    eventType: 'enablePiP',
                    data: 'PiP initiated successfully.'
                  };
                  window.ReactNativeWebView.postMessage(JSON.stringify(message));
                }).catch(error => {
                  const message = {
                    eventType: 'enablePiP',
                    data: 'PiP initiation failed: ' + error.message
                  };
                  window.ReactNativeWebView.postMessage(JSON.stringify(message));
                });
              } else {
                const message = {
                  eventType: 'enablePiP',
                  data: 'No video element found.'
                };
                window.ReactNativeWebView.postMessage(JSON.stringify(message));
              }
              true;
        """
        webView.evaluateJavaScript(jsCode, completionHandler: nil)
    }
    
    // Implement other WKNavigationDelegate methods as needed
}


struct ResponseData: Decodable {
    let trak: TrakData
}

struct TrakData: Decodable {
    let youtube: URL
}
