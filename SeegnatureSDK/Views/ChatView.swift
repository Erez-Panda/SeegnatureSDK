//
//  ChatView.swift
//  SeegnatureSDK
//
//  Created by Moshe Krush on 10/02/16.
//  Copyright © 2016 Moshe Krush. All rights reserved.
//

import UIKit

class ChatView: UIView, UITextFieldDelegate {

    var lastChatBox: UIView?
    var bottomConstraint: NSLayoutConstraint?
    
    @IBOutlet weak var chatText: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var chatTitle: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    
    override func awakeFromNib() {
        if let caller = CallUtils.currentCall?["caller"] as? NSDictionary{
            let firstName = (caller["user"] as? NSDictionary)?["first_name"] as! String
            let lastName = (caller["user"] as? NSDictionary)?["last_name"] as! String
            chatTitle.attributedText = ViewUtils.getAttrText("Chat with \(firstName) \(lastName)", color: UIColor.whiteColor(), size: 20.0)
        }
        
        chatText.attributedPlaceholder = ViewUtils.getAttrText("Type a message here...", color: UIColor.lightGrayColor(), size: 16.0)
    }

    // MARK: keyboard methods
    
    @IBAction func tappedView(tap: AnyObject) {
        let location = tap.locationInView(self)
        if CGRectContainsPoint(sendButton.frame, location){
            sendButtonPressed(tap)
        } else {
            chatText.resignFirstResponder()
        }
    }
    
//    func keyboardWillShown(sender: NSNotification){
//        let info: NSDictionary = sender.userInfo!
//        let value: NSValue = info.valueForKey(UIKeyboardFrameEndUserInfoKey) as! NSValue
//        let keyboardSize: CGSize = value.CGRectValue().size
//        UIView.animateWithDuration(0.1, animations: { () -> Void in
//            self.frame.origin.y  = -(keyboardSize.height )
//        })
//    }
//    
//    func keyboardWillHide(sender: NSNotification){
//        UIView.animateWithDuration(0.1, animations: { () -> Void in
//            self.frame.origin.y  = 0.0
//        })
//    }

    func addChatBox(message: String, isSelf: Bool){
        let chatBox = ChatBoxView(message: message, leftAlign: !isSelf)
        scrollView.addSubview(chatBox)
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        
        if (lastChatBox == nil){
            chatBox.addConstraintsToSuperview(scrollView, top: screenSize.height/2, left: nil, bottom: nil, right: nil)
        } else {
            let vConst = NSLayoutConstraint(item: chatBox, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: lastChatBox, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 10.0)
            scrollView.addConstraint(vConst)
        }
        chatBox.addConstraintsToSuperview(scrollView, top: nil, left: isSelf ? screenSize.width-chatBox.frame.width : 20, bottom: nil, right: nil)

        lastChatBox = chatBox
        
        if let bc = bottomConstraint {
            scrollView.removeConstraint(bc)
        }
        bottomConstraint  = NSLayoutConstraint(item: lastChatBox!, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: scrollView, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: -60.0)
        scrollView.addConstraint(bottomConstraint!)
        
        scrollView.contentOffset.y = scrollView.contentSize.height
        
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        sendMessageToRemote(textField.text!)
        textField.text = ""
        return true
    }
    
    func sendMessageToRemote(message: String){
        if message != "" {
            var maybeError : OTError?
            CallUtils.session?.signalWithType("chat_text", string: message, connection: nil, error: &maybeError)
            addChatBox(chatText.text!, isSelf: true)
        }
    }
    
    @IBAction func sendButtonPressed(sender: AnyObject) {
        sendMessageToRemote(chatText.text!)
        chatText.text = ""
    }

    @IBAction func closeButtonPressed(sender: AnyObject) {
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.frame.origin.y = self.frame.height
            self.removeFromSuperview()
        })
    }

}
