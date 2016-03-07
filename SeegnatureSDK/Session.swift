//
//  Session.swift
//  SeegnatureSDK
//
//  Created by Moshe Krush on 18/02/16.
//  Copyright © 2016 Moshe Krush. All rights reserved.
//

import Foundation
import OpenTok

class Session: NSObject, OTSessionDelegate, OTSubscriberKitDelegate, OTPublisherDelegate {
    
    var currentCall: NSDictionary?
    var capabilities: NSDictionary?
    var disconnectingCall: Bool?
    
    static let sharedInstance = Session()

    var sessionView = SessionView()
    
    override init() {

        printLog("Initializing session class")

    }

    func getSessionInfo(id:String, completion: (result: NSDictionary) -> Void) -> Void{

        ServerAPI.sharedInstance.getCallById(id, completion: {result -> Void in
            
            self.currentCall = result
            CallUtils.currentCall = result
            
            completion(result: result)

//            CallUtils.getCallerImage()

        })

    }
    
    func handleSessioInfoResponse(completion: () -> Void) -> Void{
        
        // Step 1: As the view is loaded initialize a new instance of OTSession
        
        if let callSession = self.currentCall?["session"] as? String {
            if let callToken = self.currentCall?["token"] as? String {
                
                CallUtils.delegate = self // set delegate
                CallUtils.initCall(callSession, token: callToken)
                
                CallUtils.whenConnected({ (result) -> Void in
                    if videoEnabled() {
                        CallUtils.doPublish()
                    }
                })
                
                completion()
                
            } else {
                completion()
            }
        } else{
            completion()
        }
    }
    
    func loadView(superView: UIView) {
        let documentView = NSBundle(forClass: SeegnatureActions.self).loadNibNamed("SessionView", owner: self, options: nil)[0] as! SessionView
        
        documentView.attachToView(superView)
        //            documentView.user = user
        
        self.sessionView = documentView

    }
    
    // MARK: - OTSession delegate callbacks
    
    func sessionDidConnect(session: OTSession) {
        NSLog("sessionDidConnect (\(session.sessionId))")
        
        // Step 2: We have successfully connected, now instantiate a publisher and
        // begin pushing A/V streams into OpenTok.
//        CallUtils.doPublish()
        if CallUtils.session?.sessionConnectionStatus == OTSessionConnectionStatus.Connected {
            CallUtils.didConnectToSession()
        }
        
    }
    
    func sessionDidDisconnect(session : OTSession) {
        NSLog("Session disconnected (\( session.sessionId))")
    }
    
    func session(session: OTSession, streamCreated stream: OTStream) {
        NSLog("session streamCreated (\(stream.streamId))")
        // Step 3a: (if NO == subscribeToSelf): Begin subscribing to a stream we
        // have seen on the OpenTok session.
        subscribeToStream(stream)
        
    }
    
    func session(session: OTSession, streamDestroyed stream: OTStream) {
        NSLog("session streamCreated (\(stream.streamId))")
        if (stream.videoType == OTStreamVideoType.Screen){
            CallUtils.doScreenUnsubscribe()
        } else {
            if CallUtils.subscriber?.stream.streamId == stream.streamId {
                //self.activeChatView.text = (self.activeChatView.text + "Remote side stopped video stream\n")
                CallUtils.doUnsubscribe()
            }
        }
    }
    
    func session(session: OTSession, connectionCreated connection : OTConnection) {
        NSLog("session connectionCreated (\(connection.connectionId))")
        if connection.connectionId != CallUtils.session?.connection.connectionId {
            //self.activeChatView.text = (self.activeChatView.text + "Remote side connected to session\n")
            CallUtils.remoteSideConnected()
            for (_, stream) in session.streams{
                if let s = stream as? OTStream{
                    subscribeToStream(s)
                }
            }
        }
    }
    
    func subscribeToStream(stream: OTStream){
//        self.sessionView.videoButtonPressed(UIButton())
//        CallUtils.doSubscribe(stream)
        CallUtils.stream = stream
        // show my video
        
        if (stream.videoType == OTStreamVideoType.Screen){
            CallUtils.doScreenSubscribe(stream)
            
        } else if CallUtils.subscriber?.stream.streamId != stream.streamId {
            CallUtils.stream = stream
//            if (showIncoming){
//                CallUtils.upcomingViewController?.close(false)
//                ViewUtils.showIncomingCall()
//            } else {
                CallUtils.doSubscribe(stream)
//            }
//            requestForCurrentSlide()
        } else if (CallUtils.isFakeCall){
            CallUtils.stream = stream
        }
    }
    
    func session(session: OTSession, connectionDestroyed connection : OTConnection) {
        NSLog("session connectionDestroyed (\(connection.connectionId))")
        //self.activeChatView.text = (self.activeChatView.text + "Remote side disconnected from session\n")
    }
    
    func session(session: OTSession, didFailWithError error: OTError) {
        NSLog("session didFailWithError (%@)", error)
    }
    
    // MARK: - OTSubscriber delegate callbacks
    
    func subscriberDidConnectToStream(subscriberKit: OTSubscriberKit) {
        NSLog("subscriberDidConnectToStream (\(subscriberKit))")        
        self.sessionView.subscriberDidConnectToStream()
        
    }
    
    func subscriber(subscriber: OTSubscriberKit, didFailWithError error : OTError) {
        NSLog("subscriber %@ didFailWithError %@", subscriber.stream.streamId, error)
    }
    
    // MARK: - OTPublisher delegate callbacks
    
    func publisher(publisher: OTPublisherKit, streamCreated stream: OTStream) {
        NSLog("publisher streamCreated %@", stream)
        /*
        // Step 3b: (if YES == subscribeToSelf): Our own publisher is now visible to
        // all participants in the OpenTok session. We will attempt to subscribe to
        // our own stream. Expect to see a slight delay in the subscriber video and
        // an echo of the audio coming from the device microphone.
        if CallUtils.subscriber == nil && SubscribeToSelf {
        CallUtils.doSubscribe(stream)
        }
        */
    }
    
    func publisher(publisher: OTPublisherKit, streamDestroyed stream: OTStream) {
        NSLog("publisher streamDestroyed %@", stream)
        
        if CallUtils.subscriber?.stream.streamId == stream.streamId {
            CallUtils.doUnsubscribe()
        }
    }
    
    func publisher(publisher: OTPublisherKit, didFailWithError error: OTError) {
        NSLog("publisher didFailWithError %@", error)
    }
    
    func session(session: OTSession!, receivedSignalType type: String!, fromConnection connection: OTConnection!, withString string: String!) {

        if ((connection?.connectionId != CallUtils.session?.connection?.connectionId) ||
            (connection == nil) || (session == nil)) {
//        if (connection?.connectionId != CallUtils.session?.connection?.connectionId) {
            printLog(string)
            self.sessionView.handleSignal(session, receivedSignalType: type, fromConnection: connection, withString: string)

        }
    }
}

func videoEnabled() -> Bool {
    
    if let val = Session.sharedInstance.capabilities!["video_enabled"] as? Bool where val == true {
        return true
    }
    
    return false
    
}
