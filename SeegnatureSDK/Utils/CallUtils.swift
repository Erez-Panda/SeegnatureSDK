//
//  CallUtils.swift
//  SeegnatureSDK
//
//  Created by Erez on 1/8/15.
//  Copyright (c) 2015 Erez. All rights reserved.
//

// *** Fill the following variables using your own Project info  ***
// ***          https://dashboard.tokbox.com/projects            ***
// Replace with your OpenTok API key


import OpenTok

let ApiKey = "45145512"

@objc protocol CallDelegate{
    optional func remoteSideConnected()
}


struct CallUtils{
    static var session : OTSession?
    static var publisher : OTPublisher?
    static var screenPublisher : OTPublisher?
    static var subscriber : OTSubscriber?
    static var screenSubscriber : OTSubscriber?
    static var token : String?
    static var stream : OTStream?
    static var sessionDelegate : OTSessionDelegate?
    static var subscriberDelegate : OTSubscriberKitDelegate?
    static var publisherDelegate : OTPublisherDelegate?
//    static var delegate:CallDelegate?
    static var delegate:Session?
    static var remoteSideConnect = false
    static var callViewController: UIViewController?
    static var incomingViewController : UIViewController?
    static var upcomingViewController : UpcomingCallViewController?
    static var rootViewController: UIViewController?
    static var fakeStream: OTStream?
    static var isFakeCall = false
    static var currentCall: NSDictionary?
    static var callInProgress: Bool = false
    static var isConnectedToSession: Bool = false
    static var connectionCallback: ((result: Bool) -> Void)?
    static var callerImage: UIImage?
    
    static func fakeCall (){
        isFakeCall = true
        ViewUtils.showIncomingCall()
    }
    
    static func startArchive(){
        if let id = self.currentCall?["id"] as? NSNumber{
            let data = ["call": id] as Dictionary<String, AnyObject>
            ServerAPI.sharedInstance.startCallArchive(data, completion: { (result) -> Void in
                
            })
        }
    }
    
    static func stopArchive(){
        if let id = self.currentCall?["id"] as? NSNumber{
            let data = ["call": id] as Dictionary<String, AnyObject>
            ServerAPI.sharedInstance.stopCallArchive(data, completion: { (result) -> Void in
                
            })
        }
    }
    
    static func isRemoteSideConnected() -> Bool{
        return remoteSideConnect
    }
    
    static func remoteSideConnected(){
        printLog("remote side connected")
        remoteSideConnect = true
//        self.delegate?.remoteSideConnected!()
    }
    
    static func didConnectToSession(){
        printLog("connected to session")
        isConnectedToSession = true
        if connectionCallback != nil{
            connectionCallback!(result: true)
        }
    }
    
    static func whenConnected(completion: (result: Bool) -> Void){
        if isConnectedToSession {
            completion(result: true)
        } else {
            printLog("false")
            connectionCallback = completion
        }
    }
    

    static func getCallerImage(){
        if let caller = CallUtils.currentCall?["caller"] as? NSDictionary{
            if let imageFileId = caller["image_file"] as? NSNumber{
                ViewUtils.getImageFile(imageFileId, completion: { (result) -> Void in
                    self.callerImage = result
                })
            }
        }
    }

    
    static func connectToCurrentCallSession(delegateViewController: UIViewController, completion: (result: NSDictionary) -> Void) -> Void{
        callViewController = delegateViewController
        ServerAPI.sharedInstance.getCurrentCall( {result -> Void in
            self.currentCall = result
            self.getCallerImage()
            // Step 1: As the view is loaded initialize a new instance of OTSession
            if let call = self.currentCall?["session"] as? String{
                CallUtils.initCall(call, token: self.currentCall?["token"] as! String)
                completion(result: self.currentCall!)
                
            } else{
                completion(result: [:])
            }
        })
    }

    static func initCall(sessionId: String, token: String){
        self.token = token
        self.sessionDelegate = self.delegate as? OTSessionDelegate
        self.subscriberDelegate = self.delegate as? OTSubscriberKitDelegate
        self.publisherDelegate = self.delegate as? OTPublisherDelegate
        session = OTSession(apiKey: ApiKey, sessionId: sessionId, delegate: sessionDelegate)
        self.doConnect()
        
    }
    
    static func pauseCall(){
        doUnsubscribe()
        doUnpublish()
        doScreenUnpublish()
        var maybeError : OTError?
        session?.disconnect(&maybeError)
        session = nil
        token = nil
        stream = nil
        sessionDelegate = nil
        subscriberDelegate = nil
        publisherDelegate = nil
        remoteSideConnect = false
        callViewController = nil
        callInProgress = false
        isConnectedToSession = false
    }
    
    static func resumeCall(){
        if (session != nil) {
            self.doConnect()
            self.doPublish()
        }
    }
    
    static func stopCall(){
        self.pauseCall()
    }
    
    // MARK: - OpenTok Methods
    
    /**
    * Asynchronously begins the session connect process. Some time later, we will
    * expect a delegate method to call us back with the results of this action.
    */
    static func doConnect() {
        if let session = self.session {
            var maybeError : OTError?
            session.connectWithToken(self.token, error: &maybeError)
            if let error = maybeError {
                ViewUtils.showAlert("OTError", message: error.localizedDescription)
            } else {
                screenPublisher = OTPublisher(delegate: self.publisherDelegate, name: "", audioTrack: false, videoTrack: true)
                screenPublisher?.videoType = OTPublisherKitVideoType.Screen
                screenPublisher?.audioFallbackEnabled = false
                //screenPublisher?.videoCapture.releaseCapture()
            }
        }
    }
    
