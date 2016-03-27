//
//  Document.swift
//  SeegnatureSDK
//
//  Created by Moshe Krush on 14/03/16.
//  Copyright © 2016 Moshe Krush. All rights reserved.
//

import Foundation

class Document: NSObject {
    
    var created: NSDate?
    var docDescription: String?
    var id: Int?
    var name: String?
    var type: Int? // file type
    var uploaderId: Int?
    var pages = Array<Page>()

    convenience override init() {
        self.init(withDictionary:[:]) // calls above mentioned controller with default name
    }

    init(withDictionary dictionary: Dictionary<String, AnyObject>) {
        
        if let val = dictionary["created"] as? String {
            self.created = val.serverDateToNSDate()
        }
        
        if let val = dictionary["desc"] as? String {
            self.docDescription = val
        }
        
        if let val = dictionary["id"] as? Int {
            self.id = val
        }
        
        if let val = dictionary["name"] as? String {
            self.name = val
        }
        
        if let val = dictionary["type"] as? Int {
            self.type = val
        }
        
        if let val = dictionary["uploader"] as? Int {
            self.uploaderId = val
        }
        
    }

}

class Page: NSObject {
    
    var url: String?
    var index: Int?
    var image: UIImage?
    var document: Int?
    var pageResourceId: Int?
    
    init(withDictionary dictionary: Dictionary<String, AnyObject>) {

        if let val = dictionary["url"] as? String {
            self.url = val
        }
        
        if let val = dictionary["index"] as? Int {
            self.index = val
        }
        
        if let val = dictionary["pageId"] as? Int {
            self.pageResourceId = val
        }
        
        if let val = dictionary["document"] as? Int {
            self.document = val
        }
        
        if let val = dictionary["image"] as? UIImage {
            self.image = val
        }
    }
    
    convenience override init() {
        self.init(withDictionary:[:]) // calls above mentioned controller with default name
    }
}


