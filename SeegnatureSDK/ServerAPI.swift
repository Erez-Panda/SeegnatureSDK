//
//  ServerAPI.swift
//  SeegnatureSDK
//
//  Created by Moshe Krush on 11/02/16.
//  Copyright © 2016 Moshe Krush. All rights reserved.
//

import Foundation

var SERVER_URL = "https://www.seegnature.com"
//var SERVER_URL = "http://www.livemed-test.com"

// MARK:

class ServerAPI {
    
    static let sharedInstance = ServerAPI()

    let manager = AFHTTPSessionManager()
    var token = ""
    
    // MARK: requst type enum
    
    enum RequestType{
        case POST
        case GET
        case DELETE
        case PATCH
        case PUT
    }
    
    func getArrayResult(result: AnyObject) ->NSArray {
        if let res = result as? NSArray {
            return res
        } else {
            if let res = result as? NSData {
                let arr_as_string = String(NSString(data: res, encoding: NSUTF8StringEncoding)!)
                let arr_first_object = arr_as_string.subString(1, length: arr_as_string.characters.count-2)
                let d = CallUtils.convertStringToDictionary(arr_first_object)
                return [d!]
            }
            return []
        }
    }
    
    func getDictionaryResult(result: AnyObject) ->NSDictionary {
        if let res = result as? NSDictionary {
            return res
        } else {
            if let res = result as? NSData {
                let newDictionary = CallUtils.convertStringToDictionary(String(NSString(data: res, encoding: NSUTF8StringEncoding)!))!
                return newDictionary
            } else {
                return [:]
            }
        }
    }
    
    func getStringResult(result: AnyObject) ->NSString {
        if let data = result as? NSData{
            if let res = NSString(data: data, encoding: NSUTF8StringEncoding){
                return res.stringByReplacingOccurrencesOfString("\"", withString: "", options: [], range: NSMakeRange(0,res.length))
            } else {
                return ""
            }
        }
        return ""
    }
    
    func getBoolResult(result: AnyObject) ->Bool {
        if let res = result as? Bool {
            return res
        } else {
            return false
        }
    }
    
    func sendDeviceToken(token: String, completion: (result: Bool) -> Void) -> Void{
        let data = ["registration_id": token] as Dictionary<String, String>
        self.http("/users/device-token/", message: data, method: .POST, completion: {result -> Void in
        })
    }
    
    func login(email: String, password: String, completion: (result: Bool) -> Void) -> Void{

        let message = ["username":email, "password":password]
        
        self.http("/api-token-auth/", message: message, method: .POST, completion: {result -> Void in
            if let res = result as? NSDictionary{
                if (nil != res["token"]){
                    self.token = res["token"] as! NSString as String
                    completion(result: true)
                } else {
                    completion(result: false)
                }
            } else {
                completion(result: false)
            }
        })
    }
    
    func logout(completion: (result: Bool) -> Void) -> Void{
//        func loginout(completion: (result: Bool) -> Void) -> Void{
            completion(result: true) //fix after adding response to server
//        }
    }
    
    
    func getUser (completion: (result: NSDictionary) -> Void) -> Void{
        self.http("/users/me/", completion: {result -> Void in
            completion(result: self.getDictionaryResult(result))
        })
    }
    
    func getUserById (id: NSNumber, completion: (result: NSDictionary) -> Void) -> Void{
        self.http("/users/\(id)/", completion: {result -> Void in
            completion(result: self.getDictionaryResult(result))
        })
    }
    
    func loginout(completion: (result: Bool) -> Void) -> Void{
        completion(result: true) //fix after adding response to server
    }
    
    func isEmailAvailable (email: String, completion: (result: NSDictionary) -> Void) -> Void{
        self.http("/users/email_available/?email=\(email)", completion: {result -> Void in
            completion(result: self.getDictionaryResult(result))
        })
    }
    func registerUser (userData: Dictionary<String, AnyObject>, completion: (result: NSDictionary) -> Void) -> Void{
        self.http("/users/", message: userData, method: .POST, completion: {result -> Void in
            completion(result: self.getDictionaryResult(result))
        })
    }
    
