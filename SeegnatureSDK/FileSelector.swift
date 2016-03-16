//
//  FileSelector.swift
//  LiveSign
//
//  Created by Erez Haim on 10/28/15.
//  Copyright © 2015 Erez. All rights reserved.
//

import Foundation
import MobileCoreServices

public protocol FileSelectorDelegate{
    func fileSelected(file: File)
}

public class FileSelector : NSObject, UIDocumentMenuDelegate, UIDocumentPickerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    public let viewController: UIViewController!
    public var delegate:FileSelectorDelegate?
    
    public init(viewController: UIViewController) {
        self.viewController = viewController
    }
    
    public func selectFile(sender: UIButton) {
        let documentMenu = UIDocumentMenuViewController(documentTypes: [kUTTypeCompositeContent as String, kUTTypeImage as String], inMode: UIDocumentPickerMode.Import)
        documentMenu.delegate = self
        documentMenu.popoverPresentationController?.sourceView = sender
        documentMenu.addOptionWithTitle("Photos", image: nil, order: UIDocumentMenuOrder.First) { () -> Void in
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.sourceType = .PhotoLibrary
            self.viewController?.presentViewController(imagePickerController, animated: true, completion: nil)
        }
        documentMenu.addOptionWithTitle("Take Photo", image: nil, order: UIDocumentMenuOrder.First) { () -> Void in
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.sourceType = .Camera
            self.viewController?.presentViewController(imagePickerController, animated: true, completion: nil)
        }
        viewController?.presentViewController(documentMenu, animated: true, completion: nil)
    }
    
    public func documentMenu(documentMenu: UIDocumentMenuViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        documentPicker.delegate = self
        viewController?.presentViewController(documentPicker, animated: true, completion:nil)
    }
    
    public func documentPicker(controller: UIDocumentPickerViewController, didPickDocumentAtURL url: NSURL) {
        getDataFromUrl(url) { (data) -> Void in
            var mimetype = "invalid"
            if url.lastPathComponent!.containsString("pdf"){
                mimetype = "application/pdf"
            } else if url.lastPathComponent!.containsString("png"){
                mimetype = "image/png"
            }
            else if url.lastPathComponent!.containsString("jpg") || url.lastPathComponent!.containsString("jepg"){
                mimetype = "image/jpeg"
            }
            self.delegate?.fileSelected(File(data: data, name: url.lastPathComponent, mimetype: mimetype))
        }
        
    }

    public func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        self.delegate?.fileSelected(File(data: UIImageJPEGRepresentation(image, 1.0), name: "image", mimetype: "image/jpeg"))
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    public func getDataFromUrl(url:NSURL, completion: ((data: NSData?) -> Void)) {
        NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) in
            completion(data: data)
            }.resume()
    }
}

public class File {
    public var data: NSData?
    public var name: String?
    public var mimetype: String
    
    public init(data: NSData?, name: String?, mimetype: String){
        self.data = data
        self.name = name
        self.mimetype = mimetype
        
    }
}