//
//  UIEventRegister.swift
//  Panda4doctor
//
//  Created by Erez on 1/28/15.
//  Copyright (c) 2015 Erez. All rights reserved.
//

struct UIEventRegister {
    
    static func gestureRecognizer(sender: UIView, rightAction: Selector, leftAction: Selector, upAction: Selector, downAction: Selector) -> Void{
        if rightAction != nil {
            let swipeRight = UISwipeGestureRecognizer(target: sender, action: rightAction)
            swipeRight.direction = UISwipeGestureRecognizerDirection.Right
            swipeRight.cancelsTouchesInView = false
            sender.addGestureRecognizer(swipeRight)
        }
        if leftAction != nil {
            let swipeLeft = UISwipeGestureRecognizer(target: sender, action: leftAction)
            swipeLeft.direction = UISwipeGestureRecognizerDirection.Left
            swipeLeft.cancelsTouchesInView = false
            sender.addGestureRecognizer(swipeLeft)
        }
        if upAction != nil {
            let swipeUp = UISwipeGestureRecognizer(target: sender, action: upAction)
            swipeUp.direction = UISwipeGestureRecognizerDirection.Up
            swipeUp.cancelsTouchesInView = false
            sender.addGestureRecognizer(swipeUp)
        }
        if downAction != nil {
            let swipeDown = UISwipeGestureRecognizer(target: sender, action: downAction)
            swipeDown.direction = UISwipeGestureRecognizerDirection.Down
            swipeDown.cancelsTouchesInView = false
            sender.addGestureRecognizer(swipeDown)
        }
        
    }
    
    static func tapRecognizer(sender: UIViewController, action: Selector){
        let tap:UITapGestureRecognizer = UITapGestureRecognizer(target: sender, action: action)
        tap.cancelsTouchesInView = false
        sender.view.addGestureRecognizer(tap)
    }
}