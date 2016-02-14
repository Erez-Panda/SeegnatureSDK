//
//  Loader.swift
//  SeegnatureSDK
//
//  Created by Moshe Krush on 10/02/16.
//  Copyright © 2016 Moshe Krush. All rights reserved.
//

import Foundation
import OpenTok

public class SeegnatureActions: NSObject {
    
    public func doSomething(){
        print("Yeah, it works")
//        var session = OTSession(apiKey: "45145512", sessionId: "abcd", delegate: nil)
//        let manager = AFHTTPSessionManager()
    }
    
    public func startSession(id: String, superView: UIView, user: String? = nil, completion: ((view: UIView) -> Void)? = nil) -> Void{
            let documentView = NSBundle(forClass: SeegnatureActions.self).loadNibNamed("SessionView", owner: self, options: nil)[0] as! SessionView
            documentView.attachToView(superView)
//            documentView.user = user
            completion?(view: documentView)

    }

}