    func updateUser (userData: Dictionary<String, AnyObject>, id: NSNumber, completion: (result: NSDictionary) -> Void) -> Void{
        self.http("/users/\(id)/",method: .PUT, message: userData, completion: {result -> Void in
            completion(result: self.getDictionaryResult(result))
        })
    }
    
    func getProducts (completion: (result: NSArray) -> Void) -> Void{
        self.http("/products/", completion: {result -> Void in
            completion(result: self.getArrayResult(result))
        })
    }
    
    func getCallOpenings (product: NSNumber, completion: (result: NSArray) -> Void) -> Void{
        self.http("/scheduler/call_openings/?product=\(product)", completion: {result -> Void in
            completion(result: self.getArrayResult(result))
        })
    }
    
    func newCall (callData: Dictionary<String, AnyObject>, fromSlot: NSNumber, completion: (result: NSDictionary) -> Void) -> Void{
        self.http("/calls/new/?from_slot=\(fromSlot)",method: .POST, message: callData, completion: {result -> Void in
            completion(result: self.getDictionaryResult(result))
        })
    }
    
    func newCallRequest (callData: Dictionary<String, AnyObject>, completion: (result: NSDictionary) -> Void) -> Void{
        self.http("/calls/requests/",method: .POST, message: callData, completion: {result -> Void in
            completion(result: self.getDictionaryResult(result))
        })
    }
    
    func getCurrentCall (completion: (result: NSDictionary) -> Void) -> Void{
        self.http("/calls/user/current/", completion: {result -> Void in
            completion(result: self.getDictionaryResult(result))
        })
    }
    
    func getCallById (id: String, completion: (result: NSDictionary) -> Void) -> Void{
        self.http("/calls/\(id)/", completion: {result -> Void in
            completion(result: self.getDictionaryResult(result))
        })
    }
    
    func updateCallById (id: NSNumber, data: Dictionary<String, AnyObject>, completion: (result: NSDictionary) -> Void) -> Void{
        self.http("/calls/\(id)/", message: data,  method: .PATCH, completion: {result -> Void in
            completion(result: self.getDictionaryResult(result))
        })
    }
    
    func deleteCallById (id: NSNumber, completion: (result: NSDictionary) -> Void) -> Void{
        self.http("/calls/\(id)/", method: .DELETE, completion: {result -> Void in
            completion(result: self.getDictionaryResult(result))
        })
    }
    
    
    func rescheduleCall (rescheduleData: Dictionary<String, AnyObject>, completion: (result: NSDictionary) -> Void) -> Void{
        self.http("/calls/requests/reschedule/", message: rescheduleData, method: .POST, completion: {result -> Void in
            completion(result: self.getDictionaryResult(result))
        })
    }
    
    func getUserCalls (completion: (result: NSArray) -> Void) -> Void {
        self.http("/calls/user/", completion: { (result) -> Void in
            completion(result: self.getArrayResult(result))
        })
    }
    
    func getUserLetters (completion: (result: NSArray) -> Void) -> Void {
        self.http("/products/user/medical_letter_requests/", completion: { (result) -> Void in
            completion(result: self.getArrayResult(result))
        })
    }
    
    func sendDeviceToken (token: String){
        let data = ["registration_id": token] as Dictionary<String, String>
        self.http("/users/device-token/", message: data, method: .POST, completion: {result -> Void in
        })
        
    }
    
    func newPostCall(data: Dictionary<String, AnyObject>, completion: (result: Bool) -> Void) -> Void{
        self.http("/calls/post_calls/", message: data, method: .POST, completion: {result -> Void in
            completion(result: true)
        })
    }
    
    func getProductArticles(product:NSNumber, completion: (result: NSArray) -> Void) -> Void{
        self.http("/products/articles/?product=\(product)", completion: {result -> Void in
            completion(result: self.getArrayResult(result))
        })
    }
    
    func getProductPromotionalMaterials(product:NSNumber, completion: (result: NSArray) -> Void) -> Void{
        self.http("/products/promotional_materials/?product=\(product)", completion: {result -> Void in
            completion(result: self.getArrayResult(result))
        })
    }
    
    func getFileUrl(file: NSNumber, completion: (result: NSString) -> Void) -> Void{
        self.http("/resources/files/?file=\(file)", isJSONRequest: false, completion: {result -> Void in
            completion(result: self.getStringResult(result))
        })
    }
    
