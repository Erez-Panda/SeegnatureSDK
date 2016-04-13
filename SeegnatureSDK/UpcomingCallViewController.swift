//
//  UpcomingCallViewController.swift
//  Panda4doctor
//
//  Created by Erez Haim on 2/5/15.
//  Copyright (c) 2015 Erez. All rights reserved.
//

import UIKit

class UpcomingCallViewController: PandaViewController, CallDelegate {

    var previousViewController: UIViewController?
    var call : NSDictionary?
    var timer: NSTimer?
    
    @IBOutlet weak var startNowButton: UIButton!
    @IBOutlet weak var startOnTimeButton: UIButton!
    @IBOutlet weak var timeLong: UILabel!
    @IBOutlet weak var callLabelLong: UILabel!
    @IBOutlet weak var longView: UIView!
    @IBOutlet weak var shortView: UIView!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var closeButton: UIButton!


    @IBOutlet weak var textWidthConstarint: NSLayoutConstraint!
    @IBOutlet weak var timeTextView: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        CallUtils.upcomingViewController = self
        shortView.layoutIfNeeded()
        closeButton.layoutIfNeeded()
        ViewUtils.bottomBorderView(shortView, borderWidth: 1.0, borderColor: ColorUtils.uicolorFromHex(0x5FB484), offset: -closeButton.bounds.height)
        ViewUtils.bottomBorderView(shortView, borderWidth: 1.0, borderColor: ColorUtils.uicolorFromHex(0x5FB484), offset: 0.0)
        ViewUtils.leftBorderView(closeButton, borderWidth: 1.0, borderColor: ColorUtils.uicolorFromHex(0x5FB484))

        
        startNowButton.setAttributedTitle(ViewUtils.getAttrText("Start call now", color: ColorUtils.buttonColor(), size: 18.0, fontName: "OpenSans-Semibold"), forState: UIControlState.Normal)
        startOnTimeButton.setAttributedTitle(ViewUtils.getAttrText("Start on time", color: ColorUtils.buttonColor(), size: 18.0), forState: UIControlState.Normal)
        
        timer = NSTimer.scheduledTimerWithTimeInterval(NSTimeInterval(1), target: self, selector: #selector(UpcomingCallViewController.updateTime), userInfo: AnyObject?(), repeats: true)
//        CallUtils.delegate = self
        if(CallUtils.isRemoteSideConnected()){
            self.remoteSideConnected()
        }
        timeTextView.textContainerInset = UIEdgeInsetsMake(15, 6, 0, 6 )
        updateTime()
    }
    

    
    func updateTime(){
        let start = call?["start"] as? NSString
        let startTime = TimeUtils.serverDateTimeStrToDate(start! as String)
        let reminingTime: NSTimeInterval = startTime.timeIntervalSinceDate(NSDate())
        let reminingTimeInt : NSInteger = NSInteger(reminingTime)
        if (reminingTime > 0){
            let min : Int = (reminingTimeInt / 60) % 60
            let sec = (reminingTimeInt % 60)
            if (sec < 10) {
                time.attributedText = ViewUtils.getAttrText("\(min):0\(sec)", color: UIColor.whiteColor(), size: 20.0, fontName: "OpenSans-BoldItalic")
                timeLong.attributedText = ViewUtils.getAttrText("\(min):0\(sec)", color: UIColor.whiteColor(), size: 28.0, fontName: "OpenSans-BoldItalic")
            } else {
                time.attributedText = ViewUtils.getAttrText("\(min):\(sec)", color: UIColor.whiteColor(), size: 20.0, fontName: "OpenSans-BoldItalic")
                timeLong.attributedText = ViewUtils.getAttrText("\(min):\(sec)", color: UIColor.whiteColor(), size: 28.0, fontName: "OpenSans-BoldItalic")
            }
        } else {
            timer?.invalidate()
            time.hidden = true
            shortView.removeConstraint(textWidthConstarint)
            let widthConstraint = NSLayoutConstraint(item: timeTextView, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 280)
            shortView.addConstraint(widthConstraint)
            timeTextView.attributedText = ViewUtils.getAttrText("We apologize for the delay, the expert will be with you shortly", color: UIColor.whiteColor(), size: 16.0)
            timeLong.attributedText = ViewUtils.getAttrText("Now", color: UIColor.whiteColor(), size: 28.0, fontName: "OpenSans-BoldItalic")
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func closeSelf(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(false)
        close(true)
    }
    
    func close(withAnimation: Bool){

        if (withAnimation){
            UIView.animateWithDuration(0.5, animations: { () -> Void in
                self.view.frame.origin.y = -1 * self.view.frame.size.height
                self.view.alpha = 0.0
                },
                completion: {result -> Void in
                    self.view.removeFromSuperview()
                    self.removeFromParentViewController()

            })
        } else {
            self.view.removeFromSuperview()
            self.removeFromParentViewController()
        }
        
        
    }

    @IBAction func startCall(sender: AnyObject) {
        
        
        // MARK: TODO --------------------
        
        
//        CallUtils.getCallViewController()?.showIncoming = false
//        CallUtils.rootViewController?.presentViewController(CallUtils.getCallViewController()!, animated: true, completion: {
//            self.navigationController?.popViewControllerAnimated(false)
//            self.close(true)
//        })

    }
    
    func remoteSideConnected() {
        if longView.hidden {
            longView.layoutIfNeeded()
            startOnTimeButton.layoutIfNeeded()
            ViewUtils.leftBorderView(startNowButton, borderWidth: 1.0, borderColor: ColorUtils.uicolorFromHex(0x5FB484))
            ViewUtils.bottomBorderView(longView, borderWidth: 1.0, borderColor: ColorUtils.uicolorFromHex(0x5FB484), offset: 0.0)
            ViewUtils.bottomBorderView(longView, borderWidth: 1.0, borderColor: ColorUtils.uicolorFromHex(0x5FB484), offset: -startOnTimeButton.bounds.height)
            UIView.animateWithDuration(0.5, animations: { () -> Void in
                self.shortView.frame.origin.y = 0
                self.shortView.alpha = 0
                
            })
            longView.frame.origin.y = -1*longView.frame.height
            longView.hidden = false
            UIView.animateWithDuration(0.5, animations: { () -> Void in
                self.longView.frame.origin.y = 0
                self.longView.alpha = 1
                
            })
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    

}
