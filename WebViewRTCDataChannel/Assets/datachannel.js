/************************************************************************
 * SCRIPT - CALLBACK INFO
 ************************************************************************/

var Callbacks = {
    DEBUG   : "debug",
    
    PEER_CONNECTION_ONLOCALDESCRIPTION          : "peerConnectionOnlocaldescription",
    PEER_CONNECTION_ONCONNECTIONSTATECHANGE     : "peerConnectionOnconnectionstatechange",
    PEER_CONNECTION_ONICECANDIDATE              : "peerConnectionOnicecandidate",
    PEER_CONNECTION_ONICECONNECTIONSTATECHANGE  : "peerConnectionOniceconnectionstatechange",
    PEER_CONNECTION_ONICEGATHERINGSTATECHANGE   : "peerConnectionOnicegatheringstatechange",
    PEER_CONNECTION_ONNEGOTIATIONNEEDED         : "peerConnectionOnnegotiationneeded",
    PEER_CONNECTION_ONSIGNALINGSTATECHANGE      : "peerConnectionOnsignalingstatechange",
    
    DATA_CHANNEL_ONCLOSE    : "dataChannelOnclose",
    DATA_CHANNEL_ONERROR    : "dataChannelOnerror",
    DATA_CHANNEL_ONMESSAGE  : "dataChannelOnmessage",
    DATA_CHANNEL_ONOPEN     : "dataChannelOnopen"
}

function sendCallback(type, message) {
    var callbackData = {
        type    : type,
        message : message
    };
    window.webkit.messageHandlers.callback.postMessage(JSON.stringify(callbackData));
}

function debug(message) {
    sendCallback(Callbacks.DEBUG, message);
}

/************************************************************************
 * RTC + DATACHANNEL IMPLEMENTATION
 ************************************************************************/

// RTC Variables!!
var peerConnection = null; // RTCPeerConnection
var dataChannel = null; // RTCDataChannel

// Default config. Ideally gets overridden by swift via script call
var peerConnectionConfig = {
    'iceServers': [
                   { 'urls': 'stun:stun.stunprotocol.org:3478' },
                   { 'urls': 'stun:stun.l.google.com:19302' },
                   ]
};

debug('config: ' + JSON.stringify(peerConnectionConfig));

// Functions

// Start the WebRTC Connection
// We're either the caller
// Or the receiver
function start(isCaller, dataChannelName) {
    debug('start: ' + isCaller);
    debug('config: ' + JSON.stringify(peerConnectionConfig));
    peerConnection = new RTCPeerConnection(peerConnectionConfig);
    peerConnection.onicecandidate = gotIceCandidate;
    peerConnection.onconnectionstatechange =    (event => sendCallback(Callbacks.PEER_CONNECTION_ONCONNECTIONSTATECHANGE, peerConnection.connectionState));
    peerConnection.oniceconnectionstatechange = (event => sendCallback(Callbacks.PEER_CONNECTION_ONICECONNECTIONSTATECHANGE, peerConnection.iceConnectionState));
    peerConnection.onicegatheringstatechange =  (event => sendCallback(Callbacks.PEER_CONNECTION_ONICEGATHERINGSTATECHANGE, peerConnection.iceGatheringState));
    
    peerConnection.onnegotiationneeded =        (event => sendCallback(Callbacks.DEBUG, 'onnegotiationneeded'));
    peerConnection.onnsignalingstatechange =    (event => sendCallback(Callbacks.PEER_CONNECTION_ONSIGNALINGSTATECHANGE, peerConnection.signalingState));
    
    debug('peerConnectionState: ' + peerConnection.connectionState);
    
    // If we're the caller, we create the Data Channel
    // Otherwise, it opens for us and we receive an event as soon as the peerConnection opens
    if (isCaller) {
        dataChannel = peerConnection.createDataChannel(dataChannelName);
        dataChannel.onmessage = (event => sendCallback(Callbacks.DATA_CHANNEL_ONMESSAGE, event.data));
        dataChannel.onopen =    (event => sendCallback(Callbacks.DATA_CHANNEL_ONOPEN, dataChannel ? dataChannel.readyState : "dead"));
        dataChannel.onclose =   (event => sendCallback(Callbacks.DATA_CHANNEL_ONCLOSE, dataChannel ? dataChannel.readyState : "dead"));
        dataChannel.onerror =   (event => sendCallback(Callbacks.DATA_CHANNEL_ONERROR, event.message));
    } else {
        peerConnection.ondatachannel = handleDataChannelCreated;
    }
    
    // Kick it off (if we're the caller)
    if (isCaller) {
        peerConnection.createOffer()
        .then(offer => peerConnection.setLocalDescription(offer))
        .then(() => debug('set local offer description'))
        .then(() => sendCallback(Callbacks.PEER_CONNECTION_ONLOCALDESCRIPTION, peerConnection.localDescription))
        .catch(errorHandler);
    }
}

