//
//  SessionView.swift
//  SeegnatureSDK
//
//  Created by Moshe Krush on 10/02/16.
//  Copyright © 2016 Moshe Krush. All rights reserved.
//

import UIKit
import OpenTok

let videoWidth : CGFloat = 264/1.5
let videoHeight : CGFloat = 198/1.5

let textPanelWidth: CGFloat = 300
let textPanelHeight: CGFloat = 120
let signPanelWidth: CGFloat = UIScreen.mainScreen().bounds.width/2
var signPanelHeight: CGFloat = 120

class SessionView: UIView, UIGestureRecognizerDelegate, UIScrollViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var endButton: UIButton!
    @IBOutlet weak var chatButton: UIButton!
    @IBOutlet weak var presentationWebView: UIWebView?
    @IBOutlet weak var chatBadge: UILabel!
    @IBOutlet weak var toggleVideoButton: UIButton!
    @IBOutlet weak var toggleSoundButton: UIButton!
    @IBOutlet weak var presentaionImage: UIImageView!
    @IBOutlet weak var bottomView: UIViewWithLayerUpdate!
    @IBOutlet weak var companyLogo: UIImageView!
    @IBOutlet weak var pointer: NIKFontAwesomeButton!
    @IBOutlet weak var scrollView: UIScrollView?

    var preLoadedImages: Array<Dictionary<Int, UIImage?>> = []
    var currentImage: UIImage?
    var currentImageUrl: String?
    var currentDocument: Int?
    var currentPage: Int?
    var modifiedImages: Dictionary<String, UIImage?> = [:]
    
    var isDragging = false
    var signView: SignDocumentPanelView?
    var addTextView: TextDocumentPanelView?
    
    var controlPanelTimer: NSTimer?
    var controlPanelHidden = false
    @IBOutlet weak var controlPanelBottomConstraint: NSLayoutConstraint!
    
    var publisherSizeConst: [NSLayoutConstraint]?
    var publisherPositionConst : Dictionary<String, NSLayoutConstraint>?
    
    let SubscribeToSelf = false

    
    var imagePicker = UIImagePickerController()
    
    var isFirstLoad = true
    
    // chat
    var messageQ : NSArray = []
    var isChatShown = false
    var chat: ChatView?
    
    // MARK: init methods
    
    override func awakeFromNib() {
        
        setControlPanel()

        addGestures()
        
        setImagePicker()
        
        self.scrollView?.delegate = self
        
        setGradient()

    }
    
    // MARK: input panels
    
    func addCustomViews() {
        setSignView()
        setTextBox()
    }
    
    func setSignView() {
        self.signView = NSBundle(forClass: SessionView.self).loadNibNamed("SignDocumentPanelView", owner: self, options: nil)[0] as? SignDocumentPanelView
        self.signView?.onClose = self.onSignViewClose
        self.signView?.onSign = self.onSignViewSign
        self.addSubview(self.signView!)
        let sizeConstraints = self.signView!.addSizeConstaints(signPanelWidth, height: signPanelHeight)
        self.signView?.height = sizeConstraints[1]
        let constraints = self.signView?.setConstraintesToCenterSuperView(self)
        self.signView?.center_x_constraint = constraints![0]
        self.signView?.center_y_constraint = constraints![1]
        self.signView?.hidden = true
    }
    
    func setTextBox() {
        addTextView = NSBundle(forClass: SessionView.self).loadNibNamed("TextDocumentPanelView", owner: self, options: nil)[0] as? TextDocumentPanelView
        addTextView?.onClose = onTextViewClose
        addTextView?.onAdd = onTextAdded
        self.addSubview(addTextView!)
        self.addTextView!.addSizeConstaints(textPanelWidth, height: textPanelHeight)
        let constraints = self.addTextView?.setConstraintesToCenterSuperView(self)
        self.addTextView?.center_x_constraint = constraints![0]
        self.addTextView?.center_y_constraint = constraints![1]
        self.addTextView?.hidden = true
    }
    
    // MARK: video methods
    
    func subscriberDidConnectToStream() {
        
        if CallUtils.screenSubscriber?.stream.videoType == OTStreamVideoType.Screen {
            if let view = CallUtils.screenSubscriber?.view {
                let screenSize: CGRect = UIScreen.mainScreen().bounds
                let ratio = CallUtils.subscriber!.stream.videoDimensions.height/CallUtils.subscriber!.stream.videoDimensions.width
                view.frame.origin = CGPointMake(0, (screenSize.height - screenSize.width*ratio)/2)
                view.frame.size = CGSizeMake(screenSize.width, screenSize.width*ratio)
            }
        } else if let view = CallUtils.subscriber?.view {
            self.addSubview(view)
            view.addConstraintsToSuperview(self, top: 0.0, left: nil, bottom: nil, right: 0.0)
            view.addSizeConstaints(videoWidth, height: videoHeight)
            if let pubView = CallUtils.publisher?.view {
                
                pubView.removeFromSuperview()
                view.addSubview(pubView)
                pubView.addConstraintsToSuperview(view, top: nil, left: nil, bottom: 0.0, right: 0.0)
                publisherSizeConst = pubView.addSizeConstaints(videoWidth, height: videoHeight)
                NSTimer.scheduledTimerWithTimeInterval(NSTimeInterval(3), target: self, selector: Selector("shrinkPublisher"), userInfo: AnyObject?(), repeats: false)
            }
        }
        
    }
    
    func shrinkPublisher(){
        if nil != CallUtils.publisher?.view {
            //view.removeConstraints(publisherSizeConst!)
            
            UIView.animateWithDuration(0.5, animations: { () -> Void in
                self.publisherSizeConst?[0].constant = videoWidth/3
                self.publisherSizeConst?[1].constant = videoHeight/3
                self.publisherPositionConst?["top"]?.constant = 2*videoHeight/3
                self.publisherPositionConst?["left"]?.constant = 2*videoHeight/3
                
                
            })
        }
    }
    
    
    func setGradient() {
        ViewUtils.addGradientLayer(bottomView, topColor: UIColor(red:0.1/255, green:0.1/255, blue:0.1/255, alpha:0.0), bottomColor: UIColor(red:0.1/255, green:0.1/255, blue:0.1/255, alpha:0.9))
        if CallUtils.subscriber == nil && !SubscribeToSelf {
            if (!CallUtils.isFakeCall){
                if let stream = CallUtils.stream{
                    CallUtils.doSubscribe(stream)
                }
            }
        }
       
        ViewUtils.roundView(chatBadge, borderWidth: 1.0, borderColor: UIColor.whiteColor())
        if ((currentImage) != nil){
            presentaionImage?.image = currentImage
        }
    }


    
    override func layoutSubviews() {

        super.layoutSubviews()
        
        if self.isFirstLoad == true {
            addCustomViews()
            ViewUtils.addGradientLayer(bottomView, topColor: UIColor(red:0.1/255, green:0.1/255, blue:0.1/255, alpha:0.0), bottomColor: UIColor(red:0.1/255, green:0.1/255, blue:0.1/255, alpha:0.9))
            if CallUtils.subscriber == nil && !SubscribeToSelf {
                if (!CallUtils.isFakeCall){
                    if let stream = CallUtils.stream{
                        CallUtils.doSubscribe(stream)
                    }
                }
                CallUtils.doPublish()
            }
            
            ViewUtils.roundView(chatBadge, borderWidth: 1.0, borderColor: UIColor.whiteColor())
            if ((currentImage) != nil){
                presentaionImage?.image = currentImage
            }
            self.isFirstLoad = false
        }
    }
    
    
    // MARK: scrollview methods
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return presentaionImage
    }

    // MARK: control panel
    
    func setControlPanel() {
        controlPanelTimer = NSTimer.scheduledTimerWithTimeInterval(NSTimeInterval(3), target: self, selector: Selector("hideControls"), userInfo: AnyObject?(), repeats: false)
    }
    
    func showControlPanel(){
        self.controlPanelHidden = false
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.controlPanelBottomConstraint.constant = 0
            self.layoutIfNeeded()
        })
        controlPanelTimer?.invalidate()
        controlPanelTimer = NSTimer.scheduledTimerWithTimeInterval(NSTimeInterval(3), target: self, selector: Selector("hideControls"), userInfo: AnyObject?(), repeats: false)
    }

    func hideControls(){
        if let controls = bottomView {
            UIView.animateWithDuration(0.5, animations: { () -> Void in
                self.controlPanelBottomConstraint.constant = controls.frame.height
                self.layoutIfNeeded()
            })
        }
        controlPanelHidden = true
    }
    
    // MARK: gestures methods
    
    func addGestures() {
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action:"tap:"))
    }

    func tap(sender:  UITapGestureRecognizer) {
        if signView?.hidden == false { // signView != nil {
            if (!CGRectContainsPoint(signView!.frame, sender.locationInView(self))){
                self.signView?.hidden = true
            }
        } else if addTextView?.hidden == false {
            if (!CGRectContainsPoint(addTextView!.frame, sender.locationInView(self))){
                self.addTextView?.hidden = true
            }
        }
        
        if self.chat == nil {
            if (controlPanelHidden) {
                showControlPanel()
            } else {
                hideControls()
            }
        } else {
            hideControls()
//            if controlPanelHidden {
//                showControlPanel()
//            }
        }

    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        if touches.count == 1 {
            if let touch: UITouch = touches.first{
                let touchLocation = touch.locationInView(self) as CGPoint
                
                
                if let subscriberRect = CallUtils.subscriber?.view.frame {
                    if (CGRectContainsPoint(subscriberRect, touchLocation)){
                        self.isDragging = true
                    }
                }
                if (CallUtils.isFakeCall){
                    if let subscriberRect = CallUtils.publisher?.view.frame {
                        if (CGRectContainsPoint(subscriberRect, touchLocation)){
                            self.isDragging = true
                        }
                    }
                } else {
                    if let view = CallUtils.publisher?.view {
                        let touchLocationinsideVideo = touch.locationInView(CallUtils.subscriber?.view) as CGPoint
                        if (CGRectContainsPoint(view.frame, touchLocationinsideVideo)){
                            
                            UIView.animateWithDuration(0.5, animations: { () -> Void in
                                if (view.frame.origin.x > 10){
                                    self.publisherSizeConst?[0].constant = videoWidth
                                    self.publisherSizeConst?[1].constant = videoHeight
                                    self.publisherPositionConst?["top"]?.constant = 0
                                    self.publisherPositionConst?["left"]?.constant = 0
                                } else {
                                    self.publisherSizeConst?[0].constant = videoWidth/3
                                    self.publisherSizeConst?[1].constant = videoHeight/3
                                    self.publisherPositionConst?["top"]?.constant = 2*videoHeight/3
                                    self.publisherPositionConst?["left"]?.constant = 2*videoHeight/3
                                }
                            })
                        }
                    }
                }
            }
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)
        self.isDragging = false
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        super.touchesCancelled(touches, withEvent: event)
        print("CANCEL")
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesMoved(touches, withEvent: event)
        if let touch: UITouch = touches.first{
            let touchLocation = touch.locationInView(self) as CGPoint
            if (self.isDragging){
                if let subscriber = CallUtils.subscriber?.view {
                    UIView.animateWithDuration(0.0,
                        delay: 0.0,
                        options: ([UIViewAnimationOptions.BeginFromCurrentState, UIViewAnimationOptions.CurveEaseInOut]),
                        animations:  {subscriber.center = touchLocation},
                        completion: nil)
                }
            }
            if signView?.hidden == false {
                self.signView?.center_x_constraint?.constant = touchLocation.x - (self.frame.width - signPanelWidth)/2
                self.signView?.center_y_constraint?.constant = touchLocation.y - (self.frame.height - signPanelHeight)/2
            }
            if addTextView?.hidden == false {
                self.addTextView?.center_x_constraint?.constant = touchLocation.x - (self.frame.width - textPanelWidth)/2
                self.addTextView?.center_y_constraint?.constant = touchLocation.y - (self.frame.height - textPanelHeight)/2
            }
        }
    }
    
    // MARK: image picker methods
    
    func setImagePicker() {
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
    }
    
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: NSDictionary!){
        
        CallUtils.doPublish()
        
        ViewUtils.getTopViewController()!.dismissViewControllerAnimated(true, completion: { () -> Void in
            
            if let id = CallUtils.currentCall?["id"] as? NSNumber{
                let newName = "\(id)_Id_Image.jpg"
                ServerAPI.sharedInstance.uploadFile(UIImageJPEGRepresentation(image, 1.0)!, filename: newName) { (result) -> Void in
                    if let file = result as? NSDictionary{
                        
                        if let fileId = file["id"] as? NSNumber {
                            
                            let newDictionary: Dictionary<String, AnyObject>  = ["file": fileId, "verify_id": true, "type": 1, "name": newName]
                            
                            CallUtils.sendJsonMessage("new_call_document", data: newDictionary)
                            
                            print("sent message")
                        }
                    }
                }
            }
        })
    }

    // MARK: handle buttons events
    
    @IBAction func signButtonPressed(sender: AnyObject) {
        self.signView!.hidden = !self.signView!.hidden
    }
    
    @IBAction func textButtonPressed(sender: AnyObject) {
        self.addTextView!.hidden = !self.addTextView!.hidden
    }
    
    @IBAction func chatButtonPressed(sender: AnyObject) {
        self.hideControls()
        if (self.isChatShown == true) {
            chat!.frame.origin.y = self.frame.size.height
            chat!.hidden = false
            releaseMessageQ()
            UIView.animateWithDuration(0.5, animations: { () -> Void in
                self.chat!.frame.origin.y = 0.0
            })
        } else {
            
            let chatView = NSBundle(forClass: SessionView.self).loadNibNamed("ChatView", owner: self, options: nil)[0] as! ChatView
            
            chatView.attachToView(self)
            self.chat = chatView
            self.chat?.frame = CGRectMake(0, self.frame.size.height, self.frame.size.width, self.frame.size.height)
            
            releaseMessageQ()
            UIView.animateWithDuration(0.5, animations: { () -> Void in
                self.chat!.frame.origin.y = 0.0
            })
        }
    }
    
    func addMessageToQ(message: String){
        messageQ = messageQ.arrayByAddingObject(message)
        chatBadge?.text = String(messageQ.count)
        chatBadge?.hidden = false
        showControlPanel()
    }
    
    func releaseMessageQ(){
        if (messageQ.count > 0){
            for message in messageQ {
                self.chat!.addChatBox(message as! String, isSelf: false)
            }
            messageQ = []
            chatBadge.hidden = true
        }
    }
    
    
    @IBAction func videoButtonPressed(sender: AnyObject) {
        if let pVideo = CallUtils.publisher?.publishVideo{
            CallUtils.publisher?.publishVideo = !pVideo
            if (!pVideo){
                toggleVideoButton.setImage(UIImage(named: "video_on_icon"), forState: UIControlState.Normal)
                if let view = CallUtils.publisher?.view {
                    if let subView = CallUtils.subscriber?.view{
                        subView.addSubview(view)
                        publisherPositionConst = self.addConstraintsToSuperview(subView, top: nil, left: nil, bottom: 0.0, right: 0.0)
                        publisherSizeConst = self.addSizeConstaints(videoWidth, height: videoHeight)
                        NSTimer.scheduledTimerWithTimeInterval(NSTimeInterval(3), target: self, selector: Selector("shrinkPublisher"), userInfo: AnyObject?(), repeats: false)
                    } else {
                        self.addSubview(view)
                        self.addConstraintsToSuperview(self, top: 0.0, left: nil, bottom: nil, right: 0.0)
                        self.addSizeConstaints(videoWidth, height: videoHeight)
                    }
                }
            } else {
                toggleVideoButton.setImage(UIImage(named: "video_off_icon"), forState: UIControlState.Normal)
                if let view = CallUtils.publisher?.view {
                    view.removeFromSuperview()
                }
            }
            
        }
    }
    
    @IBAction func audioButtonPressed(sender: AnyObject) {
        if let pAudio = CallUtils.publisher?.publishAudio{
            CallUtils.publisher?.publishAudio = !pAudio
            if (!pAudio){
                toggleSoundButton.setImage(UIImage(named: "audio_on_icon"), forState: UIControlState.Normal)
            } else {
                toggleSoundButton.setImage(UIImage(named: "audio_off_icon"), forState: UIControlState.Normal)
            }
        }
    }
    
    @IBAction func endButtonPressed(sender: AnyObject) {
        Session.sharedInstance.disconnectingCall = true
        CallUtils.stopCall()
        CallUtils.incomingViewController = nil
        self.removeFromSuperview()
        Session.sharedInstance.disconnectingCall = false
    }
    
    func closeOpenPanels(){
        self.signView?.hidden = true
        self.addTextView?.hidden = true
    }
    
    // MARK: insert signature methods
    
    func onSignViewClose(sender: UIView){
        self.signView?.hidden = true
    }
    
    func onSignViewSign(signatureView: LinearInterpView, origin: CGPoint){
        var userImage : UIImage?
        let screen =  UIScreen.mainScreen().bounds
        let zoom = scrollView!.zoomScale
        
        //let offset = scrollView!.contentOffset
        let document = presentaionImage!.image!
        
        //Image is aspect fit, scale factor will be the biggest change on image
        let scaleRatio = max(document.size.width/screen.width, document.size.height/screen.height)
        let X = (origin.x+scrollView!.contentOffset.x)/zoom
        let Y = (origin.y+scrollView!.contentOffset.y)/zoom
        
        if let pub = CallUtils.publisher?.view {
            let snapshot = pub.snapshotViewAfterScreenUpdates(true)
            userImage = takeScreenshot(snapshot)
        }
        
        let scaledSignView = PassiveLinearInterpView(frame: CGRectMake(0,0,signatureView.frame.width*scaleRatio/zoom, signatureView.frame.height*scaleRatio/zoom))
        
        //scaledSignView.path?.lineWidth *= scaleRatio/zoom
        for line in signatureView.points {
            for i in 0 ..< line.count{
                if i==0 {
                    scaledSignView.moveToPoint(CGPoint(x: line[i].x*scaleRatio/zoom , y: line[i].y*scaleRatio/zoom))
                } else {
                    scaledSignView.addPoint(CGPoint(x: line[i].x*scaleRatio/zoom , y: line[i].y*scaleRatio/zoom))
                }
            }
        }
        
        //One of these have to be 0
        let heightDiff = (screen.height*scaleRatio) - document.size.height
        let widthDiff = (screen.width*scaleRatio) - document.size.width
        
        var newDictionary = sendSignaturePoints(signatureView, origin:CGPointMake((X*scaleRatio)-widthDiff/2,(Y*scaleRatio)-heightDiff/2), imgSize:CGSizeMake( document.size.width, document.size.height), scaleRatio: scaleRatio, zoom:zoom) as Dictionary<String,AnyObject>
        
        let scaledSignImage = takeScreenshot(scaledSignView)
        UIGraphicsBeginImageContext(document.size)
        document.drawInRect(CGRectMake(0,0,document.size.width, document.size.height))
        scaledSignImage.drawInRect(CGRectMake((X*scaleRatio)-widthDiff/2,(Y*scaleRatio)-heightDiff/2,scaledSignView.frame.width, scaledSignView.frame.height))

        if userImage != nil {
            userImage!.drawInRect(CGRectMake(0,0,videoWidth, videoHeight), blendMode: CGBlendMode.Normal, alpha: 1.0)
        }
        
        let signedDoc = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let image: UIImage = signedDoc
        self.presentaionImage?.image = image
        if currentImageUrl != nil {
            modifiedImages[currentImageUrl!] = image
        }
        if currentPage != nil && currentDocument != nil {
            setImageAtIndex(image, document: currentDocument!, page: currentPage!)
        }

        newDictionary["call"] = CallUtils.currentCall!["id"] as! NSNumber
        newDictionary["page_number"] = self.currentPage!
        newDictionary["document_id"] = self.currentDocument!
        newDictionary["tracking"] = NSUUID().UUIDString
        newDictionary["type"] = "signature"

        ServerAPI.sharedInstance.newModification(newDictionary, completion: { (result) -> Void in})

    }

    
    func sendSignaturePoints(signatureView: LinearInterpView, origin: CGPoint, imgSize: CGSize, scaleRatio: CGFloat, zoom: CGFloat) -> Dictionary<String,AnyObject> {
        
        var pointsStr: String = ""
        for line in signatureView.points {
            for point in line{
                pointsStr += "\(max(point.x,0)),\(max(point.y,0))-"
            }
            pointsStr += "***"
        }
        
        let newDictionary: Dictionary<String, AnyObject>  =
        ["width": signatureView.frame.width, "height": signatureView.frame.height,
            "left": origin.x/imgSize.width, "top": origin.y/imgSize.height,
            "image_width": (imgSize.width/scaleRatio)*zoom, "image_height": (imgSize.height/scaleRatio)*zoom,
            "zoom": zoom, "points": pointsStr]
        
        CallUtils.sendJsonMessage("signature_points", data: newDictionary)
        
        return newDictionary
    }
    
    // MARK: insert text methods
    
    func onTextViewClose(sender: UIView){
        self.addTextView?.hidden = true
    }
    
    func onTextAdded(textView: UITextField, origin: CGPoint){
        //var userImage : UIImage?
        let screen =  UIScreen.mainScreen().bounds
        let zoom = scrollView!.zoomScale
        //let offset = scrollView!.contentOffset
        let document = presentaionImage!.image!
        //Image is aspect fit, scale factor will be the biggest change on image
        let scaleRatio = max(document.size.width/screen.width, document.size.height/screen.height)
        let X = (origin.x+scrollView!.contentOffset.x)/zoom
        let Y = (origin.y+scrollView!.contentOffset.y)/zoom
        
        
        //One of these have to be 0
        let heightDiff = (screen.height*scaleRatio) - document.size.height
        let widthDiff = (screen.width*scaleRatio) - document.size.width
        
        sendAddedText(textView, origin:CGPointMake((X*scaleRatio)-widthDiff/2,(Y*scaleRatio)-heightDiff/2), imgSize:CGSizeMake( document.size.width, document.size.height), scaleRatio: scaleRatio, zoom:zoom)
        
        let scaledTextView = UITextField(frame: CGRectMake(0,0,textView.frame.width*scaleRatio/zoom, textView.frame.height*scaleRatio/zoom))
        scaledTextView.text = textView.text
        scaledTextView.font = textView.font!.fontWithSize(textView.font!.pointSize*scaleRatio/zoom)
        
        
        
        let scaledTextImage = takeScreenshot(scaledTextView)
        UIGraphicsBeginImageContext(document.size)
        document.drawInRect(CGRectMake(0,0,document.size.width, document.size.height))
        scaledTextImage.drawInRect(CGRectMake((X*scaleRatio)-widthDiff/2,(Y*scaleRatio)-heightDiff/2,scaledTextView.frame.width, scaledTextView.frame.height))
        let addedTextDoc = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let image: UIImage = addedTextDoc
        self.presentaionImage?.image = image
        if currentImageUrl != nil {
            modifiedImages[currentImageUrl!] = image
        }
        if currentPage != nil && currentDocument != nil {
            setImageAtIndex(image, document: currentDocument!, page: currentPage!)
        }
        
    }
    
    func sendAddedText(textView: UITextField, origin: CGPoint, imgSize: CGSize, scaleRatio: CGFloat, zoom: CGFloat){
        
        var newDictionary: Dictionary<String, AnyObject>  =
        
        ["width": textView.frame.width, "height": textView.frame.height,
            "left": origin.x/imgSize.width, "top": origin.y/imgSize.height,
            "image_width": imgSize.width/scaleRatio, "image_height": imgSize.height/scaleRatio,
            "zoom": zoom, "text": textView.text!, "font_size": textView.font!.pointSize]
        
        CallUtils.sendJsonMessage("add_text", data: newDictionary)
        
        newDictionary["call"] = CallUtils.currentCall!["id"] as! NSNumber
        newDictionary["page_number"] = self.currentPage!
        newDictionary["document_id"] = self.currentDocument!
        newDictionary["tracking"] = NSUUID().UUIDString
        newDictionary["type"] = "text"
        
        ServerAPI.sharedInstance.newModification(newDictionary, completion: { (result) -> Void in})
        
    }
    
    // MARK: hanlde incoming events
    
    func handleSignal(session: OTSession!, receivedSignalType type: String!, fromConnection connection: OTConnection!, withString string: String!) {
        
        printLog("\(type) event")
        
        switch type {
            
        case SignalsType.Send_Meta_Data.rawValue:
            sendMetaData()
            break
        case SignalsType.Load_Res_With_Index.rawValue:
            loadResourcesWithIndex(string)
            break
        case SignalsType.Preload_Res_With_Index.rawValue:
            preLoadResourcesWithIndex(string)
            break
        case SignalsType.Chat_Text.rawValue:
            handleChatEvent(string)
            break
        case SignalsType.Line_Start_Point.rawValue:
            handleLineStart(string)
            break
        case SignalsType.Line_Point.rawValue:
            handleLinePoint(string)
            break
        case SignalsType.Line_Clear.rawValue:
            handleLineClear()
            break
        case SignalsType.Pointer_Position.rawValue:
            handlePointerPosition(string)
            break
        case SignalsType.Pointer_Hide.rawValue:
            handlePointerHide()
            break
        case SignalsType.Zoom_Scale.rawValue:
            handleZoomScale(string)
            break
        case SignalsType.Signature_Points.rawValue:
            handleSignaturePoints(string)
            break
        case SignalsType.Add_Text.rawValue:
            handleAddText(string)
            break
        case SignalsType.Ask_For_Photo.rawValue:
            handleAskForPhoto()
            break
        case SignalsType.Translate_And_Scale.rawValue:
            handleTranslateAndScale(string)
            break
        case SignalsType.Open_Rep_Box.rawValue:
            handleOpenBox(string)
            break
        case SignalsType.Text_Font_Change.rawValue:
            handleFontChange(string)
            break
        default:
            printLog("Couldn't find an event")
        }
    }

    func handleFontChange(string: String) {
        if let data = CallUtils.convertStringToDictionary(string) {
            
            // change default size according to image width
            // this will be the new size for each textbox
            // in each zoom event multiply this font in current zoom
            //
            
             // newSize = font size in relation to document
            // multiply default font size in scale
        }
    }
    
    func handleOpenBox(string: String) {

        if let box = CallUtils.convertStringToDictionary(string) {
            self.scrollView?.scrollEnabled = false
            var bounds = UIScreen.mainScreen().bounds.size
            if(UIDeviceOrientationIsLandscape(UIDevice.currentDevice().orientation)){
                bounds = CGSizeMake(max(bounds.height, bounds.width), min(bounds.height, bounds.width))
            }
            if(UIDeviceOrientationIsPortrait(UIDevice.currentDevice().orientation)){
                bounds = CGSizeMake(min(bounds.height, bounds.width), max(bounds.height, bounds.width))
            }
            //let h: CGFloat = 120
            let w: CGFloat = signPanelWidth
            let document = self.presentaionImage!.image!
            let top = box["top"] as! CGFloat*document.size.height
            let left = (box["left"] as! CGFloat)*document.size.width
            let width = box["width"] as! CGFloat*document.size.width
            let height = box["height"] as! CGFloat*document.size.height

            let scale = w/width
            //Image is aspect fit, scale factor will be the biggest change on image
            let scaleRatio = max(document.size.width/bounds.width, document.size.height/bounds.height)

            
            self.scrollView?.setZoomScale(scaleRatio*scale, animated: false)
            
            //One of these has to be 0
            let heightDiff = (bounds.height*scaleRatio*scale - document.size.height*scale)/2
            let widthDiff = (bounds.width*scaleRatio*scale - document.size.width*scale)/2
            
            let h = height*scale//min(height*scale, bounds.height*0.8)
            //let topOffset = max(0, height*scale - w/2)
            
            let X = left*scale+widthDiff-((bounds.width-w)/2)
            let Y = top*scale+heightDiff-((bounds.height-h)/2)
            
            signPanelHeight = height*scale
            self.scrollView?.contentOffset = CGPointMake(X - signPanelWidth/2 , Y - signPanelHeight/2)

            //self.signView?.frame = CGRectMake(0.5*(bounds.width-w), 0.5*(bounds.height-h), w, h)
            self.signView?.hidden = false

            self.signView?.center_x_constraint?.constant = 0
            self.signView?.center_y_constraint?.constant = 0
            self.signView?.height?.constant = signPanelHeight
            /*
            let x = data["top"] as! CGFloat // center point 0..1
            let y = data["left"] as! CGFloat // center point 0..1
            let width = data["width"] as! CGFloat // 0..1
            let height = data["height"] as! CGFloat // 0..1
            let showSignPanel = data["showSignPanel"] as! Bool
            let showTextPanel = data["showTextPanel"] as! Bool
            
            if ((showSignPanel == false) && (showTextPanel == false)) {
                return
            }
            
            let scaleRatio = getScaleRatio()
            let zoomScale = calculateScale(width, height: height, scaleRatio: scaleRatio, isSignPanel: showSignPanel ? true : false)
            scrollView?.setZoomScale(zoomScale, animated: false)
            
            let document = presentaionImage!.image!
            scrollView?.contentOffset = CGPoint(x: (document.size.width/scaleRatio)*x, y: (document.size.height/scaleRatio)*y)
*/
        }

    }
    
    func getScaleRatio() -> CGFloat {
        let screen = UIScreen.mainScreen().bounds
        let document = presentaionImage!.image!
        return max(document.size.width/screen.width, document.size.height/screen.height)
    }
    
    func calculateScale(width: CGFloat, height: CGFloat, scaleRatio: CGFloat, isSignPanel: Bool) -> CGFloat {

        let document = presentaionImage!.image!

        let containerWidth = document.size.width/scaleRatio
        let relativeWidth = containerWidth * width
        let objectWidth: CGFloat?
        
        if isSignPanel {
            objectWidth = signPanelWidth
        } else {
            objectWidth = textPanelWidth
        }
        
        let zoomScale = objectWidth! / relativeWidth
        
        return zoomScale
    }
    
    func handleTranslateAndScale(string: String) {
        if let data = CallUtils.convertStringToDictionary(string) {
            let x = data["translate"]!["x"] as! CGFloat
            let y = data["translate"]!["y"] as! CGFloat
            let imageWidth = data["image_width"] as! CGFloat
            let imageHeight = data["image_height"] as! CGFloat
            let scale = data["scale"] as! CGFloat
            
            let screen = UIScreen.mainScreen().bounds

            let new_x = (imageWidth*(scale - 1)/2) - x
            let new_y = (imageHeight*(scale - 1)/2) - y
            scrollView?.setZoomScale(scale, animated: false)
            
            let document = presentaionImage!.image!
            
            //Image is aspect fit, scale factor will be the biggest change on image

            let scaleRatio = getScaleRatio()
            let heightDiff = ((screen.height*scaleRatio) - document.size.height)/scaleRatio
            let widthDiff = ((screen.width*scaleRatio) - document.size.width)/scaleRatio

            var ratio = 0.0 as CGFloat
//            contentOffst = document.size.width/scaleRatio*top, document.size.height/scaleRatio * left
             // this is my conainer size document.size.width/scaleRatio
            // multiply everything by box width (0.1) i'm getting nagid 100 , default size is 200 -> zoom scale is 2
            if heightDiff == 0 {
                ratio = (document.size.width/scaleRatio)/imageWidth
            } else { // width
               ratio = (document.size.height/scaleRatio)/imageHeight
            }

            scrollView?.contentOffset = CGPoint(x: new_x*ratio, y: new_y*ratio)
            
        }
        
    }
    func sendMetaData() {
        let newDictionary = ["platform": "iosSDK"]
        CallUtils.sendJsonMessage(SignalsType.Send_Meta_Data.rawValue, data: newDictionary)
    }
    
    func loadResourcesWithIndex(string: String) {
        presentationWebView?.hidden = true
        presentationWebView?.loadHTMLString("", baseURL:nil)
        scrollView?.setZoomScale(1.0, animated: false)
        
        if let data = CallUtils.convertStringToDictionary(string) {

            currentDocument = data["document"] as? Int
            currentPage = data["page"] as? Int
            if let image = getImageAtIndex(currentDocument!, page: currentPage!){
                dispatch_async(dispatch_get_main_queue()){
                    self.presentaionImage.image = image
                }
            } else {
                setImageFromURL(data["url"] as! String, document: currentDocument!, page: currentPage!, completion: { (result) -> Void in
                    dispatch_async(dispatch_get_main_queue()){
                        self.presentaionImage.image = result
                    }
                    
                })
            }
        }
    }
    
    func preLoadResourcesWithIndex(string: String) {
        if string.isEmpty == false {
            if let data = CallUtils.convertStringToDictionary(string) {
                if nil == getImageAtIndex(data["document"] as! Int, page: data["page"] as! Int){
                    setImageFromURL(data["url"] as! String, document: data["document"] as! Int, page: data["page"] as! Int, completion: nil)
                }
            }
        }
    }
    
    func handleChatEvent(string: String) {
        if (self.chat != nil) {
            if (self.chat!.frame.origin.y > 10){
                addMessageToQ(string)
            } else {
                self.chat!.addChatBox(string, isSelf: false)
            }
        } else {
            addMessageToQ(string)
        }
    }
    
    func handleLineStart(string: String) {
//        if let point = getPointFromPointStr(string){
//            drawingView.moveToPoint(point)
//        }
    }
    
    func handleLinePoint(string: String) {
//        if let point = getPointFromPointStr(string){
//            drawingView.addPoint(point)
//        }
    }
    
    func handleLineClear() {
//        drawingView.cleanView()
    }
    
    func handlePointerPosition(string: String) {
//        if let point = getPointFromPointStr(string){
//            pointer.hidden = false
//            pointer.frame.origin = point
//        }
    }
    
    func handlePointerHide() {
//         pointer.hidden = true
    }
    
    func handleZoomScale(string: String) {
        let params = string.characters.split{$0 == "_"}.map { String($0) }
        
        scrollView?.setZoomScale(CGFloat((params[0] as NSString).floatValue), animated: false)
        var coordsStr = params[1].characters.split{$0 == ","}.map { String($0) }
        let x = (coordsStr[0] as NSString).floatValue
        let y = (coordsStr[1] as NSString).floatValue
        if let size =  scrollView?.contentSize {
            scrollView?.contentOffset = CGPoint(x: CGFloat(x) * size.width ,y: CGFloat(y) * size.height)
        }
    }
    
    func handleSignaturePoints(string: String) {
        
        if var data = CallUtils.convertStringToDictionary(string) {

            let document = presentaionImage!.image!

            var zoom = 1 as CGFloat
            if let val = data["zoom"] as? CGFloat {
                zoom = val
            } else {
                data["zoom"] = 1 as CGFloat
            }

          
            let originalScaling = getOriginalScaling(data)
            let signatureFrame = calculateFrameForView(data)
            
            let remoteSignatureView = PassiveLinearInterpView(frame: signatureFrame)

            let linesStr = data["points"]!.componentsSeparatedByString("***")
            for line in linesStr {
                var pointsStr = line.componentsSeparatedByString("-")
                for i in 0..<pointsStr.count {
                    if let p = getPointFromPointStr(pointsStr[i], scaleRatio: originalScaling,zoom: zoom){
                        if i == 0{
                            remoteSignatureView.moveToPoint(p)
                        } else {
                            remoteSignatureView.addPoint(p)
                        }
                    }
                }
            }
            
            let scaledSignImage = takeScreenshot(remoteSignatureView)
            drawObjectOnDocument(document, data: data, newViewFrame: remoteSignatureView.frame, newImage: scaledSignImage)

        } else {
            printLog("JSON conversion failed")
        }
    }
    
    func handleAddText(string: String) {
        if var data = CallUtils.convertStringToDictionary(string) {
            
            let document = presentaionImage!.image!

            var zoom = 1 as CGFloat
            if let val = data["zoom"] as? CGFloat {
                zoom = val
            } else {
                data["zoom"] = 1 as CGFloat
            }
            

            let originalScaling = getOriginalScaling(data)
            let textFrame = calculateFrameForView(data)

            let remoteTextView = UITextField(frame: textFrame)
            
            let fontSize = data["font_size"] as! CGFloat
            let text = data["text"] as! String
            
            remoteTextView.text = text
            remoteTextView.font = remoteTextView.font!.fontWithSize(fontSize*originalScaling/zoom)
            
            let scaledTextImage = takeScreenshot(remoteTextView)
            drawObjectOnDocument(document, data: data, newViewFrame: remoteTextView.frame, newImage: scaledTextImage)
            
        }
    }
    
    func handleAskForPhoto() {
        CallUtils.doUnpublish()
        
        imagePicker.sourceType = .Camera
        ViewUtils.getTopViewController()!.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    // MARK: set image methods
    
    func setImageAtIndex(image: UIImage, document: Int, page: Int){
        while preLoadedImages.count < document+1{
            preLoadedImages.append([:])
        }
        
        self.preLoadedImages[document][page] = image
    }
    
    func setImageFromURL(url: String, document: Int, page: Int, completion: ((result: UIImage) -> Void)?) -> Void{
        while preLoadedImages.count < document+1{
            preLoadedImages.append([:])
        }
        if let url = NSURL(string: url){
            NetworkUtils.getDataFromUrl(url) { data in
                if let image = UIImage(data: data!){
                    self.preLoadedImages[document][page] = image
                    completion?(result: image)
                }
            }
        }
    }
    
    func getImageAtIndex(document: Int, page: Int) -> UIImage?{
        if preLoadedImages.count > document{
            if let value = self.preLoadedImages[document][page]{
                return value
            }
        }
        return nil
    }
    
    // MARK: draw new object on view methods
    func calculateFrameForView(data: [String:AnyObject]) -> CGRect {

        let zoom = data["zoom"] as! CGFloat
        let width = data["width"] as! CGFloat / zoom
        let height = data["height"] as! CGFloat / zoom

        //Image is aspect fit, scale factor will be the biggest change on image
        let originalScaling = getOriginalScaling(data)
        
        let frame = CGRectMake(0,0,width*originalScaling,height*originalScaling)
        
        return frame
        
    }
    
    func getOriginalScaling(data: [String:AnyObject]) -> CGFloat {
        
        let document = presentaionImage!.image!
        let screenWidth = data["image_width"] as! CGFloat
        let screenHeight = data["image_height"] as! CGFloat

        //Image is aspect fit, scale factor will be the biggest change on image
        return max(document.size.width/screenWidth, document.size.height/screenHeight)
    }
    
    
    // Called from add text / add signature event
    func takeScreenshot(view: UIView) -> UIImage{
        UIGraphicsBeginImageContext(view.frame.size)
        view.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    func drawObjectOnDocument(document:UIImage, data: [String:AnyObject], newViewFrame: CGRect, newImage: UIImage) {
        
        let x = data["left"] as! CGFloat
        let y = data["top"] as! CGFloat
        
        UIGraphicsBeginImageContext(document.size)
        document.drawInRect(CGRectMake(0,0,document.size.width, document.size.height))
        newImage.drawInRect(CGRectMake((x*document.size.width),(y*document.size.height),newViewFrame.width, newViewFrame.height))
        let signedDoc = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let image: UIImage = signedDoc
        self.presentaionImage?.image = image
        
        if currentPage != nil && currentDocument != nil {
            setImageAtIndex(image, document: currentDocument!, page: currentPage!)
        }
    }
    
    func getPointFromPointStr(pointStr: String, scaleRatio: CGFloat, zoom: CGFloat?)-> CGPoint?{
        
        if pointStr.containsString(","){
            
            var coordsStr = pointStr.characters.split{$0 == ","}.map { String($0) }
            let x = (coordsStr[0] as NSString).floatValue
            let y = (coordsStr[1] as NSString).floatValue

            if zoom != nil {
                return CGPoint(x: CGFloat(x)/zoom!  * scaleRatio,y: CGFloat(y)/zoom! * scaleRatio)
            } else {
                let screen =  UIScreen.mainScreen().bounds
                return CGPoint(x: CGFloat(x) * screen.width ,y: CGFloat(y) * screen.height)
            }
            
        } else {
            return nil
        }
    }
    
}
