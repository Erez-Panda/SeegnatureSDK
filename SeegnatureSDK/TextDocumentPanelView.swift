//
//  SignDocumentPanelView.swift
//  Panda4doctor
//
//  Created by Erez Haim on 9/8/15.
//  Copyright (c) 2015 Erez. All rights reserved.
//

import UIKit

class TextDocumentPanelView: UIView, UITextFieldDelegate {
    
    var onAdd: ((textView: UITextField, origin: CGPoint) -> ())?
    var onClose: ((sender: UIView) -> ())?
    
    var center_x_constraint: NSLayoutConstraint?
    var center_y_constraint: NSLayoutConstraint?
    
    @IBOutlet weak var textFieldView: UITextField!
    
    override func awakeFromNib() {
        self.layer.cornerRadius = 8
        self.layer.borderColor = ColorUtils.buttonColor().CGColor
        self.layer.borderWidth = 1
        self.clipsToBounds = true
        textFieldView.delegate = self
        textFieldView.addTarget(self, action: "textDidChange", forControlEvents: UIControlEvents.EditingChanged)
        self.translatesAutoresizingMaskIntoConstraints = false
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
//        self.removeFromSuperview()
        self.hidden = true
        self.textFieldView.text = ""
    }
    @IBAction func cancel(sender: AnyObject) {
//        self.removeFromSuperview()
        self.hidden = true
        onClose?(sender: self)
    }
    
}
