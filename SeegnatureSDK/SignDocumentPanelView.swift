//
//  SignDocumentPanelView.swift
//  Panda4doctor
//
//  Created by Erez Haim on 9/8/15.
//  Copyright (c) 2015 Erez. All rights reserved.
//

import UIKit

class SignDocumentPanelView: UIView {
    
    var onSign: ((signatureView: LinearInterpView, origin: CGPoint) -> ())?
    var onClose: ((sender: UIView) -> ())?
    
    @IBOutlet weak var signView: LinearInterpView!
    
    var center_x_constraint: NSLayoutConstraint?
    var center_y_constraint: NSLayoutConstraint?
    var height: NSLayoutConstraint?
    
    override func awakeFromNib() {
        self.layer.cornerRadius = 8
        self.layer.borderColor = ColorUtils.buttonColor().CGColor
        self.layer.borderWidth = 1
        self.clipsToBounds = true
        self.signView.blockTouches = true
        self.translatesAutoresizingMaskIntoConstraints = false
    }
    
    @IBAction func sign(sender: AnyObject) {
        let offset = CGPointMake(frame.origin.x + signView.frame.origin.x, frame.origin.y + signView.frame.origin.y)
        onSign?(signatureView:signView, origin: offset)
//        self.removeFromSuperview()
        self.hidden = true
        self.signView.cleanView()
    }
    @IBAction func cancel(sender: AnyObject) {
//        self.removeFromSuperview()
        self.hidden = true
        onClose?(sender: self)
    }
    
}
