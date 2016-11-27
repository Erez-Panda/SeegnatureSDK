//
//  ViewUtils.swift
//  SeegnatureSDK
//
//  Created by Erez on 1/28/15.
//  Copyright (c) 2015 Erez. All rights reserved.
//

@objc protocol ViewDelegate{
    optional func beforeShowIncomingCall()
}


struct ViewUtils {
    
    static var profileImage: UIImage?
//    static var homeViewController: InitiateSessionViewController?
    static var upcomingViewController: UpcomingCallViewController?
    static var delegate:ViewDelegate?
    static var globalLoader: UIActivityIndicatorView?
    
    static func roundView(view: UIView, borderWidth: CGFloat, borderColor: UIColor){
        let frame = view.frame;
        view.layer.cornerRadius = frame.size.height / 2
        view.clipsToBounds = true
        view.layer.borderWidth = borderWidth;
        view.layer.borderColor = borderColor.CGColor
    }
    
    static func borderView(view: UIView, borderWidth: CGFloat, borderColor: UIColor, borderRadius: CGFloat){
        view.layer.borderWidth = borderWidth
        view.layer.cornerRadius = borderRadius
        view.layer.cornerRadius = borderRadius
        view.clipsToBounds = true
        view.layer.borderColor = borderColor.CGColor
    }
    
    static func leftBorderView(view: UIView, borderWidth: CGFloat, borderColor: UIColor) -> CALayer {
        let leftBorder = CALayer()
        leftBorder.frame = CGRectMake(0.0, 0.0, borderWidth, view.frame.size.height);
        leftBorder.backgroundColor = borderColor.CGColor
        view.layer.addSublayer(leftBorder)
        return leftBorder
    }
    
    static func rightBorderView(view: UIView, borderWidth: CGFloat, borderColor: UIColor) -> CALayer {
        let leftBorder = CALayer()
        leftBorder.frame = CGRectMake(view.frame.size.width-borderWidth, 0.0, borderWidth, view.frame.size.height);
        leftBorder.backgroundColor = borderColor.CGColor
        view.layer.addSublayer(leftBorder)
        return leftBorder
    }
    
    static func bottomBorderView(view: UIView, borderWidth: CGFloat, borderColor: UIColor, offset: CGFloat) -> CALayer{
        let bottomBorder = CALayer()
        bottomBorder.frame = CGRectMake(0.0, view.frame.size.height + offset, view.frame.size.width, borderWidth)
        bottomBorder.backgroundColor = borderColor.CGColor
        view.layer.addSublayer(bottomBorder)
        return bottomBorder
    }
    
    static func topBorderView(view: UIView, borderWidth: CGFloat, borderColor: UIColor, offset: CGFloat) -> CALayer{
        let topBorder = CALayer()
        topBorder.frame = CGRectMake(0.0, 0.0 + offset, view.frame.size.width, borderWidth)
        topBorder.backgroundColor = borderColor.CGColor
        view.layer.addSublayer(topBorder)
        return topBorder
    }
    
    static func addGradientLayer(view: UIView, topColor: UIColor, bottomColor: UIColor) -> CAGradientLayer{
        let layer : CAGradientLayer = CAGradientLayer()
        layer.frame.size = view.frame.size
        layer.frame.origin = CGPointMake(0.0,0.0)
        layer.colors = [topColor.CGColor,bottomColor.CGColor]
        view.layer.insertSublayer(layer, atIndex: 0)
        return layer
    }
    
    static func addRoundBorderView(view: UIView, borderWidth: CGFloat, borderColor: UIColor, boderSpacing: CGFloat) ->UIView{
        let roundView = UIView()
        roundView.frame = CGRectMake(view.frame.origin.x-boderSpacing,
            view.frame.origin.y-boderSpacing,
            view.frame.size.width+2*boderSpacing,
            view.frame.size.height+2*boderSpacing)
        roundView.center = view.center
        roundView.layer.borderWidth = borderWidth
        roundView.layer.cornerRadius = roundView.frame.size.height / 2
        roundView.layer.borderColor = borderColor.CGColor
        return roundView
    }
    
    static func cornerRadius(view: UIView, corners: UIRectCorner ,cornerRadius: CGFloat){
        let maskPath = UIBezierPath(roundedRect: view.bounds, byRoundingCorners: corners, cornerRadii:CGSizeMake(cornerRadius, cornerRadius))
        let maskLayer = CAShapeLayer()
        maskLayer.path = maskPath.CGPath
        view.layer.mask = maskLayer
    }
    
