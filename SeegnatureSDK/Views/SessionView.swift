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
let signPanelWidth: CGFloat = UIScreen.mainScreen().bounds.width * 0.8
var signPanelHeight: CGFloat = 140

class SessionView: UIView, UIGestureRecognizerDelegate, UIScrollViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, FileSelectorDelegate {

    @IBOutlet weak var presentationWebView: UIWebView?
    @IBOutlet weak var presentaionImage: UIImageView!
    @IBOutlet weak var drawingView: LinearInterpView!

    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var chatButton: UIButton!
    @IBOutlet weak var toggleVideoButton: UIButton!
    @IBOutlet weak var toggleSoundButton: UIButton!
    @IBOutlet weak var endButton: UIButton!
    @IBOutlet weak var chatBadge: UILabel!

    @IBOutlet weak var activity: UIActivityIndicatorView!
    
//    @IBOutlet weak var companyLogo: UIImageView! // client only
    @IBOutlet weak var pointer: NIKFontAwesomeButton!
    @IBOutlet weak var scrollView: TouchUIScrollView!
    @IBOutlet weak var toggleToolsButton: NIKFontAwesomeButton!
    
    @IBOutlet weak var controlPanelBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var sideViewLeadingConst: NSLayoutConstraint!
    @IBOutlet weak var sideView: UIView!
    @IBOutlet weak var toggleControllPanelButton: NIKFontAwesomeButton!
    
    var currentSession: Session?

    var preLoadedImages = Array<Document>()
    var currentImage: UIImage?
    var currentImageUrl: String?
    var currentDocument = 0
    var currentPage = 0
    var modifiedImages: Dictionary<String, UIImage?> = [:]
    
    var isDragging = false
    var dragOffset: CGPoint?
    var signView: SignDocumentPanelView?
    var addTextView: TextDocumentPanelView?
    
    var controlPanelTimer: NSTimer?
    var controlPanelHidden = false

    
    var publisherSizeConst: [NSLayoutConstraint]?
    var publisherPositionConst : Dictionary<String, NSLayoutConstraint>?
    
    let SubscribeToSelf = false

    var imagePicker = UIImagePickerController()
    
    var isFirstLoad = true
    
    var sentRemoteSideData = false
    
    // chat
    var messageQ : NSArray = []
    var isChatShown = false
    var chat: ChatView?
    
    
    // for rep
    var resources: Array<Dictionary<String, AnyObject>>? // only for rep
    var fileSelector: FileSelector!
    var isChangingPresentation = false
    var selectedResIndex = 0
    var displayResources: NSArray?
    var currentImageIndex = 0
    var showNextSlide = false
    var drawingMode = false
    var toolsPanelHidden = true
    
    // MARK: - init methods
    
    override func awakeFromNib() {
        
        setControlPanel()
        
        setImagePicker()
        
        self.scrollView?.delegate = self
        
        setGradient()
        
        addScreenRotationNotification()
        
    }

    override func willMoveToSuperview(newSuperview: UIView?) {
        var val = true
        if Session.sharedInstance.disconnectingCall == true {
            val = false
        }
        self.parentViewController?.navigationController?.navigationBarHidden = val
    }

    func initClientSession() {
        self.toggleToolsButton.hidden = true
        addClientGestures()
    }
    
    
    func appMovedToBackground() {
        print("moved to background", terminator: "")
        CallUtils.publisher?.publishVideo = false
    }
    
    func appMovedToForeground() {
        print("moved to foreground", terminator: "")
        CallUtils.publisher?.publishVideo = true
    }
    