    /**
     * Sets up an instance of OTPublisher to use with this session. OTPubilsher
     * binds to the device camera and microphone, and will provide A/V streams
     * to the OpenTok session.
     */
    static func doPublish() { // publish my screen
        if publisher != nil {
            return
        }
        publisher = OTPublisher(delegate: self.publisherDelegate)
        publisher?.publishVideo = false
        var maybeError : OTError?
        session?.publish(publisher, error: &maybeError)
        
        if let error = maybeError {
            ViewUtils.showAlert("OTError", message: error.localizedDescription)
        }
        
        
        if videoEnabled() { //if (isFakeCall){
            publisher?.publishVideo = true
        }
        
    }
    
    static func doScreenPublish(view: UIView) {

        screenPublisher?.videoCapture = TBScreenCapture(view: view)
        //screenPublisher?.publishVideo = true
        var maybeError : OTError?
        session?.publish(screenPublisher, error: &maybeError)
        
        
        if let error = maybeError {
            ViewUtils.showAlert("OTError", message: error.localizedDescription)
        }
        
    }
    
    // Subscribe to other user screen streaming
    static func doScreenSubscribe(stream : OTStream) {
        if let session = self.session {
            screenSubscriber = OTSubscriber(stream: stream, delegate: self.subscriberDelegate)
            var maybeError : OTError?
            session.subscribe(screenSubscriber, error: &maybeError)
            if let error = maybeError {
                ViewUtils.showAlert("OTError", message: error.localizedDescription)
            }
        }
    }
    
    // Unsubscribe to other user screen streaming    
    static func doScreenUnsubscribe() {
        if let screenSubscriber = self.screenSubscriber {
            var maybeError : OTError?
            session?.unsubscribe(screenSubscriber, error: &maybeError)
//            if let error = maybeError {
//                ViewUtils.showAlert("OTError", message: error.localizedDescription)
//            }
            
            screenSubscriber.view.removeFromSuperview()
            self.screenSubscriber = nil
        }
    }
    
    /**
     * Instantiates a subscriber for the given stream and asynchronously begins the
     * process to begin receiving A/V content for this stream. Unlike doPublish,
     * this method does not add the subscriber to the view hierarchy. Instead, we
     * add the subscriber only after it has connected and begins receiving data.
     */
    static func doSubscribe(stream : OTStream) { // subscribe to other user
        if let session = self.session {
            subscriber = OTSubscriber(stream: stream, delegate: self.subscriberDelegate)
            var maybeError : OTError?
            session.subscribe(subscriber, error: &maybeError)
            if let error = maybeError {
                ViewUtils.showAlert("OTError", message: error.localizedDescription)
            }
        }
    }
    
    /**
     * Cleans the subscriber from the view hierarchy, if any.
     */
    static func doUnsubscribe() {
        if let subscriber = self.subscriber {
            var maybeError : OTError?
            session?.unsubscribe(subscriber, error: &maybeError)
//            if let error = maybeError {
//                ViewUtils.showAlert("OTError", message: error.localizedDescription)
//            }
            
            subscriber.view.removeFromSuperview()
            self.subscriber = nil
        }
    }
    
    static func doUnpublish() {
        if let publisher = self.publisher {
            var maybeError : OTError?
            session?.unpublish(publisher, error: &maybeError)
//            if let error = maybeError {
//                ViewUtils.showAlert("OTError", message: error.localizedDescription)
//            }
            
            publisher.view.removeFromSuperview()
            self.publisher = nil
        }
    }
    
    static func doScreenUnpublish() {
        if let screenPublisher = self.screenPublisher {
            var maybeError : OTError?
            session?.unpublish(screenPublisher, error: &maybeError)
//            if let error = maybeError {
//                ViewUtils.showAlert("OTError", message: error.localizedDescription)
//            }
            
            //screenPublisher.view.removeFromSuperview()
            //self.screenPublisher = nil
        }
    }
    
    static func sendJsonMessage(type: String, data: Dictionary<String, AnyObject>){
        var maybeError : OTError?
        do{
            let jsonData = try NSJSONSerialization.dataWithJSONObject(data, options: NSJSONWritingOptions())
            self.session?.signalWithType(type, string: NSString(data: jsonData, encoding: NSUTF8StringEncoding)! as String, connection: nil, error: &maybeError)
        }
        catch{
            printLog("error")
        }
    }
    
    static func convertStringToDictionary(text: String) -> [String:AnyObject]? {
        if let data = text.dataUsingEncoding(NSUTF8StringEncoding) {
            var json: [String:AnyObject]?
            do {
                json = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableLeaves) as? [String : AnyObject]
            } catch let error as NSError {
                printLog(error)
                json = nil
            } catch {
                fatalError()
            }
            return json
        }
        return nil
    }
    
    static func convertStringToArray(text: String) -> [AnyObject]? {
        if let data = text.dataUsingEncoding(NSUTF8StringEncoding) {
            var json: [AnyObject]?
            do {
                json = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableLeaves) as? [AnyObject]
            } catch let error as NSError {
                printLog(error)
                json = nil
            } catch {
                fatalError()
            }
            return json
        }
        return nil
    }

}

