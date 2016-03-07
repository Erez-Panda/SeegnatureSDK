//
//  UIViewWithLayerUpdate.swift
//  LiveSign
//
//  Created by Erez Haim on 10/12/15.
//  Copyright © 2015 Erez. All rights reserved.
//

import UIKit

class UIViewWithLayerUpdate: UIView {
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
    // Drawing code
    }
    */
    
    override func layoutSubviews() {
        let f = self.frame
        if let layers = self.layer.sublayers{
            for layer in layers {
                layer.frame.size = f.size
            }
        }
    }
    
}