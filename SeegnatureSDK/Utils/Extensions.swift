//
//  Extensions.swift
//  SeegnatureSDK
//
//  Created by Moshe Krush on 14/02/16.
//  Copyright © 2016 Moshe Krush. All rights reserved.
//

import Foundation
import UIKit

//func printLog(text: AnyObject) {
func printLog(logMessage: AnyObject, functionName: String = __FUNCTION__) {
    print("----------------------------------")
    print("\(functionName): \(logMessage)")
    print("----------------------------------")
}

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
    
    func addSizeConstaints (width: CGFloat?, height: CGFloat?) -> Array<NSLayoutConstraint>{
        self.translatesAutoresizingMaskIntoConstraints = false
        var widthConstraint:NSLayoutConstraint = NSLayoutConstraint()
        var hightConstraint:NSLayoutConstraint = NSLayoutConstraint()
        if let w = width {
            widthConstraint = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: w)
            self.addConstraint(widthConstraint)
        }
        if let h = height {
            hightConstraint = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: h)
            self.addConstraint(hightConstraint)
        }
        return [widthConstraint, hightConstraint]
    }
    
    func setConstraintesToCenterSuperView(superView: UIView) ->Array<NSLayoutConstraint> {
        let centerXConstraint = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: superView, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0)
        superView.addConstraint(centerXConstraint)
        let centerYConstraint = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: superView, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0)
        superView.addConstraint(centerYConstraint)
        return [centerXConstraint, centerYConstraint]
    }
    
    func attachToView(superView: UIView){
        superView.addSubview(self)
        self.addConstraintsToSuperview(superView, top: 0, left: 0, bottom: 0, right: 0)
    }
    
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.nextResponder()
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}

extension String {
    var floatValue: Float {
        return (self as NSString).floatValue
    }
    
    func serverDateToNSDate() -> NSDate {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        return dateFormatter.dateFromString(self)!
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

extension Array {
    subscript (safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension UIButton {
    func setImageForAllStates(image: UIImage) {
        self.setImage(image, forState: .Application)
        self.setImage(image, forState: .Disabled)
        self.setImage(image, forState: .Focused)
        self.setImage(image, forState: .Highlighted)
        self.setImage(image, forState: .Normal)
        self.setImage(image, forState: .Reserved)
        self.setImage(image, forState: .Selected)
    }
}

extension UITextField {
    func setFontSize(size: CGFloat) {
        self.font = UIFont(name: self.font!.fontName, size: size)
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

public func getTopViewController() -> UIViewController? {
    if var topController = UIApplication.sharedApplication().keyWindow?.rootViewController {
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        
        return topController
        
    } else {
        return nil
    }
}

public func randomStringWithLength(length: Int) -> String {
    
    let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    
    let randomString : NSMutableString = NSMutableString(capacity: length)
    
    for (var i=0; i < length; i++){
        let length = UInt32 (letters.length)
        let rand = arc4random_uniform(length)
        randomString.appendFormat("%C", letters.characterAtIndex(Int(rand)))
    }
    
    return randomString as String
}

