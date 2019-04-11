//
//  WebViewRTCDataChannel.swift
//
//  Created by Zac Duthie on 18/3/19.
//  Copyright © 2019 zcduthie. All rights reserved.
//

import WebKit

public protocol WebViewRTCDataChannelDelegate {
    func webViewRTCDataChannelDidOpen(_ dataChannel: WebViewRTCDataChannel)
    func webViewRTCDataChannelDidClose(_ dataChannel: WebViewRTCDataChannel)
    func webViewRTCDataChannel(_ dataChannel: WebViewRTCDataChannel, didError error: String)
    
    
    func webViewRTCDataChannel(_ dataChannel: WebViewRTCDataChannel, didSetLocalDescription sessionDescription: Dictionary<String, Any>)
    func webViewRTCDataChannel(_ dataChannel: WebViewRTCDataChannel, didGetIceCandidate candidate: Dictionary<String, Any>)
    
    func webViewRTCDataChannel(_ dataChannel: WebViewRTCDataChannel, didReceiveMessage message: String)
}

public struct Configuration: Codable {
    let iceServers: [IceServer]
    
    public init(iceServers: [IceServer]) {
        self.iceServers = iceServers
    }
}

public struct IceServer: Codable {
    var urls: [String]
    var username: String?
    var credential: String?
    
    public init(urls: [String], username: String, credential: String) {
        self.urls = urls
        self.username = username
        self.credential = credential
    }
    
    public init(urls: [String]) {
        self.urls = urls
    }
}

public class WebViewRTCDataChannel: NSObject {
    
    /// All of the different functions we call inside the javascript
    /// Note that setConfiguration also exists, but is called manually
    /// via WKUserScript (atDocumentEnd injection)
    private enum JavascriptFunction: String {
        case connect
        case gotSessionDescriptionFromServer
        case gotIceCandidateFromServer
        case sendMessage
        case disconnect
    }
    
    var delegate: WebViewRTCDataChannelDelegate!
    var webView: WKWebView!
    
    /// Default initializer
    ///
    /// - Parameters:
    ///   - delegate: Delegate that handles events that get triggered on the data channel
    ///   - view: An active view is required so that the WKWebView can be added to the view hierarchy.
    ///   - configuration: RTC Peer connection configuration. Contains ice servers to use.
    public init?(delegate: WebViewRTCDataChannelDelegate,
                 view: UIView,
                 configuration: Configuration) {
        super.init()
        
        self.delegate = delegate
        
        // Start building the WKWebView
        let config = WKWebViewConfiguration()
        
        // And the contentController to handle all the scripts
        let userContentController = WKUserContentController()
        
        // This is the main script that all callbacks go through
        userContentController.add(self, name: "callback")
        
        // Build the peer configuration configuration object/script
        guard let configurationJsonData = try? JSONEncoder().encode(configuration),
            let configurationJsonString = String(data: configurationJsonData, encoding: .utf8)
        else {
            debug("ERROR: Could not parse ice servers")
            return nil
        }
        let setConfigurationScriptString = "setConfiguration(\(configurationJsonString));";
        let setConfigurationScript = WKUserScript(source: setConfigurationScriptString, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        userContentController.addUserScript(setConfigurationScript)
        
        config.userContentController = userContentController
        
        // Make the webview
        webView = WKWebView(frame: .zero, configuration: config)
        
        // Need to include the webView in a real view to make operations succeed
        view.addSubview(webView)
        
        // And finally, load the html page into the WebView
        
        // Kind of hard to find the html datachannel file. Nested in a few bundles (thanks cocoapods)
        let podFrameworkBundle = Bundle(for: self.classForCoder) // WebViewRTCDataChannel.framework
        
        guard let resourceBundleUrl = podFrameworkBundle.url(forResource: "WebViewRTCDataChannel", withExtension: "bundle") else {
            debug("ERROR: Could not find resource bundle")
            return nil
        }
        
        guard let bundle = Bundle(url: resourceBundleUrl) else {
            debug("ERROR: Could not load resource bundle")
            return nil
        }
        
        guard let url = bundle.url(forResource: "datachannel", withExtension: "html") else {
            debug("ERROR: Could not find datachannel resource")
            return nil
        }
        
        // Got the html page. Load it in
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }
    
    public func connect(withDataChannelName name: String) {
        debug("connect: \(name)")
        executeJavascriptFunction(javascriptFunction: .connect,
                                  withArgumentString: "\"\(name)\"")
    }
    
    /// Call this function when we've received the session description from the remote peer
    ///
    /// - Parameter sessionDescription: The session description received from the remote peer
    public func setRemoteDescription(_ sessionDescription: Dictionary<String, Any>) {
        debug("setRemoteDescription: \(sessionDescription.jsonStringRepresentation!)")
        executeJavascriptFunction(javascriptFunction: .gotSessionDescriptionFromServer,
                                  withArgumentString: sessionDescription.jsonStringRepresentation!)
    }
    
    
    /// Call this function when we've received an ice candidate from the remote peer
    ///
    /// - Parameter candidate: The ice candidate
    public func addIceCandidate(_ candidate: Dictionary<String, Any>) {
        debug("addIceCandidate: \(candidate.jsonStringRepresentation!)")
        executeJavascriptFunction(javascriptFunction: .gotIceCandidateFromServer,
                                  withArgumentString: candidate.jsonStringRepresentation!)
    }
    
    public func sendMessage(_ message: String) {
        debug("sendMessage: \(message)")
        executeJavascriptFunction(javascriptFunction: .sendMessage,
                                  withArgumentString: message)
    }
    
    public func disconnect() {
        debug("disconnect")
        executeJavascriptFunction(javascriptFunction: .disconnect,
                                  withArgumentString: "")
    }
    
    private func executeJavascriptFunction(javascriptFunction: JavascriptFunction, withArgumentString arguments: String) {
        debug("executeJavascriptFunction: \(javascriptFunction)")
        
        let javascript = String(format: "%@(%@);", javascriptFunction.rawValue, arguments)
        
        webView.evaluateJavaScript(javascript, completionHandler: { result, error in
            if (error != nil) {
                self.debug("\(error.debugDescription)")
            } else {
                self.debug("executed JavascriptFunction: \(javascriptFunction)")
            }
        })
    }
    
    private func debug(_ message: String) {
        print("[WebViewRTCDataChannel] \(message)")
    }
}

extension WebViewRTCDataChannel: WKScriptMessageHandler {
    