function gotIceCandidate(event) {
    debug('got ice candidate');
    if (event.candidate != null) {
        sendCallback(Callbacks.PEER_CONNECTION_ONICECANDIDATE, event.candidate);
        debug('sent ice candiate to remote');
    }
}

// Called when we are not the caller (ie we are the receiver)
// and the data channel has been opened
function handleDataChannelCreated(event) {
    debug('dataChannel opened');
    
    dataChannel = event.channel;
    
    dataChannel.onmessage = (event => sendCallback(Callbacks.DATA_CHANNEL_ONMESSAGE, event.data));
    dataChannel.onopen = (event => sendCallback(Callbacks.DATA_CHANNEL_ONOPEN, dataChannel ? dataChannel.readyState : "dead"));
    dataChannel.onclose = (event => sendCallback(Callbacks.DATA_CHANNEL_ONCLOSE, dataChannel ? dataChannel.readyState : "dead"));
    dataChannel.onerror = (event => sendCallback(Callbacks.DATA_CHANNEL_ONERROR, event.message));
}

function errorHandler(error) {
    debug(error);
}

/************************************************************************
 * SCRIPT FUNCTIONS - CALLABLE FROM SWIFT
 ************************************************************************/

// Called from swift to update configuration to new values
// (ie with newly fetched ice servers / turn credentials)
function setConfiguration(config) {
    peerConnectionConfig = config;
    debug('updated config: ' + JSON.stringify(peerConnectionConfig));
}

// Called from swift to initiate the connection (ie call the other end)
function connect(dataChannelName) {
    debug('connect');
    start(true, dataChannelName);
}

// Called from swift when we've received the session description from the remote peer
function gotSessionDescriptionFromServer(sdp) {
    debug('received session description from remote: ' + JSON.stringify(sdp));
    
    if (!peerConnection) start(false);
    
    peerConnection.setRemoteDescription(new RTCSessionDescription(sdp))
    .then(() => debug('set remote description'))
    .then(function() {
          // Only create answers in response to offers
          if (sdp.type == 'offer') {
          debug('got offer');
          
          peerConnection.createAnswer()
          .then(answer => peerConnection.setLocalDescription(answer))
          .then(() => debug('set local answer description'))
          .then(() => sendCallback(Callbacks.PEER_CONNECTION_ONLOCALDESCRIPTION, peerConnection.localDescription))
          .catch(errorHandler);
          }
          })
    .catch(errorHandler);
}

// Called from swift when we've received an ice candidate from the other end
// via the signalling channel. We should add it to our side
function gotIceCandidateFromServer(candidate) {
    debug('received ice candidate from remote: ' + JSON.stringify(candidate));
    
    if (!peerConnection) start(false);
    
    peerConnection.addIceCandidate(new RTCIceCandidate(candidate))
    .then(() => debug('added ice candidate'))
    .catch(errorHandler);
}

// Called from swift to send a message to the remote peer
function sendMessage(message) {
    debug("sending: " + message);
    if (dataChannel) {
        dataChannel.send(message);
    } else {
        debug("could not send. dataChannel not open");
    }
}

// Called from swift to close data channel and disconnect
function disconnect() {
    
    // Close the RTCDataChannel if it's open.
    dataChannel.close();
    
    // Close the RTCPeerConnection
    peerConnection.close();
    
    dataChannel = null;
    peerConnection = null;
}
