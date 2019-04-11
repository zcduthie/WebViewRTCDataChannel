//
//  DeadSimpleSignallingChannel.swift
//  RTCDataChannel-iOS-Demo
//
//  Created by Zac Duthie on 16/3/19.
//  Copyright © 2019 zcduthie. All rights reserved.
//

import Foundation
import Starscream

protocol DeadSimpleSignallingChannelDelegate {
    func signallingChannelDidOpen(_ channel: DeadSimpleSignallingChannel)
    func signallingChannelDidClose(_ channel: DeadSimpleSignallingChannel)
    
    func signallingChannel(_ channel: DeadSimpleSignallingChannel, didReceiveSessionDescription description: Dictionary<String, Any>)
    func signallingChannel(_ channel: DeadSimpleSignallingChannel, didReceiveIceCandidate candidate: Dictionary<String, Any>)
}

class DeadSimpleSignallingChannel {
    let delegate: DeadSimpleSignallingChannelDelegate
    let uuid: String
    let socket: WebSocket
    
    public init(url: URL, delegate: DeadSimpleSignallingChannelDelegate) {
        self.delegate = delegate
        self.uuid = UUID().uuidString
        self.socket = WebSocket(url: url)
        self.socket.delegate = self
        
        debug(message: "init \(self.uuid)")
    }
    
    public func start() {
        self.socket.connect()
    }
    
    public func stop() {
        self.socket.disconnect()
    }
    
    public func sendSessionDescription(sdp: Any) {
        send(signal: ["uuid": self.uuid,
                      "sdp": sdp])
    }
    
    public func sendIce(ice: Any) {
        send(signal: ["uuid": self.uuid,
                      "ice": ice])
    }
    
    private func send(signal: Any) {
        let jsonData = try! JSONSerialization.data(withJSONObject: signal, options: [])
        let jsonString = String(data: jsonData, encoding: .utf8)!
        self.socket.write(string: jsonString)
    }
    
    private func debug(message: String) {
        print("[DSSS] \(message)");
    }
    
}

extension DeadSimpleSignallingChannel: WebSocketDelegate {
    func websocketDidConnect(socket: WebSocketClient) {
        debug(message: "websocketDidConnect")
        delegate.signallingChannelDidOpen(self)
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        debug(message: "websocketDidDisconnect")
        delegate.signallingChannelDidClose(self)
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        let textData = text.data(using: .utf8)!
        do {
            if let signal = try JSONSerialization.jsonObject(with: textData, options: []) as? Dictionary<String,Any> {
                if (signal["uuid"] as! String == self.uuid) {
                    // our own message...
                    return
                }
                
                debug(message: "websocketDidReceiveMessage: \(text)")
                
                if (signal["sdp"] != nil) {
                    debug(message: "received sdp: \(signal["sdp"]!)")
                    delegate.signallingChannel(self, didReceiveSessionDescription: signal["sdp"] as! Dictionary<String, Any>)
                } else if (signal["ice"] != nil) {
                    debug(message: "received ice: \(signal["ice"]!)")
                    delegate.signallingChannel(self, didReceiveIceCandidate: signal["ice"] as! Dictionary<String, Any>)
                }
            } else {
                print("bad json")
            }
        } catch { print(error); }
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        debug(message: "websocketDidReceiveData: \(data.count)")
    }
    
    
}