    func newMedicalLetterRequest(request: Dictionary<String, AnyObject>, completion: (result: Bool) -> Void) -> Void{
        self.http("/products/medical_letter_requests/", method: .POST, message: request, completion: {result -> Void in
            completion(result: true)
        })
    }
    
    func newSampleRequest(request: Dictionary<String, AnyObject>, completion: (result: Bool) -> Void) -> Void{
        self.http("/products/sample_requests/", message: request ,method: .POST, completion: {result -> Void in
            completion(result: true)
        })
    }
    
    func getProductSampleTypes(product:NSNumber, completion: (result: NSArray) -> Void) -> Void{
        self.http("/products/sample_types/?product=\(product)", completion: {result -> Void in
            completion(result: self.getArrayResult(result))
        })
    }
    
    func getDictionary(type: String, completion: (result: NSArray) -> Void) -> Void{
        self.http("/dictionary/\(type)/", completion: {result -> Void in
            completion(result: self.getArrayResult(result))
        })
    }
    
    func getAllDrugs(completion: (result: NSArray) -> Void) -> Void{
        self.http("/drugs/", completion: {result -> Void in
            completion(result: self.getArrayResult(result))
        })
    }
    
    func getTherapyArea(completion: (result: NSArray) -> Void) -> Void{
        self.http("/drugs/therapy_areas/", completion: {result -> Void in
            completion(result: self.getArrayResult(result))
        })
    }
    
    func getSubTherapyArea(therapyArea: NSNumber, completion: (result: NSArray) -> Void) -> Void{
        self.http("/drugs/sub_therapy_areas/?therapy_area=\(therapyArea)", completion: {result -> Void in
            completion(result: self.getArrayResult(result))
        })
    }
    
    func getSubTherapyAreaDrugs(subTherapyArea: NSNumber, completion: (result: NSArray) -> Void) -> Void{
        self.http("/drugs/sub_therapy_drugs/?sub_therapy_area=\(subTherapyArea)", completion: {result -> Void in
            completion(result: self.getArrayResult(result))
        })
    }
    
    func getSubTherapyAreaProduct(subTherapyArea: NSNumber, completion: (result: NSArray) -> Void) -> Void{
        self.http("/drugs/sub_therapy_products/?sub_therapy_area=\(subTherapyArea)", completion: {result -> Void in
            completion(result: self.getArrayResult(result))
        })
    }
    
    func setUserEmailNotifications(request: Dictionary<String, AnyObject>, completion: (result: Bool) -> Void) -> Void{
        self.http("/users/doctors/email_settings/", method: .POST, message: request, completion: {result -> Void in
            completion(result: true)
        })
    }
    
    func resetUserPassword(request: Dictionary<String, AnyObject>, completion: (result: NSDictionary) -> Void) -> Void{
        self.http("/users/reset_password/", message: request ,method: .POST, completion: {result -> Void in
            completion(result: self.getDictionaryResult(result))
        })
    }
    
    func sendSupportEmail(request: Dictionary<String, AnyObject>, completion: (result: Bool) -> Void) -> Void{
        self.http("/users/support_email/", message: request ,method: .POST, completion: {result -> Void in
            completion(result: true)
        })
    }
    
    func newSignedDocument(data: Dictionary<String, AnyObject>, completion: (result: NSDictionary) -> Void) -> Void{
        self.http("/sign-documents/", message: data, method: .POST, completion: {result -> Void in
            completion(result: self.getDictionaryResult(result))
        })
    }
    
    func newPartialDocument(data: Dictionary<String, AnyObject>, completion: (result: NSDictionary) -> Void) -> Void{
        self.http("/sign-documents/partial/", message: data, method: .POST, completion: {result -> Void in
            completion(result: self.getDictionaryResult(result))
        })
    }
    
    func lockDocument(data: Dictionary<String, AnyObject>, completion: (result: NSDictionary) -> Void) -> Void{
        self.http("/sign-documents/lock/", message: data, method: .POST, completion: {result -> Void in
            completion(result: self.getDictionaryResult(result))
        })
    }
    
