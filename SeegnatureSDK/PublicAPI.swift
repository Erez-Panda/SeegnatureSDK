//
//  SeegnatureActions.swift
//  SeegnatureSDK
//
//  Created by Moshe Krush on 10/02/16.
//  Copyright © 2016 Moshe Krush. All rights reserved.
//

import Foundation

public class SeegnatureActions: NSObject {

    public func getSessionInfo(id: String, completion: (result: Bool) -> Void) {

        Session.sharedInstance.getSessionInfo(id, completion:  { (result) -> Void in
            if (result.count == 0) {
                completion(result: false)
            } else {
                completion(result: true)
            }
        })
        
    }

    public func startSession(superView: UIView, dictionary: NSDictionary, completion: () -> Void) {

        Session.sharedInstance.handleSessioInfoResponse({ () -> Void in

            Session.sharedInstance.capabilities = dictionary
            Session.sharedInstance.loadView(superView)
            completion()
        })
    }

}