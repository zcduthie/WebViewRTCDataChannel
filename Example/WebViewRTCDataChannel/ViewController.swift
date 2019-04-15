//
//  ViewController.swift
//  WebViewRTCDataChannel
//
//  Created by zcduthie on 03/30/2019.
//  Copyright (c) 2019 zcduthie. All rights reserved.
//

import UIKit
import WebViewRTCDataChannel

public struct TwilioResponse: Codable {
    // (Some other parameters...)
    // And...
    let ice_servers: [TwilioIceServer]
}

public struct TwilioIceServer: Codable {
    let url: String
    let username: String?
    let credential: String?
}

class ViewController: UIViewController {
    
    let WEBSOCKET_SERVER = "wss://10.0.0.30:8443"
    
    var signallingChannel: DeadSimpleSignallingChannel!
    var webViewRTCDataChannel: WebViewRTCDataChannel!
    
    // Timer used to send some debug messages
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchIceServers()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func fetchIceServers() {
        Twilio.fetchNTSToken { (iceServers) in
            DispatchQueue.main.async {
                self.createWebViewRTCDataChannel(withConfiguration: Configuration(iceServers: iceServers))
            }
        }
    }
    
    private func createWebViewRTCDataChannel(withConfiguration configuration: Configuration) {
        signallingChannel = DeadSimpleSignallingChannel(url: URL(string: WEBSOCKET_SERVER)!, delegate: self)
        signallingChannel.start()
        
        webViewRTCDataChannel = WebViewRTCDataChannel(delegate: self,
                                                      view: view,
                                                      configuration: configuration)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { // Change `2.0` to the desired number of seconds.
            // Code you want to be delayed
            self.webViewRTCDataChannel.connect(withDataChannelName: "test123")
        }
    }
    
    private func getConfiguration() -> Dictionary<String, Any> {
        
        return ["iceServers": [[
            "urls": [ "stun:ms-m2.xirsys.com" ]
            ], [
                "username": "Hhnn3UEtrJfvYQ-X5X50B746gXUAZoP75qm9u8MTwObJcZLnfECPcbOIkvrXFI2GAAAAAFye_z56Y2R1dGhpZWhvdA==",
                "credential": "19bbc41c-52ad-11e9-a0b1-069d28f6feae",
                "urls": [
                    "turn:ms-m2.xirsys.com:80?transport=udp",
                    "turn:ms-m2.xirsys.com:3478?transport=udp",
                    "turn:ms-m2.xirsys.com:80?transport=tcp",
                    "turn:ms-m2.xirsys.com:3478?transport=tcp",
                    "turns:ms-m2.xirsys.com:443?transport=tcp",
                    "turns:ms-m2.xirsys.com:5349?transport=tcp"
                ]
            ]]
        ]
    }
    
}

extension ViewController: DeadSimpleSignallingChannelDelegate {
    
    func signallingChannelDidOpen(_ channel: DeadSimpleSignallingChannel) {
        print("signallingChannelDidOpen")
    }
    
    func signallingChannelDidClose(_ channel: DeadSimpleSignallingChannel) {
        print("signallingChannelDidClose")
    }
    
    func signallingChannel(_ channel: DeadSimpleSignallingChannel, didReceiveSessionDescription description: Dictionary<String, Any>) {
        print("signallingChannel_didReceiveSessionDescription: \(description)")
        
        webViewRTCDataChannel.setRemoteDescription(description)
    }
    
    func signallingChannel(_ channel: DeadSimpleSignallingChannel, didReceiveIceCandidate candidate:  Dictionary<String, Any>) {
        print("signallingChannel_didReceiveIceCandidate: \(candidate)")
        
        webViewRTCDataChannel.addIceCandidate(candidate)
    }
    
}

extension ViewController: WebViewRTCDataChannelDelegate {
    
    static var counter: Int = 0
    
    func webViewRTCDataChannelDidOpen(_ dataChannel: WebViewRTCDataChannel) {
        print("webViewRTCDataChannelDidOpen")
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { (timer) in
            self.webViewRTCDataChannel.sendMessage("\(ViewController.counter)")
            ViewController.counter += 1
            if (ViewController.counter > 60) {
                timer.invalidate()
                self.webViewRTCDataChannel.disconnect()
            }
        }
    }
    
    func webViewRTCDataChannelDidClose(_ dataChannel: WebViewRTCDataChannel) {
        print("webViewRTCDataChannelDidClose")
        timer?.invalidate()
    }
    
    func webViewRTCDataChannel(_ dataChannel: WebViewRTCDataChannel, didError error: String) {
        print("webViewRTCDataChannel didError: \(error)")
        timer?.invalidate()
    }
    
    func webViewRTCDataChannel(_ dataChannel: WebViewRTCDataChannel, didSetLocalDescription sessionDescription: Dictionary<String, Any>) {
        signallingChannel.sendSessionDescription(sdp: sessionDescription)
    }
    
    func webViewRTCDataChannel(_ dataChannel: WebViewRTCDataChannel, didGetIceCandidate candidate: Dictionary<String, Any>) {
        signallingChannel.sendIce(ice: candidate)
    }
    
    func webViewRTCDataChannel(_ dataChannel: WebViewRTCDataChannel, didReceiveMessage message: String) {
        print(message)
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
