//
//  UIEventRegister.swift
//  Panda4doctor
//
//  Created by Erez on 1/28/15.
//  Copyright (c) 2015 Erez. All rights reserved.
//

struct UIEventRegister {
    
    static func gestureRecognizer(sender: UIViewController, rightAction: Selector, leftAction: Selector, upAction: Selector, downAction: Selector) -> Void{
        if rightAction != "" {
            let swipeRight = UISwipeGestureRecognizer(target: sender, action: rightAction)
            swipeRight.direction = UISwipeGestureRecognizerDirection.Right
            swipeRight.cancelsTouchesInView = false
            sender.view.addGestureRecognizer(swipeRight)
        }
        if leftAction != "" {
            let swipeLeft = UISwipeGestureRecognizer(target: sender, action: leftAction)
            swipeLeft.direction = UISwipeGestureRecognizerDirection.Left
            swipeLeft.cancelsTouchesInView = false
            sender.view.addGestureRecognizer(swipeLeft)
        }
        if upAction != "" {
            let swipeUp = UISwipeGestureRecognizer(target: sender, action: upAction)
            swipeUp.direction = UISwipeGestureRecognizerDirection.Up
            swipeUp.cancelsTouchesInView = false
            sender.view.addGestureRecognizer(swipeUp)
        }
        if downAction != "" {
            let swipeDown = UISwipeGestureRecognizer(target: sender, action: downAction)
            swipeDown.direction = UISwipeGestureRecognizerDirection.Down
            swipeDown.cancelsTouchesInView = false
            sender.view.addGestureRecognizer(swipeDown)
        }
        
    }
    
    static func tapRecognizer(sender: UIViewController, action: Selector){
        let tap:UITapGestureRecognizer = UITapGestureRecognizer(target: sender, action: action)
        tap.cancelsTouchesInView = false
        sender.view.addGestureRecognizer(tap)
    }
}