    func getGeonamesChildren(geonameId: NSNumber, completion: (result: NSDictionary) -> Void) -> Void{
        self.http("http://api.geonames.org/children?type=json&geonameId=\(geonameId)&username=erezh", useURLPrefix: false, completion: {result -> Void in
            completion(result: self.getDictionaryResult(result))
        })
    }
    func getGeonamesSearch(data: Dictionary<String, AnyObject>, completion: (result: NSDictionary) -> Void) -> Void{
        var message = data
        message["type"] = "json"
        message["username"] = "erezh"
        self.http("http://api.geonames.org/search?featureCode=PPL&featureCode=PPLA&featureCode=PPLA2", message: message, useURLPrefix: false, completion: {result -> Void in
            completion(result: self.getDictionaryResult(result))
        })
    }
    
    func newContact(data: Dictionary<String, AnyObject>, completion: (result: NSDictionary) -> Void) -> Void{
        self.http("/contacts/", message: data, method: .POST, completion: {result -> Void in
            completion(result: self.getDictionaryResult(result))
        })
    }
    
    func newResource(data: Dictionary<String, AnyObject>, completion: (result: NSDictionary) -> Void) -> Void{
        self.http("/resources/", message: data, method: .POST, completion: {result -> Void in
            completion(result: self.getDictionaryResult(result))
        })
    }
    
    func newGuestCall (callData: Dictionary<String, AnyObject>, completion: (result: NSDictionary) -> Void) -> Void{
        self.http("/calls/new/?guest_call=\(true)", message: callData, method: .POST, completion: {result -> Void in
            completion(result: self.getDictionaryResult(result))
        })
    }
    
    func newModification(data: Dictionary<String, AnyObject>, completion: (result: NSDictionary) -> Void) -> Void{
        self.http("/sign-documents/modifications/", message: data, method: .POST, completion: {result -> Void in
            completion(result: self.getDictionaryResult(result))
        })
    }
    func getResourceDisplay(resourceId: NSNumber, completion: (result: NSArray) -> Void) -> Void{
        self.http("/resources/display/?resource=\(resourceId)", completion: {result -> Void in
            completion(result: self.getArrayResult(result))
        })
    }
    
    func startCallArchive(data: Dictionary<String, AnyObject>,completion: (result: Bool) -> Void) -> Void{
        self.http("/calls/archive/start/", message: data, method: .POST, completion: {result -> Void in
            completion(result: true)
        })
    }
    
    func stopCallArchive(data: Dictionary<String, AnyObject>,completion: (result: Bool) -> Void) -> Void{
        self.http("/calls/archive/stop/", message: data, method: .POST, completion: {result -> Void in
            completion(result: true)
        })
    }
    
    
    
    func getAFManager(isJSONRequest: Bool) -> AFHTTPSessionManager{

        if (isJSONRequest){
            self.manager.requestSerializer = AFJSONRequestSerializer()
            self.manager.requestSerializer.setValue("application/json", forHTTPHeaderField: "Content-Type")
            self.manager.requestSerializer.setValue("application/json", forHTTPHeaderField: "Accept")
        } else {
            self.manager.responseSerializer = AFHTTPResponseSerializer()
        }
        if (self.token != ""){
            self.manager.requestSerializer.setValue("Token", forHTTPHeaderField: "WWW-Authenticate")
            self.manager.requestSerializer.setValue("Token \(self.token)", forHTTPHeaderField: "Authorization")
        }
        return manager
    }
    
    func getResponseHandler(completion: (result: AnyObject) -> Void) -> (operation: NSURLSessionDataTask,responseObject: AnyObject?) -> Void{
        return {(operation: NSURLSessionDataTask,responseObject: AnyObject?) in
            if responseObject != nil{
                completion(result: responseObject!)
            } else {
                completion(result: false)
            }
        }
    }
    
    func getErrorHandler(completion: (result: AnyObject) -> Void) -> (operation: NSURLSessionDataTask?,error: NSError!) -> Void{
        return {(operation: NSURLSessionDataTask?,error: NSError!) in
            completion(result: false)
            self.printError(error)
            print("Error: " + error.localizedDescription)
        }
    }
    
