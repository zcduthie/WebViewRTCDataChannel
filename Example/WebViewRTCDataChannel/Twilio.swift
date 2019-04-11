//
//  DeadSimpleSignallingChannel.swift
//  RTCDataChannel-iOS-Demo
//
//  Created by Zac Duthie on 16/3/19.
//  Copyright © 2019 zcduthie. All rights reserved.
//

import Foundation
import WebViewRTCDataChannel

class Twilio {
    static let TWILIO_ACCOUNT_SID = "YOUR_ACCOUNT_SID"
    static let TWILIO_AUTH_TOKEN = "YOUR_AUTH_TOKEN"
    
    public static func fetchNTSToken(with completionHandler: @escaping ([IceServer]) -> Void) {
        // Create the request
        let url = URL(string: "https://api.twilio.com/2010-04-01/Accounts/\(TWILIO_ACCOUNT_SID)/Tokens.json")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // And the session config for it
        let config = URLSessionConfiguration.default
        
        let username = TWILIO_ACCOUNT_SID,
        password = TWILIO_AUTH_TOKEN,
        loginString = String(format: "%@:%@", username, password),
        loginData = loginString.data(using: String.Encoding.utf8)!,
        base64LoginString = loginData.base64EncodedString(),
        basicAuthString = "Basic \(base64LoginString)"
        config.httpAdditionalHeaders = ["Authorization" : basicAuthString]
        
        let session = URLSession(configuration: config)
        
        let task = session.dataTask(with: request) { (data, response, error) in
            
            guard let response = response as? HTTPURLResponse,
                let data = data,
                error == nil else {
                    print(error ?? "Unknown http request error")
                    return
            }
            
            guard (200 ... 299) ~= response.statusCode else {
                print("Ice server statusCode should be 2xx, but is \(response.statusCode)")
                print("response=\(response)")
                return
            }
            
            guard let twilioResponse = try? JSONDecoder().decode(TwilioResponse.self, from: data) else {
                print("Invalid ice response")
                return
            }
            
            var repackagedIceServers = [IceServer]()
            
            for twilioIceServer in twilioResponse.ice_servers {
                let iceServer: IceServer
                if twilioIceServer.username != nil &&
                    twilioIceServer.credential != nil {
                    iceServer = IceServer(urls: [twilioIceServer.url], username: twilioIceServer.username!, credential: twilioIceServer.credential!)
                } else {
                    iceServer = IceServer(urls: [twilioIceServer.url])
                }
                repackagedIceServers.append(iceServer)
            }
            
            completionHandler(repackagedIceServers)
        }
        
        task.resume()
    }
    
}
