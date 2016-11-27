//
//  LinearInterpView.swift
//  Panda4rep
//
//  Created by Erez Haim on 5/8/15.
//  Copyright (c) 2015 Erez. All rights reserved.
//

import UIKit

class LinearInterpView: UIView {
    
    var path : UIBezierPath?
    var enabled = true
    var points: Array<Array<CGPoint>> = []
    var blockTouches = false
    
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        ColorUtils.uicolorFromHex(0x000F7D).setStroke()
        //UIColor.blackColor().setStroke()
        path?.stroke()
        // Drawing code
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.multipleTouchEnabled = false
        self.backgroundColor = UIColor.clearColor()
        path = UIBezierPath()
        path?.lineWidth = 2.0
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if !blockTouches{
            super.touchesBegan(touches, withEvent: event)
        }
        if (enabled){
            if let touch: UITouch = touches.first{
                //((touch.gestureRecognizers as NSArray)[0] as! UIGestureRecognizer).cancelsTouchesInView = false
                let touchLocation = touch.locationInView(self) as CGPoint
                path?.moveToPoint(touchLocation)
                points.append([touchLocation])
            }
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if !blockTouches{
            super.touchesEnded(touches, withEvent: event)
        }
    }
    override func touchesCancelled(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if !blockTouches{
            super.touchesCancelled(touches, withEvent: event)
        }
    }
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if !blockTouches{
            super.touchesMoved(touches, withEvent: event)
        }
        if (enabled){
            if let touch: UITouch = touches.first{
                let touchLocation = touch.locationInView(self) as CGPoint
                path?.addLineToPoint(touchLocation)
                points[points.count-1].append(touchLocation)
                self.setNeedsDisplay()
            }
        }
    }
    
    func cleanView(){
        if (self.path != nil) {
            self.path?.removeAllPoints()
            points = []
            self.setNeedsDisplay()
        }
    }
    
    
}
