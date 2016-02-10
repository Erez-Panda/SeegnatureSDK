//
//  Loader.swift
//  SeegnatureSDK
//
//  Created by Moshe Krush on 10/02/16.
//  Copyright © 2016 Moshe Krush. All rights reserved.
//

import Foundation
import OpenTok

public class SwiftFrameworks {
    public init (){
        print("Class has been initialised")
        
    }
    
    public func doSomething(){
        print("Yeah, it works")
        var session = OTSession(apiKey: "45145512", sessionId: "abcd", delegate: nil)
    }
}
