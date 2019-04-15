# WebViewRTCDataChannel

A simple working iOS RTCDataChannel built using WKWebView.

Rather than include the external native WebRTC iOS framework at [https://webrtc.org/native-code/ios](https://webrtc.org/native-code/ios/), this library leverages WebKit's inbuilt WebRTC functionality and exposes WebRTC functionality through the WKWebView control.

[![CI Status](https://img.shields.io/travis/zcduthie/WebViewRTCDataChannel.svg?style=flat)](https://travis-ci.org/zcduthie/WebViewRTCDataChannel)
[![Version](https://img.shields.io/cocoapods/v/WebViewRTCDataChannel.svg?style=flat)](https://cocoapods.org/pods/WebViewRTCDataChannel)
[![License](https://img.shields.io/cocoapods/l/WebViewRTCDataChannel.svg?style=flat)](https://cocoapods.org/pods/WebViewRTCDataChannel)
[![Platform](https://img.shields.io/cocoapods/p/WebViewRTCDataChannel.svg?style=flat)](https://cocoapods.org/pods/WebViewRTCDataChannel)

## Example

The example included for this project is built as an end point to the 'as simple as it gets' [WebRTC-Example-DataChannel](https://github.com/zcduthie/WebRTC-Example-RTCDataChannel) project.

The [WebRTC-Example-DataChannel](https://github.com/zcduthie/WebRTC-Example-RTCDataChannel) project contains both a signaling server, and sample clients that can run and communicate through the server.

The example included in this project acts as one of the clients. Follow the instructions given in the [WebRTC-Example-DataChannel](https://github.com/zcduthie/WebRTC-Example-RTCDataChannel) project to start a copy of the server and open one client, and then use this project's included example as the other client. You'll need to update the following line in ViewController.swift:
```swift
let WEBSOCKET_SERVER = "wss://10.0.0.30:8443"
```

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

WebViewRTCDataChannel is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'WebViewRTCDataChannel'
```

## Usage

To create a data channel, first you'll need to fetch and provide ice servers that include TURN servers.
```swift
// Fetch Ice Servers
// Use Twilio helper (provided for convenience), or provide yourself
Twilio.fetchNTSToken { (iceServers) in
    DispatchQueue.main.async { // data channel must be created on main thread
        createWebViewRTCDataChannel(withConfiguration: Configuration(iceServers: iceServers))
    }
}

// Create an instance of the data channel
private func createWebViewRTCDataChannel(withConfiguration configuration: Configuration) {
    var webViewRTCDataChannel = WebViewRTCDataChannel(delegate: self,
                                                    view: view,
                                                    configuration: configuration)
}


```

Once it's created, you can listen for messages received through the data channel.
```swift
// Listen for data channel events
extension ViewController: WebViewRTCDataChannelDelegate {

    func webViewRTCDataChannelDidOpen(_ dataChannel: WebViewRTCDataChannel) {
        print("webViewRTCDataChannelDidOpen")
    }

    func webViewRTCDataChannelDidClose(_ dataChannel: WebViewRTCDataChannel) {
        print("webViewRTCDataChannelDidClose")
    }

    func webViewRTCDataChannel(_ dataChannel: WebViewRTCDataChannel, didError error: String) {
        print("webViewRTCDataChannel didError: \(error)")
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
```

## iOS WebRTC Support Summary
(Relevant as of March 2019)

WebKit announced support for WebRTC from iOS 11.<br>

Both WKWebView and Safari are built on top of WebKit, however their WebRTC support differs as follows:

### **Safari**

Since iOS11, **Safari App Browser now fully supports WebRTC**.

The caveat to this is that by default Safari does not expose 'Host' ICE Candidates for security reasons. This means that WebRTC likely won't be able to establish a connection over STUN - and will require a TURN server.

You can get around this by:
- Manually disabling the Ice Candidate Restrictions in Developer Settings in Safari Browser (you can do this on both desktop and mobile)
- Calling getUserMedia()!!! Safari have implemented their security restrictions such that the 'Host' ICE Candidates are disabled *until* you accept Camera/Microphone permissions via getUserMedia(). As such, many people do something like the following (and prompt the user to accept):
```javascript
// (taken from WebRTC Samples GitHub)
if (adapter.browserDetails.browser === 'safari') {
    try {
        console.log('Call getUserMedia() to trigger media permission request.');
        const stream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': true});
        stream.getTracks().forEach(t=> t.stop());
    } catch (e) {
        console.error('Error requesting permission: ', e);
        return;
    }
}
```

### **WKWebView**

WebRTC has three main Javascript components:
- MediaStream (aka getUserMedia)
- RTCPeerConnection
- RTCDataChannel

Fortunately for us, **WKWebView supports both RTCPeerConnection and RTCDataChannel**. And that's all we need for an RTCDataChannel.

Unfortunately for us, due to security reasons **WKWebView does not yet support MediaStream**. This appears to still be true as of iOS 12. As described in the Safari section above, this is not good news for us, because it means that we can't discover 'Host' ICE Candidates. This leaves us requiring TURN (unless srflx - Server Reflexive candidates work on your network).

<br>

tldr; WebRTC is **fully supported in Safari**, and **partially supported in WKWebView** (RTCDataChannel works via TURN)

## Roadmap

As it currently stands, the project exposes a basic implementation of a WebRTC DataChannel through a WKWebView. Whilst the aim of the library is to be very basic, there are numerous improvements that can be made. Some of which include:
- Add convenient method for enabling / disabling logging
- Update example to contain it's own README.md with better instructions
- Update example to use a GUI that matches the Web GUI included in [WebRTC-Example-DataChannel](https://github.com/zcduthie/WebRTC-Example-RTCDataChannel)

## License

WebViewRTCDataChannel is available under the MIT license. See the LICENSE file for more info.

