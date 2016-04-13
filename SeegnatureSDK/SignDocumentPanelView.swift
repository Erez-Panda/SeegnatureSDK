//
//  SignDocumentPanelView.swift
//  Panda4doctor
//
//  Created by Erez Haim on 9/8/15.
//  Copyright (c) 2015 Erez. All rights reserved.
//

import UIKit

class SignDocumentPanelView: UIView, InputPanelsDelegate {
    
    var onSign: ((signatureView: LinearInterpView, origin: CGPoint) -> ())?
    var onClose: ((sender: UIView) -> ())?
    
    @IBOutlet weak var signView: LinearInterpView!
    
    var center_x_constraint: NSLayoutConstraint?
    var center_y_constraint: NSLayoutConstraint?
    var height: NSLayoutConstraint?
    var last_open_box_info: String?
    
    var isOpenedOnRemoteSide = false
    
    @IBOutlet weak var SignButton: UIButton!
    @IBOutlet weak var moveButton: NIKFontAwesomeButton!
    
    override func awakeFromNib() {
        self.layer.cornerRadius = 8
        self.layer.borderColor = ColorUtils.buttonColor().CGColor
        self.layer.borderWidth = 1
        self.clipsToBounds = true
        self.signView.blockTouches = true
        self.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func openedOnRemoteSide(touchLocation: CGPoint) {

        dispatch_async(dispatch_get_main_queue()){
            self.moveButton.backgroundColor = UIColor.grayColor()
            self.moveButton.color = UIColor.whiteColor()
            self.SignButton.backgroundColor = UIColor.grayColor()
            self.layer.borderColor = UIColor.grayColor().CGColor
            self.userInteractionEnabled = false
        }
        
        let bounds = UIScreen.mainScreen().bounds
        self.center_x_constraint?.constant = touchLocation.x - bounds.width/2
        self.center_y_constraint?.constant = touchLocation.y - bounds.height/2
        self.isOpenedOnRemoteSide = true
    }
    
    override var hidden: Bool {
        get {
            return super.hidden
        }
        set(v) {
            super.hidden = v
            self.last_open_box_info = nil
            if self.signView != nil {
                self.signView.cleanView()
                self.SignButton.backgroundColor = ColorUtils.uicolorFromHex(0x67CA94)
                self.moveButton.color = UIColor.whiteColor()
                self.moveButton.backgroundColor = ColorUtils.uicolorFromHex(0x67CA94)
                self.layer.borderColor = ColorUtils.uicolorFromHex(0x67CA94).CGColor
                if self.isOpenedOnRemoteSide {
                    self.userInteractionEnabled = false
                } else {
                    self.userInteractionEnabled = true
                }
                if v {
                    self.isOpenedOnRemoteSide = false
                }
                (self.superview as! SessionView).scrollView.scrollEnabled = v
            }
        }
    }
    
    @IBAction func sign(sender: AnyObject) {
        let offset = CGPointMake(frame.origin.x + signView.frame.origin.x, frame.origin.y + signView.frame.origin.y)
        onSign?(signatureView:signView, origin: offset)
        self.hidden = true
        self.signView.cleanView()
    }
    @IBAction func cancel(sender: AnyObject) {
        self.hidden = true
        onClose?(sender: self)
    }
    
    
}
