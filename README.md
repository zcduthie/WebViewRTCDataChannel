# WebViewRTCDataChannel

A simple working iOS RTCDataChannel built using WKWebView.

Rather than include the external native WebRTC iOS framework at [https://webrtc.org/native-code/ios](https://webrtc.org/native-code/ios/), this library leverages WebKit's inbuilt WebRTC functionality and exposes WebRTC functionality through the WKWebView control.

[![CI Status](https://img.shields.io/travis/zcduthie/WebViewRTCDataChannel.svg?style=flat)](https://travis-ci.org/zcduthie/WebViewRTCDataChannel)
[![Version](https://img.shields.io/cocoapods/v/WebViewRTCDataChannel.svg?style=flat)](https://cocoapods.org/pods/WebViewRTCDataChannel)
[![License](https://img.shields.io/cocoapods/l/WebViewRTCDataChannel.svg?style=flat)](https://cocoapods.org/pods/WebViewRTCDataChannel)
[![Platform](https://img.shields.io/cocoapods/p/WebViewRTCDataChannel.svg?style=flat)](https://cocoapods.org/pods/WebViewRTCDataChannel)

## Example

The example included for this project is built as an end point to the 'as simple as it gets' [WebRTC-Example-DataChannel](https://github.com/zcduthie/WebRTC-Example-RTCDataChannel) project.

The WebRTC-Example-DataChannel project contains both a signaling server, and sample clients that can run and communicate through the server.

The example included in this project acts as one of the clients. Follow the instructions given in that project to start a copy of the server and open one client, and then use this example project as the other client.  

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

WebViewRTCDataChannel is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'WebViewRTCDataChannel'
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

## License

WebViewRTCDataChannel is available under the MIT license. See the LICENSE file for more info.

