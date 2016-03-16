//
//  LoginController.swift
//  SeegnatureSDK
//
//  Created by Moshe Krush on 10/03/16.
//  Copyright © 2016 Moshe Krush. All rights reserved.
//

import Foundation

class LoginController: NSObject {

    static let sharedInstance = LoginController()
    
    override init() {
        printLog("Initializing Login controller class")
    }

    
//    func sendLoginRequest(email:String, password: String, completion: (result: Bool) -> Void) -> Void {
//        
//        ServerAPI.sharedInstance.(id, completion: {result -> Void in
//            
//            self.currentCall = result
//            CallUtils.currentCall = result
//            
//            completion(result: result)
//            
//            //            CallUtils.getCallerImage()
//            
//        })
//        
//    }

}