    enum CallbackType: String {
        case debug
        
        case peerConnectionOnlocaldescription
        case peerConnectionOnconnectionstatechange
        case peerConnectionOnicecandidate
        case peerConnectionOniceconnectionstatechange
        case peerConnectionOnicegatheringstatechange
        case peerConnectionOnnegotiationneeded
        case peerConnectionOnsignalingstatechange
        
        case dataChannelOnclose
        case dataChannelOnerror
        case dataChannelOnmessage
        case dataChannelOnopen
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        let messageName = message.name
        
        if messageName != "callback" {
            debug("[WebViewRTCDataChannel] unknown message type: \(messageName)")
            return;
        }
        
        guard let messageBody = message.body as? String else {
            debug("[WebViewRTCDataChannel] bad message body for \(messageName)")
            return;
        }
        
        guard let jsonDictionary = messageBody.jsonDictionary else {
            debug("[WebViewRTCDataChannel] bad json for \(messageName)")
            return;
        }
        
        guard let callbackMessage = jsonDictionary["message"] else {
            debug("[WebViewRTCDataChannel] bad message for \(messageName)")
            return;
        }
        
        guard let callbackTypeString = jsonDictionary["type"] as? String else {
            debug("[WebViewRTCDataChannel] bad type for \(messageName)")
            return;
        }
        guard let callbackType = CallbackType(rawValue: callbackTypeString) else {
            debug("[WebViewRTCDataChannel] unknown type for \(messageName)")
            return;
        }
        
        handleCallback(type: callbackType, message: callbackMessage)
    }
    
    private func handleCallback(type: CallbackType, message: Any) {
        switch type {
        // DEBUG
        case .debug:
            debug("[HTML] \(message as! String)")
            break
        // PEER CONNECTION
        case .peerConnectionOnlocaldescription:
            delegate.webViewRTCDataChannel(self, didSetLocalDescription: message as! Dictionary)
            break
        case .peerConnectionOnicecandidate:
            delegate.webViewRTCDataChannel(self, didGetIceCandidate: message as! Dictionary)
            break
        case .peerConnectionOnconnectionstatechange:
            debug("Connection state change: \(message as! String)")
            break
        case .peerConnectionOniceconnectionstatechange,
             .peerConnectionOnicegatheringstatechange,
             .peerConnectionOnsignalingstatechange:
            debug("\(type) | \(message as! String)")
            break
        // DATA CHANNEL
        case .dataChannelOnmessage:
            debug("DataChannel message: \(message as! String)")
            delegate.webViewRTCDataChannel(self, didReceiveMessage: message as! String)
            break
        case .dataChannelOnopen:
            delegate.webViewRTCDataChannelDidOpen(self)
            break
        case .dataChannelOnclose:
            delegate.webViewRTCDataChannelDidClose(self)
            break
        case .dataChannelOnerror:
            delegate.webViewRTCDataChannel(self, didError: message as! String)
            break
        default:
            debug("No handler for \(type) | \(message)")
        }
    }
}

extension String {
    var jsonDictionary: Dictionary<String, Any>? {
        guard let jsonData = self.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: jsonData, options: []) as! Dictionary<String,Any>
    }
    var jsonArray: Array<Any>? {
        guard let jsonData = self.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: jsonData, options: []) as! Array<Any>
    }
}

extension Dictionary {
    var jsonStringRepresentation: String? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: self, options: []) else { return nil }
        return String(data: jsonData, encoding: .utf8)
    }
}
