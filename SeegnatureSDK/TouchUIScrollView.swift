//
//  TouchUIScrollView.swift
//  Panda4rep
//
//  Created by Erez Haim on 7/28/15.
//  Copyright (c) 2015 Erez. All rights reserved.
//

import UIKit

class TouchUIScrollView: UIScrollView {
    var parent: UIViewController?
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        parent?.touchesBegan(touches, withEvent: event)
        super.touchesBegan(touches, withEvent: event)
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        parent?.touchesMoved(touches, withEvent: event)
        super.touchesMoved(touches, withEvent: event)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        parent?.touchesEnded(touches, withEvent: event)
        super.touchesEnded(touches, withEvent: event)
    }
    /*
    override func touchesCancelled(touches: Set<NSObject>!, withEvent event: UIEvent!) {
    parent?.touchesCancelled(touches, withEvent: event)
    super.touchesCancelled(touches, withEvent: event)
    }
    */
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