    func printError(error:NSError){
        if let info = error.userInfo as? Dictionary<String, AnyObject>{
            if let data = info["com.alamofire.serialization.response.error.data"] as? NSData{
                if let res = NSString(data: data, encoding: NSUTF8StringEncoding){
                    print(res)
                    res.stringByReplacingOccurrencesOfString("\"", withString: "", options: [], range: NSMakeRange(0,res.length))
                } else {
                }
            }
        }
    }
    
    func http(url: String, message: Dictionary<String, AnyObject>? = nil, isJSONRequest: Bool = true, method: RequestType = .GET, useURLPrefix: Bool = true, completion: (result: AnyObject) -> Void) -> Void{
        if (!NetworkUtils.checkConnection()){
            completion(result: false)
            return
        }
        let manager = getAFManager(isJSONRequest)
        let requestUrl = useURLPrefix ? SERVER_URL + url : url
        switch method{
        case .POST:
            manager.POST(requestUrl, parameters: message, progress: nil, success: getResponseHandler(completion),failure: getErrorHandler(completion))
            break
        case .GET:
            manager.GET(requestUrl, parameters: message, progress: nil, success: getResponseHandler(completion),failure: getErrorHandler(completion))
            break
        case .PATCH:
            manager.PATCH(requestUrl, parameters: message, success: getResponseHandler(completion),failure: getErrorHandler(completion))
            break
        case .PUT:
            manager.PUT(requestUrl, parameters: message, success: getResponseHandler(completion),failure: getErrorHandler(completion))
            break
        case .DELETE:
            manager.DELETE(requestUrl, parameters: message, success: getResponseHandler(completion),failure: getErrorHandler(completion))
            break
        }
    }
    func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().UUIDString)"
    }
    
    func uploadFile(data: NSData, filename:String, mimetype: String = "image/jpeg", completion: (result: AnyObject) -> Void) -> Void{
        if (!NetworkUtils.checkConnection()){
            completion(result: false)
            return
        }
        let request = NSMutableURLRequest(URL: NSURL(string: SERVER_URL + "/resources/upload/")!)
        let session = NSURLSession.sharedSession()
        
        request.HTTPMethod = "PUT"
        let boundary = generateBoundaryString()
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let body = NSMutableData()
        let mimetype = mimetype
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
        body.appendString("Content-Type: \(mimetype)\r\n\r\n")
        body.appendData(data)
        body.appendString("\r\n")
        body.appendString("--\(boundary)--\r\n")
        request.HTTPBody = body
        
        
        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            print("Response: \(response)")
            if (response == nil || (response as! NSHTTPURLResponse).statusCode > 299){
                completion(result: [:])
                return
            }
            let strData = NSString(data: data!, encoding: NSUTF8StringEncoding)
            print("Body: \(strData)")
            var err: NSError?
            var json: AnyObject?
            do {
                json = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableLeaves)
            } catch let error as NSError {
                err = error
                json = nil
            } catch {
                fatalError()
            }
            
            // Did the JSONObjectWithData constructor return an error? If so, log the error to the console
            if(err != nil) {
                print(err!.localizedDescription)
                let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print("Error could not parse JSON: '\(jsonStr)'")
            }
            else {
                // The JSONObjectWithData constructor didn't return an error. But, we should still
                // check and make sure that json has a value using optional binding.
                if nil != json {
                    // Okay, the parsedJSON is here, let's get the value for 'success' out of it
                    //                    var success = parseJSON["firstName"] as? String
                    //                    println("Succes: \(success)")
                    completion(result: json!)
                }
                else {
                    // Woa, okay the json object was nil, something went worng. Maybe the server isn't running?
                    let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
                    print("Error could not parse JSON: \(jsonStr)")
                }
            }
        })
        task.resume()
    }
    
    func downloadFile(url: String, completion: (result: AnyObject) -> Void) -> Void{
        let session = NSURLSession.sharedSession()
        
        let task = session.downloadTaskWithURL(NSURL(string: url)!, completionHandler: { (nsUrl, response, error) -> Void in
            print(response!.suggestedFilename)
            do {
                try NSFileManager.defaultManager().moveItemAtPath(nsUrl!.path!, toPath:response!.suggestedFilename!)
            } catch _ {
            };
            completion(result: NSURL(fileURLWithPath: response!.suggestedFilename!))
            
        })
        task.resume()
    }
    
    
}