//
//  ChatBoxView.swift
//  Panda4doctor
//
//  Created by Erez Haim on 2/23/15.
//  Copyright (c) 2015 Erez. All rights reserved.
//

import UIKit

class ChatBoxView: UIView {
    var textView =  UITextView()
    var timeLabel =  UILabel()
    var tail =  UIImageView()
    
    override init (frame : CGRect) {
        super.init(frame : frame)
        addBehavior()
    }
    
    convenience init () {
        self.init(frame:CGRectZero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    convenience init(message: String, leftAlign: Bool){
        self.init(frame:CGRectZero)
        
        self.backgroundColor = UIColor.clearColor()
        translatesAutoresizingMaskIntoConstraints = false
        
        textView.text = "\(message)"
        textView.textColor = UIColor.whiteColor()
        textView.userInteractionEnabled = false
        textView.font = UIFont(name: "OpenSans", size: 14.0 )
        textView.backgroundColor = leftAlign ? ColorUtils.buttonColor() : ColorUtils.uicolorFromHex(0x58586F)
        ViewUtils.borderView(textView, borderWidth: 1.0, borderColor: UIColor.clearColor(), borderRadius: 13.0)
        
        timeLabel.text = TimeUtils.dateToTimeStr(NSDate())
        timeLabel.textColor = UIColor(red:1, green:1, blue:1, alpha:0.5)
        timeLabel.font = UIFont(name: "OpenSans", size: 12.0 )
        
        
        tail.image = UIImage(named: leftAlign ? "other_chupchik" : "my_chupchik")
        
        
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        
        self.addSubview(textView)
        self.addSubview(tail)
        self.addSubview(timeLabel)
        
        tail.sizeToFit()
        tail.addSizeConstaints(tail.frame.width, height: tail.frame.height)
        
        timeLabel.sizeToFit()
        timeLabel.addSizeConstaints(timeLabel.frame.width, height: timeLabel.frame.height)
        
        textView.textContainerInset = UIEdgeInsetsMake(6, 6, 6, 6 + timeLabel.frame.width)
        
        textView.sizeToFit()
        if (textView.frame.width > screenSize.width*0.7){
            textView.addSizeConstaints(screenSize.width*0.7 + 10, height: nil)
            textView.frame.size = textView.sizeThatFits(CGSizeMake(screenSize.width*0.7 + 10, CGFloat(MAXFLOAT)))
            
        } else {
            textView.addSizeConstaints(textView.frame.width + 10, height: nil)
            textView.frame.size = textView.sizeThatFits(CGSizeMake(textView.frame.width + 10, CGFloat(MAXFLOAT)))
        }
        textView.addSizeConstaints(nil, height: textView.frame.height)
        timeLabel.addConstraintsToSuperview(self, top: textView.frame.height - timeLabel.frame.height - 3.0, left: textView.frame.width - timeLabel.frame.width - 5, bottom: nil, right: nil)
        textView.addConstraintsToSuperview(self, top: 0.0, left: 0.0, bottom: nil, right: nil)

        
        let vConst = NSLayoutConstraint(item: textView, attribute: leftAlign ? NSLayoutAttribute.Leading :NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: tail, attribute: NSLayoutAttribute.Leading, multiplier: 1, constant: leftAlign ? 0.0 : 7.0)
        let bConst = NSLayoutConstraint(item: textView, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: tail, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0.0)
        self.addConstraints([vConst, bConst])
        
        self.frame.size = CGSizeMake(textView.frame.width + tail.frame.width + 20, textView.frame.height)
        self.addSizeConstaints(self.frame.width, height: self.frame.height)
        
        
        
    }
    
    func addBehavior (){
        
    }
    
    
}
