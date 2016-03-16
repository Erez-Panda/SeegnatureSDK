//
//  SeegnatureActions.swift
//  SeegnatureSDK
//
//  Created by Moshe Krush on 10/02/16.
//  Copyright © 2016 Moshe Krush. All rights reserved.
//

import Foundation

public class SeegnatureActions: NSObject {

    public func sendDeviceToken(token: String) {
        printLog("Sending device token to server")
        ServerAPI.sharedInstance.sendDeviceToken(token)
    }
    
    public func login(email: String, password: String, completion: (result: Bool) -> Void) {
        printLog("Sending login request")
        ServerAPI.sharedInstance.login(email, password: password, completion: { (result) -> Void in
            completion(result: result)
        })
    }
    
    public func logout(completion: (result: Bool) -> Void) {
        printLog("Sending login request")
        ServerAPI.sharedInstance.logout(){ (result) -> Void in
            completion(result: result)
        }
    }
    
    public func getUserDetails(completion: (result: NSDictionary) -> Void) -> Void{
        printLog("Getting user info")
        ServerAPI.sharedInstance.getUser({result -> Void in
            completion(result: result)
        })
    }
    
    public func getFileFromURL(file: NSNumber, completion: (result: NSString) -> Void) -> Void{
        printLog("Requesting file")
        ServerAPI.sharedInstance.getFileUrl(file, completion: { (result) -> Void in
            completion(result: result)
        })
    }

    public func getSessionInfo(id: String, completion: (result: Bool) -> Void) {
        printLog("Requsting session info")
        Session.sharedInstance.getSessionInfo(id, completion:  { (result) -> Void in
            if (result.count == 0) {
                completion(result: false)
            } else {
                completion(result: true)
            }
        })
    }
    
    public func startSession(superView: UIView, dictionary: NSDictionary, isRep: Bool, resources: Array<Dictionary<String, AnyObject>>?, completion: () -> Void) {
        printLog("Starting session")
        Session.sharedInstance.handleSessioInfoResponse({ () -> Void in
            Session.sharedInstance.capabilities = dictionary
            Session.sharedInstance.isRep = isRep
            if (resources != nil) {
                Session.sharedInstance.resources = resources                
            } else {
                if let res = Session.sharedInstance.currentCall!["related_resource"] as? Dictionary<String, AnyObject>{
                    Session.sharedInstance.resources = [res]
                }
            }

            Session.sharedInstance.loadView(superView)
            completion()
        })
    }
    
    public func uploadFile(data: NSData, fileName: String, mimeType: String, completion: (result: NSDictionary) -> Void) -> Void {
        printLog("Uploading file")
        ServerAPI.sharedInstance.uploadFile(data, filename: fileName, mimetype: mimeType, completion: { (result) -> Void in
            if let res = result as? NSDictionary {
                completion(result: res)
            } else {
                completion(result: [:])
            }
        })
    }
    
    public func createNewContact(info: Dictionary<String, AnyObject>, completion: (result: NSDictionary) -> Void) -> Void {
        printLog("New contact request")
        ServerAPI.sharedInstance.newContact(info, completion: { (result) -> Void in
            completion(result: result)
        })
    }
    
    public func newResource(info: Dictionary<String, AnyObject>, completion: (result: NSDictionary) -> Void) -> Void {
        printLog("Creating new resource")
        ServerAPI.sharedInstance.newResource(info, completion: { (result) -> Void in
            completion(result: result)
        })
    }
    
    public func newGuestCall(callData: Dictionary<String, AnyObject>, completion: (result: NSDictionary) -> Void) -> Void {
        ServerAPI.sharedInstance.newGuestCall(callData, completion: { (result) -> Void in
            completion(result: result)
        })
    }

}