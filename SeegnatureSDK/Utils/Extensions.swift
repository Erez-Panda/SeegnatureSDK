//
//  Extensions.swift
//  SeegnatureSDK
//
//  Created by Moshe Krush on 14/02/16.
//  Copyright © 2016 Moshe Krush. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    
    func addBorder(borderColor: UIColor, borderWidth: CGFloat = 1) {
        self.layer.borderWidth = borderWidth
        self.clipsToBounds = true
        self.layer.borderColor = borderColor.CGColor
    }
    
    func addConstraintsToSuperview(superView: UIView, top: CGFloat?, left: CGFloat?, bottom: CGFloat?, right: CGFloat?) -> Dictionary<String, NSLayoutConstraint> {
        var result : Dictionary<String, NSLayoutConstraint> = [:]
        self.translatesAutoresizingMaskIntoConstraints = false
        if let t = top {
            let topConstraint = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: superView, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: t)
            superView.addConstraint(topConstraint)
            result["top"] = topConstraint
        }
        if let l = left {
            let leftConstraint = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: superView, attribute: NSLayoutAttribute.Leading, multiplier: 1, constant: l)
            superView.addConstraint(leftConstraint)
            result["left"] = leftConstraint
        }
        if let b = bottom {
            let bottomConstraint = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: superView, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: b)
            superView.addConstraint(bottomConstraint)
            result["bottom"] = bottomConstraint
        }
        
        if let r = right {
            let rightConstraint = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: superView, attribute: NSLayoutAttribute.Right, multiplier: 1, constant: r)
            superView.addConstraint(rightConstraint)
            result["right"] = rightConstraint
        }
        return result
    }
    
    func addSizeConstaints (view: UIView, width: CGFloat?, height: CGFloat?) -> Array<NSLayoutConstraint>{
        view.translatesAutoresizingMaskIntoConstraints = false
        var widthConstraint:NSLayoutConstraint = NSLayoutConstraint()
        var hightConstraint:NSLayoutConstraint = NSLayoutConstraint()
        if let w = width {
            widthConstraint = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: w)
            view.addConstraint(widthConstraint)
        }
        if let h = height {
            hightConstraint = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: h)
            view.addConstraint(hightConstraint)
        }
        return [widthConstraint, hightConstraint]
    }
}

extension NSMutableData {
    
    /// Append string to NSMutableData
    ///
    /// Rather than littering my code with calls to `dataUsingEncoding` to convert strings to NSData, and then add that data to the NSMutableData, this wraps it in a nice convenient little extension to NSMutableData. This converts using UTF-8.
    ///
    /// - parameter string:       The string to be added to the `NSMutableData`.
    
    func appendString(string: String) {
        let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        appendData(data!)
    }
}

extension UIImage {
    
    func imageWithColor(tintColor: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        
        let context = UIGraphicsGetCurrentContext()!
        CGContextTranslateCTM(context, 0, self.size.height)
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextSetBlendMode(context, CGBlendMode.Normal)
        
        let rect = CGRectMake(0, 0, self.size.width, self.size.height) as CGRect
        CGContextClipToMask(context, rect, self.CGImage)
        tintColor.setFill()
        CGContextFillRect(context, rect)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext() as UIImage
        UIGraphicsEndImageContext()
        
        return newImage
    }
}

