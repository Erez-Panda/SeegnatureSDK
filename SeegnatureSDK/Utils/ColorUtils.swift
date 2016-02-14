//
//  ColorUtils.swift
//  Panda4doctor
//
//  Created by Erez on 1/27/15.
//  Copyright (c) 2015 Erez. All rights reserved.
//

struct ColorUtils {

    static func uicolorFromHex(rgbValue:UInt32)->UIColor{
        let red = CGFloat((rgbValue & 0xFF0000) >> 16)/256.0
        let green = CGFloat((rgbValue & 0xFF00) >> 8)/256.0
        let blue = CGFloat(rgbValue & 0xFF)/256.0
        return UIColor(red:red, green:green, blue:blue, alpha:1.0)
    }
    
    static func mainColor()-> UIColor{
        return uicolorFromHex(0x464567)
    }
    
    static func buttonColor()-> UIColor{
        return uicolorFromHex(0x67CA94)
    }

}