    // called on first load
    func initDocument() {
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SessionView.appMovedToBackground), name: UIApplicationWillResignActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SessionView.appMovedToForeground), name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        self.presentationWebView?.stopLoading()
        if self.currentSession?.isRep == true {
            initRepSession()
        } else {
            initClientSession()
        }
        
        addCustomViews()
        ViewUtils.addGradientLayer(bottomView, topColor: UIColor(red:0.1/255, green:0.1/255, blue:0.1/255, alpha:0.0), bottomColor: UIColor(red:0.1/255, green:0.1/255, blue:0.1/255, alpha:0.9))
        
        showControlPanel()
        
        isFirstLoad = false
    }
    
    func initRepSession() {
        if isFirstLoad {
            addRepGestures()
            scrollView.parent = self.parentViewController!
            
            fileSelector = FileSelector(viewController: self.parentViewController!)
            fileSelector.delegate = self
            changeDisplayResource(0)
            
            resources = resources?.filter({ (resource) -> Bool in
                if let type = resource["type"] as? Int{
                    return type == 1
                } else {
                    return false
                }
            })
            
            self.bottomView.layoutIfNeeded()
            ViewUtils.cornerRadius(toggleControllPanelButton, corners: [.TopLeft, .TopRight], cornerRadius: 20.0)
            ViewUtils.cornerRadius(toggleToolsButton, corners: [.BottomRight, .TopRight], cornerRadius: 10.0)
            ViewUtils.roundView(chatBadge, borderWidth: 1.0, borderColor: UIColor.whiteColor())
            if ((currentImage) != nil){
                presentaionImage?.image = currentImage
            }
            
            sideView.translatesAutoresizingMaskIntoConstraints = false
            bottomView.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    // MARK: - screen rotation
    func addScreenRotationNotification() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SessionView.screenRotated), name: UIDeviceOrientationDidChangeNotification, object: nil)
    }
    
    func screenRotated() {
        NSTimer.scheduledTimerWithTimeInterval(NSTimeInterval(0.1), target: self, selector: #selector(SessionView.rotateScreen), userInfo: AnyObject?(), repeats: false)
    }
    
    func rotateScreen() {
        if let data = self.signView?.last_open_box_info {
            handleOpenBox(data)
        }
        
        if let data = self.addTextView?.last_open_box_info {
            handleOpenBox(data)
        }
    }
    
    // MARK: - rep methods
    
    // Rep -> called when changing resource
    func changeDisplayResource(index: Int) {
        if preLoadedImages.count <= index{
            if !isChangingPresentation {
                if self.resources?.count > 0{
                    if let resource = self.resources?[index]{
                        if (resource["type"] as! NSNumber == 1){
                            if let resourceId = resource["id"] as? NSNumber {
                                isChangingPresentation = true
                                activity.startAnimating()
                                ServerAPI.sharedInstance.getResourceDisplay(resourceId, completion: { (result) -> Void in
                                    if result.count > 0 {
                                        self.displayResources = result
                                    } else {
                                        self.displayResources = nil
                                    }
                                    if let dispRes = self.displayResources?[0] as? NSDictionary{
                                        self.loadImage(dispRes["id"] as! NSNumber)
                                    }
                                    if self.currentSession!.isRep == true {
                                        self.preLoadDisplayResources({
                                            if self.sentRemoteSideData == false {
                                                self.remoteSideConnected()
                                            }
                                        })
                                    }
                                })
                            }
                        }
                    }
                }
            }
        } else {
            let doc = getDocumentById(preLoadedImages[index].id!)
            ServerAPI.sharedInstance.getResourceDisplay(doc.id!, completion: { (result) -> Void in
                if result.count > 0 {
                    self.displayResources = result
                } else {
                    self.displayResources = nil
                }
                if let dispRes = self.displayResources?[0] as? NSDictionary{
                    self.loadImage(dispRes["id"] as! NSNumber)
                }
                if self.currentSession!.isRep == true {
                    self.preLoadDisplayResources({
                        if self.sentRemoteSideData == false {
                            self.remoteSideConnected()
                        }
                    })
                }
            })
        }
    }

    func loadImage(imageFile: NSNumber){
        ServerAPI.sharedInstance.getFileUrl(imageFile, completion: { (result) -> Void in
            self.currentImageUrl = result as String
            let url = NSURL(string: result as String)
            if let data = NSData(contentsOfURL: url!){
                dispatch_async(dispatch_get_main_queue()){
                    self.presentaionImage?.image = UIImage(data: data)
                    self.isChangingPresentation = false
                    self.activity.stopAnimating()
                }
            }
        })
    }
    
    // rep only
    func preLoadImage(imageFile: NSNumber, index: Int){
        ServerAPI.sharedInstance.getFileUrl(imageFile, completion: { (result) -> Void in
            let scopeIndex = index
            let scopeSelectedResIndex = self.selectedResIndex
            let url = NSURL(string: result as String)
            let data = ["page": scopeIndex,
                "document": self.getSelectedResourceId(scopeSelectedResIndex),
                "url": result as String] as Dictionary<String, AnyObject>
            let documentId = self.getSelectedResourceId(scopeSelectedResIndex) as Int
            CallUtils.sendJsonMessage("preload_res_with_index", data: data)
            if url != nil {
                self.fileSelector.getDataFromUrl(url!) { data in
                    if data != nil{
                        self.addPageToDocument(documentId, pageIndex: index, image: UIImage(data: data!)!, url: result as String, pageId: imageFile as Int)
                        dispatch_async(dispatch_get_main_queue()){
                            if self.showNextSlide {
                                self.activity.stopAnimating()
                                self.showNextSlide = false
                                self.next(UISwipeGestureRecognizer())
                            }
                        }
                    }
                }
            }
        })
    }
    
    // MARK: - on remote side connected
    func remoteSideConnected() {
        if self.currentSession?.isRep == true {
            handleRemoteSideConnectedAsClient()
        } else {
            handleRemoteSideConnectedAsRep()
        }
    }
    
    func handleRemoteSideConnectedAsClient() {

        if preLoadedImages.isEmpty {
            return
        }
        
        sendMetaDataRequest([:])
        sendLoadResWithIndexRequest(currentPage)
        sendPreloadResRequest()
        sendFontChange()
        sentRemoteSideData = true
    }
    

    
    func handleRemoteSideConnectedAsRep() {

    }
    
    // MARK: - uiscrollview delegate
    
    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView?, atScale scale: CGFloat) {
        sendTranslateAndScale()
        self.addTextView!.setFontSize(getScaleRatio(), zoom: scrollView.zoomScale, documentWidth: self.presentaionImage!.image!.size.width)
        sendFontChange()
    }

    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        sendTranslateAndScale()
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if ((self.signView?.hidden == false) || (self.addTextView?.hidden == false)) {
            scrollView.scrollEnabled = false
        } else {
            if scrollView.zoomScale != 1.0 {
                scrollView.scrollEnabled = true
            } else {
                scrollView.scrollEnabled = false
            }
        }

    }
    
    // MARK: - tap gestures handlers
    
    // swipe right: move to next page
    func next(sender: UISwipeGestureRecognizer) {

        if scrollView.zoomScale != 1 {
            return
        }
        
        if self.isDragging || self.drawingMode || !signView!.hidden || !addTextView!.hidden {
            return
        }
        if (currentImageIndex+1 == preLoadedImages[selectedResIndex].pages.count){
            return
        }
        if let document = preLoadedImages[safe: selectedResIndex] {
            if let page = self.getPageByIndex(document, index: currentImageIndex+1) {
                currentImageIndex += 1
                self.presentaionImage?.image = page.image
                currentPage += 1
                if let urlStr = page.url {
                    let data = ["page": self.currentImageIndex,
                        "document": self.getSelectedResourceId(),
                        "url": urlStr] as Dictionary<String, AnyObject>
                    CallUtils.sendJsonMessage("load_res_with_index", data: data)
                }
            }
        } else {
            showNextSlide = true
            activity.startAnimating()
        }
    }
    
    // swipe left: move to previous page
    func prev(sender: UISwipeGestureRecognizer) {
        
        if scrollView.zoomScale != 1 {
            return
        }
        
        if self.isDragging || self.drawingMode || !signView!.hidden || !addTextView!.hidden {
            return
        }
        
        if currentImageIndex <= 0{
            return
        }
        
        if let document = preLoadedImages[safe: selectedResIndex] {
            if let page = self.getPageByIndex(document, index: currentImageIndex-1) {
                if let image = page.image {
                    currentImageIndex -= 1
                    self.presentaionImage.image = image
                    currentPage -= 1
                    if let urlStr = page.url{
                        let data = ["page": self.currentImageIndex,
                            "document": self.getSelectedResourceId(),
                            "url": urlStr] as Dictionary<String, AnyObject>
                        CallUtils.sendJsonMessage("load_res_with_index", data: data)
                    }
                }
            }
        }
    }
    
    // swipe up: move to previous document
    func up(sender: UISwipeGestureRecognizer) {
        
        if scrollView.zoomScale != 1 {
            return
        }
        
        let old = selectedResIndex
        if self.isDragging || self.drawingMode || !signView!.hidden || !addTextView!.hidden {
            return
        }
        if (selectedResIndex+1 >= self.resources?.count){
            selectedResIndex = -1
        }
        selectedResIndex += 1
        if old != selectedResIndex{
            currentImageIndex = -1
            changeDisplayResource(selectedResIndex)
        }
    }
    
    // swipe down: move to next document
    func down(sender: UISwipeGestureRecognizer) {
        
        if scrollView.zoomScale != 1 {
            return
        }
        
        let old = selectedResIndex
        if self.isDragging || self.drawingMode || !signView!.hidden || !addTextView!.hidden {
            return
        }
        if selectedResIndex <= 0{
            selectedResIndex = self.resources!.count
        }
        selectedResIndex -= 1
        if old != selectedResIndex{
            currentImageIndex = -1
            changeDisplayResource(selectedResIndex)
        }
    }
    
    // long tap: open sign panel on client's side.
    func longTap(sender: UILongPressGestureRecognizer){
        if sender.state == .Began {
            openInputPanelOnRemote(sender, panelType: PanelType.sign_panel)
        }
    }
    
    // double tap: open text panel on client's side
    func doubleTap(sender: UITapGestureRecognizer) {
        openInputPanelOnRemote(sender, panelType: PanelType.text_panel)
    }

    
    @IBAction func togglePanelButtonTapped(sender: AnyObject) {
        if (controlPanelHidden == true) {
            showControlPanel()
        } else {
            hideControlPanel()
        }
    }
    
    
    func getSelectedResourceId() ->NSNumber{
        if let id = self.resources?[selectedResIndex]["id"] as? NSNumber{
            return id
        }
        return selectedResIndex
    }
    
    func getSelectedResourceId(index: Int) ->NSNumber{
        if let id = self.resources?[index]["id"] as? NSNumber{
            return id
        }
        return selectedResIndex
    }
    
    // only rep
    func preLoadDisplayResources(completion: () -> Void) {
        if let resources = displayResources {
            if preLoadedImages[safe: selectedResIndex] == nil {
                for index in 0..<resources.count {
                    if let dispRes = resources[index] as? NSDictionary{
                        self.preLoadImage(dispRes["id"] as! NSNumber, index: index)
                    }
                }
            }
        }
    }
    

    
    func fileSelected(file: File) {
        ServerAPI.sharedInstance.uploadFile(file.data!, filename: file.name!, mimetype: file.mimetype) { (result) -> Void in
            if let fileId = result["id"] as? Int{
                let fileUrl = result["url"] as! String
                let callId = CallUtils.currentCall!["id"] as! Int
                let res : Dictionary<String, AnyObject> = ["name": "\(file.name!) for call \(callId)",
                    "type": 1,
                    "url": fileUrl,
                    "file": fileId
                ]
                ServerAPI.sharedInstance.newResource(res, completion: { (result) -> Void in
                    if let newDocDictionary = result as? Dictionary<String, AnyObject> {
                        self.resources?.append(newDocDictionary)
                        let _ = self.addNewDocument(result as! Dictionary<String, AnyObject>)
                        self.down(UISwipeGestureRecognizer())
                    }
                })
            }
        }
    }
    
    // MARK: input panels
    
    func addCustomViews() {
        if self.signView == nil {
            setSignView()
        }

        if self.addTextView == nil {
            setTextBox()
        }
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
    
    func showVideo(view: UIView){
        self.addSubview(view)
        view.addConstraintsToSuperview(self, top: 0.0, left: nil, bottom: nil, right: 0.0)
        view.addSizeConstaints(videoWidth, height: videoHeight)
        
        if let pubView = CallUtils.publisher?.view {
            
            pubView.removeFromSuperview()
            view.addSubview(pubView)
            pubView.addConstraintsToSuperview(view, top: nil, left: nil, bottom: 0.0, right: 0.0)
            publisherSizeConst = pubView.addSizeConstaints(videoWidth, height: videoHeight)
            NSTimer.scheduledTimerWithTimeInterval(NSTimeInterval(3), target: self, selector: #selector(SessionView.shrinkPublisher), userInfo: AnyObject?(), repeats: false)
        }
    }
    
    func openPublishDialog(view: UIView?){
        let caller = CallUtils.currentCall?["caller"] as? NSDictionary
        let firstName = caller!["user"]!["first_name"] as! String
        
        let alertController = UIAlertController(title: "Incoming Video", message: "\(firstName) is calling you", preferredStyle: .Alert)
        
        let yesAction = UIAlertAction(title: "ANSWER", style: .Default) { (action:UIAlertAction) in
            print("Yes button pressed", terminator: "")
            CallUtils.doPublish()
            if let streamView = view{
                self.showVideo(streamView)
            }
            
        }
        
        let noAction = UIAlertAction(title: "DECLINE", style: .Default) { (action:UIAlertAction) in
            print("No button pressed", terminator: "");
        }
        
        alertController.addAction(yesAction)
        alertController.addAction(noAction)
        self.parentViewController!.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func subscriberDidConnectToStream() {
        
        if CallUtils.screenSubscriber?.stream.videoType == OTStreamVideoType.Screen {
            if let view = CallUtils.screenSubscriber?.view {
                self.addSubview(view)
                let screenSize: CGRect = UIScreen.mainScreen().bounds
                let ratio = CallUtils.subscriber!.stream.videoDimensions.height/CallUtils.subscriber!.stream.videoDimensions.width
                view.addSizeConstaints(screenSize.width, height: screenSize.width*ratio)
                view.setConstraintesToCenterSuperView(self)
            }
        } else if let view = CallUtils.subscriber?.view {
            if self.currentSession?.isRep == true{
                CallUtils.doPublish()
                showVideo(view)
            } else {
                openPublishDialog(view)
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
            ViewUtils.roundView(chatBadge, borderWidth: 1.0, borderColor: UIColor.whiteColor())
            if ((currentImage) != nil){
                presentaionImage?.image = currentImage
            }
            self.isFirstLoad = false
        }
    }

    // MARK: - Rep tools panel methods
    @IBAction func toggleToolsPanel(sender: AnyObject) {
        if (toolsPanelHidden == true) {
            showRepToolsPanel()
        } else {
            hideRepToolsPanel()
        }
    }
    
    func showRepToolsPanel() {
        self.toolsPanelHidden = false
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.sideViewLeadingConst.constant = 0
            self.layoutIfNeeded()
        })
    }
    
    func hideRepToolsPanel() {
        if let controls = self.sideView {
            UIView.animateWithDuration(0.5, animations: { () -> Void in
                self.sideViewLeadingConst.constant = controls.frame.width
                self.layoutIfNeeded()
            })
        }
        toolsPanelHidden = true
    }
    
    @IBAction func deleteChanges(sender: AnyObject) {
        let callId = CallUtils.currentCall!["id"] as! Int
        let documentId = self.preLoadedImages[currentDocument].id!
        let page = currentPage
        if let url = getCurrentPage(page)?.url {
            let newDictionary: Dictionary<String, AnyObject>  = ["callId": callId, "document": documentId, "page": page, "url": url]
            if let document = preLoadedImages[safe: selectedResIndex] {
                if let page = self.getPageByIndex(document, index: currentImageIndex) {
                    self.presentaionImage?.image = page.image
                }
            }
            ServerAPI.sharedInstance.deletePartialDocument(["call": callId, "document_id": documentId, "page_number": page], completion: { (result) in
                //
            })
            CallUtils.sendJsonMessage(SignalsType.Clean_Page.rawValue, data: newDictionary)
        }
        
        
        hideRepToolsPanel()
    }
    
    @IBAction func openDropbox(sender: NIKFontAwesomeButton) {
        fileSelector.selectFile(sender)
    }
    
    @IBAction func openWebPage(sender: NIKFontAwesomeButton) {
        
        let urlAddress = "https://www.google.com";
        let url = NSURL(string: urlAddress)
        let requestObj = NSURLRequest(URL: url!)
        
        self.presentationWebView?.loadRequest(requestObj)
        self.presentationWebView!.hidden = false
        CallUtils.doScreenPublish(presentationWebView!)
        
    }
    
    func showDropboxItem(url: NSURL!){
        if let data = NSData(contentsOfURL: url){
            self.presentationWebView!.loadData(data, MIMEType: "application/pdf", textEncodingName: "ISO-8859-1", baseURL: url)
            self.presentationWebView!.hidden = false
            CallUtils.doScreenPublish(presentationWebView!)
        }
    }
    
    func showVideoItem(url: String){
        stopSharing()
        var embedHTML = "<html><head>"
        embedHTML += "<style type=\"text/css\">"
        embedHTML += "body {"
        embedHTML += "background-color: transparent;color: white;}</style></head><body style=\"margin:0; position:absolute; top:50%; left:50%; -webkit-transform: translate(-50%, -50%);\"><embed webkit-playsinline id=\"yt\" src=\"\(url)\" type=\"application/x-shockwave-flash\"width=\"\(320)\" height=\"\(300)\"></embed></body></html>"
        
        
        self.presentationWebView!.loadHTMLString(embedHTML, baseURL:nil)
        self.presentationWebView!.hidden = false
        var maybeError : OTError?
        CallUtils.session?.signalWithType("load_video", string: url + "?autoplay=1&fs=1", connection: nil, error: &maybeError)
    }
    
    @IBAction func lockDocument(sender: NIKFontAwesomeButton) {
        ViewUtils.showAlert("Lock Request", message: "A lock request has been sent to the client")
        CallUtils.sendJsonMessage(SignalsType.Ask_To_Lock.rawValue, data: [:])
    }
    
    @IBAction func stopSharing(sender: NIKFontAwesomeButton) {
        stopSharing()
    }
    
    func hideDocumentImage() {
        self.presentaionImage.hidden = true
    }
    
    func showDocumentImage() {
        self.presentaionImage.hidden = false
    }
    
    func stopSharing(){
        CallUtils.doScreenUnpublish()
        self.presentationWebView?.hidden = true
        var maybeError : OTError?
        CallUtils.session?.signalWithType("unload_video", string: "", connection: nil, error: &maybeError)
        self.presentationWebView?.loadHTMLString("", baseURL:nil)
    }
    
    // MARK: - drawing tool methods (disabled)
    @IBAction func toggleDrawingMode(sender: NIKFontAwesomeButton) {
        if self.drawingMode {
            drawingMode = false
            drawingView.enabled = false
            drawingView.userInteractionEnabled = false
            sender.color = UIColor.whiteColor()
            //self.view.sendSubviewToBack(drawingView)
            if (self.subviews[3] as NSObject == drawingView){
                self.exchangeSubviewAtIndex(2, withSubviewAtIndex: 3)
            }
            
        } else {
            drawingMode = true
            drawingView.enabled = true
            drawingView.userInteractionEnabled = true
            sender.color = UIColor.blueColor()
            if (self.subviews[2] as NSObject == drawingView){
                self.exchangeSubviewAtIndex(2, withSubviewAtIndex: 3)
            }
            //self.view.bringSubviewToFront(drawingView)
        }
    }
    
    @IBAction func cleanDrawing(sender: AnyObject) {
        drawingView.cleanView()
        var maybeError : OTError?
        CallUtils.session?.signalWithType("line_clear", string: "", connection: nil, error: &maybeError)
    }
    
    // MARK: - scrollview methods
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return presentaionImage
    }

    // MARK: - control panel
    
    func setControlPanel() {
        controlPanelTimer = NSTimer.scheduledTimerWithTimeInterval(NSTimeInterval(5), target: self, selector: #selector(SessionView.hideControlPanel), userInfo: AnyObject?(), repeats: false)
    }
    
    func showControlPanel(){
        self.controlPanelHidden = false
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.controlPanelBottomConstraint.constant = 0
            self.layoutIfNeeded()
        })
        controlPanelTimer?.invalidate()
        controlPanelTimer = NSTimer.scheduledTimerWithTimeInterval(NSTimeInterval(3), target: self, selector: #selector(SessionView.hideControlPanel), userInfo: AnyObject?(), repeats: false)
    }

    func hideControlPanel(){
        if let controls = bottomView {
            UIView.animateWithDuration(0.5, animations: { () -> Void in
                self.controlPanelBottomConstraint.constant = -controls.frame.height
                self.layoutIfNeeded()
            })
        }
        controlPanelHidden = true
    }
    
    // MARK: - gestures methods
    
    func addClientGestures() {
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action:#selector(SessionView.tap(_:))))
    }
    
    func addRepGestures() {
        UIEventRegister.gestureRecognizer(self, rightAction:#selector(SessionView.prev(_:)), leftAction: #selector(SessionView.next(_:)), upAction: #selector(SessionView.up(_:)), downAction: #selector(SessionView.down(_:)))
        let longTapReco = UILongPressGestureRecognizer(target: self, action: #selector(SessionView.longTap(_:)))
        longTapReco.cancelsTouchesInView = false
        self.addGestureRecognizer(longTapReco)
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(SessionView.doubleTap(_:)))
        doubleTap.cancelsTouchesInView = false
        doubleTap.numberOfTapsRequired = 2
        self.addGestureRecognizer(doubleTap)
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action:#selector(SessionView.tap(_:))))
    }

    func tap(sender:  UITapGestureRecognizer) {
        if signView?.hidden == false {
            if (!CGRectContainsPoint(signView!.frame, sender.locationInView(self))){
                self.signView?.hidden = true
                if self.currentSession?.isRep == true {
                    sendCloseBoxRequest(false)
                }
            }
        } else if addTextView?.hidden == false {
            if (!CGRectContainsPoint(addTextView!.frame, sender.locationInView(self))){
                self.addTextView?.hidden = true
                if self.currentSession?.isRep == true {
                    sendCloseBoxRequest(true)
                }
            }
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
                if signView?.hidden == false  && self.signView?.isOpenedOnRemoteSide != true{
                    dragOffset = touch.locationInView(signView) as CGPoint
                }
                if addTextView?.hidden == false && self.addTextView?.isOpenedOnRemoteSide != true{
                    dragOffset = touch.locationInView(addTextView) as CGPoint
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
        print("CANCEL", terminator: "")
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
            if signView?.hidden == false  && self.signView?.isOpenedOnRemoteSide != true{
                self.signView?.center_x_constraint?.constant = touchLocation.x - (self.frame.width - signPanelWidth)/2 - dragOffset!.x
                self.signView?.center_y_constraint?.constant = touchLocation.y - (self.frame.height - signPanelHeight)/2 - dragOffset!.y
            }
            if addTextView?.hidden == false && self.addTextView?.isOpenedOnRemoteSide != true{
                self.addTextView?.center_x_constraint?.constant = touchLocation.x - (self.frame.width - textPanelWidth)/2 - dragOffset!.x
                self.addTextView?.center_y_constraint?.constant = touchLocation.y - (self.frame.height - textPanelHeight)/2 - dragOffset!.y
            }
        }
    }
    
    // MARK: - image picker methods
    
    func setImagePicker() {
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
    }
    
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: NSDictionary!){
        
        CallUtils.publisher?.publishVideo = true
        
        ViewUtils.getTopViewController()!.dismissViewControllerAnimated(true, completion: { () -> Void in
            if let id = CallUtils.currentCall?["id"] as? NSNumber{
                let newName = "\(id)_Id_Image.jpg"
                showSpinner("Uploading file")
                ServerAPI.sharedInstance.uploadFile(UIImageJPEGRepresentation(image, 1.0)!, filename: newName) { (result) -> Void in
                    hideSpinner()
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

    // MARK: - handle buttons events
    
    @IBAction func signButtonPressed(sender: AnyObject) {
        self.signView!.hidden = !self.signView!.hidden
    }
    
    @IBAction func textButtonPressed(sender: AnyObject) {
        self.addTextView!.hidden = !self.addTextView!.hidden
    }
    
    @IBAction func chatButtonPressed(sender: AnyObject) {
        self.hideControlPanel()
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
            UIView.animateWithDuration(0.4, animations: { () -> Void in
                self.chat!.frame.origin.y = 0.0
            })
        }
    }
    
    @IBAction func videoButtonPressed(sender: AnyObject) {
        if let pVideo = CallUtils.publisher?.publishVideo{
            CallUtils.publisher?.publishVideo = !pVideo
            if (!pVideo){
                if let image = ViewUtils.loadUIImageNamed("video_on_icon") {
                    self.toggleVideoButton.setImageForAllStates(image)
                }
                if let view = CallUtils.publisher?.view {
                    if let subView = CallUtils.subscriber?.view{
                        subView.addSubview(view)
                        publisherPositionConst = view.addConstraintsToSuperview(subView, top: nil, left: nil, bottom: 0.0, right: 0.0)
                        publisherSizeConst = self.addSizeConstaints(videoWidth, height: videoHeight)
                        NSTimer.scheduledTimerWithTimeInterval(NSTimeInterval(3), target: self, selector: #selector(SessionView.shrinkPublisher), userInfo: AnyObject?(), repeats: false)
                    } else {
                        self.addSubview(view)
                        self.addConstraintsToSuperview(self, top: 0.0, left: nil, bottom: nil, right: 0.0)
                        self.addSizeConstaints(videoWidth, height: videoHeight)
                    }
                }
            } else {
                if let image = ViewUtils.loadUIImageNamed("video_off_icon") {
                    toggleVideoButton.setImageForAllStates(image)
                }

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
                if let image = ViewUtils.loadUIImageNamed("audio_on_icon") {
                    toggleSoundButton.setImageForAllStates(image)
                }
            } else {
                if let image = ViewUtils.loadUIImageNamed("audio_off_icon") {
                    toggleSoundButton.setImageForAllStates(image)
                }
            }
        }
    }
    
    @IBAction func endButtonPressed(sender: AnyObject) {
        Session.sharedInstance.disconnectingCall = true
        CallUtils.stopCall()
        CallUtils.incomingViewController = nil
        self.preLoadedImages.removeAll()
        self.removeFromSuperview()
        removeObservers()
        Session.sharedInstance.disconnectingCall = false
        self.parentViewController?.navigationController?.navigationBarHidden = false
    }
    
    func removeObservers() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - chat methods
    
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
    
    // TODO: put this somewhere else
    func closeOpenPanels(){
        self.signView?.hidden = true
        self.addTextView?.hidden = true
    }
    
    // MARK: - insert signature methods
    
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
        
        setImageAtIndex(image, document: currentDocument, page: currentPage)

        newDictionary["call"] = CallUtils.currentCall!["id"] as! NSNumber
        newDictionary["page_number"] = self.currentPage
        newDictionary["document_id"] = self.currentDocument
        newDictionary["tracking"] = randomStringWithLength(16)
        newDictionary["type"] = "signature"

        ServerAPI.sharedInstance.newModification(newDictionary, completion: { (result) -> Void in })
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
    
    func onTextAdded(textView: UITextField, origin: CGPoint, textHeightOffset: CGFloat, textHeight: CGFloat){

        let screen =  UIScreen.mainScreen().bounds
        let zoom = scrollView!.zoomScale
        let document = presentaionImage!.image!
        
        //Image is aspect fit, scale factor will be the biggest change on image
        let scaleRatio = max(document.size.width/screen.width, document.size.height/screen.height)
        let X = (origin.x+scrollView!.contentOffset.x)/zoom
        let Y = (origin.y+scrollView!.contentOffset.y)/zoom
        
        let Y_with_offset = (origin.y+scrollView!.contentOffset.y+textHeightOffset)/zoom
        
        //One of these have to be 0
        let heightDiff = (screen.height*scaleRatio) - document.size.height
        let widthDiff = (screen.width*scaleRatio) - document.size.width
        
        sendAddedText(textView,
                      origin:CGPointMake((X*scaleRatio)-widthDiff/2,(Y_with_offset*scaleRatio)-heightDiff/2),
                      imgSize:CGSizeMake( document.size.width, document.size.height),
                      scaleRatio: scaleRatio,
                      zoom:zoom,
                      textHeight: textHeight)
        
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
        
        setImageAtIndex(image, document: currentDocument, page: currentPage)
        
    }
    
    func sendAddedText(textView: UITextField, origin: CGPoint, imgSize: CGSize, scaleRatio: CGFloat, zoom: CGFloat, textHeight: CGFloat){
        
        var newDictionary: Dictionary<String, AnyObject>  =
        
        ["width": textView.frame.width, "height": textView.frame.height,
            "left": origin.x/imgSize.width, "top": origin.y/imgSize.height,
            "image_width": (imgSize.width/scaleRatio)*zoom, "image_height": (imgSize.height/scaleRatio)*zoom,
            "zoom": zoom, "text": textView.text!, "font_size": Int(textView.font!.pointSize)]
        
        CallUtils.sendJsonMessage("add_text", data: newDictionary)
        
        newDictionary["call"] = CallUtils.currentCall!["id"] as! NSNumber
        newDictionary["page_number"] = self.currentPage
        newDictionary["document_id"] = self.currentDocument
        newDictionary["tracking"] = randomStringWithLength(16)
        newDictionary["font_size"] = Int(textView.font!.pointSize)
        newDictionary["type"] = "text"
        newDictionary["height"] = textHeight
        
        ServerAPI.sharedInstance.newModification(newDictionary, completion: { (result) -> Void in})

    }
    
    enum SignalsType : String{
        case Send_Meta_Data = "send_meta_data"
        case Load_Res_With_Index = "load_res_with_index"            // load specific page immediately
        case Preload_Res_With_Index = "preload_res_with_index"      // load other pages on background
        case Chat_Text = "chat_text"                                // chat message
        case Line_Start_Point = "line_start_point"
        case Line_Point = "line_point"
        case Line_Clear = "line_clear"
        case Pointer_Position = "pointer_position"
        case Pointer_Hide = "pointer_hide"
        case Signature_Points = "signature_points"
        case Add_Text = "add_text"
        case Ask_For_Photo = "ask_for_photo"
        case Translate_And_Scale = "translate_and_scale"
        case Open_Rep_Box = "mouse_pos"
        case Text_Font_Change = "text_font_change"
        case Ask_To_Lock = "ask_to_lock"
        case Erase_Frame = "erase_frame" // not for now
        case Close_Rep_Box = "close_box"
        case Clean_Page = "clean_page"
        case Confirm_Lock = "confirm_lock"
        case Ask_For_Video = "ask_for_video"
    }
    
    // MARK: outgoing messages
    
    func sendCloseBoxRequest(isTextBox: Bool) {
        var dictionary = ["type": "sign_box"]
        if isTextBox {
            dictionary["type"] = "text_box"
        }
        CallUtils.sendJsonMessage(SignalsType.Close_Rep_Box.rawValue, data: dictionary)
    }
    
    func sendMetaDataRequest(dictionary: Dictionary<String,AnyObject>) {
        CallUtils.sendJsonMessage(SignalsType.Send_Meta_Data.rawValue, data: dictionary)
    }
    
    func sendLoadResWithIndexRequest(index: Int) {
        if let page = getCurrentPage(index){
            let data = ["page": index, "document": self.getSelectedResourceId(), "url": page.url!, "pageId": page.pageResourceId!] as Dictionary<String, AnyObject>
            CallUtils.sendJsonMessage(SignalsType.Load_Res_With_Index.rawValue, data: data)
        }
    }
    
    func sendPreloadResRequest() {
        let doc = getDocumentById(currentDocument)
        doc.pages.sortInPlace({$0.index < $1.index})
        var data = Dictionary<String, AnyObject>()
        for page in doc.pages {
            data = ["page": page.index!, "document": doc.id!, "url": page.url!]
            CallUtils.sendJsonMessage(SignalsType.Preload_Res_With_Index.rawValue, data: data)
        }
    }
    
    func sendFontChange() {
        if let document = self.presentaionImage?.image {
            let newFontSize = ((self.addTextView!.textFieldView.font!.pointSize/scrollView.zoomScale)*getScaleRatio())/document.size.width
                CallUtils.sendJsonMessage(SignalsType.Text_Font_Change.rawValue, data: ["newSize": newFontSize])
        }
    }
    
    func openInputPanelOnRemote(sender: UIGestureRecognizer, panelType: PanelType) {
        let touchLocation = sender.locationInView(self)
        let originPoint = getOriginFromCenterPoint(touchLocation)
        let zoom = scrollView!.zoomScale
        let scaleRatio = getScaleRatio()
        
        let isTextPanel: Bool?
        let panelView: UIView?
        
        switch panelType {
        case .text_panel:
            isTextPanel = true
            panelView = self.addTextView
            (panelView as! TextDocumentPanelView).openedOnRemoteSide(touchLocation)
            break
        case .sign_panel:
            isTextPanel = false
            panelView = self.signView
            (panelView as! SignDocumentPanelView).openedOnRemoteSide(touchLocation)
        }

        panelView?.hidden = false
        
        let relativeSize = getRelativeSize(CGSizeMake(panelView!.frame.width, panelView!.frame.height), zoom: zoom, scaleRatio: scaleRatio)
         let data = ["showTextPanel":isTextPanel!, "showSignPanel": !isTextPanel!, "top": originPoint.y, "left": originPoint.x, "height": relativeSize.height, "width": relativeSize.width] as Dictionary<String, AnyObject>

        CallUtils.sendJsonMessage(SignalsType.Open_Rep_Box.rawValue, data: data)
        
    }
    
    func getOriginFromCenterPoint(origin: CGPoint) -> CGPoint {
        let document = presentaionImage!.image!
        let screen =  UIScreen.mainScreen().bounds
        let zoom = scrollView!.zoomScale
        
        //Image is aspect fit, scale factor will be the biggest change on image
        let scaleRatio = max(document.size.width/screen.width, document.size.height/screen.height)
        
        //One of these have to be 0
        let heightDiff = (screen.height*scaleRatio) - document.size.height
        let widthDiff = (screen.width*scaleRatio) - document.size.width
        
        
        let X = (origin.x+scrollView!.contentOffset.x)/zoom
        let Y = (origin.y+scrollView!.contentOffset.y)/zoom
        return CGPointMake(((X*scaleRatio)-widthDiff/2)/document.size.width,((Y*scaleRatio)-heightDiff/2)/document.size.height)
    }
    
    func getRelativeSize(panelSize: CGSize, zoom: CGFloat, scaleRatio: CGFloat) -> CGSize {
        let document = presentaionImage.image!
        
        return CGSizeMake(panelSize.width/((document.size.width/scaleRatio)*zoom), panelSize.height/((document.size.height/scaleRatio)*zoom))
    }
    
    func getWidth(inputView: UIView, scale: CGFloat) -> CGSize {
        return CGSizeMake(inputView.frame.width/scale, inputView.frame.height/scale)
    }

    
    // MARK: incoming events
    
    func handleSignal(session: OTSession!, receivedSignalType type: String!, fromConnection connection: OTConnection!, withString string: String!) {
        
        printLog("\(type) event")
        
        switch type {
            
        case SignalsType.Send_Meta_Data.rawValue:
            sendMetaDataRequest(["platform": "iosSDK"])
            break
        case SignalsType.Load_Res_With_Index.rawValue: // called only on client side
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
        case SignalsType.Ask_To_Lock.rawValue:
            handleAskToLock(string)
            break
        case SignalsType.Close_Rep_Box.rawValue:
            handleCloseRepBox(string)
            break
        case SignalsType.Erase_Frame.rawValue:
            handleEraseFrame(string)
            break
        case SignalsType.Clean_Page.rawValue:
            handleCleanPage(string)
            break
        case SignalsType.Confirm_Lock.rawValue:
            handleLockRespose(string)
            break
        case SignalsType.Ask_For_Video.rawValue:
            handleAskForVideo(string)
            break
        default:
            printLog("Couldn't find an event")
        }
    }

    func handleCleanPage(string: String) {
        if let data = CallUtils.convertStringToDictionary(string) {
            let document = getDocumentById(data["document"] as! Int)
            let page = getPageByIndex(document, index: data["page"] as! Int)
            if let val = page?.url {
                setImageFromURL(val, document: document.id!, page: page!.index!, completion: { (result) -> Void in
                    page?.image = result
                    if page?.index == self.currentPage {
                        dispatch_async(dispatch_get_main_queue()){
                            self.presentaionImage.image = result
                        }
                    }
                })
            }
        }
    }
    
    func handleEraseFrame(string: String) {
        if var data = CallUtils.convertStringToDictionary(string) {
            data["zoom"] = 1
            let document = presentaionImage!.image!
            let blankFrame = calculateFrameForView(data)
            let blankView = UIView(frame: blankFrame)
            blankView.backgroundColor = UIColor.whiteColor()
            let scaledTextImage = takeScreenshot(blankView)
            drawObjectOnDocument(document, data: data, newViewFrame: blankView.frame, newImage: scaledTextImage)
            
        }
    }
    
    func handleCloseRepBox(string: String) {
        if let data = CallUtils.convertStringToDictionary(string) {
            if let val = data["type"] as? String {
                if val == "text_box" {
                    self.addTextView?.hidden = true
                } else {
                    self.signView?.hidden = true
                }
            }
        }
    }
    
    func handleAskToLock(string: String) {
        if let data = CallUtils.convertStringToDictionary(string) {
            
            let caller = CallUtils.currentCall?["caller"] as? NSDictionary
            let firstName = caller!["user"]!["first_name"] as! String
            
            let alertController = UIAlertController(title: "Lock request", message: "\(firstName) has requested to lock the document! Do you agree?", preferredStyle: .Alert)
            
            let yesAction = UIAlertAction(title: "YES", style: .Default) { (action:UIAlertAction) in
                print("Yes button pressed", terminator: "")
                self.sendLockResponse(data, val: true)
            }
            
            let noAction = UIAlertAction(title: "NO", style: .Default) { (action:UIAlertAction) in
                print("No button pressed", terminator: "");
                self.sendLockResponse(data, val: false)
            }
            
            alertController.addAction(yesAction)
            alertController.addAction(noAction)

            self.parentViewController!.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    func sendLockResponse(data: Dictionary<String, AnyObject>, val: Bool) {
        var d = data
        d["lock"] = val
        CallUtils.sendJsonMessage(SignalsType.Confirm_Lock.rawValue, data: d)
    }
    
    func handleLockRespose(string: String) {
        if let data = CallUtils.convertStringToDictionary(string) {
            if let val = data["lock"] as? Bool {
                if val == true {
                    if let id = CallUtils.currentCall?["id"] as? NSNumber{
                        ServerAPI.sharedInstance.lockDocument(["call": id, "document": self.getSelectedResourceId()]) { (result) -> Void in
                            dispatch_async(dispatch_get_main_queue()){
                                var title = "Document Locked"
                                var message = "Email with the signed document will be sent to you shortly"
                                
                                if nil==result["success"]{
                                    title = "Lock Error"
                                    message = "No change detected in document"
                                }
                                ViewUtils.showAlert(title, message: message)
                            }
                        }
                    }
                } else {
                    ViewUtils.showAlert("Request Declined", message: "The client has rejected your request to lock the document")
                }
            }
        }
    }
    
    func handleAskForVideo(string:String){
        openPublishDialog(nil)
    }
    
    func handleFontChange(string: String) {
        if let data = CallUtils.convertStringToDictionary(string) {
            self.addTextView!.relativeFontSize = data["newSize"] as? CGFloat
            handleZoom()
        }
    }

    func handleOpenBox(string: String) {

        if let box = CallUtils.convertStringToDictionary(string) {
            if scrollView != nil {
                if let document = self.presentaionImage?.image {
                    let top = box["top"] as! CGFloat*document.size.height
                    let left = (box["left"] as! CGFloat)*document.size.width
                    let width = box["width"] as! CGFloat*document.size.width
                    let height = box["height"] as! CGFloat*document.size.height
                    let showSignPanel = box["showSignPanel"] as? Bool
                    let showTextPanel = box["showTextPanel"] as? Bool
                    
                    if ((showSignPanel != true) && (showTextPanel != true)) {
                        return
                    }
                    
                    self.scrollView?.scrollEnabled = false
                    
                    var bounds = UIScreen.mainScreen().bounds.size

                    if(UIDeviceOrientationIsLandscape(UIDevice.currentDevice().orientation)){
                        bounds = CGSizeMake(max(bounds.height, bounds.width), min(bounds.height, bounds.width))
                    }
                    if(UIDeviceOrientationIsPortrait(UIDevice.currentDevice().orientation)){
                        bounds = CGSizeMake(min(bounds.height, bounds.width), max(bounds.height, bounds.width))
                    }

                    let w: CGFloat = signPanelWidth
                    let scale = w/width
                    
                    // Image is aspect fit, scale factor will be the biggest change on image
                    let scaleRatio = max(document.size.width/bounds.width, document.size.height/bounds.height)
                    
                    UIView.animateWithDuration(0.4, animations: { () -> Void in
                        self.scrollView?.setZoomScale(scaleRatio*scale, animated: false)
                        self.handleZoom()
                    })
                    
                    
                    // One of these has to be 0
                    let heightDiff = (bounds.height*scaleRatio*scale - document.size.height*scale)/2
                    let widthDiff = (bounds.width*scaleRatio*scale - document.size.width*scale)/2

                    let h = height*scale
                    let X = left*scale+widthDiff-((bounds.width-w)/2)
                    let Y = top*scale+heightDiff-((bounds.height-h)/2)
                    
                    signPanelHeight = height*scale
                    self.scrollView?.contentOffset = CGPointMake(X - signPanelWidth/2 , Y - signPanelHeight/2)

                    if showSignPanel == true {
                        self.signView?.hidden = false
                        self.addTextView?.hidden = true
                        self.signView?.center_x_constraint?.constant = 0
                        self.signView?.center_y_constraint?.constant = 0
                        self.signView?.last_open_box_info = string
                    } else {
                        if showTextPanel == true {
                            self.addTextView?.hidden = false
                            self.signView?.hidden = true
                            self.addTextView?.center_x_constraint?.constant = 0
                            self.addTextView?.center_y_constraint?.constant = 0
                            self.addTextView?.last_open_box_info = string
                        }
                    }
                    
                    handleZoom()
                }
            }
            
        }
    }
    
    func handleZoom() {
        if let _ = presentaionImage.image {
            self.addTextView!.setFontSize(getScaleRatio(), zoom: scrollView.zoomScale, documentWidth: self.presentaionImage!.image!.size.width)
            sendFontChange()
        }
    }
    
    func getScaleRatio() -> CGFloat {
        
        let document = presentaionImage!.image!
        var bounds = UIScreen.mainScreen().bounds.size
        
        if(UIDeviceOrientationIsLandscape(UIDevice.currentDevice().orientation)){
            bounds = CGSizeMake(max(bounds.height, bounds.width), min(bounds.height, bounds.width))
        }
        if(UIDeviceOrientationIsPortrait(UIDevice.currentDevice().orientation)){
            bounds = CGSizeMake(min(bounds.height, bounds.width), max(bounds.height, bounds.width))
        }
        
        // Image is aspect fit, scale factor will be the biggest change on image
        return max(document.size.width/bounds.width, document.size.height/bounds.height)
    }

    
    func sendTranslateAndScale() {

        let documentImage = presentaionImage.image!
        let current_x = scrollView.contentOffset.x
        let current_y = scrollView.contentOffset.y
        
        let imageSize = getImageSize(documentImage, scaleRatio: getScaleRatio())
        let imageWidth = imageSize.width
        let imageHeight = imageSize.height
        
        let scale = scrollView!.zoomScale
        let X = (imageWidth*(scale - 1)/2) - current_x
        let Y = (imageHeight*(scale - 1)/2) - current_y
        
        let data = ["translate" : ["x": X, "y": Y], "image_width": imageWidth, "image_height": imageHeight, "scale": scale] as Dictionary<String, AnyObject>
        
        CallUtils.sendJsonMessage(SignalsType.Translate_And_Scale.rawValue, data: data)

    }
    
    // image size is the size of the image the user sees (screen - image spaces from bounds)
    func getImageSize(documentImage: UIImage, scaleRatio: CGFloat) -> CGSize {
        return CGSizeMake(documentImage.size.width/scaleRatio, documentImage.size.height/scaleRatio)
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
            
            UIView.animateWithDuration(0.4, animations: { () -> Void in
                self.scrollView?.setZoomScale(scale, animated: false)
                self.handleZoom()
            })

            
            let document = presentaionImage!.image!
            
            //Image is aspect fit, scale factor will be the biggest change on image

            let scaleRatio = getScaleRatio()
            let heightDiff = ((screen.height*scaleRatio) - document.size.height)/scaleRatio

            var ratio = 0.0 as CGFloat
             // this is my conainer size document.size.width/scaleRatio
            // multiply everything by box width (0.1). lets say i'm getting 100 , default size is 200 -> zoom scale is 2
            if heightDiff == 0 {
                ratio = (document.size.width/scaleRatio)/imageWidth
            } else { // width
               ratio = (document.size.height/scaleRatio)/imageHeight
            }

            scrollView?.contentOffset = CGPoint(x: new_x*ratio, y: new_y*ratio)
            
        }
        
    }

    func loadResourcesWithIndex(string: String) {

        presentationWebView?.hidden = true
        presentationWebView?.loadHTMLString("", baseURL:nil)
        scrollView?.setZoomScale(1.0, animated: false)
        handleZoom()
        
        if let data = CallUtils.convertStringToDictionary(string) {

            currentDocument = data["document"] as! Int
            currentPage = data["page"] as! Int
            if let image = getImageAtIndex(currentDocument, page: currentPage){
                dispatch_async(dispatch_get_main_queue()){
                    self.presentaionImage.image = image
                }
            } else {
                setImageFromURL(data["url"] as! String, document: currentDocument, page: currentPage, completion: { (result) -> Void in
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
                if getImageAtIndex(data["document"] as! Int, page: data["page"] as! Int) == nil {
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
        
        UIView.animateWithDuration(0.4, animations: { () -> Void in
            self.scrollView?.setZoomScale(CGFloat((params[0] as NSString).floatValue), animated: false)
            self.handleZoom()
        })
        
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
        
        self.signView?.hidden = true
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
        
        self.addTextView?.hidden = true
    }
    
    func handleAskForPhoto() {
        CallUtils.publisher?.publishVideo = false
        
        imagePicker.sourceType = .Camera
        ViewUtils.getTopViewController()!.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    // MARK: set image methods
    
    // client only
    func setImageAtIndex(image: UIImage, document: Int, page: Int){
        let doc = getDocumentById(document)
        if let page = getPageByIndex(doc, index: page) {
            page.image = image
        }
    }
    
    func setImageFromURL(urlPath: String, document: Int, page: Int, completion: ((result: UIImage) -> Void)?) -> Void{
        if let url = NSURL(string: urlPath){
            NetworkUtils.getDataFromUrl(url) { data in
                if let image = UIImage(data: data!){
                    self.addPageToDocument(document, pageIndex: page, image: image, url: urlPath)
                    completion?(result: image)
                }
            }
        }
    }
    
    func getImageAtIndex(document: Int, page: Int) -> UIImage?{
        let doc = self.getDocumentById(document)
        if let page = getPageByIndex(doc, index: page) {
            return page.image
        } else {
            return nil
        }
        
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
        
//        if currentPage != nil && currentDocument != nil {
            setImageAtIndex(image, document: currentDocument, page: currentPage)
//        }
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
    
    func getDocumentById(id: Int) -> Document {
        for doc in self.preLoadedImages {
            if doc.id == id {
                return doc
            }
        }
        let doc = Document(withDictionary: ["id": id])
        self.preLoadedImages.append(doc)
        return doc
    }
    
    func addNewDocument(dictionary: Dictionary<String, AnyObject>) -> Document {
        let doc = Document(withDictionary: dictionary)
        self.preLoadedImages.append(doc)
        return doc
    }
    
    func addPageToDocument(docId: Int, pageIndex: Int, image: UIImage, url: String, pageId: Int? = nil) {
        let doc = self.getDocumentById(docId)
        for page in doc.pages {
            if page.index == pageIndex {
                return
            }
        }
        var dictionary = ["document":docId, "index":pageIndex, "image": image, "url": url] as Dictionary<String, AnyObject>
        if pageId != nil {
            dictionary["pageId"] = pageId
        }
        doc.pages.append(Page(withDictionary: dictionary))
    }
    
    func getPageByIndex(doc: Document, index: Int) -> Page? {
        for page in doc.pages {
            if page.index == index {
                return page
            }
        }
        return nil
    }
    
    func getCurrentPage(index: Int) -> Page? {
        let document = preLoadedImages[self.selectedResIndex]
        return getPageByIndex(document, index: index)
    }

}