    static func slideViewOutVertical(view: UIView){
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            view.frame.origin.y = screenSize.height
            
        })
    }
    static func slideViewOutVertical(view: UIView, animate: Bool){
        if (animate){
            slideViewOutVertical(view)
        } else {
            let screenSize: CGRect = UIScreen.mainScreen().bounds
            view.frame.origin.y = screenSize.height
        }
        
        
    }
    
    static func slideViewinVertical(view: UIView){
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            view.frame.origin.y = screenSize.height - view.frame.height
            
        })
    }
    
    static func getBlurEffect(view:UIView) -> UIImage{
        let snapshotView:UIView = view.snapshotViewAfterScreenUpdates(true)!
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, true, 0.0)
        snapshotView.drawViewHierarchyInRect(view.bounds, afterScreenUpdates: true)
        let imgaa :UIImage = UIGraphicsGetImageFromCurrentImageContext()!;
        
        let ciimage :CIImage = CIImage(image: imgaa)!
        let filter : CIFilter = CIFilter(name:"CIGaussianBlur")!
        filter.setDefaults()
        filter.setValue(ciimage, forKey: kCIInputImageKey)
        filter.setValue(5, forKey: kCIInputRadiusKey)
        let outputImage : CIImage = filter.outputImage!
        let finalImage :UIImage = UIImage(CIImage: outputImage)
        return finalImage
        
    }
    
    static func getProfileImage(completion: (result: UIImage) -> Void) -> Void{
        if ((profileImage) != nil){
            completion(result: profileImage!)
        } else {
            let defaultUser = NSUserDefaults.standardUserDefaults()
            if let userProfile : AnyObject = defaultUser.objectForKey("userProfile") {
                if let imageFile = userProfile["image_file"] as? NSNumber{
                    getImageFile(imageFile, completion: { (result) -> Void in
                        self.profileImage = result
                        completion(result: result)
                    })
                }
            }
        }
    }
    
    static func getImageFile(id: NSNumber, completion: (result: UIImage) -> Void) -> Void{
        ServerAPI.sharedInstance.getFileUrl(id, completion: { (result) -> Void in
            if let url = NSURL(string: result as String){
                if let data = NSData(contentsOfURL: url){
                    dispatch_async(dispatch_get_main_queue()){
                        let image = UIImage(data: data)
                        completion(result: image!)
                    }
                }
            }
        })
    }
    
    static func slideInCallAlert(viewController: UIViewController, call: NSDictionary){
        upcomingViewController = viewController.storyboard?.instantiateViewControllerWithIdentifier("upcomingCall") as? UpcomingCallViewController
        upcomingViewController!.call = call
        upcomingViewController!.previousViewController = viewController
        upcomingViewController!.view.frame.origin.y = -1 * upcomingViewController!.view.frame.size.height
        if let parent = viewController.parentViewController {
            parent.addChildViewController(upcomingViewController!)
            parent.view.addSubview(upcomingViewController!.view)
            parent.view.bringSubviewToFront(upcomingViewController!.view)
        } else {
            viewController.addChildViewController(upcomingViewController!)
            viewController.view.addSubview(upcomingViewController!.view)
            viewController.view.bringSubviewToFront(upcomingViewController!.view)
        }
        upcomingViewController!.view.alpha = 0.0
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.upcomingViewController!.view.frame.origin.y = 0
            self.upcomingViewController!.view.alpha = 1
            
        })
    }
    
    static func showIncomingCall(){
        if (CallUtils.incomingViewController != nil){
            return
        }
        self.delegate?.beforeShowIncomingCall?()
        let rvc = getTopViewController()
        CallUtils.rootViewController = rvc
        let incomingCall = rvc?.storyboard?.instantiateViewControllerWithIdentifier("IncomingCall") as! IncomingCallViewController
        rvc?.presentViewController(incomingCall, animated: true, completion: nil)
        
    }
    
    static func getTopViewController() -> UIViewController?{
        if var topController = UIApplication.sharedApplication().keyWindow?.rootViewController{
            while ((topController.presentedViewController) != nil) {
                topController = topController.presentedViewController!
            }
            return topController
        }
        return nil
    }
    
    static func setBackButton(vc: UIViewController){
        if (vc.navigationItem.leftBarButtonItem?.tag == 10){
            return
        }
        let backBtn   = UIButton(type: UIButtonType.Custom)
        backBtn.frame = CGRectMake(0, 0, 18, 16);
        if let image = ViewUtils.loadUIImageNamed("back_btn") {
            backBtn.setBackgroundImage(image, forState: UIControlState.Normal)
        }
        backBtn.addTarget(vc, action: Selector("back"), forControlEvents: UIControlEvents.TouchUpInside)
        let backButton = UIBarButtonItem(customView: backBtn)
        backButton.tag = 10
        vc.navigationItem.leftBarButtonItem = backButton
    }
    
    static func setMenuButton (vc: UIViewController){
        if (vc.navigationItem.rightBarButtonItem?.tag == 10){
            return
        }
        let menuBtn   = UIButton(type: UIButtonType.Custom)
        menuBtn.frame = CGRectMake(0, 0, 20, 15);
        if let image = ViewUtils.loadUIImageNamed("menu_btn") {
            menuBtn.setBackgroundImage(image, forState: UIControlState.Normal)
        }
        menuBtn.addTarget(vc, action: Selector("menu"), forControlEvents: UIControlEvents.TouchUpInside)
        let menuButton = UIBarButtonItem(customView: menuBtn)
        menuButton.tag = 10
        vc.navigationItem.rightBarButtonItem = menuButton
    }
    
    static func getAttrText(string:String, color: UIColor, size: CGFloat) -> NSMutableAttributedString{
        return getAttrText(string, color: color, size: size, fontName: "OpenSans")
    }
    
    static func getAttrText(string:String, color: UIColor, size: CGFloat, fontName:String) -> NSMutableAttributedString{
        return getAttrText(string, color: color, size: size, fontName: fontName, addShadow: false)
    }
    
    static func getAttrText(string:String, color: UIColor, size: CGFloat, fontName:String, addShadow: Bool) -> NSMutableAttributedString{
        let str = NSMutableAttributedString(string: string)
        str.addAttribute(NSForegroundColorAttributeName,
            value: color,
            range: NSMakeRange(0,string.characters.count))
        str.addAttributes([NSFontAttributeName:UIFont(name: fontName, size: size )!], range:  NSMakeRange(0,string.characters.count) )
        if (addShadow){
            let shadow = NSShadow()
            shadow.shadowBlurRadius = 5;
            shadow.shadowColor = UIColor.whiteColor()
            shadow.shadowOffset = CGSizeMake(0, 0)
            str.addAttributes([NSShadowAttributeName:shadow], range:  NSMakeRange(0,string.characters.count))
        }
        return str
    }
    
    static func addCenterAttr (attrText: NSMutableAttributedString) -> NSMutableAttributedString{
        let p: NSMutableParagraphStyle = NSMutableParagraphStyle()
        p.alignment = NSTextAlignment.Center
        attrText.addAttribute(NSParagraphStyleAttributeName, value: p, range: NSMakeRange(0,attrText.string.characters.count))
        return attrText
    }
    
    static func showSimpleError(message: String){
        showAlert("Error", message: message)
    }
    
    static func showAlert(title: String = "Error", message: String) {
        if (Session.sharedInstance.disconnectingCall == true) {
            return
        }
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        
        let OKAction = UIAlertAction(title: "OK", style: .Default) { (action:UIAlertAction!) in
            print("OK button pressed");
        }
        alertController.addAction(OKAction)
        
        self.getTopViewController()?.presentViewController(alertController, animated: true, completion:nil)
    }
    
    
    static func startGlobalLoader(){
        globalLoader = UIActivityIndicatorView()
        globalLoader!.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
        
        if let topView = getTopViewController()?.view{
            topView.addSubview(globalLoader!)
            globalLoader!.startAnimating()
            topView.bringSubviewToFront(globalLoader!)
            globalLoader!.translatesAutoresizingMaskIntoConstraints = false
            let canterXConstraint = NSLayoutConstraint(item: globalLoader!, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: topView, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0)
            topView.addConstraint(canterXConstraint)
            let canterYConstraint = NSLayoutConstraint(item: globalLoader!, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: topView, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0)
            topView.addConstraint(canterYConstraint)
            
        }
        
    }
    
    static func stopGlobalLoader(){
        dispatch_async(dispatch_get_main_queue()){
            globalLoader?.removeFromSuperview()
        }
    }
    
    static func loadUIImageNamed(name: String) -> UIImage? {
        return UIImage(named: name, inBundle: NSBundle(forClass: SessionView.self), compatibleWithTraitCollection: nil)
    }
    
}
