//
//  SignDocumentPanelView.swift
//  Panda4doctor
//
//  Created by Erez Haim on 9/8/15.
//  Copyright (c) 2015 Erez. All rights reserved.
//

import UIKit

class TextDocumentPanelView: UIView, UITextFieldDelegate, InputPanelsDelegate {
    
    var onAdd: ((textView: UITextField, origin: CGPoint) -> ())?
    var onClose: ((sender: UIView) -> ())?
    
    var center_x_constraint: NSLayoutConstraint?
    var center_y_constraint: NSLayoutConstraint?
    
    var last_open_box_info: String?
    var isOpenedOnRemoteSide = false
    
    @IBOutlet weak var textFieldView: UITextField!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var moveButton: NIKFontAwesomeButton!
    
    override func awakeFromNib() {
        self.layer.cornerRadius = 8
        self.layer.borderColor = ColorUtils.buttonColor().CGColor
        self.layer.borderWidth = 1
        self.clipsToBounds = true
        textFieldView.delegate = self
        textFieldView.addTarget(self, action: "textDidChange", forControlEvents: UIControlEvents.EditingChanged)
        self.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func openedOnRemoteSide(touchLocation: CGPoint) {

        dispatch_async(dispatch_get_main_queue()){
            self.moveButton.backgroundColor = UIColor.grayColor()
            self.moveButton.color = UIColor.whiteColor()
            self.addButton.backgroundColor = UIColor.grayColor()
            self.layer.borderColor = UIColor.grayColor().CGColor
            self.userInteractionEnabled = false
        }

        let bounds = UIScreen.mainScreen().bounds
        self.center_x_constraint?.constant = touchLocation.x - bounds.width/2
        self.center_y_constraint?.constant = touchLocation.y - bounds.height/2
        self.isOpenedOnRemoteSide = true
        
    }
    
    func setFontSize(scaleRatio: CGFloat, zoom: CGFloat) {
        self.textFieldView.font = self.textFieldView.font?.fontWithSize((16/scaleRatio)*zoom)
    }
    
    override var hidden: Bool {
        get {
            return super.hidden
        }
        set(v) {
            super.hidden = v
            self.last_open_box_info = nil
            if (self.textFieldView != nil) {
                self.textFieldView.text = ""
                self.addButton.backgroundColor = ColorUtils.uicolorFromHex(0x67CA94)
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
    
    func textDidChange(){
        let constraintRect = CGSize(width: CGFloat.max, height: textFieldView.frame.height)
        
        
        let boundingBox = textFieldView.text!.boundingRectWithSize(constraintRect, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName: textFieldView.font!], context: nil)
        
        let delta = boundingBox.width - textFieldView.frame.width
        if delta > 0 {
            let bounds = UIScreen.mainScreen().bounds
            if (self.frame.size.width + delta + self.frame.origin.x) < bounds.width{
                self.frame.size.width += delta
            } else {
                textFieldView.text = textFieldView.text?.stringByPaddingToLength(textFieldView.text!.characters.count-1, withString: "", startingAtIndex: 0)
            }
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func sign(sender: AnyObject) {
        textFieldView.resignFirstResponder()
        let offset = CGPointMake(frame.origin.x + textFieldView.frame.origin.x, frame.origin.y + textFieldView.frame.origin.y)
        onAdd?(textView:textFieldView, origin: offset)
        self.hidden = true
        self.textFieldView.text = ""
    }
    @IBAction func cancel(sender: AnyObject) {
        self.hidden = true
        onClose?(sender: self)
    }
    
}
